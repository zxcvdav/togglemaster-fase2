# syntax=docker/dockerfile:1

# --- Estagio 1: Build (dependencias) ---
FROM python:3.11-slim AS builder

# Instalar dependências para compilar pacotes (como psycopg2)
RUN apt-get update && apt-get install -y --no-install-recommends \
    gcc \
    libpq-dev \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /src

# Criar ambiente virtual
RUN python -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"
RUN pip install --no-cache-dir --upgrade pip

# Copiar apenas o requirements primeiro (melhora o uso de cache do Docker)
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copiar todo o resto do código da sua máquina para o container
COPY . .

# --- Estagio 2: Runtime ---
FROM python:3.11-slim AS runtime

# Instalar curl (para healthcheck) e libpq5 (necessário para o psycopg2 rodar)
RUN apt-get update \
    && apt-get install -y --no-install-recommends curl libpq5 \
    && rm -rf /var/lib/apt/lists/* \
    && groupadd -r app && useradd -r -g app app

WORKDIR /app

# Copiar o ambiente virtual e o código do estágio de build
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