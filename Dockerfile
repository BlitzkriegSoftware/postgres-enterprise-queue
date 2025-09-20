FROM postgres:16-trixie
RUN apt update -y
RUN apt upgrade -y
RUN apt install curl ca-certificates cron -y
RUN apt install postgresql-16-cron -y
# Deal w. weird version path problem
# RUN mkdir -p /usr/share/postgresql/17/extension
# RUN mkdir -p /usr/lib/postgresql/17/lib/bitcode/pg_cron/src/
# RUN cp /usr/share/postgresql/16/extension/pg_cron.control /usr/share/postgresql/17/extension/pg_cron.control
# RUN cp /usr/share/postgresql/16/extension/pg_cron--1.1--1.2.sql /usr/share/postgresql/17/extension/pg_cron--1.1--1.2.sql
# RUN cp /usr/share/postgresql/16/extension/pg_cron--1.4-1--1.5.sql /usr/share/postgresql/17/extension/pg_cron--1.4-1--1.5.sql
# RUN cp /usr/share/postgresql/16/extension/pg_cron--1.4--1.4-1.sql /usr/share/postgresql/17/extension/pg_cron--1.4--1.4-1.sql
# RUN cp /usr/share/postgresql/16/extension/pg_cron--1.0--1.1.sql /usr/share/postgresql/17/extension/pg_cron--1.0--1.1.sql
# RUN cp /usr/share/postgresql/16/extension/pg_cron--1.2--1.3.sql /usr/share/postgresql/17/extension/pg_cron--1.2--1.3.sql
# RUN cp /usr/share/postgresql/16/extension/pg_cron--1.0.sql /usr/share/postgresql/17/extension/pg_cron--1.0.sql
# RUN cp /usr/share/postgresql/16/extension/pg_cron--1.3--1.4.sql /usr/share/postgresql/17/extension/pg_cron--1.3--1.4.sql
# RUN cp /usr/lib/postgresql/16/lib/pg_cron.so /usr/lib/postgresql/17/lib/pg_cron.so
# RUN cp /usr/lib/postgresql/16/lib/bitcode/pg_cron/src/pg_cron.bc /usr/lib/postgresql/17/lib/bitcode/pg_cron/src/pg_cron.bc
# .pgpass
RUN mkdir -p /var/lib/postgresql/data
COPY ./data/.pgpass /var/lib/postgresql/data/.pgpass
RUN chmod 0600 /var/lib/postgresql/data/.pgpass
# postgres configuration for pg_cron
RUN mkdir -p /var/lib/postgresql/data/pgdata
COPY ./data/postgresql.conf.cron /var/lib/postgresql/data/postgresql.conf.cron

ENV POSTGRES_SHARED_PRELOAD_LIBRARIES="pg_cron"
ENV CRON_DATABASE_NAME="postgres"
ENV cron.database_name='postgres'