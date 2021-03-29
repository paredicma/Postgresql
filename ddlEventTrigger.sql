 CREATE SCHEMA IF NOT EXISTS sox  AUTHORIZATION postgres;
 CREATE OR REPLACE FUNCTION sox.f_ddl_prevent_function() RETURNS event_trigger AS $$
DECLARE _record RECORD;
BEGIN
    FOR _record IN SELECT * FROM pg_event_trigger_ddl_commands() LOOP
if current_user = 'postgres' OR current_user = 'enterprisedb' OR current_user = 'elysion' then --in ('enterprisedb','postgres') then
null;
else
RAISE EXCEPTION 'According to  SOX policies, You are not allowed to create/change %', _record.object_identity;
end if;
    END LOOP;
END;
$$
LANGUAGE plpgsql;

drop EVENT TRIGGER ddl_prevent_trigger;
alter event trigger ddl_prevent_trigger disable ;

\dy ddl_prevent_trigger



CREATE EVENT TRIGGER ddl_prevent_trigger                          
  ON ddl_command_end WHEN TAG IN ('CREATE FUNCTION','CREATE RULE','CREATE TRIGGER', 'CREATE TABLE' ,
  'ALTER FUNCTION','ALTER RULE','ALTER TRIGGER','ALTER TABLE','DROP FUNCTION','DROP RULE','DROP TRIGGER', 'DROP TABLE' )
  EXECUTE PROCEDURE sox.f_ddl_prevent_function();
  
  
  
  
  CREATE EVENT TRIGGER ddl_prevent_trigger\n ON ddl_command_end WHEN TAG IN ('CREATE FUNCTION','CREATE RULE','CREATE TRIGGER', 'CREATE TABLE' ,'ALTER FUNCTION','ALTER RULE','ALTER TRIGGER','ALTER TABLE','DROP FUNCTION','DROP RULE','DROP TRIGGER', 'DROP TABLE' )\n  EXECUTE PROCEDURE sox.f_ddl_prevent_function();

drop function f_test(); 
 CREATE or REPLACE FUNCTION f_test(rolename text) RETURNS void                  
    LANGUAGE plpgsql
    AS $$
BEGIN
EXECUTE 'CREATE ROLE ' || roleName ||' NOLOGIN;';
END;
$$




---------------

postgres=# alter table t1 add column g text;
ERROR:  You are not allowed to change public.t1
CONTEXT:  PL/pgSQL function no_ddl() line 5 at RAISE
Cool, but there is an issue with the current implementation:

---------------

postgres=# create table t2 ( a int );
CREATE TABLE
postgres=# alter table t2 add column b text;
ERROR:  You are not allowed to change public.t2
CONTEXT:  PL/pgSQL function no_ddl() line 5 at RAISE

--What we effectively did is to deny all alter statements for all objects in that database. 
-- This is probably not what you want. A better approach is this:

---------------

CREATE OR REPLACE FUNCTION no_ddl() RETURNS event_trigger AS $$
DECLARE r RECORD;
BEGIN
    FOR r IN SELECT * FROM pg_event_trigger_ddl_commands() LOOP
      IF ( r.objid::regclass::text = 't1' )
      THEN
            RAISE EXCEPTION 'You are not allowed to change %', r.object_identity;
      END IF;
    END LOOP;
END;
$$
LANGUAGE plpgsql;

--This way we are only raising the exception when the table “t1” is involved and do nothing for all other tables:

---------------

postgres=# alter table t2 add column b text;
ALTER TABLE
postgres=# alter table t1 add column b text;
ERROR:  You are not allowed to change public.t1

Sunucu Adi:	NOKTAFCI01
Hesap Adi:	PG_SOX_RAPOR 
Sifre:	ridz_3xX?790



 IF NOT EXISTS(

CREATE OR REPLACE FUNCTION sox.f_ddl_prevent_function() RETURNS event_trigger AS $$
DECLARE _record RECORD;
BEGIN
    FOR _record IN SELECT * FROM pg_event_trigger_ddl_commands() LOOP
		if current_user = 'postgres' OR current_user = 'enterprisedb' OR current_user = 'mmsuper'  OR current_user = 'testuser' then 
			null;
		else
			RAISE EXCEPTION 'According to  SOX policies, You are not allowed to create/change %', _record.object_identity;
		end if;
    END LOOP;
END;
$$
LANGUAGE plpgsql;






create view v_logonTrigger ( host_name,db_name,client_ip,ip_mask  ) as 
 select hbalist.host_name,hbalist.db_name,hbalist.client_ip,hbalist.ip_mask  
   from t_hba_list hbalist, t_sox_dblist dblist 
   where hbalist.host_name=dblist.host_name
   and hbalist.client_ip<>'127.0.0.1'
and (hbalist.db_name=dblist.db_name or hbalist.db_name  in ('all','samerole','sameuser','replication'))
and ( ip_mask<>32 or hbalist.client_ip not in (
   select clientname from ( 
   select ciname as clientname from mv_prod_serverlist
   union 
   select ip as clientname from mv_prod_serverlist
						) as prod_table ) 
   ) ;
select distinct(host_name||' : '||db_name||' : '||client_ip||' : '||ip_mask ) as SOX001_violation from v_logontrigger ; 

   select hbalist.host_name,hbalist.db_name,hbalist.client_ip,hbalist.ip_mask  
   from t_hba_list hbalist, t_sox_dblist dblist 
   where hbalist.host_name=dblist.host_name
		and hbalist.db_name=dblist.db_name;
   where ( ip_mask<>32 or client_ip not in (
   select client_ip from ( 
   select ciname as client_ip from mv_prod_serverlist
   union 
   select ip as clinet_ip from mv_prod_serverlist
						) as prod_table ) 
   ) 
   and client_ip<>'127.0.0.1'  and (
   host_name in (select host_name from t_sox_dblist) 
   );

