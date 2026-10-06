# syntax=docker/dockerfile:1

# --- Estagio 1: Build (dependencias) ---
FROM python:3.11-slim AS builder

RUN apt-get update && apt-get install -y --no-install-recommends git \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /src

# Pinado no commit atual (nao em "main") -- ver nota de reprodutibilidade nos
# Dockerfiles Go. Para atualizar: troque REPO_REF pelo novo commit.
ARG REPO_URL=https://github.com/FIAP-TCs/flag-service.git
ARG REPO_REF=21052b1abcf209ea6848350bdd9928b80b7f86fe
RUN git clone --depth 1 "$REPO_URL" . \
    && git fetch --depth 1 origin "$REPO_REF" \
    && git checkout "$REPO_REF"

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
EXPOSE 8002

HEALTHCHECK --interval=10s --timeout=3s --start-period=5s --retries=5 \
    CMD curl -fsS http://127.0.0.1:8002/health || exit 1

CMD ["gunicorn", "--bind", "0.0.0.0:8002", "--workers", "2", "--timeout", "30", "app:app"]
