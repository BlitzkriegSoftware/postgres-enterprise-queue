# postgres-enterprise-queue

Postgres queue with leasing, cleanup, etc, leverages [pg_cron](https://github.com/citusdata/pg_cron)

## Start Postgres and install cron & pg_cron

```powershell
.\start-pg.ps1
```

## stop postgres

```powershell
.\stop-pg.ps1
```

## Leverages

### pg_cron

- [pg_cron](https://github.com/citusdata/pg_cron)

## Enterprise Queuing

Here are the documents for Postgres Enterprise Queues (PEQ)

- [Start Here](./doc/README.md)
- [Message Lifecycle](./doc/MESSAGE_LIFECYCLE.md)
- [Schema](./doc/SCHEMA.md)
- [Adminstration](./doc/PEQ_ADMIN.md)
- [Configuration](./doc/CONFIG.md)
