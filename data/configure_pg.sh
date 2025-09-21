#!/usr/bin/env bash
set -o xtrace
cp /var/lib/postgresql/data/postgresql.conf.cron /var/lib/postgresql/data/pgdata/postgresql.conf
su -- postgres -c 'pg_ctl restart'
set +o xtrace