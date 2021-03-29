--------------------------------------------------------

CREATE TABLE testschema.testtable 
(
    id bigint NOT NULL,
    service bigint,
    client character varying(40) COLLATE pg_catalog."default",
    source bigint DEFAULT 0,
    send_time timestamp without time zone NOT NULL,
    content text COLLATE pg_catalog."default",
    transaction_id character varying(50) COLLATE pg_catalog."default",
    nickname character varying(1000) COLLATE pg_catalog."default",
    avatar_url character varying(200) COLLATE pg_catalog."default",
    campaign_id bigint DEFAULT '-1'::integer
) PARTITION BY RANGE (send_time) ;

SELECT partman.create_parent('testschema.testtable', 'send_time', 'native', 'daily', p_start_partition := '2017-01-01');

UPDATE partman.part_config SET premake = 8 WHERE parent_table = 'testschema.testtable';

SELECT cron.schedule('@daily', $$select partman.run_maintenance(p_parent_table := 'testschema.testtable',p_analyze := false)$$);

 select partman.run_maintenance(p_parent_table := 'testschema.testtable');
 
 SELECT cron.unschedule(1);
 
-----------------------------------
 
 UPDATE partman.part_config SET retention = '10 days', retention_keep_table=false WHERE parent_table='myschema.t1';
 
 create_parent(p_parent_table text, p_control text, p_type text, p_interval text, p_constraint_cols text[] DEFAULT
NULL, p_premake int DEFAULT 4, p_automatic_maintenance text DEFAULT 'on', p_start_partition text DEFAULT NULL,
p_inherit_fk boolean DEFAULT true, p_epoch text DEFAULT 'none', p_upsert text DEFAULT '', p_publications text[]
DEFAULT NULL, p_trigger_return_null boolean DEFAULT true, p_template_table text DEFAULT NULL, p_jobmon boolean
DEFAULT true, p_debug boolean DEFAULT false)RETURNS boolean


SELECT partman.create_parent('testschema.testtable', 'send_time', 'native', 'daily', p_start_partition := '2017-01-01');


UPDATE partman.part_config SET retention = '10 days', retention_keep_table=false WHERE parent_table='t1';
select partman.run_maintenance(p_parent_table := 'myschema.t1',retention = '10 days',p_debug := TRUE);


SELECT partman.create_partition_id('testschema.testtable', )



SELECT run_maintenance ( p_analyze : = false ); 

SELECT cron.schedule('@daily', $$SELECT partman.run_maintenance(p_analyze := false)$$);

UPDATE partman.part_config SET retention_keep_table = false, retention = '1 month' WHERE parent_table = 'myschema.t4';

UPDATE partman.part_config SET retention_keep_table = false, retention = '2 days' WHERE parent_table = 'myschema.t4';

UPDATE partman.part_config SET premake = 10 WHERE parent_table = 'myschema.t4';

SELECT cron.schedule('@daily', $$SELECT partman.run_maintenance(p_analyze := false)$$);

