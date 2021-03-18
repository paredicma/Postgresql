#-*- coding: utf-8 -*-
## Author		   		: Mustafa YAVUZ
## E-mail		   		: msyavuz@gmail.com
## Version		  		: 1.1.0
## Date		 			: 19.03.20120
## OS System			: Redhat/Centos 7,8
## OS User		  		: postgres -> must be superuser
## DB Systems	   		: Postgresql
## System Requirement   : python 2.6 or 2.7
import os
import sys
import commands
from time import *
import socket
##################PARAMETERS##################
CONFIG_HOST='10.20.30.40'
CONFIG_PORT='5432'
CONFIG_DB='configdb'
CONFIG_USER='postgres'
CONFIG_PWD='MyPass_01'
##################TARGET CLUSTER##################
CLUSTER_NAME='testdb'
LOG_FILE="hbaManager.log"
SILENT_MODE=False
PG_LOCAL_SERVER_DIR='/pgdata/data/'
PG_REMOTE_SERVER_LIST=[['10.20.30.41','/pgdata/data/'],['10.20.30.42','/pgdata/data/']]
DB_NAME='postgres'
DB_USER='postgres'  ## superuser
DB_PASSWORD='targetDBPass_11'
DB_PORT='5432'
BIN_DIR='/usr/pgsql-13/bin/'
############################## GENERAL FUNCTION ###########################
def get_datetime():
	my_year=str(localtime()[0])
	my_mounth=str(localtime()[1])
	my_day=str(localtime()[2])
	my_hour=str(localtime()[3])
	my_min=str(localtime()[4])
	my_sec=str(localtime()[5])
	if(len(str(my_mounth))==1):
		my_mounth="0"+my_mounth
	if(len(my_day)==1):
		my_day="0"+my_day
	if(len(my_hour)==1):
		my_hour="0"+my_hour
	if(len(my_min)==1):
		my_min="0"+my_min
	if(len(my_sec)==1):
		my_sec="0"+my_sec
	return my_year+"."+my_mounth+"."+my_day+" "+my_hour+":"+my_min+":"+my_sec
def fileAppendWrite(file, writeText):
	try :
		fp=open(file,'ab')
		fp.write('\n'+writeText)
		fp.close()
		return True
	except :
		print ('!!! An error is occurred while writing file !!!')
		return False
def logWrite(logFile,logText):
	if(SILENT_MODE):
		logText=get_datetime()+' ::: '+logText
		fileAppendWrite(logFile,logText)
	else:
		print (logText)
		logText=get_datetime()+' ::: '+logText
		fileAppendWrite(logFile,logText)
def validIP(IPaddr):
	try:
		socket.inet_aton(IPaddr)
		return True
	except socket.error:
		return False
############################## AUX FUNCTIONS ##################
def set_rules(CONFIG_HOST,CONFIG_PORT,CONFIG_DB,CONFIG_USER,CONFIG_PWD):
	getStatus,getResponse = commands.getstatusoutput("export PGPASSWORD="+CONFIG_PWD+" ; "+ BIN_DIR+"psql -t -h "+CONFIG_HOST+" -d "+CONFIG_DB+" -U "+CONFIG_USER+" -p "+CONFIG_PORT+" -c \"select rule_id, rule_type,db_name,user_name,ip_address,method,comment from hba.hba_automater  where cluster_name='"+CLUSTER_NAME+"' and status='PROGRESS' ;\" ")
#	getStatus,getResponse = commands.getstatusoutput("export PGPASSWORD="+CONFIG_PWD+" ; "+ BIN_DIR+"psql -t -h "+CONFIG_HOST+" -d "+CONFIG_DB+" -U "+CONFIG_USER+" -p "+CONFIG_PORT+" -c 'select rule_id, rule_type,db_name,user_name,ip_address,comment from hba.hba_automater where cluster_name='''"+CLUSTER_NAME+"''' and status='''PROGRESS''';'")
	print "status : "+ str (getStatus)
	print "response : "+ str (getResponse)
	if ( getStatus==0 and getResponse.find('host')>-1 ):
		for ruleRow in (getResponse).split("\n"):
			print (ruleRow)	
			ruleRow=ruleRow.replace(" ","")
			if (len(ruleRow)>10):
				myRow=ruleRow.split("|")
				if(hba_manage(myRow[1],myRow[2],myRow[3],myRow[4],myRow[5],myRow[6])):
					get2Status,get2Response = commands.getstatusoutput("export PGPASSWORD="+CONFIG_PWD+" ; "+ BIN_DIR+"psql -h "+CONFIG_HOST+" -d "+CONFIG_DB+" -U "+CONFIG_USER+" -p "+CONFIG_PORT+" -c \"update hba.hba_automater set status='DONE'  where rule_id="+str(myRow[0])+" ;\" ")
					print get2Response
