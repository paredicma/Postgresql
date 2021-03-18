##################### # PostgreSQL pgStatLoader (pgStatLoader.py) ############
#!/usr/bin/python
#-*- coding: utf-8 -*-
## Author			: Mustafa YAVUZ, Fatih Mencutekin
## E-mail			: mustafa.yavuz@turkcell.com.tr
## Version			: 0.1
## Date				: 12.03.2021
## OS System 		: Redhat/Centos 7,8, debian/Ubuntu
## pg Version 		: 10.x,11.x,12.x,13.x  
## Python Libs      : psycopg2
################## LIBRARIES ################################
import os
from time import *
from string import *
import psycopg2
import socket
##################PARAMETERS##########################
myHostName=socket.gethostname()
sleepTime=1  # 
mainDB='postgres'
dbSuperUser = 'postgres'
myQuery='select 1'
reportServer='reportServerName'
reportDB='reportDBName'
reportUser='reportUserName'
reportPwd='UserPWD'
reportPort='5432'
#########################################
isPrimary=False # Do NOT change
deadTupleQuery="SELECT pg_stat_all_tables.schemaname,  pg_stat_all_tables.relname,  pg_stat_all_tables.n_live_tup,    pg_stat_all_tables.n_dead_tup, to_char(pg_stat_all_tables.last_autovacuum, 'YYYY-MM-DD HH24:MI:SS') AS last_autovacuum  FROM pg_stat_all_tables where pg_stat_all_tables.n_dead_tup>10000   ORDER BY (pg_stat_all_tables.n_dead_tup::double precision / (pg_stat_all_tables.n_live_tup::double precision * current_setting('autovacuum_vacuum_scale_factor'::text)::double precision + current_setting('autovacuum_vacuum_threshold'::text)::double precision)) DESC  LIMIT 30"
cacheHitQuery="select datname, round(sum(blks_hit)*100/sum(blks_hit+blks_read),2) as hit_ratio from pg_stat_database where datname not in ('postgres','powa','template0','template1') group by datname"
tableSizeQuery="SELECT  nspname as schema_name, relname AS table_name,     pg_total_relation_size (C .oid)  AS table_size  FROM     pg_class C  LEFT JOIN pg_namespace N ON (N.oid = C .relnamespace) WHERE    nspname NOT IN ( 'pg_catalog',  'information_schema'    ) and pg_total_relation_size (C .oid)>100000000 AND C .relkind <> 'i' AND nspname !~ '^pg_toast' ORDER BY    pg_total_relation_size (C .oid) DESC LIMIT 30"
mydbSizeListQuery="SELECT pg_database.datname as database_name, pg_database_size(pg_database.datname) AS size_in_bytes FROM pg_database where datname not in ('postgres','powa','template0','template1') group by datname"
#################PARAMETERS##########################
def mainDBQuery(myQuery):
	conn = psycopg2.connect(database=mainDB,user=dbSuperUser)
	cursor = conn.cursor()
	cursor.execute(myQuery)
	myResult=cursor.fetchall()
	conn.close()
	return myResult
#	for datname in dbname:
#		print(datname)
def reportDBQuery(myQuery):
	conn = psycopg2.connect(host=reportServer,database=reportDB,port=reportPort,user=reportUser,password=reportPwd)
	cursor = conn.cursor()
	cursor.execute(myQuery)
	conn.commit()
	conn.close()
def reportDBQueryReturn(myQuery):
        conn = psycopg2.connect(host=reportServer,database=reportDB,port=reportPort,user=reportUser,password=reportPwd)
        cursor = conn.cursor()
        cursor.execute(myQuery)
        myResult=cursor.fetchall()
        conn.close()
        return myResult
def targetDBQuery(myDB,myQuery):
	conn = psycopg2.connect(database=myDB,user=dbSuperUser)
	cursor = conn.cursor()
	cursor.execute(myQuery)
	myResult=cursor.fetchall()
	conn.close()
	return myResult	
def getDBPrimaryStatus():
	myResp = mainDBQuery("select pg_is_in_recovery()")
	if (str(myResp[0]).find("f")):
		return True
	else:
		return 	False	
def getDBlist():
	cmdResponseArray = mainDBQuery("select datname from pg_database where datname not in ('postgres','powa','template0','template1')")
	return 	cmdResponseArray
