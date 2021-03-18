##################### # PostgreSQL Replication Control  ############
#!/usr/bin/python
#-*- coding: utf-8 -*-
## Author			: Mustafa YAVUZ
## E-mail			: msyavuz@gmail.com
## Version			: 0.1
## Date				: 21.01.2020
## OS System 		: Redhat/Centos 6-7, debian/Ubuntu
## pg Version 		: 9.x,10.x,11.x,12.x  
################## LIBRARIES ################################
import os
import commands
from time import *
import socket
from string import *
##################PARAMETERS##########################
myLogFile = 'pgReplication.log'
writeLogFile = True
dbSuperUser = 'postgres'
dbSuperPass = ''
pgPort='5432'
binDir='/usr/pgsql-12/bin/'
mailTO = 'test@test.com'
ClusterName='testCluster'
##################PARAMETERS##########################
def standbyTime():
	cmdStatus, isMaster = commands.getstatusoutput(binDir+"psql -t -c  'select pg_is_in_recovery()'")
	if (isMaster.find('f') >-1):
		print (' I am master')
		qStatus, qResult = commands.getstatusoutput(binDir+"psql -c 'select client_hostname as standby_name, EXTRACT(EPOCH FROM replay_lag) as time_diff_sn, now() as current_time,   now()-replay_lag as standby_time from pg_stat_replication'")
		if(str(qStatus)=='0'):
			logWrite(myLogFile, True, 'INFO : Standby Gap Report ( '+ClusterName+' )\n---------------------------------\n'+qResult)
#		else:
#			logWrite(myLogFile, True, 'ERROR : When DB backup file was deleting. Something went wrong. \nCheck proccess !!!\nFile Name ->' +delFileName)
def fileAppendWrite(file, writeText):
	try :
		fp=open(file,'ab')
		fp.write(writeText+'\n')
		fp.close()
	except :
		print ('!!! An error is occurred while writing file !!!')
def logWrite(logFile, sendMail ,logText):
	if(writeLogFile):
		print (logText)
		fileAppendWrite(logFile,logText)
		if ( sendMail ):
			 os.system('echo "'+logText+'" | mailx -s "PG Replica Control ('+str(os.uname()[1])+')" '+mailTO+' ')
	else:
		print (logText)
################ Main Function ############
def main():
	standbyTime()
main()
