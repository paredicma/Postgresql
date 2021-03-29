-- FOREIGN DATA WRAPPER
-- https://wiki.postgresql.org/wiki/Foreign_data_wrappers


-- schema fdw

CREATE SERVER fdw_test FOREIGN DATA WRAPPER postgres_fdw OPTIONS (host '10.10.10.1', dbname 'testdb', port '5432', fetch_size '10000');
 
CREATE USER MAPPING FOR postgres  SERVER fdw_test   OPTIONS (user 'utest', password 'MyPass1_'); 

CREATE SCHEMA _testschema;
 
IMPORT FOREIGN SCHEMA testschema FROM SERVER fdw_test INTO _testschema;


--- Table fdw

--source db
create table employee (id int, first_name varchar(20), last_name varchar(20));
insert into employee values (1,'jobin','augustine'),(2,'avinash','vallarapu'),(3,'fernando','camargos');

-- target db
CREATE SERVER fdw_test FOREIGN DATA WRAPPER postgres_fdw OPTIONS (host '10.10.10.1', dbname 'testdb', port '5432', fetch_size '10000');
 
CREATE USER MAPPING FOR postgres  SERVER fdw_test   OPTIONS (user 'utest', password 'MyPass1_'); 

CREATE FOREIGN TABLE test1
(id int, first_name character varying(20), last_name character varying(20))
SERVER fdw_test OPTIONS (schema_name 'public', table_name 'test1');


