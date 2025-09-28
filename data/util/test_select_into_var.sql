DO $$
DECLARE
	backoff_base INTEGER;
BEGIN
	select CAST(setting_value AS INTEGER)
	into backoff_base
	from test01.queue_configuration 
	where setting_name = 'backoff_base';

	RAISE NOTICE 'backoff_base: %', backoff_base;
END $$ LANGUAGE plpgsql;
