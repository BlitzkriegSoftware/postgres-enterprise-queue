DROP PROCEDURE IF EXISTS {schema}.cron_clean_message_queue();

CREATE OR REPLACE PROCEDURE {schema}.cron_clean_message_queue(
    IN max_retries integer DEFAULT 7,
    IN ts_exeeded TIMESTAMP DEFAULT CURRENT_TIMESTAMP
)
LANGUAGE plpgsql
AS $BODY$

DECLARE
    msg_id uuid;
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
BEGIN

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

ALTER PROCEDURE {schema}.cron_clean_message_queue( integer, TIMESTAMP )
    OWNER TO postgres;
