-- PROCEDURE: {schema}.message_ack(uuid, character varying, text)

DROP PROCEDURE IF EXISTS {schema}.message_ack(uuid, character varying, text);

CREATE OR REPLACE PROCEDURE {schema}.message_ack(
	IN msg_id uuid,
	IN ack_by character varying DEFAULT 'system'::character varying,
	IN reason_why text DEFAULT 'ACK'::text)
LANGUAGE plpgsql
AS $BODY$

DECLARE
	inserted_rows integer := 0;
BEGIN
	-- START TRANSACTION;

	INSERT INTO {schema}.message_history(
		message_id, message_state_id, created_on, history_on, created_by, message_json, reason_why)
	SELECT message_id, 3, created_on, CURRENT_TIMESTAMP, ack_by, message_json, reason_why
		FROM {schema}.message_queue 
		WHERE 
		(
			(message_id = msg_id) and
			(leased_by = ack_by) and
			(lease_expires >= CURRENT_TIMESTAMP)
		);
		
	GET DIAGNOSTICS inserted_rows = ROW_COUNT;
	
	IF inserted_rows > 0 THEN
		DELETE FROM {schema}.message_queue where message_id = msg_id;
		call {schema}.add_audit(msg_id, 3, ack_by, reason_why);
	ELSE
		call {schema}.add_audit(msg_id, 99, ack_by, 'Client did not own impacted queue item or lease expired');
		RAISE EXCEPTION 'Client did not own impacted queue item or lease expired: %', msg_id;
	END IF;

	-- COMMIT;

END;
$BODY$;

ALTER PROCEDURE {schema}.message_ack(uuid, character varying, text)
    OWNER TO postgres;
