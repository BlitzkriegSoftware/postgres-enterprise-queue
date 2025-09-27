CREATE TABLE test01.queue_configuration
(
    setting_name character varying(128),
    setting_value character varying(2048) NOT NULL,
    unit character varying(32) DEFAULT 'minutes',
    casted_as character varying(64) DEFAULT 'integer',
    modified_by character varying(128) DEFAULT 'system',
    modified_on timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    notes text,
    PRIMARY KEY (setting_name)
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS test01.queue_configuration
    OWNER to postgres;