DROP PROCEDURE IF EXISTS {schema}.cron_unlock();

CREATE OR REPLACE PROCEDURE {schema}.cron_unlock(
    IN lease_duration_in integer DEFAULT 0
)
LANGUAGE plpgsql
AS $BODY$

DECLARE
    item_ttl integer := 0;
    item_ttl_default integer := 4320;
    lease_duration integer := 0;
    lease_duration_default integer := 30;
    max_retries integer := 0;
    max_retries_default integer := 7;
    msg_id uuid;
    state_id integer := 88;
    ts TIMESTAMP;
    ts_exeeded TIMESTAMP := CURRENT_TIMESTAMP;
    who_by varchar(128) := 'system';
    why_so varchar(128) := 'retries or TTL exeeded';
    
BEGIN
    select COALESCE(CAST(setting_value AS INTEGER), max_retries_default)
        into max_retries
        from {schema}.queue_configuration 
        where setting_name = 'max_retries';

    lease_duration := lease_duration_in;
    if lease_duration <= 0 then

        select COALESCE(CAST(setting_value AS INTEGER), lease_duration_default)
            into lease_duration
            from {schema}.queue_configuration 
            where setting_name = 'lease_duration';

    end if;

    -- buffer the least duration
    lease_duration := lease_duration * 2;
    ts := CURRENT_TIMESTAMP - make_interval( 0, 0, 0, 0, 0, 0, lease_duration );

    update 
        {schema}.message_queue  
    set
        message_state_id = 1,
        retries = retries + 1,
        lease_expires = CURRENT_TIMESTAMP,
        leased_by = NULL
    where
        message_state_id = 2 
        AND
        lease_expires < ts;

    --
    -- clean out message queue
    select COALESCE(CAST(setting_value AS INTEGER), item_ttl_default)
        into item_ttl
        from {schema}.queue_configuration 
        where setting_name = 'item_ttl';
    -- years, months, weeks, days, hours, mins, secs
    ts_exeeded := CURRENT_TIMESTAMP -  make_interval( 0, 0, 0, 0, 0, item_ttl, 0 );
    -- move really dead ones to dead letter
    CALL {schema}.cron_clean_message_queue( max_retries, ts_exeeded );

END;
$BODY$;

ALTER PROCEDURE {schema}.cron_unlock( integer )
    OWNER TO postgres;
