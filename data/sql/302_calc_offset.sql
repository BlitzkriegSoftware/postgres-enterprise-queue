-- FUNCTION: {schema}.calculate_offset(integer)

DROP FUNCTION IF EXISTS {schema}.calculate_offset(integer);

CREATE OR REPLACE FUNCTION {schema}.calculate_offset(
	numberofretries integer)
    RETURNS integer
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE PARALLEL UNSAFE
AS $BODY$

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
	from {schema}.queue_configuration 
	where setting_name = 'backoff_base';
	
	select COALESCE( CAST(setting_value AS INTEGER),2)
	into backoff_factor
	from {schema}.queue_configuration 
	where setting_name = 'backoff_factor';
	
    select COALESCE(CAST(setting_value AS INTEGER),99)
	into backoff_jitter_max
	from {schema}.queue_configuration 
	where setting_name = 'backoff_jitter_max';
	
    select COALESCE(CAST(setting_value AS INTEGER),11)
	into backoff_jitter_min
	from {schema}.queue_configuration 
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
$BODY$;

ALTER FUNCTION {schema}.calculate_offset(integer)
    OWNER TO postgres;
