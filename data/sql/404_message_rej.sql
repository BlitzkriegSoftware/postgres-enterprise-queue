-- PROCEDURE: {schema}.message_rej(uuid, character varying, text)

DROP PROCEDURE IF EXISTS {schema}.message_rej(uuid, character varying, text);

CREATE OR REPLACE PROCEDURE {schema}.message_rej(
	IN message_id uuid,
	IN rej_by character varying DEFAULT 'system'::character varying,
	IN reason_why text DEFAULT 'completed'::text)
LANGUAGE plpgsql
AS $BODY$

DECLARE 
	inserted_rows integer := 0;
	
BEGIN

	INSERT INTO {schema}.dead_letter(
		message_id, message_state_id, created_on, dead_on, created_by, message_json, reason_why)
	SELECT message_id, 7, created_on, CURRENT_TIMESTAMP, rej_by, message_json, reason_why
		FROM {schema}.message_queue 
		WHERE 
		(
			(message_id = message_id) and
			(leased_by = rej_by) and
			(lease_expires <= CURRENT_TIMESTAMP)
		);
		
	GET DIAGNOSTICS inserted_rows = ROW_COUNT;
	
	if inserted_rows = 1 then
		DELETE FROM {schema}.message_queue where message_id = message_id;
		call {schema}.add_audit(message_id, 7, rej_by, reason_why);
	else
		call {schema}.add_audit(message_id, 99, rej_by, 'Client did not own impacted queue item');
		RAISE EXCEPTION 'Client did not own impacted queue item: %', message_id;
	end if;

	COMMIT;

END;
$BODY$;

ALTER PROCEDURE {schema}.message_rej(uuid, character varying, text)
    OWNER TO postgres;
