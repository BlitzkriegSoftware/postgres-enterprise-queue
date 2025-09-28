DO $$
DECLARE
	backoff_jitter_max INTEGER;
	backoff_jitter_min INTEGER;
	jittered INTEGER;
BEGIN

    select CAST(setting_value AS INTEGER)
	into backoff_jitter_max
	from test01.queue_configuration 
	where setting_name = 'backoff_jitter_max';
	
    select CAST(setting_value AS INTEGER)
	into backoff_jitter_min
	from test01.queue_configuration 
	where setting_name = 'backoff_jitter_min';

	SELECT floor(random() * (backoff_jitter_max - backoff_jitter_min + 1) + backoff_jitter_min)::int
	into jittered;


	RAISE NOTICE 'jittered: %', jittered;
END $$ LANGUAGE plpgsql;