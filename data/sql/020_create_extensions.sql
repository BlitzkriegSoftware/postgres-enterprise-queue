-- Install extensions

CREATE EXTENSION IF NOT EXISTS pg_cron version '1.6';
CREATE EXTENSION IF NOT EXISTS pldbgapi;
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- SELECT uuid_generate_v4() as generated_uuid;

select * from pg_available_extensions() order by name;