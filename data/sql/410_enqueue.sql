-- PROCEDURE: {schema}.enqueue(json, uuid, integer, character varying)

CREATE OR REPLACE PROCEDURE {schema}.enqueue(
	IN message_json json,
	IN message_id uuid DEFAULT uuid_generate_v4(),
	IN delay_seconds integer DEFAULT 0,
	IN created_by character varying DEFAULT 'system'::character varying)
LANGUAGE 'plpgsql'
AS $BODY$

DECLARE
	ts TIMESTAMP := CURRENT_TIMESTAMP;
	xid8value xid8;
	
BEGIN

	if( delay_seconds <> 0 ) then
		ts := ts + make_interval( 0, 0, 0, 0, 0, 0, delay_seconds);
	end if;

	INSERT INTO {schema}.message_queue(
			message_id, 
			message_state_id, 
			retries, 
			available_on, 
			lease_expires, 
			leased_by, 
			created_on, 
			created_by, 
			message_json
		) VALUES (
			COALESCE(message_id, uuid_generate_v4()), 
			1, 
			0, 
			ts, 
			null, 
			null, 
			CURRENT_TIMESTAMP, 
			COALESCE(created_by, 'system'), 
			message_json
		);

	select pg_current_xact_id_if_assigned()
	into xid8value;

	if(xid8value is not null) then
		COMMIT;
	end if;
END;
$BODY$;

ALTER PROCEDURE {schema}.enqueue(json, uuid, integer, character varying)
    OWNER TO postgres;
