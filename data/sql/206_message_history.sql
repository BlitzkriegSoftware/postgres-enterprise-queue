-- Table: {schema}.message_history

CREATE TABLE {schema}.message_history
(
    message_id uuid DEFAULT uuid_generate_v4(),
    message_state_id integer NOT NULL DEFAULT 1,
    created_on timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    history_on timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    created_by character varying(128) DEFAULT 'system',
    message json NOT NULL DEFAULT '{}',
    reason_why text NOT NULL DEFAULT 'expired',
    PRIMARY KEY (message_id)
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS {schema}.message_history
    OWNER to postgres;
