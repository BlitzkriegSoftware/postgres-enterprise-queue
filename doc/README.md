# README.md -- Start Here

Please read: [Message Lifecycle](./MESSAGE_LIFECYCLE.md)

## Generate an enterprise queue

Here is how to generate an enterprise queue in the desired schema. One schema per enteprise queue is the design choice for this library.

### Prerequisites

Make sure you have:

- NPM v11+
- Node v24+
- Powershell 7+

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
    -SchemaName "test01"
```

- `ConnectionString`: valid Postgres Connectiojn String (sample is the docker one)
- `SchemaName`: (required) schema to put the queue into
- `RoleName`: (unused, future)

### Make-Queue: What does it do?

1. Takes the schema in `sql\`
2. In each file replaces `{schema}` token with your schema name
3. Copies transformed files into `temp\` folder
4. Plays scripts in numeric order ascending at the postgres instance and database in the connection string
5. Queue is ready for use

This will create the objects in [schema](./SCHEMA.md) and the default [configuration](./CONFIG.md).

## How to use your Queue

See: [Use your Queue](./USE_QUEUE.md)

## Other Pages

- [Start Here](./README.md)
- [Message Lifecycle](./MESSAGE_LIFECYCLE.md)
- [Schema](./SCHEMA.md)
- [Adminstration](./PEQ_ADMIN.md)
- [Configuration](./CONFIG.md)
- [Use the Queue](./USE_QUEUE.md)

[^Home](../README.md)