def getDeadTupleInfo():
	for myDBName in getDBlist():
		reportDBQuery("delete from grafana.deadtuplestat where host='"+myHostName+"' and database='"+myDBName[0]+"'" )
		tupleInsertSQL=''
		for myDeadTupleRow in targetDBQuery(myDBName[0],deadTupleQuery):
			if(str(myDeadTupleRow[4])=='None'):
				tupleInsertSQL+="insert into  grafana.deadtuplestat ( host, database, schemaname, tablename,live_tuple,dead_tuple ) values ('"+myHostName+"','"+myDBName[0]+"','"+myDeadTupleRow[0]+"','"+myDeadTupleRow[1]+"',"+str(myDeadTupleRow[2])+","+str(myDeadTupleRow[3])+"); "
			else:
				tupleInsertSQL+="insert into  grafana.deadtuplestat ( host, database, schemaname, tablename,live_tuple,dead_tuple,last_autovacuum ) values ('"+myHostName+"','"+myDBName[0]+"','"+myDeadTupleRow[0]+"','"+myDeadTupleRow[1]+"',"+str(myDeadTupleRow[2])+","+str(myDeadTupleRow[3])+", '"+str(myDeadTupleRow[4])+"'::timestamp); "
#		print (tupleInsertSQL)
		if (tupleInsertSQL!=''):
			reportDBQuery(tupleInsertSQL)
#		print (tupleInsertSQL)
		sleep(0.1)

##select datname, round(sum(blks_hit)*100/sum(blks_hit+blks_read),2) as hit_ratio from pg_stat_database group by datname;		
def getCacheHitRatio():
	reportDBQuery("delete from grafana.cache_hit_ratio where host='"+myHostName+"' ;" )
	tupleInsertSQL=''
	for myCacheHitRow in mainDBQuery(cacheHitQuery):
		if(str(myCacheHitRow[1])=='None'):
			tupleInsertSQL+="insert into  grafana.cache_hit_ratio ( host, database ) values ('"+myHostName+"','"+myCacheHitRow[0]+"'); "
		else:
			tupleInsertSQL+="insert into  grafana.cache_hit_ratio ( host, database, percentage ) values ('"+myHostName+"','"+myCacheHitRow[0]+"','"+str(myCacheHitRow[1])+"'::float ); "
	if (tupleInsertSQL!=''):
		reportDBQuery(tupleInsertSQL)		
def getBigTables():
	for myDBName in getDBlist():
		reportDBQuery("delete from grafana.table_size where host='"+myHostName+"' and database='"+myDBName[0]+"'" )
		tupleInsertSQL=''
		for mytables in targetDBQuery(myDBName[0],tableSizeQuery):
				tupleInsertSQL+="insert into  grafana.table_size ( host, database, schema_name, table_name,table_size ) values ('"+myHostName+"','"+myDBName[0]+"','"+mytables[0]+"','"+mytables[1]+"','"+str(mytables[2])+"'); "
		if (tupleInsertSQL!=''):
			reportDBQuery(tupleInsertSQL)
#		print (tupleInsertSQL)
		sleep(0.1)			
def getVersion():
        reportDBQuery("DELETE FROM grafana.server_version where host='"+myHostName+"' ;" )
        tupleInsertSQL=''
        myVersion = mainDBQuery("SHOW server_version")
        myVersionResult = ''.join(myVersion[0])
        tupleInsertSQL+="insert into grafana.server_version (host,version) values ('"+myHostName+"','"+myVersionResult+"'); "
        if (tupleInsertSQL!=''):
                reportDBQuery(tupleInsertSQL)
def getdbSize():
	tupleInsertSQL=''
	sizeRecordControl = reportDBQueryReturn("select count(*) as rowCount  from grafana.db_size_history WHERE host = '"+myHostName+"' AND record_date > now() - interval '1 hour' ")
	sizeRecordControlValue = sizeRecordControl[0][0]
	mydbSizeList = mainDBQuery(mydbSizeListQuery)
	for mydbSize in mydbSizeList:
#		mydbSizeValue = mydbSize[0]
		tupleInsertSQL+="insert into grafana.db_size_history(host,database,size,record_date) values ( '"+myHostName+"','"+mydbSize[0]+"' ,'"+str(mydbSize[1])+"','now()'); " 
	if (tupleInsertSQL!='' and sizeRecordControlValue < 1):
		reportDBQuery(tupleInsertSQL)
################ Main Function ############
def main():
	isPrimary=getDBPrimaryStatus()
	if(isPrimary):
        getDeadTupleInfo()
		getCacheHitRatio()
		getBigTables()
		getVersion()
		getdbSize()
main()
