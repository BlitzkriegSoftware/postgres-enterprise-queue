
-- call test01.enqueue('{}');

DO $$

DECLARE 
	msg_id varchar;
	expires TIMESTAMP;
	msg_json json;

BEGIN

	select b.msg_id, b.expires, b.msg_json 
	into msg_id, expires, msg_json 
	from test01.dequeue('client03', 30) as b;
	
	RAISE NOTICE 'id: %, expires: %, json: %', msg_id, expires, msg_json;
	
END $$ LANGUAGE plpgsql;
