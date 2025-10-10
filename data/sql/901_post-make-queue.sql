-- Test post queue deployment
-- DO NOT RUN ON A LIVE QUEUE
-- 
CREATE OR REPLACE PROCEDURE {schema}.post_deploy_test()
LANGUAGE 'plpgsql'
AS $BODY$

DECLARE
    audit_count INTEGER DEFAULT 0;
    audit_count_post INTEGER DEFAULT 0;
    available_on TIMESTAMP DEFAULT CURRENT_TIMESTAMP;
    backoff_jitter_max INTEGER DEFAULT 99;
    backoff_jitter_min INTEGER DEFAULT 1;
    client_id varchar(128) = 'client01';
    delay_seconds INTEGER DEFAULT 0;
    die_roll INTEGER DEFAULT 0;
    expires TIMESTAMP;
    lease_duration INTEGER DEFAULT 30;
    lease_expires TIMESTAMP DEFAULT CURRENT_TIMESTAMP;
    loop_count INTEGER DEFAULT 0;
    max_recs INTEGER DEFAULT 50;
    message_state_id INTEGER DEFAULT 1;
    msg_id uuid DEFAULT uuid_generate_v4();
    msg_json json = '{}';
    retries INTEGER DEFAULT 0;
    test_bad INTEGER DEFAULT 0;
    test_iteration_max INTEGER := max_recs / 2;
    test_result INTEGER DEFAULT 0; -- 0 Pass, 1 Fail
    ts TIMESTAMP DEFAULT CURRENT_TIMESTAMP;

BEGIN
    call {schema}.reset_queue();

    --
    -- Create some test messages
    loop_count := 0;
    loop
        exit when loop_count >= max_recs;
        loop_count := loop_count + 1;

        SELECT random_value into die_roll from {schema}.random_between(1,100);

        if (die_roll < 20) then
            call {schema}.enqueue(msg_json);
        else 

            msg_id := uuid_generate_v4();

            if( die_roll > 80 ) then
                message_state_id := 2;
                retries := 1;
                delay_seconds := die_roll * 3;
                available_on := CURRENT_TIMESTAMP + make_interval( 0, 0, 0, 0, 0, 0, delay_seconds );
                lease_expires := available_on + make_interval( 0, 0, 0, 0, 0, 0, lease_duration );
            else 
                message_state_id := 1;
                retries := 0;
                delay_seconds := 0;
                available_on := CURRENT_TIMESTAMP;
                lease_expires := null;
            end if;

            INSERT INTO test01.message_queue(message_id, message_state_id, retries, available_on, lease_expires)
            VALUES (msg_id, message_state_id, retries, available_on, lease_expires);

            call {schema}.add_audit(msg_id, message_state_id, client_id, 'test queue');

        end if;

    end loop;

    select count(*)
    into audit_count_post
    from {schema}.message_audit;

    IF audit_count_post <= loop_count THEN
        test_bad := test_bad + 1;
        RAISE NOTICE 'Post create messages counts are odd. Expected: %, Actual: %', loop_count, audit_count_post;
    END IF;

    -- do some tests
    loop_count := 0;
    loop
        exit when loop_count >= test_iteration_max;
        loop_count := loop_count + 1;

        select count(*)
        into audit_count
        from {schema}.message_audit;

        select b.msg_id, b.expires, b.msg_json 
            into msg_id, ts, msg_json 
            from test01.dequeue(client_id, lease_duration) as b;

        IF msg_id IS NULL THEN
            test_bad := test_bad + 1;
            test_result := 1;
            RAISE NOTICE 'Unexpected: no more messages';
            exit;
        END IF;

        IF ts > CURRENT_TIMESTAMP THEN
            test_bad := test_bad + 1;
            test_result := 1;
            RAISE NOTICE 'Timestamp in future: %', msg_id;
        END IF;

        SELECT random_value into die_roll from {schema}.random_between(1,100);
        IF die_roll < 10 THEN
            call {schema}.message_rej(msg_id, client_id, 'bad format');
        ELSIF die_roll > 80 THEN
            call {schema}.message_nak(msg_id,client_id, 'uow fail');
        ELSE
            call {schema}.message_ack(msg_id,client_id, 'ack');
        END IF;

        select count(*)
            into audit_count_post
            from {schema}.message_audit;

        IF audit_count >= audit_count_post THEN
            test_bad := test_bad + 1;
            test_result := 1;
            RAISE NOTICE 'Audit Count is Off for %', msg_id;
        END IF;

    end loop;

    -- Reset is desirable
    -- call {schema}.reset_queue();

    --
    -- Test Results
	RAISE NOTICE 'test result: %, Failed Tests: %', test_result, test_bad;
END;
$BODY$;
