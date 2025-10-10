-- Message NAK
CREATE OR REPLACE PROCEDURE {schema}.message_nak(
	IN msg_id uuid,
	IN nak_by character varying DEFAULT 'system'::character varying,
	IN reason_why text DEFAULT 'uow fail'::text
)
LANGUAGE plpgsql
AS $$

DECLARE
	numberofretries integer;
	delay integer;
	ts timestamp;
	updated_rows integer := 0;

BEGIN
	-- START TRANSACTION;

	select COALESCE(retries,0)
	into numberofretries
	from {schema}.message_queue
	where message_id = message_id;

	select COALESCE(lease_expires, CURRENT_TIMESTAMP)
	into ts
	from {schema}.message_queue
	where message_id = msg_id;

	numberofretries := numberofretries + 1;

	select {schema}.calculate_offset(numberofretries)
	into delay;

	update {schema}.message_queue
	set
		retries = numberofretries,
		message_state_id = 1,
		available_on = ts + make_interval(0, 0, 0, 0, 0, 0, delay),
		lease_expires = null
	WHERE 
		(
			(message_id = msg_id) and
			(leased_by = nak_by) and
			(lease_expires >= CURRENT_TIMESTAMP)
		);
		
	GET DIAGNOSTICS updated_rows = ROW_COUNT;

	if updated_rows < 1 then
		call {schema}.add_audit(msg_id, 99, nak_by, 'Client did not own impacted queue item or lease expired');
		RAISE EXCEPTION 'Client did not own impacted queue item or lease expired: %', msg_id;
	ELSE
		call {schema}.add_audit(msg_id, 1, nak_by, reason_why);
	end if;

	-- COMMIT;
END;
$$;
