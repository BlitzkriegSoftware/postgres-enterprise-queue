-- PROCEDURE: {schema}.add_audit(uuid, integer, character varying, text)

DROP PROCEDURE IF EXISTS {schema}.add_audit(uuid, integer, character varying, text);

CREATE OR REPLACE PROCEDURE {schema}.add_audit(
	IN message_id uuid,
	IN message_state_id integer,
	IN audit_by character varying,
	IN reason_why text)
LANGUAGE 'plpgsql'
AS $BODY$

DECLARE

BEGIN

	INSERT INTO {schema}.message_audit(
		message_id, message_state_id, audit_by, reason_why)
		VALUES (message_id, message_state_id, audit_by, reason_why);

	COMMIT;
END;
$BODY$;

ALTER PROCEDURE {schema}.add_audit(uuid, integer, character varying, text)
    OWNER TO postgres;
