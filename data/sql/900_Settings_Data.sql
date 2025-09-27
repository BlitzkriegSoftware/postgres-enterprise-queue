TRUNCATE TABLE {schema}.queue_configuration;

INSERT INTO {schema}.queue_configuration(
	setting_name, setting_value, unit, casted_as, notes)
	VALUES ('item_delay', '0', 'seconds', 'number',  'delay making message available by this number of seconds, sometimes its useful to have a short initial delay. More often, a jitted value when queuing up batches of messages is useful. For scheduling messages in the future, use the parameters in the procedures');

INSERT INTO {schema}.queue_configuration(
	setting_name, setting_value, unit, casted_as, notes)
	VALUES ('item_ttl', '4320', 'minutes', 'number',  'items in the queue live for this # of minutes, before they get moved to dead_letter table, this is a very long time. If anything, consider shortening it.');

INSERT INTO {schema}.queue_configuration(
	setting_name, setting_value, unit, casted_as, notes)
	VALUES ('lease_duration', '30', 'seconds', 'number',  'this is the default lease on an item, if not specified in the call, think hard about this by monitoring the average unit of work, and adjust the setting to be that time plus two standard deviations (rounding up to the nearest second), and remember to consider what should happpen when the system is under stress and adjust the lease time setting as needed either in here or as a parameter to the procedure calls. The "art" is to balance making sure most units of work that will complete successfully do finish, and those that will not, will not VS. having the unit of work (which represents business value) be overly delayed. The happy path is this value is never used.');

INSERT INTO {schema}.queue_configuration(
	setting_name, setting_value, unit, casted_as, notes)
	VALUES ('dead_letter_retention', '30', 'days', 'number',  'messages are purged from dead letter after this many days. Remember messages can be requeued using the procedures');
	
INSERT INTO {schema}.queue_configuration(
	setting_name, setting_value, unit, casted_as, notes)
	VALUES ('history_retention', '181', 'days', 'number',  'this should be adjusted for your orgs data retention policy. Removal from history is a hard delete, but history can be recovered from backups');

INSERT INTO {schema}.queue_configuration(
	setting_name, setting_value, unit, casted_as, notes)
	VALUES ('max_retries', '5', 'count', 'number',  'A message can be processed no more than this many times. Backoff is exponential and jittered, see next settings. Carefully concider if the total maximum elapsed time to process a message and get around to successfully executing its associated unit of work is reasonable.');

INSERT INTO {schema}.queue_configuration(
	setting_name, setting_value, unit, casted_as, notes)
	VALUES ('backoff_base', '10', 'seconds', 'number',  'think carefully before changing any of these settings, see Backoff formula');

INSERT INTO {schema}.queue_configuration(
	setting_name, setting_value, unit, casted_as, notes)
	VALUES ('backoff_factor', '2', 'number', 'number',  'think carefully before changing any of these settings, see Backoff formula');

INSERT INTO {schema}.queue_configuration(
	setting_name, setting_value, unit, casted_as, notes)
	VALUES ('backoff_jitter_min', '11', 'number', 'number',  'think carefully before changing any of these settings, see Backoff formula');

INSERT INTO {schema}.queue_configuration(
	setting_name, setting_value, unit, casted_as, notes)
	VALUES ('backoff_jitter_max', '99', 'number', 'number',  'think carefully before changing any of these settings, see Backoff formula');

INSERT INTO {schema}.queue_configuration(
	setting_name, setting_value, unit, casted_as, notes)
	VALUES ('cron_schedule_retention_queue', '*/7 * * * * *', 'cron', 'string',  'Schedule to run the main queue lock clearing procedure on, every 7 minutes');

INSERT INTO {schema}.queue_configuration(
	setting_name, setting_value, unit, casted_as, notes)
	VALUES ('cron_schedule_retention_dead_letter', '0 3 * * *', 'cron', 'string',  'Schedule to run the dead-letter cleanup procedure on, 3am Daily');

INSERT INTO {schema}.queue_configuration(
	setting_name, setting_value, unit, casted_as, notes)
	VALUES ('cron_schedule_retention_history', '8 1 * * 6', 'cron', 'string',  'Schedule to run history cleanup procedure on,  1:08am Saturday');
