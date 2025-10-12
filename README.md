# postgres-enterprise-queue

- [postgres-enterprise-queue](#postgres-enterprise-queue)
  - [Enterprise Queuing](#enterprise-queuing)
  - [Start Postgres and install cron \& pg\_cron](#start-postgres-and-install-cron--pg_cron)
    - [What does it do?](#what-does-it-do)
    - [Docker Postgres SQL Connection String](#docker-postgres-sql-connection-string)
  - [open a bash shell on Postgres container](#open-a-bash-shell-on-postgres-container)
  - [stop postgres](#stop-postgres)
    - [What it does](#what-it-does)
  - [Leverages](#leverages)
    - [pg\_cron](#pg_cron)

Postgres queue with leasing, cleanup, etc.

## Enterprise Queuing

Here are the documents for Postgres Enterprise Queues (PEQ)

- [Start Here](./doc/README.md)
- [Message Lifecycle](./doc/MESSAGE_LIFECYCLE.md)
- [Schema](./doc/SCHEMA.md)
- [Adminstration](./doc/PEQ_ADMIN.md)
- [Configuration](./doc/CONFIG.md)
- [Use the Queue](./doc/USE_QUEUE.md)
- [FAQ](./doc/FAQ.md)

## Start Postgres and install cron & pg_cron

```powershell
.\start-pg.ps1
```

### What does it do?

1. Creates a custom variation of Psotgres from `Dockerfile`
2. Adds in plugins we want (see file above)
3. Configures plugins
4. Starts container running, which starts base postgres
5. Reconfigures postgres
6. Restarts postgres
7. Finishes up
8. Postgres w. plugins ready for use

> Horrible work arounds, if you have a better way, create an issue, or put in a PR
> It works though.

### Docker Postgres SQL Connection String

```text
postgresql://postgres:password123-@localhost:5432/postgres
```

## open a bash shell on Postgres container

```powershell
.\bash-pg.ps1
```

It opens a bash shell...with handy guidance

```text
SQL Scripts Folder: /var/lib/postgresql/data
  su -- postgres -c {pg_command}
Postgres Utilities Folder: /usr/lib/postgresql/16/bin
Postgres Logs: /var/log/postgresql
root@248bcee33ea9:/var/lib/postgresql/data#
```


## stop postgres

```powershell
.\stop-pg.ps1
```

### What it does

1. Stops image
2. Does a tear down (you can customize to stop this, change start too.

## Leverages

### pg_cron

- [pg_cron](https://github.com/citusdata/pg_cron)
