#!/bin/bash
set -e
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "targeting_db" \
    -f /docker-entrypoint-initdb.d/targeting-schema.sql.raw
