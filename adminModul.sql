--IDM Entegration (with SOX) Version : 2.0.2
-- USER CREATE --
create extension IF NOT EXISTS plpgsql; 

do $$
begin
    if not exists(select 1 FROM pg_roles WHERE rolname='admin') then
        create user admin superuser;
    end if;
end
$$ language plpgsql;

--do $$
--begin
--    if not exists(select 1 FROM pg_roles WHERE rolname='personel_user') then
--        create role personel_user;
--    end if;
--end
--$$ language plpgsql;
-- alter user admin set search_path to 'admin_schema';

create schema IF NOT EXISTS admin_schema ; 

--------------------

create table IF NOT EXISTS admin_schema.admin_audit (
process_id serial,
admin_function_name varchar(256),
admin_process_detail varchar(1024),
process_time timestamp default now()
);
create index IF NOT EXISTS idx_admin_audit_fname on admin_schema.admin_audit (admin_function_name); 
create index IF NOT EXISTS idx_admin_audit_ptime on admin_schema.admin_audit (process_time);           
create index IF NOT EXISTS idx_admin_audit_pdetail on admin_schema.admin_audit (admin_process_detail); 

--------------- FUNCTIONS-----------------------
CREATE or REPLACE FUNCTION admin_schema.sp_admin_create_role(rolename text) RETURNS void
    LANGUAGE plpgsql
    AS $$

BEGIN
EXECUTE 'CREATE ROLE "' || roleName ||'" NOLOGIN;';
--EXECUTE 'INSERT INTO admin_schema.admin_audit (admin_function_name,admin_process_detail) VALUES (''sp_admin_create_role'', ''CREATE ROLE ' || roleName ||' NOLOGIN;'' ) ';
EXECUTE 'INSERT INTO admin_schema.admin_audit (admin_function_name,admin_process_detail) VALUES (''sp_admin_create_role'', ''CREATE ROLE ' || roleName ||' NOLOGIN'' ) ';
END;
$$;
-----------------------------------
CREATE or REPLACE FUNCTION admin_schema.sp_admin_create_user(username text, password text, OUT _result text) RETURNS text
    LANGUAGE plpgsql
    AS $$
DECLARE
  md5hashPwdUsername varchar;	
BEGIN
select '1' into _result      from pg_user  where usename = username;
md5hashPwdUsername:= (select  'md5'||md5(''||password||''||username||'') );
if _result is null then
	EXECUTE 'CREATE USER "' || userName ||'" WITH PASSWORD ''' || password || '''  connection limit 10 valid until '''||(select now()+ interval '6 month')||''';';
	EXECUTE 'INSERT INTO admin_schema.admin_audit (admin_function_name,admin_process_detail) VALUES (''sp_admin_create_user:'||userName||''', '''||md5hashPwdUsername||''') ;';
--	EXECUTE 'GRANT personel_user to "' || userName ||'";';
else
	EXECUTE 'ALTER USER "' || userName ||'" WITH PASSWORD ''' || password || '''  connection limit 10 valid until '''||(select now()+ interval '6 month')||''';';
	EXECUTE 'INSERT INTO admin_schema.admin_audit (admin_function_name,admin_process_detail) VALUES (''sp_admin_create_user:'||userName||''', '''||md5hashPwdUsername||''') ;';
--	EXECUTE 'GRANT personel_user to "' || userName ||'";';
	-- RAISE EXCEPTION 'This user is already exist : username ->%', username;
end if; 
EXCEPTION 
	WHEN others then 
		RAISE EXCEPTION 'This user is already exist  : username -> %', username;
END;
$$;

-----------------------------------
CREATE or REPLACE FUNCTION admin_schema.sp_admin_add_role_to_user(username text, rolename text) RETURNS void
    LANGUAGE plpgsql
    AS $$
BEGIN
	EXECUTE 'GRANT "' || roleName || '" TO "' || userName ||'";';
	EXECUTE 'INSERT INTO admin_schema.admin_audit (admin_function_name,admin_process_detail) VALUES (''sp_admin_add_role_to_user'', ''GRANT ' || roleName || ' TO ' || userName ||''') ';
EXCEPTION 
	WHEN others then 
		null;
END;
$$;
-----------------------------------

CREATE or REPLACE FUNCTION admin_schema.sp_admin_disable_user(username text) RETURNS void
    LANGUAGE plpgsql
    AS $$
DECLARE
  _resultCheck varchar;
  target_user varchar;
BEGIN
target_user:= username;
select '1' into _resultCheck from (select * from pg_user where usesuper='f' and usename=target_user) as chechSuper;
if _resultCheck is not null then
	EXECUTE 'DROP ROLE "' || target_user || '" ;';
	EXECUTE 'INSERT INTO admin_schema.admin_audit (admin_function_name,admin_process_detail) VALUES (''sp_admin_disable_user'', ''DROP ROLE '|| target_user ||''') ';
