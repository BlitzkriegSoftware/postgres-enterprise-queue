# How to use your queue

- [How to use your queue](#how-to-use-your-queue)
  - [Nice demo](#nice-demo)
- [Producers: Enqueue item](#producers-enqueue-item)
- [Consumers: Dequeue Item and do a Unit of Work](#consumers-dequeue-item-and-do-a-unit-of-work)
  - [What is a unit-of-work?](#what-is-a-unit-of-work)
  - [dequeue()](#dequeue)
  - [Do the Unit of Work](#do-the-unit-of-work)
  - [Post UoW call one of these methods](#post-uow-call-one-of-these-methods)
    - [(1) ACK (Completed)](#1-ack-completed)
    - [(2) NAK (Can't complete)](#2-nak-cant-complete)
    - [(3) REJ (Reject)](#3-rej-reject)
    - [(4) RSH (Rescheduling a message)](#4-rsh-rescheduling-a-message)
  - [Too Many: NAK, RSH, Lease-Expired-Events](#too-many-nak-rsh-lease-expired-events)
- [The Audit: Tracing what happened to your messages](#the-audit-tracing-what-happened-to-your-messages)

## Nice demo

There is nice example of the unit of work pattern and basic queue usage in the SQL file [Post Deployment Test](../data/sql/901_post_deploy_test.sql).

# Producers: Enqueue item 

Producers make messages to be the fodder for units of work by adding a new item, a message, to the queue, by calling:

```sql
 call {schema}.enqueue(msg_json [, uuid] [,delay_seconds] [,created_by]);
```

Messages are retained for at least the number of retries in the `queue_configuration` table setting of `max_retries`.

| field         | required | default            | note                                           |
| :------------ | :------: | :----------------- | :--------------------------------------------- |
| message_json  |   yes    | (none)             | valid json                                     |
| message_id    |    no    | uuid_generate_v4() | unique guid                                    |
| delay_seconds |    no    | 0                  | use to delay messages from being processed     |
| created_by    |    no    | 'system'           | who made the message, any valid string will do |

# Consumers: Dequeue Item and do a Unit of Work

1. Get a message
2. Do unit-of-work
3. Explicitly act on the message

## What is a unit-of-work?

> See [Unit of Work](https://en.wikipedia.org/wiki/Unit_of_work) on Wikipedia

Basically, we enqueue a message to serve as the payload of information for some processing to be done by a consumer, queued up by a producer, that is the smallest amount of processing that is an atomic unit to be processed. 

<img src='./UoW_Pattern.png' width='800px'>

A UoW has one of these possible outcomes:

* (1) ACK: Happy path, work is done successfully
* (2) NAK: Work could not be done, but is do-able in the future, potentially if given more time
   - Rescheduled (worse case, really need to delay processing)
* (3) REJ: UoW should NOT be done.
* (4) RSH: Alternative to NAK, not just NAK, rescheduled into the future

> One message => One Unit of Work

The unit of work (UoW) execution must be completed in less time than the `lease_duration` e.g. by the TIMESTAMP returned as `expires` or subsequent calls to ACK, NAK, or REJ will fail as technically, the client does not "own" the work item any more so the system has effectively done an "auto-NAK". This mechanism is baked into the `dequeue()` procedure, but also part of the scheduled cron job [cron_unlock](../data/sql/520_cron_unlock.sql) which matches the 'lease expired' event in the diagram above.

## dequeue()

Try and get one message of the queue for the specified lease_duration in seconds.

```sql
DECLARE
    msg_id uuid DEFAULT uuid_generate_v4();
    expires TIMESTAMP;
    msg_json json = '{}';

select q.msg_id, q.expires, q.msg_json
    into msg_id, expires, msg_json
    from test01.dequeue(client_id, lease_duration) as q;
```

This fetches these fields:

- `msg_id`: UUID {GUID} unique id of message
- `expires`: When does the lease expire?
- `msg_json`: The JSON payload of the message

Some notes on the arguments:

- The client_id should be a unique value across all the instances that use this queue
  - Worse case, you can use a GUID (uuid)

- If not supplied, the lease_duration is fetched from `queue_configuration` table setting of `lease_duration`, with a fallback of `30` seconds.

## Do the Unit of Work

AKA Process the Message and do whatever business logic is needed.

## Post UoW call one of these methods

All of them have three common arguments:

- `msg_id`: the UUID of the message
- `client_id`: of the client
- `reason`: why we called the UOW method, this flows into the `audit`

### (1) ACK (Completed)

The unit of work expressed by the message was completed successfully, the message is moved to history.

> This is the happy path.

```sql
call {schema}.message_ack(msg_id, client_id, 'ack');
```

### (2) NAK (Can't complete)

The unit of work cannot be processed successfully, and some other client should process it. 

This is also what happens if the message times out (lease expires). 

See the discussion below on [Nak](./USE_QUEUE.md#too-many-naks-or-lease-expired-events).

```sql
call {schema}.message_nak(msg_id, client_id, reason_why);
```

> Please pass a detailed `reason_why` as an explaination as it will flow into the audit. 

### (3) REJ (Reject)

The message is bad somehow, and can never be processed, it needs to be moved to DEAD-LETTER.

This what what should happen when:

- Message is malformed
- Has already been processed
- Is no longer relavant
- etc.

```sql
call {schema}.message_rej(msg_id, client_id, reason_why);
```

> For this method in particularly, the `reason_why` should be as detailed as possible for troubleshooting later. The use of an error code or somesuch is a good idea.


### (4) RSH (Rescheduling a message) 

This does a NAK **plus** punts the message the `delay_seconds` into the future, use when you want to overcome a transitory fault in dependancy of the unit of work that hopefully will be healed with time.

```sql
call {schema}.message_reschedule(msg_id, delay_seconds, [,done_by] [,reason_why])
```

- `msg_id`: the UUID of the message
- `delay_seconds`: (default 3600 [1 hour])
  - Zero: use default
  - Postive: number future
  - Negative:  number past aka immediate delivery
- `done_by`: (default 'system')
- `reason_why`: (default: 'rescheduled')
   - Please consider suppling a detailed reason why a message is being rescheduled for the audit
   - Including a unique reason-code is a good practice 

Other effects: 
- It also bumps the messages expiration time by the same amount as the rescheduled amount
- `retries` are set to zero and the lease info is cleared


## Too Many: NAK, RSH, Lease-Expired-Events

If the calls to the completion events fail, increase the `lease_duration` AND/OR investigate why the UoW itself is taking so long to process. 

The default of 30 seconds is a long time to process anything in computer time.

If the problem is that, to do the Unit-of-Work (UoW), some other dependancies are not ready or available, and may not be for a while, so what we need to do **instead** of calling [NAK()](./USE_QUEUE.md#2-nak-cant-complete) is to call [Reschedule()](./USE_QUEUE.md#rescheduling-a-message) to bump the message into the future.

Please also see [Message Lifecycle](./MESSAGE_LIFECYCLE.md).

# The Audit: Tracing what happened to your messages 

The audit trail for system end up in the table `message_audit` and are put there because various functions and procedures call the procedure:

```sql
call {schema}.add_audit(
	IN msg_id uuid,
	IN state_id integer,
	IN audit_by character varying,
	IN reason_why text
);
```

* `msg_id`: the key of the message (uuid, guid)
* `state_id`: a valid state (see [message_state](../data/sql/702_message_state_Data.sql) table)
* `audit_by`: caller, typically 'system' or `client_id`
* `reason_why`: (text) a text explaination that is searchable in the source code
   - Use of a reason-code is a good practice 

So querying the table `message_audit` table 'where' or 'order by' `message_id` is useful:

```sql
-- Find out what happened to a message whose id start with...
SELECT * FROM test01.message_audit
  WHERE cast(message_id as varchar) like '0303%'
  ORDER BY message_id, audit_on ASC LIMIT 100
```

Example output:

 | audit_id | message_id | message_state_id | audit_on | audit_by | reason_why |
 |:---|:---|:---|:---|:---|:---|
 | 21 | 0303596d-ed09-4b82-9cbd-6d36c41eeb6d | 1 | 2025-10-11 05:36:03.667064+00 | system | enqueued | 
 | 91 | 0303596d-ed09-4b82-9cbd-6d36c41eeb6d | 2 | 2025-10-11 05:36:03.711044+00 | client01 | dequeued. lease seconds: 30 | 
 | 92 | 0303596d-ed09-4b82-9cbd-6d36c41eeb6d | 3 | 2025-10-11 05:36:03.711044+00 | client01 | ack | 

[<--- Start Here](./README.md)