# NodeJS Sample

Simulate the unit of work in TypeScript and NodeJS

- [NodeJS Sample](#nodejs-sample)
  - [Watch the Video](#watch-the-video)
  - [Test Engine](#test-engine)
  - [One time setup](#one-time-setup)
    - [Start Docker](#start-docker)
    - [Create the PEQ Postgres 16 + Plug-ins Instance and Run it](#create-the-peq-postgres-16--plug-ins-instance-and-run-it)
    - [Create the default PEQ](#create-the-default-peq)
    - [Restore Node Packages](#restore-node-packages)
    - [Do a test compile](#do-a-test-compile)
  - [Run Tests](#run-tests)

> See the source code

## Watch the Video

See The [YouTube](https://www.youtube.com/watch?v=d0OfD_Dq17M)

## Test Engine

After fighting `jest`, I switched to [bun](https://bun.sh/reference/bun/test)

## One time setup

### Start Docker

Start Docker-Desktop

### Create the PEQ Postgres 16 + Plug-ins Instance and Run it

```powershell
..\..\start-pg.ps1
```

### Create the default PEQ

```powershell
..\..\make-queue.ps1
```

### Restore Node Packages

```powershell
# Make node_modules
npm i
```

### Do a test compile

```powershell
# Compile everything using tsconfig.json
npx tsc
```

## Run Tests

```powershell
# Run all the tests
npx bun test --coverage
```
