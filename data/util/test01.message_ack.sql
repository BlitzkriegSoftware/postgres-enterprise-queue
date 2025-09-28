-- ACK a Message
CREATE OR REPLACE PROCEDURE test01.message_ack(message_id uuid, ack_by varchar(128) = 'system', reason_why text = 'completed')
LANGUAGE SQL
AS $$

BEGIN;

	INSERT INTO test01.message_history(
		message_id, message_state_id, created_on, history_on, created_by, message_json, reason_why)
	SELECT message_id, 3, created_on, CURRENT_TIMESTAMP, ack_by, message_json, reason_why
		FROM test01.message_queue 
		WHERE message_id = message_id;	
	
	DELETE FROM test01.message_queue where message_id = message_id;

	COMMIT;

END;
$$;

