DROP PROCEDURE IF EXISTS {schema}.cron_audit_clean();

CREATE OR REPLACE PROCEDURE {schema}.cron_audit_clean(
    IN audit_retention_in integer DEFAULT 0
)
LANGUAGE plpgsql
AS $BODY$

DECLARE
    audit_retention integer := 0;
    audit_retention_default integer := 31;
    ts TIMESTAMP;

BEGIN

    audit_retention := audit_retention_in;
    if audit_retention <= 0 then

        select COALESCE(CAST(audit_retention AS INTEGER), audit_retention_default)
            into audit_retention
            from {schema}.queue_configuration 
            where setting_name = 'audit_retention';

    end if;

    -- years, months, weeks, days, hours, mins, seconds
    ts := CURRENT_TIMESTAMP - make_interval( 0, 0, 0, audit_retention, 0, 0, 0 );

    -- Delete old audit rows
    DELETE FROM {schema}.message_audit WHERE created_on < ts;

END;


$BODY$;

ALTER PROCEDURE {schema}.cron_audit_clean( integer )
    OWNER TO postgres;
