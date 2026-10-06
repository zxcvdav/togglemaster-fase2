# syntax=docker/dockerfile:1

# --- Estagio 1: Build (dependencias) ---
FROM python:3.11-slim AS builder

RUN apt-get update && apt-get install -y --no-install-recommends \
    gcc \
    libpq-dev \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /src

RUN python -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

RUN pip install --no-cache-dir --upgrade pip

# Copia o requirements.txt da sua máquina local
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copia todo o código local do targeting-service para dentro do container
COPY . .

# --- Estagio 2: Runtime ---
FROM python:3.11-slim AS runtime

RUN apt-get update \
    && apt-get install -y --no-install-recommends curl libpq5 \
    && rm -rf /var/lib/apt/lists/* \
    && groupadd -r app && useradd -r -g app app

WORKDIR /app
COPY --from=builder /opt/venv /opt/venv
COPY --from=builder /src /app

ENV PATH="/opt/venv/bin:$PATH" \
    PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

USER app
EXPOSE 8003

HEALTHCHECK --interval=10s --timeout=3s --start-period=5s --retries=5 \
    CMD curl -fsS http://127.0.0.1:8003/health || exit 1

CMD ["gunicorn", "--bind", "0.0.0.0:8003", "--workers", "2", "--timeout", "30", "app:app"]