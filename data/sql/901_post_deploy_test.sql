-- Test post queue deployment
-- DO NOT RUN ON A LIVE QUEUE
-- 
CREATE OR REPLACE PROCEDURE {schema}.post_deploy_test(
    -- 0 clear no data, 1 at begining, 2 at begining and end of test
    test_flag integer DEFAULT 2,
    -- How many iterations
    test_iterations integer DEFAULT 100   
)
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
    message_state_id INTEGER DEFAULT 1;
    msg_id uuid DEFAULT uuid_generate_v4();
    msg_json json = '{}';
    reschedule_delay integer := 900;
    retries INTEGER DEFAULT 0;
    test_bad INTEGER DEFAULT 0;
    test_iteration_default INTEGER := 100;
    test_iterations_consumer INTEGER := 0;
    test_result INTEGER DEFAULT 0; -- 0 Pass, 1 Fail
    test_result_text varchar(128);
    ts TIMESTAMP DEFAULT CURRENT_TIMESTAMP;

BEGIN
    -- clean start
    IF test_flag > 0 THEN
        call {schema}.reset_queue();
        RAISE NOTICE 'Reset Tables';
    END IF;

    IF test_iterations < 0 THEN
        test_iterations := test_iteration_default;
    END IF;

    --
    -- The PRODUCER
    loop_count := 0;
    loop
        exit when loop_count >= test_iterations;
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

    -- The CONSUMER
    test_iterations_consumer := test_iterations * 2 / 3;
    
    loop_count := 0;
    loop
        exit when loop_count >= test_iterations_consumer;
        loop_count := loop_count + 1;

        select count(*)
            into audit_count
            from {schema}.message_audit;

        --
        -- Unit of Work Begin

        select b.msg_id, b.expires, b.msg_json 
            into msg_id, ts, msg_json 
            from test01.dequeue(client_id, lease_duration) as b;

        RAISE NOTICE '[%] dequeue. ID: %, expires: %, json: %', loop_count, msg_id, ts, msg_json;

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

            -- Randomly decide the outcome of our UoW (to simulate processing)
            SELECT random_value into die_roll from {schema}.random_between(1, 100);
            IF die_roll < 10 THEN
                RAISE NOTICE '   REJ'; -- 3
                call {schema}.message_rej(msg_id, client_id, 'bad format');
            ELSIF die_roll < 30 THEN
                RAISE NOTICE '   NAK'; -- 2
                call {schema}.message_nak(msg_id, client_id, 'uow fail');
            ELSIF die_roll < 40 THEN
                RAISE NOTICE '   RSH'; -- 4
                call {schema}.message_reschedule(msg_id, reschedule_delay, client_id, 'temp. unavailable');
            ELSE
                RAISE NOTICE '   ACK'; -- 1
                call {schema}.message_ack(msg_id, client_id, 'ack');
            END IF;

        EXCEPTION
            WHEN OTHERS THEN
                RAISE NOTICE 'An unknown error occurred: %', SQLERRM;
                test_bad := test_bad + 1;
                test_result := 1;

        END;

        -- Unit of Work END
        --

    END LOOP;

    -- Reset is desirable
    IF test_flag > 1 THEN
        call {schema}.reset_queue();
        RAISE NOTICE 'Reset Tables';
    END IF;

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
