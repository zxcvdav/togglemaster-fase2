# --- Estágio 1: Build ---
FROM golang:1.22-alpine AS builder

RUN apk add --no-cache git

WORKDIR /src

# Código-fonte vem da pasta do serviço (contexto de build), filtrado pelo .dockerignore
COPY . .

# O go.sum do repositório está corrompido (contém o texto de um go.mod), então é
# descartado; -mod=mod resolve as dependências e regenera o go.sum no build.
RUN rm -f go.sum \
    && CGO_ENABLED=0 GOOS=linux go build -mod=mod -trimpath -ldflags="-s -w" -o /out/evaluation-service .

# Mini healthcheck em Go (a imagem distroless não tem wget/curl/shell)
RUN echo 'package main; import ("net/http"; "os"); func main() { resp, err := http.Get("http://127.0.0.1:8004/health"); if err != nil || resp.StatusCode != 200 { os.Exit(1) } }' > /tmp/healthcheck.go \
    && CGO_ENABLED=0 GOOS=linux go build -trimpath -ldflags="-s -w" -o /out/healthcheck /tmp/healthcheck.go

# --- Estágio 2: Runtime (distroless) ---
FROM gcr.io/distroless/static-debian12:nonroot AS runtime

WORKDIR /app

COPY --from=builder /out/evaluation-service /app/evaluation-service
COPY --from=builder /out/healthcheck /app/healthcheck

USER nonroot:nonroot
EXPOSE 8004

HEALTHCHECK --interval=10s --timeout=3s --start-period=5s --retries=5 \
    CMD ["/app/healthcheck"]

ENTRYPOINT ["/app/evaluation-service"]