#			for myField in myRow:
#				print(myField)
#			print ("--------------")
		return True
	else:
		return False
def reload_conf(hostIP):
	getStatus,getResponse = commands.getstatusoutput("export PGPASSWORD="+DB_PASSWORD+" ; "+ BIN_DIR+"psql -t -h "+hostIP+" -d "+DB_NAME+" -U "+DB_USER+" -p "+DB_PORT+" -c 'select pg_reload_conf()'")
#	   print "status : "+ str (getStatus)
#	   print "status : "+ str (getResponse)
	if ( getStatus==0 and getResponse.find('t')>-1 ):
		return True
	else:
		return False
def copy_hba(remoteIP,remoteConfDir): ## OK -> return 0 , Not OK -> return 256
	copy_state=os.system('scp -p -q -o "StrictHostKeyChecking no" '+PG_LOCAL_SERVER_DIR+'pg_hba.conf  postgres@'+remoteIP+':'+remoteConfDir+'pg_hba.conf')
	if ( copy_state==0 ):
		return True
	else:
		return False
def edit_hba(hostType,targetDB,userName,clientIP,connType,ruleComment):
		myResult=fileAppendWrite(PG_LOCAL_SERVER_DIR+'pg_hba.conf', hostType+'	'+targetDB+'		'+userName+'		'+clientIP+'/32 '+connType+'			## '+ruleComment+' ->> this record added by hbaManager. Date :'+get_datetime())
		return myResult
#returnVAl=raw_input('\n--------------\n')
############################## AUX FUNCTIONS ##################

##############################  DECISION PROCESS ##########################
def hba_manage(hostType,targetDB,userName,clientIP,connType,ruleComment): ##
	if( hostType =='host' or hostType =='hostssl' or hostType =='hostnossl' ):
		if( targetDB !=''):
			if( userName !=''):
				if( validIP(str(clientIP))):
					if( connType=='md5' or connType=='scram-sha-256' ):
						edit_hba(hostType,targetDB,userName,clientIP,connType,ruleComment)
						if ( reload_conf("localhost") ):
							logWrite(LOG_FILE,"pg_hba.conf reload succesed on localhost")
						else:
							logWrite(LOG_FILE,"ERROR !!!! while pg_hba.conf reload process on localhost")
						for RemoteHost in PG_REMOTE_SERVER_LIST:
							myResult=copy_hba(RemoteHost[0],RemoteHost[1])
							if ( myResult ):
								logWrite(LOG_FILE,"pg_hba.conf was copied to -> "+RemoteHost[0]+":"+RemoteHost[1])
								return True
								if ( reload_conf(RemoteHost[0]) ):
									logWrite(LOG_FILE,"pg_hba.conf reload succesed on ->"+RemoteHost[0])
								else:
									logWrite(LOG_FILE,"ERROR !!!! while pg_hba.conf reload process on ->"+RemoteHost[0])
							else:
								logWrite(LOG_FILE,"ERROR !!! when pg_hba.conf copy to -> "+RemoteHost[0]+":"+RemoteHost[1])
								return False
					else:
						logWrite(LOG_FILE,"!!! NOT valid Auth. Type entered\n Auth Meth. must be ->(md5/scram-sha-256) :"+connType)
						return False	
				else:
						logWrite(LOG_FILE,"!!! NOT valid IP entered :"+clientIP)
						return False
			else:
				logWrite(LOG_FILE,"User Name parameter canNOT  be null !!!")
				return False
		else:
			logWrite(LOG_FILE,"DB Name canNOT be null !!!")
			return False
	else:
		logWrite(LOG_FILE,"Host type must be host/hostssl/hostnossl !!!")
		return False		
def main():
#	try:
	set_rules(CONFIG_HOST,CONFIG_PORT,CONFIG_DB,CONFIG_USER,CONFIG_PWD)
##		hba_manage(sys.argv[1],sys.argv[2],sys.argv[3],sys.argv[4])
#	except:
#		logWrite(LOG_FILE,"!!! Wrong input : must be that format:\n 'python hbaManager.py [DBName] [userName] [clientIP] [authType(md5/scram-sha-256/trust)]'")
main()