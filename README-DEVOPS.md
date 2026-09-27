# Como rodar o ecossistema ToggleMaster localmente

## 0. Pré-requisitos
- Docker + Docker Compose v2 (`docker compose version` deve funcionar).
- Acesso de rede de saída no momento do build (os Dockerfiles clonam os repositórios via `git` e baixam dependências Go/pip -- ver seção 2).

## 1. Descompacte o pacote
Não precisa clonar nenhum dos 5 repositórios. Cada Dockerfile faz `git clone`
do repositório real (FIAP-TCs) dentro do próprio estágio de build, pinado no
commit atual de cada repo. Só descompacte `togglemaster-infra.zip` e entre na
pasta:

```
togglemaster-infra/
├── docker-compose.yml
├── .env.example
├── db-init/
│   ├── postgres-auth/
│   └── postgres-flags/
├── auth-service/           <- so Dockerfile + .dockerignore
├── flag-service/            <- so Dockerfile + .dockerignore
├── targeting-service/        <- so Dockerfile + .dockerignore
├── evaluation-service/      <- Dockerfile + .dockerignore + evaluator.go (patch)
└── analytics-service/        <- Dockerfile + .dockerignore + app.py (patch)
```

## 2. Como os dois patches obrigatórios são aplicados
Você não precisa fazer nada manualmente aqui -- os Dockerfiles de
`evaluation-service` e `analytics-service` clonam o repositório real e depois
sobrescrevem, via `COPY`, o único arquivo quebrado pela versão corrigida que
já está na pasta (`evaluator.go` e `app.py`, respectivamente). Se quiser
conferir o motivo de cada patch, veja os comentários dentro dos próprios
Dockerfiles.

**Atualizando para um commit mais novo do repositório upstream:** os
Dockerfiles pinam `ARG REPO_REF=<sha>` no commit que existia quando isso foi
escrito, e não em `main` -- uma tag móvel faria o Docker reaproveitar uma
imagem em cache de uma versão antiga do código sem avisar, mesmo que o
upstream tenha mudado. Se o repositório evoluir, atualize manualmente o SHA
no `ARG` do Dockerfile correspondente (ou passe `--build-arg
REPO_REF=<novo-sha>` na hora do build) e rode `docker compose build --no-cache
<servico>`.

**Limitação que não testei de fato:** não tenho um daemon Docker neste
ambiente para rodar `docker build`/`docker compose up` de ponta a ponta. Os
Dockerfiles foram construídos a partir da leitura direta do código-fonte de
cada repositório e de práticas padrão de Go/Python/Postgres, mas isso não
substitui rodar o build de verdade -- se algo quebrar no seu ambiente, o log
do `docker compose logs -f <servico>` é o próximo passo, não uma suposição
minha sobre o que está errado.

## 3. Configure o .env
```bash
cp .env.example .env
```
Deixe `SERVICE_API_KEY` em branco por enquanto -- ela só existe depois do passo 5.

## 4. Suba o stack
```bash
docker compose up -d --build
```
Isso builda as 5 imagens e sobe: 2 Postgres, Redis, DynamoDB Local (+ o job `dynamodb-init`, que cria a tabela e sai sozinho), e os 5 microsserviços. `evaluation-service` sobe, mas sem `SERVICE_API_KEY` ele não consegue autenticar no `flag-service`/`targeting-service` -- isso é esperado neste ponto.

Acompanhe com:
```bash
docker compose ps
docker compose logs -f
```

## 5. Crie a API key de serviço e reinicie o evaluation-service
```bash
curl -X POST http://localhost:8001/admin/keys \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer admin-secreto-123" \
  -d '{"name": "evaluation-service-key"}'
```
Copie o `key` retornado, cole em `SERVICE_API_KEY=` no `.env`, e:
```bash
docker compose up -d evaluation-service
```

## 6. Valide o fluxo completo
1. Crie uma flag: `POST http://localhost:8002/flags` (com a mesma chave, ou crie outra via passo 5 para o seu próprio uso de teste).
2. Crie uma regra de segmentação: `POST http://localhost:8003/rules`.
3. Avalie: `GET http://localhost:8004/evaluate?user_id=...&flag_name=...` -- rode duas vezes e confira o log "Cache HIT" na segunda.
4. Confira o DynamoDB Local:
   ```bash
   aws dynamodb scan --table-name ToggleMasterAnalytics --endpoint-url http://localhost:8000
   ```
   (funciona sem credenciais reais, com `AWS_ACCESS_KEY_ID=local` `AWS_SECRET_ACCESS_KEY=local` no ambiente do seu shell, já que o DynamoDB Local não valida nada).

## Limitações conhecidas e intencionais
- **SQS continua sendo AWS real.** Os READMEs originais referenciam AWS Academy, então isso não foi tratado como lacuna a fechar -- só a conta com DynamoDB Local. Sem `AWS_SQS_URL`/credenciais reais, o `evaluation-service` loga `[SQS_DISABLED]` e segue normalmente; o `analytics-service` fica tentando `receive_message` contra a fila-placeholder e logando erro a cada ~10s (não trava, só não recebe nada).
- **`dynamodb-init` é idempotente por causa do `|| echo`.** Em re-execuções, `create-table` falha porque a tabela já existe, mas o job retorna código 0 mesmo assim. Se você quiser diferenciar "já existe" de "erro de verdade", isso precisa de tratamento mais fino no `command`.
