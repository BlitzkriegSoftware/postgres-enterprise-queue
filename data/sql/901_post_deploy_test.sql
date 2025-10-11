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
    current TIMESTAMP;
    delay_seconds INTEGER DEFAULT 0;
    die_roll INTEGER DEFAULT 0;
    empty_id uuid := CAST('00000000-0000-0000-0000-000000000000' as uuid);
    expires TIMESTAMP;
    lease_duration INTEGER DEFAULT 30;
    lease_expires TIMESTAMP DEFAULT CURRENT_TIMESTAMP;
    lease_owner varchar(128);
    loop_count INTEGER DEFAULT 0;
    max_recs INTEGER DEFAULT 50;
    message_state_id INTEGER DEFAULT 1;
    msg_id uuid DEFAULT uuid_generate_v4();
    msg_json json = '{}';
    retries INTEGER DEFAULT 0;
    test_bad INTEGER DEFAULT 0;
    test_iteration_max INTEGER := max_recs / 2;
    test_result INTEGER DEFAULT 0; -- 0 Pass, 1 Fail
    test_result_text varchar(128);
    ts TIMESTAMP DEFAULT CURRENT_TIMESTAMP;

BEGIN
    -- clean start
    call {schema}.reset_queue();

    --
    -- Create some test messages
    loop_count := 0;
    loop
        exit when loop_count >= max_recs;
        loop_count := loop_count + 1;
        call {schema}.enqueue(msg_json);
    end loop;

    select count(*)
    into audit_count_post
    from {schema}.message_audit;

    IF audit_count_post <> loop_count THEN
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

        RAISE NOTICE 'dequeue. ID: %, expires: %, json: %', msg_id, ts, msg_json;

        IF ((msg_id IS NULL) or (msg_id = empty_id)) THEN
            test_bad := test_bad + 1;
            test_result := 1;
            RAISE NOTICE '   Unexpected: no more messages';
            CONTINUE;
        END IF;

        current := CURRENT_TIMESTAMP;
        IF ts <= current THEN
            test_bad := test_bad + 1;
            test_result := 1;
            RAISE NOTICE '   Timestamp in the past: %', current;
            CONTINUE;
        END IF;

        BEGIN

            SELECT random_value into die_roll from {schema}.random_between(1, 100);
            IF die_roll < 10 THEN
                RAISE NOTICE '   REJ';
                call {schema}.message_rej(msg_id, client_id, 'bad format');
            ELSIF die_roll > 80 THEN
                RAISE NOTICE '   NAK';
                call {schema}.message_nak(msg_id, client_id, 'uow fail');
            ELSE
                RAISE NOTICE '   ACK';
                call {schema}.message_ack(msg_id, client_id, 'ack');
            END IF;

        EXCEPTION
            WHEN OTHERS THEN
                RAISE NOTICE 'An unknown error occurred: %', SQLERRM;
        END;

    END LOOP;

    -- Reset is desirable
    call {schema}.reset_queue();

    --
    -- Test Results
    IF test_result = 0 THEN
        test_result_text := 'pass';
    ELSE
        test_result_text := 'fail';
    END IF;

	RAISE NOTICE 'test result: %, Failed Tests: %', test_result_text, test_bad;

END;
$BODY$;
