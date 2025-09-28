-- Message NAK
CREATE OR REPLACE PROCEDURE {schema}.message_nak(message_id uuid)
LANGUAGE plpgsql
AS $$

DECLARE
	numberofretries integer;
	delay integer;
	ts timestamp;
	
BEGIN
	select COALESCE(retries,0)
	into numberofretries
	from {schema}.message_queue
	where message_id = message_id;

	select COALESCE(lease_expires, CURRENT_TIMESTAMP)
	into ts
	from {schema}.message_queue
	where message_id = message_id;

	numberofretries := numberofretries + 1;

	select {schema}.calculate_offset(numberofretries)
	into delay;

	update {schema}.message_queue
	set
		retries = numberofretries,
		message_state_id = 1,
		available_on = ts + make_interval( 0, 0, 0, 0, 0, 0, delay),
		lease_expires = null
	where message_id = message_id;

	COMMIT;
END;
$$;
