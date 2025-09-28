-- PROCEDURE: {schema}.message_rej(uuid, character varying, text)

DROP PROCEDURE IF EXISTS {schema}.message_rej(uuid, character varying, text);

CREATE OR REPLACE PROCEDURE {schema}.message_rej(
	IN message_id uuid,
	IN rej_by character varying DEFAULT 'system'::character varying,
	IN reason_why text DEFAULT 'completed'::text)
LANGUAGE 'sql'
AS $BODY$

BEGIN;

	INSERT INTO test01.dead_letter(
		message_id, message_state_id, created_on, dead_on, created_by, message_json, reason_why)
	SELECT message_id, 7, created_on, CURRENT_TIMESTAMP, rej_by, message_json, reason_why
		FROM {schema}.message_queue 
		WHERE message_id = message_id;	
	
	DELETE FROM {schema}.message_queue where message_id = message_id;

	COMMIT;

END;
$BODY$;
ALTER PROCEDURE {schema}.message_rej(uuid, character varying, text)
    OWNER TO postgres;
