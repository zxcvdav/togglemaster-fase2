# syntax=docker/dockerfile:1

# --- Estagio 1: Build ---
FROM golang:1.21-alpine AS builder

RUN apk add --no-cache git

WORKDIR /src

# Pinado no commit atual do repo (nao em "main") para builds reproduziveis --
# uma tag movel faria o `docker build` sem --no-cache continuar servindo uma
# imagem cacheada de uma versao antiga do codigo mesmo que o upstream mude.
# Para atualizar: troque REPO_REF pelo novo commit apos validar.
ARG REPO_URL=https://github.com/FIAP-TCs/auth-service.git
ARG REPO_REF=56e447f83409bf35b22ef04a9e39c2e30df9af33
RUN git clone --depth 1 "$REPO_URL" . \
    && git fetch --depth 1 origin "$REPO_REF" \
    && git checkout "$REPO_REF"

# NOTA: repo original nao tem go.sum commitado -- `go mod tidy` regenera um
# valido, exigindo rede ate o proxy do Go durante o build (normal).
RUN go mod tidy && go mod download

RUN CGO_ENABLED=0 GOOS=linux go build -trimpath -ldflags="-s -w" -o /out/auth-service .

# --- Estagio 2: Runtime ---
FROM alpine:3.19 AS runtime

RUN apk add --no-cache ca-certificates wget \
    && addgroup -S app && adduser -S app -G app

WORKDIR /app
COPY --from=builder /out/auth-service .

USER app
EXPOSE 8001

HEALTHCHECK --interval=10s --timeout=3s --start-period=5s --retries=5 \
    CMD wget -qO- http://127.0.0.1:8001/health || exit 1

ENTRYPOINT ["/app/auth-service"]
