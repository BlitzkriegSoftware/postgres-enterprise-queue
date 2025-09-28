-- Test post queue deployment
-- DO NOT RUN ON A LIVE QUEUE

DO $$
DECLARE
    test_result INTEGER DEFAULT 0; -- 0 Pass, 1 Fail
    test_msg varchar(2048) := 'pass';
    die_roll INTEGER DEFAULT 0;
    delay_seconds INTEGER DEFAULT 0;
    max_recs INTEGER DEFAULT 50;
    count INTEGER DEFAULT 0;
    message_state_id INTEGER DEFAULT 1;
    retries INTEGER DEFAULT 0;
    available_on TIMESTAMP DEFAULT CURRENT_TIMESTAMP;
    lease_expires TIMESTAMP DEFAULT CURRENT_TIMESTAMP;
    lease_duration INTEGER DEFAULT 30;
    backoff_jitter_min INTEGER DEFAULT 1;
    backoff_jitter_max INTEGER DEFAULT 99;

BEGIN
    call {schema}.reset_queue();

    --
    -- Create some test messages
    loop
        exit when count >= max_recs;
        count := count + 1;

        SELECT floor(random() * (backoff_jitter_max - backoff_jitter_min + 1) + backoff_jitter_min)::int
	    into die_roll;

        if( die_roll > 80 ) then
            message_state_id := 2;
            retries := 1;
            delay_seconds := die_roll * 3;
            available_on := CURRENT_TIMESTAMP + make_interval( 0, 0, 0, 0, 0, 0, delay_seconds)
            lease_expires := available_on +make_interval( 0, 0, 0, 0, 0, 0, lease_duration)
        else 
            message_state_id := 1;
            retries := 0;
            available_on := CURRENT_TIMESTAMP;
            lease_expires := null;
        end if;

        INSERT INTO test01.message_queue(message_state_id, retries, available_on, lease_expires)
	    VALUES (message_state_id, retries, available_on, lease_expires);

    end loop;

    -- do some tests
    

    -- reset
    call {schema}.reset_queue();

    --
    -- Test Results
	RAISE NOTICE 'test result: % => %', test_result, test_msg;
END $$ LANGUAGE plpgsql;