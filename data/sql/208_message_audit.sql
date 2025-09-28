-- Table: {schema}.message_audit

CREATE TABLE {schema}.message_audit
(
    audit_id bigint NOT NULL,
    message_id uuid DEFAULT uuid_generate_v4(),
    message_state_id integer NOT NULL DEFAULT 0,
    audit_on timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    audit_by character varying(128) DEFAULT 'system',
    reason_why text NOT NULL DEFAULT '',
    PRIMARY KEY (audit_id)
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS {schema}.message_audit
    OWNER to postgres;

CREATE SEQUENCE {schema}.message_audit_message_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE {schema}.message_audit_message_id_seq OWNER TO postgres;

ALTER SEQUENCE {schema}.message_audit_message_id_seq OWNED BY {schema}.message_audit.audit_id;
