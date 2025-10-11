DROP PROCEDURE IF EXISTS {schema}.cron_history_clean();

CREATE OR REPLACE PROCEDURE {schema}.cron_history_clean(
    IN history_retention_in integer DEFAULT 0
)
LANGUAGE plpgsql
AS $BODY$

DECLARE
    history_retention integer := 0;
    history_retention_default integer := 181;
    ts TIMESTAMP;

BEGIN

    history_retention := history_retention_in;
    if history_retention <= 0 then

        select COALESCE(CAST(setting_value AS INTEGER), history_retention_default)
            into history_retention
            from {schema}.queue_configuration 
            where setting_name = 'history_retention';

    end if;

    -- years, months, weeks, days, hours, mins, seconds
    ts := CURRENT_TIMESTAMP - make_interval( 0, 0, 0, history_retention, 0, 0, 0 );

    -- Delete old history rows
    DELETE FROM test01.message_history WHERE created_on < ts;

END;


$BODY$;

ALTER PROCEDURE {schema}.cron_history_clean( integer )
    OWNER TO postgres;
