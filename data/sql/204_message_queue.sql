-- Table: {schema}.message_queue

CREATE TABLE {schema}.message_queue
(
    message_id uuid DEFAULT uuid_generate_v4(),
    message_state_id integer NOT NULL DEFAULT 1,
    retries integer NOT NULL DEFAULT 0,
    available_on timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    lease_expires timestamp with time zone DEFAULT NULL,
    leased_by character varying(128) DEFAULT 'system',
    created_on timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    created_by character varying(128) DEFAULT 'system',
    message_expires timestamp with time zone DEFAULT NULL,
    message_json json NOT NULL DEFAULT '{}',
    PRIMARY KEY (message_id)
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS {schema}.message_queue
    OWNER to postgres;
