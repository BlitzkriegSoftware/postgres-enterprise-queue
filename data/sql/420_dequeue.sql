-- {schema}.dequeue one message
CREATE OR REPLACE FUNCTION {schema}.dequeue(
		leased_by varchar(128),
	    lease_seconds integer = -1
	)
    RETURNS {schema}.queue_item
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE PARALLEL UNSAFE
AS $BODY$

DECLARE
    lease_duration integer := lease_seconds;
    lease_duration_min integer := 10;
    lease_duration_default integer := 30;
    ts TIMESTAMP := CURRENT_TIMESTAMP;
    expires TIMESTAMP;
BEGIN
    if(lease_duration < lease_duration_min) then
        select COALESCE(CAST(setting_value AS INTEGER), lease_duration_default)
        into lease_duration
        from {schema}.queue_configuration 
        where setting_name = 'lease_duration';
    end if;

    expires := ts + make_interval( 0, 0, 0, 0, 0, 0, lease_duration);

    WITH cte AS (
        SELECT message_id, lease_expires, message_json
        FROM {schema}.message_queue
        WHERE (message_state_id = 1) OR (message_state_id in (2,4,5) and (lease_expires < CURRENT_TIMESTAMP))
        ORDER BY available_on
        LIMIT 1
        FOR UPDATE SKIP LOCKED
    )
    UPDATE {schema}.message_queue
    SET message_state_id = 2, lease_expires = expires, leased_by = leased_by
    FROM cte
    WHERE {schema}.message_queue.message_id = cte.message_id
    RETURNING {schema}.message_queue.message_id, expires, {schema}.message_queue.message_json;
	
END;
$BODY$;

ALTER FUNCTION {schema}.dequeue(varchar(128), integer)
    OWNER TO postgres;
