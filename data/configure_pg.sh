#!/usr/bin/env bash
set -o xtrace
# pgpass
chmod 0600 /var/lib/postgresql/data/.pgpass
# Upgrade
apt update -y
apt upgrade -y
apt install curl ca-certificates cron -y
# Register plug-in source
/usr/share/postgresql-common/pgdg/apt.postgresql.org.sh -y
# Cron Plug-In
apt install postgresql-pg-cron
set +o xtrace
