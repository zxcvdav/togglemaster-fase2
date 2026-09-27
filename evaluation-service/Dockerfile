# syntax=docker/dockerfile:1

# --- Estagio 1: Build ---
FROM golang:1.21-alpine AS builder

RUN apk add --no-cache git

WORKDIR /src

ARG REPO_URL=https://github.com/FIAP-TCs/evaluation-service.git
ARG REPO_REF=5e8ade059f69650d2e8cfbefad0a83cfac25f0a9
RUN git clone --depth 1 "$REPO_URL" . \
    && git fetch --depth 1 origin "$REPO_REF" \
    && git checkout "$REPO_REF"

# PATCH OBRIGATORIO: evaluator.go do upstream nao compila (usa os.Getenv sem
# importar "os" no arquivo). Este COPY sobrescreve o arquivo quebrado com a
# versao corrigida que fica ao lado deste Dockerfile no build context.
COPY evaluator.go ./evaluator.go

# go.sum commitado no upstream esta corrompido (contem o conteudo de go.mod,
# nao checksums) -- removemos e deixamos `go mod tidy` regenerar um valido.
RUN rm -f go.sum && go mod tidy && go mod download

RUN CGO_ENABLED=0 GOOS=linux go build -trimpath -ldflags="-s -w" -o /out/evaluation-service .

# --- Estagio 2: Runtime ---
FROM alpine:3.19 AS runtime

RUN apk add --no-cache ca-certificates wget \
    && addgroup -S app && adduser -S app -G app

WORKDIR /app
COPY --from=builder /out/evaluation-service .

USER app
EXPOSE 8004

HEALTHCHECK --interval=10s --timeout=3s --start-period=5s --retries=5 \
    CMD wget -qO- http://127.0.0.1:8004/health || exit 1

ENTRYPOINT ["/app/evaluation-service"]
