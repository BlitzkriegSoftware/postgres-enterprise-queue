# README.md -- Start Here

- [README.md -- Start Here](#readmemd----start-here)
  - [See Also](#see-also)
  - [Generate an enterprise queue](#generate-an-enterprise-queue)
    - [Prerequisites](#prerequisites)
    - [Preperation](#preperation)
  - [Make an enterprise queue](#make-an-enterprise-queue)
    - [Make-Queue: What does it do?](#make-queue-what-does-it-do)
  - [How to use your Queue](#how-to-use-your-queue)

## See Also
- [Message Lifecycle](./MESSAGE_LIFECYCLE.md)
- [Schema](./SCHEMA.md)
- [Adminstration](./PEQ_ADMIN.md)
- [Configuration](./CONFIG.md)
- [Use the Queue](./USE_QUEUE.md)
- [FAQ](./FAQ.md)

## Generate an enterprise queue

Here is how to generate an enterprise queue in the desired schema. One schema per enteprise queue is the design choice for this library.

### Prerequisites

Make sure you have: Powershell 7+

### Preperation

Checklist

> Prefer: the snake_case convention for postgres names, avoiding reserved words

- [ ] Decide on the DB to host your PEQ
- [ ] Decide on a unique schema name to host your queue artifacts, thus deleting the schema deletes the queue (and warning! the history)
- [ ] Decide if you need a custom role, and if so, pick a unique name

## Make an enterprise queue

```powershell
.\make-queue.ps1 `
    -ConnectionString "postgresql://postgres:password123-@localhost:5432/postgres" `
    -SchemaName "test01" `
    -RoleName "test-q-role"
```

Arguments:
- `ConnectionString`: valid Postgres Connection String (sample is the docker one)
- `SchemaName`: (required) schema to put the queue into
- `RoleName`: (unused, future)

### Make-Queue: What does it do?

1. Takes the schema in `sql\` that start with `##_`, starting at the minimum index of *110* inclusive
2. In each file replaces `{schema}` token with your schema name, and `{rolename}` with your role name
3. Copies transformed files into `temp\` folder which is emptied first
4. Execute scripts in numeric order ascending at the postgres instance and database in the connection string
5. When done, the queue is ready for use

This will create the objects in [schema](./SCHEMA.md) and the default [configuration](./CONFIG.md).

With empty tables, except the lookup tables of:

- [Configuration Settings](../data/sql/700_queue_configuration_Data.sql)
- [Message States](../data/sql/702_message_state_Data.sql)

It will also setup the [CRON jobs](./PEQ_ADMIN.md#scheduled-jobs)

## How to use your Queue

This of course, why we made it in the first place. See: [Use your Queue](./USE_QUEUE.md)

[^Home](../README.md)