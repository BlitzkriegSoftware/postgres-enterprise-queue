-- PROCEDURE: {schema}.enqueue(json, uuid, integer, character varying, integer)

CREATE OR REPLACE PROCEDURE {schema}.enqueue(
	IN message_json json,
	IN message_id uuid DEFAULT uuid_generate_v4(),
	IN delay_seconds integer DEFAULT 0,
	IN created_by character varying DEFAULT 'system'::character varying
	in item_ttl integer DEFAULT 0
)
LANGUAGE 'plpgsql'
AS $BODY$

DECLARE
	item_ttl_default integer := 4320; -- minutes
	ts TIMESTAMP := CURRENT_TIMESTAMP;
	expires TIMESTAMP := CURRENT_TIMESTAMP;
	xid8value xid8;
	reason_why varchar := 'enqueued.';
	
BEGIN

	-- Positive into the future, negative is ASAP
	if( delay_seconds <> 0 ) then
		ts := ts + make_interval( 0, 0, 0, 0, 0, 0, delay_seconds);
	end if;

	-- Item Time-to-Live (TTL)
	if item_ttl < 0 then
		select COALESCE(CAST(setting_value AS INTEGER), item_ttl_default)
			into item_ttl
			from {schema}.queue_configuration 
			where setting_name = 'item_ttl';
	end if;

	expires := CURRENT_TIMESTAMP + make_interval( 0, 0, 0, 0, 0, item_ttl, 0);

	INSERT INTO {schema}.message_queue(
			message_id, 
			message_state_id, 
			retries, 
			available_on, 
			lease_expires, 
			leased_by, 
			created_on, 
			created_by,
			message_expires, 
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
			expires,
			message_json
		);

	reason_why := reason_why || ' Expires Minutes: ' || cast(item_ttl as varchar);

	call {schema}.add_audit(message_id, 1, created_by, reason_why);

	select pg_current_xact_id_if_assigned()
	into xid8value;

	if(xid8value is not null) then
		COMMIT;
	end if;
END;
$BODY$;

ALTER PROCEDURE {schema}.enqueue(json, uuid, integer, character varying, integer)
    OWNER TO postgres;
