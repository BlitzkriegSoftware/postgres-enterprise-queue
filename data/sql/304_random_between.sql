-- FUNCTION: {schema}.random_between(integer, integer)

DROP FUNCTION IF EXISTS {schema}.random_between(integer, integer);

CREATE OR REPLACE FUNCTION {schema}.random_between(
	min_value integer,
	max_value integer,
	OUT random_value integer)
    RETURNS integer
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE PARALLEL UNSAFE
AS $BODY$

BEGIN 

    SELECT floor(random() * (max_value - min_value + 1) + min_value)::int
        into random_value;

	return;

END;

$BODY$;

ALTER FUNCTION {schema}.random_between(integer, integer)
    OWNER TO postgres;