else
	RAISE EXCEPTION 'You cannot drop superuser : username ->%', target_user;
end if; 
END;
$$;
-----------------------------------
CREATE or REPLACE FUNCTION admin_schema.sp_admin_reset_password(username text, password text) RETURNS void
    LANGUAGE plpgsql
    AS $$
DECLARE
  md5hashPwdUsername varchar;	
  _resultCheck varchar;
BEGIN
--EXECUTE 'ALTER USER ' || userName || ' WITH PASSWORD ''' || password ||''';';
md5hashPwdUsername:= (select  'md5'||md5(''||password||''||username||'') );
select '1' into _resultCheck from (
select * from admin_schema.admin_audit  
where admin_function_name like 'sp_admin_create_user:%' or admin_function_name like 'sp_admin_reset_password:%' 
order by process_time desc limit 10 ) as chechPwd
where chechPwd.admin_process_detail=md5hashPwdUsername;
if _resultCheck is null then
EXECUTE 'ALTER USER "' || username || '" WITH PASSWORD ''' || password ||'''   valid until '''||(select now()+ interval '6 month')||''';';
EXECUTE 'INSERT INTO admin_schema.admin_audit (admin_function_name,admin_process_detail) VALUES (''sp_admin_reset_password:'||username||''', '''||md5hashPwdUsername||''');';
else
	RAISE EXCEPTION 'You cannot use your last 10 password as new password : username ->%', username;
end if; 
EXCEPTION 
	WHEN others then 
		RAISE EXCEPTION 'You cannot use your last 10 password as new password : username -> %', username;
END;
$$;

----------------------------------

CREATE or REPLACE FUNCTION admin_schema.sp_admin_get_role_objprivs(rname name) RETURNS TABLE(rolename text, objname text, privname text, schemaname text)
    LANGUAGE plpgsql
    AS $$
BEGIN
return query 
select tablePriv.grantee::text as rolename, tablePriv.table_name::text as objname, 
 tablePriv.privilege_type::text as privname, tablePriv.table_schema::text as schemaname 
 FROM information_schema.table_privileges tablePriv        join pg_roles on (pg_roles.rolname = tablePriv.grantee)
 where tablePriv.grantee = rname and  pg_roles.rolcanlogin='f';  
EXECUTE 'INSERT INTO admin_schema.admin_audit (admin_function_name,admin_process_detail) VALUES (''sp_admin_get_role_objprivs'', ''Role:  '|| rname ||' '');';
EXCEPTION 
	WHEN others then 
		null;
END;
$$;
-----------------------------------
CREATE or REPLACE FUNCTION admin_schema.sp_admin_get_roles() RETURNS TABLE(rolename name)
    LANGUAGE plpgsql
    AS $$
BEGIN
return query
select distinct(troles.rolname) as rolename 
from pg_roles troles, information_schema.role_table_grants tprivs 
where troles.rolcanlogin='f' and tprivs.grantee=troles.rolname order by rolename ; 
EXECUTE 'INSERT INTO admin_schema.admin_audit (admin_function_name,admin_process_detail) VALUES (''sp_admin_get_roles'', ''-null-'');';
EXCEPTION 
	WHEN others then 
		null;
END;
$$;
-----------------------------------
CREATE or REPLACE FUNCTION admin_schema.sp_admin_remove_objpriv_from_role(rolename text, privname text, objectname text, schemaname text) RETURNS void
    LANGUAGE plpgsql
    AS $$
