CREATE SCHEMA grafana;

CREATE TABLE grafana.cache_hit_ratio (
    record_id integer NOT NULL,
    host character varying,
    database character varying,
    percentage numeric
);


CREATE SEQUENCE grafana.cache_hit_ratio_record_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;



CREATE TABLE grafana.db_size_history (
    record_id integer NOT NULL,
    host character varying,
    database character varying,
    size double precision,
    record_date timestamp without time zone
);



CREATE SEQUENCE grafana.db_size_history_record_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


CREATE TABLE grafana.deadtuplestat (
    report_id integer NOT NULL,
    host character varying,
    database character varying,
    schemaname character varying,
    tablename character varying,
    dead_tuple integer,
    live_tuple integer,
    last_autovacuum timestamp without time zone
);

CREATE SEQUENCE grafana.deadtuplestat_report_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


CREATE TABLE grafana.server_version (
    record_id integer NOT NULL,
    host character varying,
    version character varying
);

CREATE SEQUENCE grafana.server_version_record_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


CREATE TABLE grafana.table_size (
    record_id integer NOT NULL,
    host character varying,
    database character varying,
    schema_name character varying,
    table_name character varying,
    table_size bigint
);

CREATE SEQUENCE grafana.table_size_record_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

CREATE VIEW grafana.v_db_size_history AS
 SELECT db_size_history.record_id,
    db_size_history.host,
    db_size_history.database,
    db_size_history.size,
    (db_size_history.record_date - '03:00:00'::interval) AS record_date
   FROM grafana.db_size_history;


ALTER TABLE ONLY grafana.cache_hit_ratio ALTER COLUMN record_id SET DEFAULT nextval('grafana.cache_hit_ratio_record_id_seq'::regclass);
ALTER TABLE ONLY grafana.db_size_history ALTER COLUMN record_id SET DEFAULT nextval('grafana.db_size_history_record_id_seq'::regclass);
ALTER TABLE ONLY grafana.deadtuplestat ALTER COLUMN report_id SET DEFAULT nextval('grafana.deadtuplestat_report_id_seq'::regclass);
ALTER TABLE ONLY grafana.server_version ALTER COLUMN record_id SET DEFAULT nextval('grafana.server_version_record_id_seq'::regclass);
ALTER TABLE ONLY grafana.table_size ALTER COLUMN record_id SET DEFAULT nextval('grafana.table_size_record_id_seq'::regclass);
ALTER TABLE ONLY grafana.deadtuplestat
    ADD CONSTRAINT deadtuplestat_pkey PRIMARY KEY (report_id);

CREATE INDEX cache_hit_ratio_host_database_idx ON grafana.cache_hit_ratio USING btree (host, database);
CREATE UNIQUE INDEX db_size_history_host_database_record_date_idx ON grafana.db_size_history USING btree (host, database, record_date);
CREATE INDEX db_size_history_record_date_idx ON grafana.db_size_history USING brin (record_date);
CREATE INDEX deadtuplestat_host_idx ON grafana.deadtuplestat USING btree (host);
