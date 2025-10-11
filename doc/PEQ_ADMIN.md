# Administration of PEQ

See Also:
* [Schema](./SCHEMA.md)
* [Message Lifecycle](./MESSAGE_LIFECYCLE.md)

## CRON Jobs

```sql
-- list of jobs
select jobid, jobname, schedule, command from cron.job;

-- job execution history
select * from cron.job_run_details order by start_time desc;
```

## CRON Procedures

These are called by the CRON jobs see [CRON Setup Script](../data/sql/800_Cron_Setup.sql)

### cron_clean_message_queue

Called by `cron_history_clean`

```sql
call cron_clean_message_queue(max_retries, ts_exeeded);
```

Moves messages to `dead-letter` that fit either these criteria:

- `max_retries`: exceed for a mesasage
    - `max_retries` (default 7) from `queue_configuration`
- `ts_exeeded`: message is older than this timestamp computed from TTL
  - `item_ttl` (default: 4320 minutes) from `queue_configuration` + current timestamp



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
* `history_retention_in`: If Zero computed from `history_retention` value (181 days by default) from `queue_configuration`
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

* `dead_letter_retention_in`: default 0
   - If zero, fetched from `queue_configuration` row `dead_letter_retention` (default 91 days)

If any dead-letter are older than this, they are deleted from `dead-letters`.

## Reseting all DATA in the queue system

> WARNING! There is NO UNDO. So be sure this is what you want.

To remove queue entirely, delete its `schema`. 

To just reset it to the newly created state, use this procedure:

```sql
-- Warning this is the nuclear option, there is no UNDO
 call {schema}.reset_queue();
```

