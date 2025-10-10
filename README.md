# postgres-enterprise-queue

Postgres queue with leasing, cleanup, etc, leverages [pg_cron](https://github.com/citusdata/pg_cron)

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

## stop postgres

```powershell
.\stop-pg.ps1
```

### What it does

1. Stops image
2. Does a tear down (you can customize to stop this, change start too.

## Make an enterprise queue

```powershell
.\make-queue.ps1 `
    -ConnectionString "postgresql://postgres:password123-@localhost:5432/postgres" `
    -SchemaName "test01" 
```

* `ConnectionString`: valid Postgres Connectiojn String (sample is the docker one)
* `SchemaName`: (required) schema to put the queue into 
* `RoleName`: (unused, future)

### What does it do?

1. Takes the schema in `sql\` 
2. In each file replaces `{schema}` token with your schema name
3. Copies transformed files into `temp\` folder
4. Plays scripts in numeric order ascending at the postgres instance and database in the connection string
5. Queue is ready for use

## Leverages

### pg_cron

- [pg_cron](https://github.com/citusdata/pg_cron)

```sql
-- list of jobs
select jobid, jobname, schedule, command from cron.job;

-- job execution history
select * from cron.job_run_details order by start_time desc;
```

## Enterprise Queuing

Here are the documents for Postgres Enterprise Queues (PEQ)

- [Start Here](./doc/README.md)
- [Message Lifecycle](./doc/MESSAGE_LIFECYCLE.md)
- [Schema](./doc/SCHEMA.md)
- [Adminstration](./doc/PEQ_ADMIN.md)
- [Configuration](./doc/CONFIG.md)
