-- Table: {schema}.message_state

DROP TABLE IF EXISTS {schema}.message_state;

CREATE TABLE IF NOT EXISTS {schema}.message_state
(
    message_state_id integer NOT NULL,
    state_title character varying(32) COLLATE pg_catalog."default",
    is_fsm boolean DEFAULT true,
    CONSTRAINT message_state_pkey PRIMARY KEY (message_state_id)
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS {schema}.message_state
    OWNER to postgres;