#!/usr/bin/env bash
set -o xtrace
# pgpass
chmod 0600 /var/lib/postgresql/data/.pgpass
# Upgrade
apt update -y
apt upgrade -y
apt install curl ca-certificates -y
# Register plug-in source
/usr/share/postgresql-common/pgdg/apt.postgresql.org.sh -y
# Cron Plug-In
apt install postgresql-16-cron -y
pushd /var/lib/postgresql/data/pgdata
cp ./postgresql.conf ./postgresql.conf.backup
sed -i /#shared_preload_libraries/s/#shared_preload_libraries/shared_preload_libraries/g ./postgresql.conf
sed -i /shared_preload_libraries/s/\'\'/\'pg_cron\'/g ./postgresql.conf
cat ../postgres_conf_adds.txt >> ./postgresql.conf
popd
# Restart DB
su -- postgres -c /var/lib/postgresql/data/restart_pg.sh
set +o xtrace
