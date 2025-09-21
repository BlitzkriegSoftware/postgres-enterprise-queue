FROM postgres:16-trixie
RUN apt update -y
RUN apt upgrade -y
RUN apt install curl ca-certificates cron -y
RUN apt install postgresql-16-cron -y
# .pgpass
RUN mkdir -p /var/lib/postgresql/data
COPY ./data/.pgpass /var/lib/postgresql/data/.pgpass
RUN chmod 0600 /var/lib/postgresql/data/.pgpass
# postgres configuration for pg_cron
RUN mkdir -p /var/lib/postgresql/data/pgdata
COPY ./data/postgresql.conf.cron /var/lib/postgresql/data/postgresql.conf.cron
RUN chmod +r /var/lib/postgresql/data/postgresql.conf.cron
ENV POSTGRES_SHARED_PRELOAD_LIBRARIES="pg_cron"
ENV CRON_DATABASE_NAME="postgres"