-- PROCEDURE: {schema}.message_ack(uuid, character varying, text)

DROP PROCEDURE IF EXISTS {schema}.message_ack(uuid, character varying, text);

CREATE OR REPLACE PROCEDURE {schema}.message_ack(
	IN message_id uuid,
	IN ack_by character varying DEFAULT 'system'::character varying,
	IN reason_why text DEFAULT 'completed'::text)
LANGUAGE 'sql'
AS $BODY$

DECLARE
	inserted_rows integer := 0;
BEGIN;

	INSERT INTO {schema}.message_history(
		message_id, message_state_id, created_on, history_on, created_by, message_json, reason_why)
	SELECT message_id, 3, created_on, CURRENT_TIMESTAMP, ack_by, message_json, reason_why
		FROM {schema}.message_queue 
		WHERE 
		(
			(message_id = message_id) and
			(leased_by = ack_by) and
			(lease_expires <= CURRENT_TIMESTAMP)
		);
	GET DIAGNOSTICS inserted_rows = ROW_COUNT;
    RETURN inserted_rows;
	
	if(inserted_rows = 1) then
		DELETE FROM {schema}.message_queue where message_id = message_id;
	else
		 RAISE EXCEPTION 'Client did not own impacted queue item: %', message_id
	end if;

	COMMIT;

END;
$BODY$;
ALTER PROCEDURE {schema}.message_ack(uuid, character varying, text)
    OWNER TO postgres;
