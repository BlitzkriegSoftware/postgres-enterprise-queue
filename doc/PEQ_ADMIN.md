# Administration of PEQ

- [Administration of PEQ](#administration-of-peq)
  - [Cron](#cron)
  - [Scheduled Jobs](#scheduled-jobs)
  - [CRON Execution History](#cron-execution-history)
  - [CRON Procedures](#cron-procedures)
    - [cron_clean_message_queue](#cron_clean_message_queue)
    - [cron_unlock](#cron_unlock)
    - [cron_history_clean](#cron_history_clean)
    - [cron_audit_clean](#cron_audit_clean)
    - [cron_dead_letter_retention](#cron_dead_letter_retention)
  - [Recovering Messages](#recovering-messages)
    - [From History](#from-history)
    - [From Dead-Letter](#from-dead-letter)
  - [Removing a Queue entirely](#removing-a-queue-entirely)
  - [Reseting all DATA in the queue system](#reseting-all-data-in-the-queue-system)

## Cron

Copied from [pg_cron](https://github.com/citusdata/pg_cron/blob/main/README.md?plain=1)

```
 ┌───────────── min (0 - 59)
 │ ┌────────────── hour (0 - 23)
 │ │ ┌─────────────── day of month (1 - 31) or last day of the month ($)
 │ │ │ ┌──────────────── month (1 - 12)
 │ │ │ │ ┌───────────────── day of week (0 - 6) (0 to 6 are Sunday to
 │ │ │ │ │                  Saturday, or use names; 7 is also Sunday)
 │ │ │ │ │
 │ │ │ │ │
 * * * * *
```

An easy way to create a cron schedule is: [crontab.guru](http://crontab.guru/).

## Scheduled Jobs

```sql
select jobid, jobname, schedule, command from cron.job;
```

| "jobid" | "jobname"               | "schedule"          | "command"                                   |
| ------: | :---------------------- | :------------------ | :------------------------------------------ |
|       3 | "retention_queue"       | "_/7 _ \* \* \* \*" | "CALL test01.cron_unlock(0)"                |
|       4 | "retention_dead_letter" | "0 3 \* \* \*"      | "CALL test01.cron_dead_letter_retention(0)" |
|       5 | "retention_history"     | "8 1 \* \* 6"       | "CALL test01.cron_history_clean(0)"         |
|       6 | "retention_audit_log"   | "0 3 \* \* \*"      | "CALL test01.cron_audit_clean(0)"           |
|       7 | "nightly-vacuum"        | "45 4 \* \* \*"     | "VACUUM"                                    |

## CRON Execution History

```sql
-- job execution history
select * from cron.job_run_details order by start_time desc;
```

## CRON Procedures

These are called by the CRON jobs see [CRON Setup Script](../data/sql/800_Cron_Setup.sql)

### cron_clean_message_queue

Called by `cron_history_clean`

```sql
call cron_clean_message_queue(max_retries);
```

Moves messages to `dead-letter` that fit either these criteria:

- `max_retries`: exceed for a mesasage
  - `max_retries` (default 7) from `queue_configuration`
- The `CURRENT_TIMESTAMP` is greater than the messages `message_expires` field
  - This is set on message create from `item_ttl` (default: 4320 minutes) from `queue_configuration` + current timestamp

### cron_unlock

```sql
call cron_unlock([lease_duration_in]);
```

- `lease_duration_in`: default 0
  - if zero fetched from `queue_configuration` row `lease_duration` (default 30 seconds)

1. Breaks expired leases, clears lease data, increments retries (does a NAK effectively)
2. Calls `cron_clean_message_queue` (see above)

### cron_history_clean

```sql
call cron_history_clean([history_retention_in]);
```

- `history_retention_in`: If Zero computed from `history_retention` value (181 days by default) from `queue_configuration`
  - Messages old than this are deleted from the `message_history` table

### cron_audit_clean

```sql
call cron_audit_clean([audit_retention_in]);
```

- `audit_retention_in`: (default 0)
  - if zero fetched from `queue_configuration` row `audit_retention` (defaullt 31)

Cleans out any records from `message_audit` table older than X days.

### cron_dead_letter_retention

```sql
call cron_dead_letter_retention([dead_letter_retention_in]);
```

- `dead_letter_retention_in`: default 0
  - If zero, fetched from `queue_configuration` row `dead_letter_retention` (default 91 days)

If any dead-letter are older than this, they are deleted from `dead-letters`.

## Recovering Messages

A recovered message is a **COPY** with a new `uuid` (guid) and an audit record that links to the old ID.

### From History

```sql

```

### From Dead-Letter

```sql

```

## Removing a Queue entirely

To remove queue entirely, delete its `schema`.

> > WARNING! There is NO UNDO. This is none reversable.

## Reseting all DATA in the queue system

> WARNING! There is NO UNDO. So be sure this is what you want.

To just reset a queue e.g. remove all of the data effectively rentuning it to the newly created state, use this procedure:

```sql
-- Warning this is the nuclear option, there is no UNDO
 call {schema}.reset_queue();
```

[<--- Start Here](./README.md)
