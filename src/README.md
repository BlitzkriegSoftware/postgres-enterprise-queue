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

### Invocation

```powershell
npx ts-node index.ts -s="${Schema}" -c="${Connection}" [-r="${Role}"]
```

* `-c` well formed Postgres connection string including database
  - example: `postgresql://postgres:password123-@localhost/postgres`
  - this is the working connection string for the docker database

* `-s` unique schema name
  - example: `peq_schema_01`
  - having the prefix `peq_` or even `peq_schema_` is not a bad idea

* `-r` (optional) unique role name
  - example: `peq_role_01`
  - having the prefix `peq_` or even `peq_role_` is not a bad idea

This will create the objects in [schema](./SCHEMA.md) and the default [configuration](./CONFIG.md).