BEGIN
EXECUTE 'REVOKE ' || privname || ' ON "' || schemaName|| '"."' || objectname || '" FROM "' || roleName ||'";';
EXECUTE 'INSERT INTO admin_schema.admin_audit (admin_function_name,admin_process_detail) VALUES (''sp_admin_remove_objpriv_from_role'', ''REVOKE ' || privname || ' ON ' || schemaName|| '.' || objectname || ' FROM ' || roleName ||''');';
EXCEPTION 
	WHEN others then 
		null;
END
$$;

-----------------------------------
CREATE or REPLACE FUNCTION admin_schema.sp_admin_remove_role_from_user(username text, rolename text) RETURNS void
    LANGUAGE plpgsql
    AS $$
BEGIN
EXECUTE 'REVOKE "' || roleName || '" FROM "' || userName ||'";';
EXECUTE 'INSERT INTO admin_schema.admin_audit (admin_function_name,admin_process_detail) VALUES (''sp_admin_remove_role_from_user'', ''REVOKE ' || roleName || ' FROM  ' || userName || ''');';
EXCEPTION 
	WHEN others then 
		null;
END;
$$;

-----------------------------------

CREATE or REPLACE FUNCTION admin_schema.sp_admin_add_objpriv_to_role(rolename text, privname text, objectname text, schemaname text) RETURNS void
    LANGUAGE plpgsql
    AS $$
BEGIN  
EXECUTE 'GRANT USAGE on schema "' || schemaname|| '" TO "' || rolename ||'";';
EXECUTE 'GRANT ' || privname || ' ON "' || schemaname|| '"."' || objectname || '" TO "' || rolename ||'";';
EXECUTE 'INSERT INTO admin_schema.admin_audit (admin_function_name,admin_process_detail) VALUES (''sp_admin_add_objpriv_to_role'', ''GRANT ' || privname || ' ON ' || schemaname|| '.' || objectname || ' TO ' || rolename ||''');';
--EXCEPTION 
--	WHEN others then 
--		null;
END;
$$;

-----------------------------------

CREATE or REPLACE FUNCTION admin_schema.sp_admin_get_user_roles(usernametext text) RETURNS TABLE(roleusername name, rolename name)
    LANGUAGE plpgsql
    AS $$
BEGIN
if usernametext is null then
 usernametext = 'pg_user.usename';
end if;
RETURN QUERY
 EXECUTE
    'select usename as roleusername , rolname as rolename  
	from pg_user 	left join (select * from pg_auth_members, pg_roles 
    where pg_roles.oid=pg_auth_members.roleid) pg_members on (pg_user.usesysid=pg_members.member)
	where pg_user.usename in ('''|| usernametext||''');'  ; 
EXECUTE 'INSERT INTO admin_schema.admin_audit (admin_function_name,admin_process_detail) VALUES (''sp_admin_get_user_roles'', '' USERNAME: ' || usernametext||''');';	
RETURN;

--EXCEPTION 
--	WHEN others then 
--		null;
END;
$$;
-----------------------------------


CREATE or REPLACE FUNCTION admin_schema.sp_admin_get_objects() RETURNS TABLE(schemanm text, objectnm text, objecttype text, objectpermission text)
    LANGUAGE plpgsql
    AS $$
DECLARE 
 titles TEXT DEFAULT '';
 rec_film   RECORD;
 cur_films CURSOR
 FOR SELECT
	relname,relkind,n.nspname
FROM pg_catalog.pg_class c
LEFT JOIN pg_catalog.pg_namespace n ON n.oid = c.relnamespace
WHERE c.relkind IN ('r','v')
and relname not like 'pg_%'  
and n.nspname not in ('information_schema', 'pg_catalog','admin_schema','sox')
and n.nspname not like 'pg_toast%' and  n.nspname not like 'sys%' and n.nspname not like '%timescaledb%';
BEGIN
   -- Open the cursor
   OPEN cur_films; 
   LOOP
    -- fetch row into the film
      FETCH cur_films INTO rec_film;
    -- exit when no more row to fetch
      EXIT WHEN NOT FOUND; 
       schemanm:=rec_film.nspname;
       objectnm:=rec_film.relname;
       objecttype:=rec_film.relkind;
       -- build the output
      IF rec_film.relkind='r'  THEN 
         objectpermission:='SELECT,INSERT,UPDATE,DELETE';
		objecttype:='TABLE';
     		
     END IF;
      IF rec_film.relkind='v'  THEN 
        objectpermission:='SELECT,INSERT';	
		objecttype:='VIEW';
      END IF;
  RETURN NEXT;
  END LOOP;
EXECUTE 'INSERT INTO admin_schema.admin_audit (admin_function_name,admin_process_detail)
 VALUES (''sp_admin_get_objects'', ''-null-'');';	
