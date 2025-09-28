-- ACK a message
CREATE OR REPLACE PROCEDURE message_ack(message_id uuid, ack_by varchar(128), reason text = 'completed')
LANGUAGE SQL
AS $$

BEGIN

SELECT message_id, message_state_id, retries, available_on, lease_expires, created_on, created_by, message
	FROM test01.message_queue where message_id = message_id;

INSERT INTO test01.message_history(
	message_id, message_state_id, created_on, history_on, created_by, message, reason_why)
	VALUES (?, ?, ?, ?, ?, ?, ?);

END;
$$;

