FROM postgres:16.9-trixie
RUN apt update -y
RUN apt upgrade -y
RUN apt install curl ca-certificates cron -y
RUN apt install postgresql-16-cron -y
RUN apt install postgresql-16-pldebugger -y
# .pgpass
RUN mkdir -p /var/lib/postgresql/data
COPY ./data/.pgpass /var/lib/postgresql/data/.pgpass
RUN chmod 0600 /var/lib/postgresql/data/.pgpass
# pg_hba.conf with updates
RUN mkdir -p /var/lib/postgresql/data/pgdata
COPY ./data/pg_hba.conf /var/lib/postgresql/data/pgdata/pg_hba.conf
RUN chmod 0600 /var/lib/postgresql/data/pgdata/pg_hba.conf
# postgres configuration for pg_cron
RUN mkdir -p /var/lib/postgresql/data/pgdata
COPY ./data/configure_pg.sh /var/lib/postgresql/data/configure_pg.sh
RUN chmod +rx /var/lib/postgresql/data/configure_pg.sh
COPY ./data/pg_cron_add.sh /var/lib/postgresql/data/pg_cron_add.sh
RUN chmod +rx /var/lib/postgresql/data/pg_cron_add.sh
COPY ./data/postgresql.conf.cron /var/lib/postgresql/data/postgresql.conf.cron
RUN chmod +r /var/lib/postgresql/data/postgresql.conf.cron
ENV POSTGRES_SHARED_PRELOAD_LIBRARIES="pg_cron"
ENV CRON_DATABASE_NAME="postgres"