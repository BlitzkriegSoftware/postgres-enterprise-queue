FROM postgres:13.22-trixie
RUN apt update -y
RUN apt upgrade -y
RUN apt install curl ca-certificates cron -y
RUN apt install postgresql-16-cron -y
# Deal w. weird version path problem
RUN mkdir -p /usr/share/postgresql/13
RUN cp -r /usr/share/postgresql/16/extension /usr/share/postgresql/13
# .pgpass
RUN mkdir -p /var/lib/postgresql/data
COPY ./data/.pgpass /var/lib/postgresql/data/.pgpass
RUN chmod 0600 /var/lib/postgresql/data/.pgpass
# postgres configuration for pg_cron
RUN mkdir -p /var/lib/postgresql/data/pgdata
COPY ./data/postgresql.conf.cron /var/lib/postgresql/data/postgresql.conf.cron

ENV POSTGRES_SHARED_PRELOAD_LIBRARIES="pg_cron"
ENV CRON_DATABASE_NAME="postgres"