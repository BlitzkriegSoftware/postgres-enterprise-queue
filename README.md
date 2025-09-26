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

- [Start Here](./README.md)
- [Message Lifecycle](./src/MESSAGE_LIFECYCLE.md)
- [Schema](./src/SCHEMA.md)
- [Adminstration](./src/PEQ_ADMIN.md)
- [Configuration](./src/CONFIG.md)
