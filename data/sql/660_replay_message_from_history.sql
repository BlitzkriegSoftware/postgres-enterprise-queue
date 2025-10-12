DROP PROCEDURE IF EXISTS {schema}.replay_message_from_history(uuid, integer, varchar, integer, varchar);

CREATE OR REPLACE PROCEDURE {schema}.replay_message_from_history(
    IN msg_id uuid DEFAULT uuid_generate_v4(),
    IN delay_seconds integer DEFAULT 0,
    IN recovered_by varchar DEFAULT 'system',
    IN item_ttl integer DEFAULT 0,
    IN reason_why varchar DEFAULT 'history recovered.'
)
LANGUAGE 'plpgsql'

AS $$

DECLARE
    message_id uuid;
    message_id_new uuid := uuid_generate_v4();
    message_json json := '{}';
    empty_uuid uuid := CAST('00000000-0000-0000-0000-000000000000' as uuid);
    reason_why_new varchar := reason_why;

BEGIN
    select
        mh.message_json
    into 
        message_json
    from
        {schema}.message_history mh
    where
        mh.message_id = msg_id;

    IF (message_json is null) THEN
        RAISE EXCEPTION 'No Message History found with Id: %', msg_id;
    ELSE
        call {schema}.enqueue(message_json, message_id_new, delay_seconds, recovered_by, item_ttl);
        reason_why_new := reason_why || ' Previous uuid: ' || cast(msg_id as varchar);
        call {schema}.add_audit(message_id_new, 32, recovered_by, reason_why_new);
        reason_why_new := reason_why || ' New uuid: ' || cast(message_id_new as varchar);
        call {schema}.add_audit(msg_id, 32, recovered_by, reason_why_new);
    END IF;

END;
$$;

ALTER PROCEDURE {schema}.replay_message_from_history(uuid, integer, varchar, integer, varchar)
    OWNER TO postgres;
