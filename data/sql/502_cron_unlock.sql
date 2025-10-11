DROP PROCEDURE IF EXISTS {schema}.cron_unlock();

CREATE OR REPLACE PROCEDURE {schema}.cron_unlock(
    IN lease_duration_in integer DEFAULT 0
)
LANGUAGE plpgsql
AS $BODY$

DECLARE
    ts TIMESTAMP;
    lease_duration integer := 0;
    lease_duration_default integer := 30;
    max_retries integer := 0;
    max_retries_default integer := 7;
    item_ttl integer := 0;
    item_ttl_default integer := 4320;
    msg_id uuid;
    state_id integer := 88;
    who_by varchar(128) := 'system';
    why_so varchar(128) := 'retries or TTL exeeded';
    ts_exeeded TIMESTAMP := CURRENT_TIMESTAMP;
    
    
BEGIN
    select COALESCE(CAST(setting_value AS INTEGER), max_retries_default)
        into max_retries
        from {schema}.queue_configuration 
        where setting_name = 'max_retries';

    select COALESCE(CAST(setting_value AS INTEGER), item_ttl_default)
        into item_ttl
        from {schema}.queue_configuration 
        where setting_name = 'item_ttl';

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

    -- move really dead one to dead letter
    -- years, months, weeks, days, hours, mins, secs
    ts_exeeded := CURRENT_TIMESTAMP -  make_interval( 0, 0, 0, 0, 0, item_ttl, 0 );

    DECLARE
        dead_cursor CURSOR FOR 
        select message_id 
            from {schema}.message_queue 
            where 
                (
                (retries > max_retries)
                OR
                (created_on < ts_exeeded)
                )
                ;

    OPEN dead_cursor;

    LOOP
        FETCH dead_cursor INTO msg_id; 
        EXIT WHEN NOT FOUND; 

        INSERT INTO {schema}.dead_letter(message_id, message_state_id, created_on, dead_on, created_by, reason_why, message_json)
            SELECT message_id, state_id, created_on, CURRENT_TIMESTAMP, who_by, why_so, message_json
            FROM {schema}.message_queue  
            WHERE message_id = msg_id;

        DELETE from {schema}.message_queue WHERE message_id = msg_id;

        call {schema}.add_audit(msg_id, state_id, who_by, why_so);
    END LOOP;

    CLOSE dead_cursor;

END;
$BODY$;

ALTER PROCEDURE {schema}.cron_unlock( integer )
    OWNER TO postgres;
