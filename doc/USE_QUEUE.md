# How to use your queue

There is nice example of the unit of work pattern and basic queue usage in the SQL file [Post Deployment Test](data\sql\901_post_deploy_test.sql).

## Enqueue items

Add a new item to the queue

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

## Dequeue Items

Try and get one message of the queue for the specified lease_duration in seconds.

```sql
DECLARE
    msg_id uuid DEFAULT uuid_generate_v4();
    expires TIMESTAMP;
    msg_json json = '{}';

select b.msg_id, b.expires, b.msg_json
    into msg_id, expires, msg_json
    from test01.dequeue(client_id, lease_duration) as b;
```

This fetches these fields:

- `msg_id`: UUID {GUID} unique id of message
- `expires`: When does the lease expire?
- `msg_json`: The JSON payload of the message

Some notes on the arguments:

- The client_id should be a unique value across all the instances that use this queue

  - Worse case, you can use a GUID (uuid)

- If not supplied, the lease_duration is fetched from `queue_configuration` table setting of `lease_duration`, with a fallback of `30` seconds.

## Unit of Work

The unit of work must be completed in less time than the `lease_duration` e.g. by the TIMESTAMP returned as `expires` or subsequent calls to ACK, NAK, or REJ will fail.

Please see [Message Lifecycle](./MESSAGE_LIFECYCLE.md).

All of them have 3 arguments:

- `msg_id`: the UUID of the message
- `client_id`: of the client
- `reason`: why we called the UOW method, this flows into the `audit`

### ACK (Completed)

The unit of work expressed by the message was completed successfully, the message is moved to history.

> This is the happy path.

```sql
call {schema}.message_ack(msg_id, client_id, 'ack');
```

### NAK (Can't complete)

The unit of work can not be processed successfully, and some other client should process it. This is also what happens if the message times out.

```sql
call {schema}.message_nak(msg_id, client_id, 'uow fail');
```

## REJ (Reject)

The message is bad somehow, and can never be processed, it is moved to DEAD-LETTER.

This what what should happen when:

- Message is malformed
- Has already been processed
- Is no longer relavant
- etc.

```sql
call {schema}.message_rej(msg_id, client_id, 'bad format');
```
