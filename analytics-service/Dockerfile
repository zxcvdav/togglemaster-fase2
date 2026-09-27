# syntax=docker/dockerfile:1

# --- Estagio 1: Build (dependencias) ---
FROM python:3.11-slim AS builder

RUN apt-get update && apt-get install -y --no-install-recommends git \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /src

ARG REPO_URL=https://github.com/FIAP-TCs/analytics-service.git
ARG REPO_REF=212d7e9b7e50f881c4022bc9e8d2722f08a2a3e2
RUN git clone --depth 1 "$REPO_URL" . \
    && git fetch --depth 1 origin "$REPO_REF" \
    && git checkout "$REPO_REF"

# PATCH OBRIGATORIO: app.py do upstream cria o client do DynamoDB sem
# endpoint_url, entao nao ha como apontar para o DynamoDB Local via variavel
# de ambiente (boto3==1.26.50 e anterior ao AWS_ENDPOINT_URL_DYNAMODB nativo).
# Este COPY sobrescreve com a versao com o endpoint_url opcional adicionado.
COPY app.py ./app.py

RUN python -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"
RUN pip install --no-cache-dir --upgrade pip \
    && pip install --no-cache-dir -r requirements.txt

# --- Estagio 2: Runtime ---
FROM python:3.11-slim AS runtime

RUN apt-get update \
    && apt-get install -y --no-install-recommends curl \
    && rm -rf /var/lib/apt/lists/* \
    && groupadd -r app && useradd -r -g app app

WORKDIR /app
COPY --from=builder /opt/venv /opt/venv
COPY --from=builder /src /app

ENV PATH="/opt/venv/bin:$PATH" \
    PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

USER app
EXPOSE 8005

HEALTHCHECK --interval=10s --timeout=3s --start-period=5s --retries=5 \
    CMD curl -fsS http://127.0.0.1:8005/health || exit 1

CMD ["gunicorn", "--bind", "0.0.0.0:8005", "--workers", "1", "--timeout", "60", "app:app"]
