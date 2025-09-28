-- TYPE: Message item
DROP TYPE IF EXISTS {schema}.queue_item;
CREATE TYPE {schema}.queue_item AS (
    message_id uuid, 
    lease_expires timestamp with time zone, 
    message_json json
);
