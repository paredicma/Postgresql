Sunucu Adi:	NOKTAFCI01
Hesap Adi:	PG_SOX_RAPOR 
Sifre:	xxxxxxxx

create user sox_admin encrypted password 'Pass_971'  superuser;
create database sox_rapor owner to sox_admin;

/c sox_rapor

create extension tds_fdw;

CREATE SERVER onent_db FOREIGN DATA WRAPPER tds_fdw  OPTIONS (servername '10.218.207.144', port '62595');

CREATE USER MAPPING FOR sox_admin SERVER onent_db OPTIONS (username 'PG_SOX_RAPOR', password 'xxxxxxxx');



CREATE FOREIGN TABLE t_prod_serverlist (        
CINAME varchar(128) NULL ,
IP varchar(255) NULL ,
VALUE varchar(255) NULL  )
SERVER onent_db
OPTIONS ( match_column_names 'CINAME', query 'SELECT 
BSM.ITEM_NAME as CINAME,
CR.SUB_CI_NAME AS IP,
CIA.VALUE
FROM ONENT.NEMS_CMDB.BSM_CI (NOLOCK) BSM
INNER JOIN ONENT.NEMS_CMDB.CI (NOLOCK) CI
ON CI.NO=BSM.ITEM_ID AND CI.IS_DELETED=0
INNER JOIN ONENT.NEMS_CMDB.CI_RELATION_INFO (NOLOCK) CR
ON CR.CI_NO=CI.NO AND SUB_SERVICE_NAME=''IP''
INNER JOIN ONENT.NEMS_CMDB.CI_ATTRIBUTE (NOLOCK) CIA
ON CI.ID=CIA.CI_ID AND CI.IS_DELETED=0 AND CIA.VALUE=''PRODUCTION'' ');

create materialized view mv_prod_serverlist as select CINAME,IP,VALUE  from t_prod_serverlist;
refresh materialized view mv_prod_serverlist ;  


CREATE FOREIGN TABLE t_serverlist (        
CINAME varchar(128) NULL ,
IP varchar(255) NULL ,
VALUE varchar(255) NULL  )
SERVER onent_db
OPTIONS ( match_column_names 'CINAME', query 'SELECT 
BSM.ITEM_NAME as CINAME,
CR.SUB_CI_NAME AS IP,
CIA.VALUE
FROM ONENT.NEMS_CMDB.BSM_CI (NOLOCK) BSM
INNER JOIN ONENT.NEMS_CMDB.CI (NOLOCK) CI
ON CI.NO=BSM.ITEM_ID AND CI.IS_DELETED=0
INNER JOIN ONENT.NEMS_CMDB.CI_RELATION_INFO (NOLOCK) CR
ON CR.CI_NO=CI.NO AND SUB_SERVICE_NAME=''IP''
INNER JOIN ONENT.NEMS_CMDB.CI_ATTRIBUTE (NOLOCK) CIA
ON CI.ID=CIA.CI_ID AND CI.IS_DELETED=0');


