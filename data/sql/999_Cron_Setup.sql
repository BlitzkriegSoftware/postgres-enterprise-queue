
DO $$

DECLARE 
    cron_vacuum varchar;
    cron_schedule_retention_queue varchar;
    cron_schedule_retention_dead_letter varchar;
    cron_schedule_retention_history  varchar;
    cron_schedule_retention_audit_log varchar;

    cron_vacuum_default varchar :=  '45 4 * * *';
    cron_schedule_retention_queue_default varchar := '*/7 * * * * *';
    cron_schedule_retention_dead_letter_default varchar  :=  '0 3 * * *';
    cron_schedule_retention_history_default varchar := '8 1 * * 6';
    cron_schedule_retention_audit_log_default varchar := '0 3 * * *';

BEGIN

    select COALESCE(setting_value, cron_vacuum_default)
        into cron_vacuum
        from {schema}.queue_configuration 
        where setting_name = 'cron_vacuum';

    select COALESCE(setting_value, cron_schedule_retention_queue_default)
        into cron_schedule_retention_queue
        from {schema}.queue_configuration 
        where setting_name = 'cron_schedule_retention_queue';

    select COALESCE(setting_value, cron_schedule_retention_dead_letter_default)
        into cron_schedule_retention_dead_letter
        from {schema}.queue_configuration 
        where setting_name = 'cron_schedule_retention_dead_letter';

    select COALESCE(setting_value, cron_schedule_retention_history_default)
        into cron_schedule_retention_history
        from {schema}.queue_configuration 
        where setting_name = 'cron_schedule_retention_history';

    select COALESCE(setting_value, cron_schedule_retention_audit_log_default)
        into cron_schedule_retention_audit_log
        from {schema}.queue_configuration 
        where setting_name = 'cron_schedule_retention_audit_log';

    -- do the PEQ scheduled tasks
    SELECT cron.schedule('retention_queue', cron_schedule_retention_queue, 'CALL {schema}.cron_unlock(0)');
    SELECT cron.schedule('retention_dead_letter', cron_schedule_retention_dead_letter, 'CALL {schema}.cron_dead_letter_retention(0)');
    SELECT cron.schedule('retention_history', cron_schedule_retention_history, 'CALL {schema}.cron_history_clean(0)');
    SELECT cron.schedule('retention_audit_log', cron_schedule_retention_audit_log, 'CALL {schema}.cron_audit_clean(0)');

    -- bonus, do a nightly vaccuum
    SELECT cron.schedule('nightly-vacuum', cron_vacuum, 'VACUUM');

    select * from cron.job_run_details order by start_time desc;

END $$ LANGUAGE plpgsql;
