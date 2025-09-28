TRUNCATE TABLE {schema}.message_state;

INSERT INTO {schema}.message_state(
	message_state_id, state_title, is_fsm)
	VALUES (1, 'queued', true);

INSERT INTO {schema}.message_state(
	message_state_id, state_title, is_fsm)
	VALUES (2, 'leased', true);

INSERT INTO {schema}.message_state(
	message_state_id, state_title, is_fsm)
	VALUES (3, 'history', false);

INSERT INTO {schema}.message_state(
	message_state_id, state_title, is_fsm)
	VALUES (4, 'rescheduled', false);
	
INSERT INTO {schema}.message_state(
	message_state_id, state_title, is_fsm)
	VALUES (5, 'lease-expired', true);
	
INSERT INTO {schema}.message_state(
	message_state_id, state_title, is_fsm)
	VALUES (6, 'message-expired', false);
	
INSERT INTO {schema}.message_state(
	message_state_id, state_title, is_fsm)
	VALUES (7, 'dead-letter', false);

INSERT INTO {schema}.message_state(
	message_state_id, state_title, is_fsm)
	VALUES (99, 'error', false);