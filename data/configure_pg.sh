#!/usr/bin/env bash
# pgpass
chmod 0600 ./.pgpass
# Upgrade
apt update -y
apt upgrade -y
apt install curl ca-certificates -y
# Register plug-in source
/usr/share/postgresql-common/pgdg/apt.postgresql.org.sh -y
# Cron Plug-In
apt install postgresql-16-cron -y
cp ./pgdata/postgresql.conf  ./pgdata/postgresql.conf.backup
sed -i /#shared_preload_libraries/s/#shared_preload_libraries/shared_preload_libraries/g ./pgdata/postgresql.conf
sed -i /shared_preload_libraries/s/\'\'/\'pg_cron\'/g ./pgdata/postgresql.conf
cat ./postgres_conf_adds.txt >> ./pgdata/postgresql.conf
# Restart DB
su -- postgres -c ./configure_pg.sh
