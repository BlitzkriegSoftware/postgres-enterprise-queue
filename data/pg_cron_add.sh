#!/usr/bin/env bash
export username="postgres"
export PGPASSWORD="password123-"
export master="postgres"
set -o xtrace
cd /usr/lib/postgresql/16/bin
./psql  -h "localhost" -U "${username}" -d "${master}" -a -f /var/lib/postgresql/data/sql/020_create_extensions.sql
set +o xtrace