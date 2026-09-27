#!/bin/bash
set -e
# Este container ja sobe com o banco padrao (POSTGRES_DB=flags_db).
# Aqui criamos o segundo banco que targeting-service vai usar.
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
    CREATE DATABASE targeting_db;
EOSQL
