# syntax=docker/dockerfile:1

# --- Build stage ---
FROM golang:1.21-alpine AS builder

WORKDIR /app

# Instala git para resolução de dependências
RUN apk add --no-cache git

# Copia arquivos de dependência
COPY go.mod go.sum* ./

# Baixa dependências conhecidas
RUN go mod download

# Copia todo o código-fonte
COPY . .

# Sincroniza e corrige o go.mod/go.sum
RUN go mod tidy

# Compila a aplicação gerando o binário
RUN CGO_ENABLED=0 GOOS=linux go build -trimpath -ldflags="-s -w" -o /app/auth-service .

# --- Runtime stage ---
FROM alpine:3.19 AS runtime

# Instala certificados, cliente Postgres e wget para o HEALTHCHECK
# Cria grupo e usuário não-root por segurança
RUN apk add --no-cache ca-certificates postgresql-client wget \
    && addgroup -S app && adduser -S app -G app

WORKDIR /app

# Copia o binário compilado do estágio builder
COPY --from=builder /app/auth-service .

# Copia a pasta db/ se ela existir no projeto (o wildcard db* impede o build de falhar se a pasta não existir)
COPY --chown=app:app db* ./db/

# Define o usuário não-privilegiado
USER app

EXPOSE 8001
ENV PORT=8001

# Healthcheck usando o wget instalado
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD wget --no-verbose --tries=1 --spider http://localhost:${PORT}/health || exit 1

ENTRYPOINT ["/app/auth-service"]









