CREATE SCHEMA hba;


CREATE TABLE hba.cluster_list (
    cluster_id integer NOT NULL,
    cluster_name character varying(128) NOT NULL,
    active boolean DEFAULT true,
    sw_module character varying(256),
    db_name character varying(256)
);

CREATE SEQUENCE hba.cluster_list_cluster_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


CREATE TABLE hba.hba_automater (
    rule_id integer NOT NULL,
    rule_type character varying(64) DEFAULT 'host'::character varying,
    db_name character varying(128) NOT NULL,
    user_name character varying(128) NOT NULL,
    ip_address character varying(16) NOT NULL,
    method character varying(32) DEFAULT 'md5'::character varying NOT NULL,
    expire_date date,
    status character varying(32) DEFAULT 'PROGRESS'::character varying,
    comment character varying(512),
    cluster_name character varying(128) NOT NULL
);


CREATE SEQUENCE hba.hba_automater_rule_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE ONLY hba.cluster_list ALTER COLUMN cluster_id SET DEFAULT nextval('hba.cluster_list_cluster_id_seq'::regclass);

ALTER TABLE ONLY hba.hba_automater ALTER COLUMN rule_id SET DEFAULT nextval('hba.hba_automater_rule_id_seq'::regclass);
