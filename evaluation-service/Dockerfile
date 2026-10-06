# syntax=docker/dockerfile:1

# --- Estágio 1: Build ---
FROM golang:1.22-alpine AS builder

RUN apk add --no-cache git

WORKDIR /src

ARG REPO_URL=https://github.com/FIAP-TCs/evaluation-service.git
ARG REPO_REF=5e8ade059f69650d2e8cfbefad0a83cfac25f0a9

# Forma correta de baixar um commit específico sem falhar no git fetch
RUN git init \
    && git remote add origin "$REPO_URL" \
    && git fetch --depth 1 origin "$REPO_REF" \
    && git checkout FETCH_HEAD

# Sobrescreve o arquivo corrigido (certifique-se de remover o import "context" dele)
COPY evaluator.go ./evaluator.go

# Regenera go.sum e baixa dependências
RUN rm -f go.sum && go mod tidy && go mod download

# Compila o binário da aplicação
RUN CGO_ENABLED=0 GOOS=linux go build -trimpath -ldflags="-s -w" -o /out/evaluation-service .

# Compila o mini healthcheck em Go (substitui wget/curl)
RUN echo 'package main; import ("net/http"; "os"); func main() { resp, err := http.Get("http://127.0.0.1:8004/health"); if err != nil || resp.StatusCode != 200 { os.Exit(1) } }' > /tmp/healthcheck.go \
    && CGO_ENABLED=0 GOOS=linux go build -trimpath -ldflags="-s -w" -o /out/healthcheck /tmp/healthcheck.go


# --- Estágio 2: Runtime (Distroless Ultra-Seguro) ---
FROM gcr.io/distroless/static-debian12:nonroot AS runtime

WORKDIR /app

COPY --from=builder /out/evaluation-service /app/evaluation-service
COPY --from=builder /out/healthcheck /app/healthcheck

USER nonroot:nonroot
EXPOSE 8004

HEALTHCHECK --interval=10s --timeout=3s --start-period=5s --retries=5 \
    CMD ["/app/healthcheck"]

ENTRYPOINT ["/app/evaluation-service"]
