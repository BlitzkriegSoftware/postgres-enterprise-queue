
DROP PROCEDURE IF EXISTS {schema}.message_reschedule(uuid, integer, varchar, text );

CREATE OR REPLACE PROCEDURE {schema}.message_reschedule(
	IN msg_id uuid,
    IN delay_seconds integer DEFAULT 3600,
	IN done_by character varying DEFAULT 'system'::character varying,
	IN reason_why text DEFAULT 'Rescheduled'::text)
LANGUAGE plpgsql
AS $BODY$

DECLARE
	inserted_rows integer := 0;
    ts TIMESTAMP := CURRENT_TIMESTAMP;
BEGIN
    if delay_seconds = 0 then
        delay_seconds := 3600;
    end if;

    ts := CURRENT_TIMESTAMP + make_interval( 0, 0, 0, 0, 0, 0, delay_seconds);

    update
        {schema}.message_queue
    set
        available_on = ts,
        message_state_id = 1, -- 4 rescheduled
        lease_expires = null,
        leased_by = null,
        message_expires = message_expires + make_interval( 0, 0, 0, 0, 0, 0, delay_seconds),
        retries = 0
    where
        (message_id = msg_id);

    reason_why := reason_why || '. Seconds delayed: ' || cast(delay_seconds as varchar);

    call {schema}.add_audit(msg_id, 4, done_by, reason_why);
END;
$BODY$;

ALTER PROCEDURE {schema}.message_reschedule(uuid, integer, varchar, text )
    OWNER TO postgres;
