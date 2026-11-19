#!/bin/bash
set -euo pipefail

cd /cartodb

if [ ! -f config/database.yml ]; then
  cp config/database.yml.sample config/database.yml
fi

if [ ! -f config/app_config.yml ]; then
  cp config/app_config.yml.sample config/app_config.yml
fi

mkdir -p log tmp/pids tmp/cache tmp/sockets

if [ -n "${PGHOST:-}" ]; then
  for _ in $(seq 1 30); do
    pg_isready -h "$PGHOST" -U "${PGUSER:-postgres}" && break
    sleep 1
  done
  db_name="${PGDATABASE:-carto_db_${RAILS_ENV:-test}}"
  if ! psql -h "$PGHOST" -U "${PGUSER:-postgres}" -d postgres -tAc "SELECT 1 FROM pg_database WHERE datname = '${db_name}'" | grep -q 1; then
    psql -h "$PGHOST" -U "${PGUSER:-postgres}" -d postgres -c "CREATE DATABASE \"${db_name}\""
  fi
fi

bundle check || bundle install

exec "$@"