--EXCEPTION 
--	WHEN others then 
--		null;
END; $$;
-----------------------------------


CREATE or REPLACE FUNCTION admin_schema.sp_create_ro_app_user(schema_name text) RETURNS boolean 
    LANGUAGE plpgsql
    AS $$
DECLARE
  newRole varchar;	
  currentDB varchar;
  _userCheck varchar;
  _schemaCheck varchar;
BEGIN
	SELECT current_database() into currentDB;
	newRole:= 'role_ro_'|| currentDB ||'_'|| schema_name ; 	
	select '1' into _schemaCheck from ( select nspname from pg_namespace ) as schemaTable 	where schemaTable.nspname=schema_name;
	select '1' into _userCheck from ( select rolname from pg_roles) as rolTable 	where rolTable.rolname=newRole;
	if _schemaCheck is not null then
		if _userCheck is null then
			EXECUTE 'CREATE ROLE "' || newRole || '";';
			RAISE NOTICE  'Role Create -> OK';
			EXECUTE 'GRANT USAGE ON SCHEMA "'|| schema_name || '" TO "'|| newRole || '";';
			RAISE NOTICE  'Scheme Usage Grant -> OK';
			EXECUTE 'GRANT SELECT ON ALL TABLES IN SCHEMA "'|| schema_name || '" TO "'|| newRole || '";';
			RAISE NOTICE  'Select All Tables Grant -> OK';
			EXECUTE 'ALTER DEFAULT PRIVILEGES IN SCHEMA "'|| schema_name || '" GRANT SELECT ON TABLES TO "'|| newRole || '";';
			RAISE NOTICE  'Default Select All Tables Grant -> OK';
			RAISE NOTICE  'Role NAME :%', newRole;
			return true;			
		else
			RAISE NOTICE  'Role Already Exists';
			EXECUTE 'GRANT USAGE ON SCHEMA "'|| schema_name || '" TO "'|| newRole || '";';
			RAISE NOTICE  'Scheme Usage Grant -> OK';
			EXECUTE 'GRANT SELECT ON ALL TABLES IN SCHEMA "'|| schema_name || '" TO "'|| newRole || '";';
			RAISE NOTICE  'Select All Tables Grant -> OK';
			EXECUTE 'ALTER DEFAULT PRIVILEGES IN SCHEMA "'|| schema_name || '" GRANT SELECT ON TABLES TO "'|| newRole || '";';
			RAISE NOTICE  'Default Select All Tables Grant -> OK';
			RAISE NOTICE  'Role NAME :%', newRole;
			return true;
		end if; 
	else
		RAISE EXCEPTION 'Schema does NOT exists : schemaname ->%', schema_name;
		return false;
	end if;
EXCEPTION 
	WHEN others then 
	RAISE EXCEPTION 'Unexpected Error when function executed !!!';
END;
$$;
-----------------------------------

CREATE or REPLACE FUNCTION admin_schema.sp_create_rw_app_user(schema_name text) RETURNS boolean 
    LANGUAGE plpgsql
    AS $$
DECLARE
  newRole varchar;	
  currentDB varchar;
  _userCheck varchar;
  _schemaCheck varchar;
