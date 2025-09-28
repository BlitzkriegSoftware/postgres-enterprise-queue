DO $$
DECLARE
	-- args
	client_id varchar(128) := 'client01';
	lease_seconds integer := 30;
	-- vars
	lease_duration integer := lease_seconds;
    lease_duration_min integer := 10;
    lease_duration_default integer := 30;
    ts TIMESTAMP := CURRENT_TIMESTAMP;
    expires TIMESTAMP;
	message_id uuid;
	message_json json;
BEGIN

    expires := ts + make_interval( 0, 0, 0, 0, 0, 0, lease_duration);

    WITH cte AS (
        SELECT message_id, lease_expires, message_json
        FROM test01.message_queue
        WHERE (message_state_id = 1) OR (message_state_id in (2,4,5) and (lease_expires < CURRENT_TIMESTAMP))
        ORDER BY available_on
        LIMIT 1
        FOR UPDATE SKIP LOCKED
    )
    UPDATE test01.message_queue
    SET message_state_id = 2, lease_expires = expires, leased_by = client_id
    FROM cte
    WHERE test01.message_queue.message_id = cte.message_id
    RETURNING test01.message_queue.message_id,  test01.message_queue.message_json
	INTO message_id, message_json;

	return (select message_id, expires, message_json)
	
END $$ LANGUAGE plpgsql;