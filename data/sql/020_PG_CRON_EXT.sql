-- Install cron extension

-- select * from pg_available_extensions();

CREATE EXTENSION IF NOT EXISTS pg_cron version '1.6';