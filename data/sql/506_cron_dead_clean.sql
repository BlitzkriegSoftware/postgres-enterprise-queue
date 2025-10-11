DROP PROCEDURE IF EXISTS {schema}.cron_dead_letter_retention();

CREATE OR REPLACE PROCEDURE {schema}.cron_dead_letter_retention(
    IN dead_letter_retention_in integer DEFAULT 0
)
LANGUAGE plpgsql
AS $BODY$

DECLARE
    dead_letter_retention integer := 0;
    dead_letter_retention_default integer := 91;
    ts TIMESTAMP;

BEGIN

    dead_letter_retention := dead_letter_retention_in;
    if dead_letter_retention <= 0 then

        select COALESCE(CAST(setting_value AS INTEGER), dead_letter_retention_default)
            into dead_letter_retention
            from {schema}.queue_configuration 
            where setting_name = 'dead_letter_retention';

    end if;

    -- years, months, weeks, days, hours, mins, seconds
    ts := CURRENT_TIMESTAMP - make_interval( 0, 0, 0, dead_letter_retention, 0, 0, 0 );

    -- Delete old history rows
    DELETE FROM {schema}.dead_letter WHERE created_on < ts;

END;


$BODY$;

ALTER PROCEDURE {schema}.cron_dead_letter_retention( integer )
    OWNER TO postgres;