BEGIN
	SELECT current_database() into currentDB;
	newRole:= 'role_rw_'|| currentDB ||'_'|| schema_name  ;	
	select '1' into _schemaCheck from ( select nspname from pg_namespace ) as schemaTable 	where schemaTable.nspname=schema_name;
	select '1' into _userCheck from ( select rolname from pg_roles) as rolTable 	where rolTable.rolname=newRole;
	if _schemaCheck is not null then
		if _userCheck is null then
			EXECUTE 'CREATE ROLE "' || newRole || '";';
			RAISE NOTICE  'Role Create -> OK';
			EXECUTE 'GRANT USAGE ON SCHEMA "'|| schema_name || '" TO "'|| newRole || '";';
			RAISE NOTICE  'Scheme Usage Grant -> OK';
			EXECUTE 'GRANT SELECT,INSERT,UPDATE,DELETE ON ALL TABLES IN SCHEMA "'|| schema_name || '" TO "'|| newRole || '";';
			RAISE NOTICE  'SELECT,INSERT,UPDATE,DELETE All Tables Grant -> OK';
			EXECUTE 'ALTER DEFAULT PRIVILEGES IN SCHEMA "'|| schema_name || '" GRANT SELECT,INSERT,UPDATE,DELETE ON TABLES TO "'|| newRole || '";';
			RAISE NOTICE  'Default SELECT,INSERT,UPDATE,DELETE All Tables Grant -> OK';		
			EXECUTE 'GRANT SELECT,UPDATE ON ALL SEQUENCES IN SCHEMA "'|| schema_name || '" TO "'|| newRole || '";';
			RAISE NOTICE  'SELECT,UPDATE All Sequences Grant -> OK';
			EXECUTE 'ALTER DEFAULT PRIVILEGES IN SCHEMA "'|| schema_name || '" GRANT SELECT,UPDATE ON SEQUENCES TO "'|| newRole || '";';
			RAISE NOTICE  'Default SELECT,UPDATE All Sequences Grant -> OK';	
			EXECUTE 'GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA "'|| schema_name || '" TO "'|| newRole || '";';
			RAISE NOTICE  'EXECUTE All FUNCTIONS Grant -> OK';
			EXECUTE 'ALTER DEFAULT PRIVILEGES IN SCHEMA "'|| schema_name || '" GRANT EXECUTE ON FUNCTIONS TO "'|| newRole || '";';
			RAISE NOTICE  'Default EXECUTE All FUNCTIONS Grant -> OK';
			RAISE NOTICE  'Role NAME :%', newRole;
			return true;
		else
			RAISE NOTICE  'Role Already Exists';
			EXECUTE 'GRANT USAGE ON SCHEMA "'|| schema_name || '" TO "'|| newRole || '";';
			RAISE NOTICE  'Scheme Usage Grant -> OK';
			EXECUTE 'GRANT SELECT,INSERT,UPDATE,DELETE ON ALL TABLES IN SCHEMA "'|| schema_name || '" TO "'|| newRole || '";';
			RAISE NOTICE  'SELECT,INSERT,UPDATE,DELETE All Tables Grant -> OK';
			EXECUTE 'ALTER DEFAULT PRIVILEGES IN SCHEMA "'|| schema_name || '" GRANT SELECT,INSERT,UPDATE,DELETE ON TABLES TO "'|| newRole || '";';
			RAISE NOTICE  'Default SELECT,INSERT,UPDATE,DELETE All Tables Grant -> OK';
			EXECUTE 'GRANT SELECT,UPDATE ON ALL SEQUENCES IN SCHEMA "'|| schema_name || '" TO "'|| newRole || '";';
			RAISE NOTICE  'SELECT,UPDATE All Sequences Grant -> OK';
			EXECUTE 'ALTER DEFAULT PRIVILEGES IN SCHEMA "'|| schema_name || '" GRANT SELECT,UPDATE ON SEQUENCES TO "'|| newRole || '";';
			RAISE NOTICE  'Default SELECT,UPDATE All Sequences Grant -> OK';
			EXECUTE 'GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA "'|| schema_name || '" TO "'|| newRole || '";';
			RAISE NOTICE  'EXECUTE All FUNCTIONS Grant -> OK';
			EXECUTE 'ALTER DEFAULT PRIVILEGES IN SCHEMA "'|| schema_name || '" GRANT EXECUTE ON FUNCTIONS TO "'|| newRole || '";';
			RAISE NOTICE  'Default EXECUTE All FUNCTIONS Grant -> OK';
			RAISE NOTICE  'Role NAME :%', newRole;
			return true;
		end if; 
	else
		RAISE EXCEPTION 'Schema does NOT exists : schemaname ->%', schema_name;
	end if;
EXCEPTION 
	WHEN others then 
	RAISE EXCEPTION 'Unexpected Error when function executed !!!';
END;
$$;

-----------------------------------

CREATE or REPLACE FUNCTION admin_schema.sp_create_app_user(schema_name text) RETURNS boolean 
    LANGUAGE plpgsql
    AS $$
BEGIN
			EXECUTE 'select admin_schema.sp_create_rw_app_user('''||schema_name||''');';
			RAISE NOTICE  'RW Role Create -> OK';
			EXECUTE 'select admin_schema.sp_create_ro_app_user('''||schema_name||''');';
			RAISE NOTICE  'RO Role Create -> OK';
			return true;
EXCEPTION 
	WHEN others then 
	RAISE EXCEPTION 'Unexpected Error when function executed !!!';
END;
$$;
-----------------------------------



