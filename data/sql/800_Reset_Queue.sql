-- RESET ALL QUEUE Data
-- This is the nucular option

DROP PROCEDURE IF EXISTS {schema}.reset_queue();

CREATE OR REPLACE PROCEDURE {schema}.reset_queue()
LANGUAGE 'sql'
AS $BODY$

BEGIN;

    truncate table {schema}.dead_letter;
    truncate table {schema}.message_history;
    truncate table {schema}.message_queue;

    ALTER SEQUENCE {schema}.message_audit_message_id_seq RESTART WITH 1;
    TRUNCATE TABLE {schema}.message_audit RESTART IDENTITY CASCADE;

	COMMIT;

END;
$BODY$;

ALTER PROCEDURE {schema}.reset_queue()
    OWNER TO postgres;
