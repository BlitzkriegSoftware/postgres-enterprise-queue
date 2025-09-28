-- calculate offset in seconds
DROP FUNCTION IF EXISTS test01.calculate_offset;

CREATE OR REPLACE FUNCTION test01.calculate_offset(numberOfRetries INTEGER)
RETURNS INTEGER
LANGUAGE plpgsql
AS $$

DECLARE
	backoff_base INTEGER;
	backoff_factor INTEGER;
	backoff_jitter_max INTEGER;
	backoff_jitter_min INTEGER;
	jittered INTEGER;
	delay INTEGER;
BEGIN

	select COALESCE(CAST(setting_value AS INTEGER),10)
	into backoff_base
	from test01.queue_configuration 
	where setting_name = 'backoff_base';
	
	select COALESCE( CAST(setting_value AS INTEGER),2)
	into backoff_factor
	from test01.queue_configuration 
	where setting_name = 'backoff_factor';
	
    select COALESCE(CAST(setting_value AS INTEGER),99)
	into backoff_jitter_max
	from test01.queue_configuration 
	where setting_name = 'backoff_jitter_max';
	
    select COALESCE(CAST(setting_value AS INTEGER),11)
	into backoff_jitter_min
	from test01.queue_configuration 
	where setting_name = 'backoff_jitter_min';

	if(numberOfRetries <= 0) then
		numberOfRetries := 0;
	end if;

	SELECT floor(random() * (backoff_jitter_max - backoff_jitter_min + 1) + backoff_jitter_min)::int
	into jittered;

	SELECT backoff_base * POWER(backoff_factor, numberOfRetries) + jittered
	INTO delay;

	RETURN delay;
END;
$$;	
	