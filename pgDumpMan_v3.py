##################### # PostgreSQL pgDump Manager (pgDumpMan.py) ############
#!/usr/bin/python
#-*- coding: utf-8 -*-
## Author			: Mustafa YAVUZ
## E-mail			: msyavuz@gmail.com
## Version			: 3.0
## Date				: 05.02.2021
## OS System 		: Redhat/Centos 6-7, debian/Ubuntu
## pg Version 		: 9.x,10.x,11.x,12.x  
################## LIBRARIES ################################
import os
import commands
from time import *
import socket
from string import *
########################DBLIST####################### - pg_dump
###dbList=[['db_name'],['backup_keep_day'],['include_schemas (comma seperated)'],['backup_format'][extraCommand]]
dbList = []
dbList.append(['test','2','all','custom',''])
########################DBLIST#######################
##################PARAMETERS##########################
autoDiscover=True
defaultKeepDay='3'
defaultBackupFormat='custom'
fullInstanceBackup= False
fullInstanceBackupKeepDay='2'
RoleBackup= True
RoleBackupKeepDay='3'
myLogFile = 'pgDumpMan.log'
mailTO='test@test.com'
sleepTime=30  # 
isStandby=False #True
writeLogFile = True
dbSuperUser = 'postgres'
dbSuperPass = ''
pgPort='5432'
backupDir='/data01/testbackup/'
binDir = '/usr/pgsql-13/bin/'
backupAlias='test-'
totalBackupSucceed = 0
totalBackupFail = 0
totalBackupJob = 0
totalDeletedOldBackup = 0
##################PARAMETERS##########################
def getDBlist():
	cmdStatus=''
	cmdResponse=''
	if (dbSuperPass=='' ):
		cmdStatus, cmdResponse = commands.getstatusoutput(binDir+'psql -p '+pgPort+' -t -c "select datname from pg_database where datname not in (\'postgres\',\'powa\',\'template0\',\'template1\')"')
	else:
		cmdStatus, cmdResponse = commands.getstatusoutput('export PGPASSWORD='+dbSuperPass+' ;'+binDir+'psql -p '+pgPort+' -t -c "select datname from pg_database where datname not in (\'postgres\',\'powa\',\'template0\',\'template1\')" ')
	if(str(cmdStatus)=='0'):
		myDbNameList=cmdResponse.replace(" ","").split("\n")
		for myDbName in myDbNameList:
			isDBExist=False
			if(myDbName!=""):
#				print (myDbName)				
				for existDBname in dbList:
					if(existDBname[0]==myDbName):
						isDBExist=True
				if (isDBExist==False):
					dbList.append([myDbName,defaultKeepDay,'all',defaultBackupFormat,''])
#	print (dbList)
def makeRoleBackup( pgPort, backupDir, backupAlias):
	global totalBackupSucceed, totalBackupFail
	backupFileName=backupAlias+'roles_'+get_datetime()+'.dmp'
	cmdStatus=''
	cmdResponse=''
	if (dbSuperPass=='' ):
		cmdStatus, cmdResponse = commands.getstatusoutput(binDir+'pg_dumpall -r -p '+pgPort+' -f '+backupDir+backupFileName)
	else:
		cmdStatus, cmdResponse = commands.getstatusoutput('export PGPASSWORD='+dbSuperPass+' ;'+binDir+'pg_dumpall -r -p '+pgPort+' -f '+backupDir+backupFileName)
	if(str(cmdStatus)=='0'):
		totalBackupSucceed+=1
		logWrite(myLogFile, False, 'INFO : Instance role backup completed: File Name ->' +backupDir+backupFileName)
		delOldBackupFiles(backupDir,'roles',RoleBackupKeepDay,'')
	else:
		totalBackupFail+=1
		logWrite(myLogFile, True,'ERROR : When Instance role backup proccess. Something went wrong. \nCheck proccess !!!\nFile Name ->' +backupDir+backupFileName)
		return False
def makeFullBackup( pgPort, backupDir, backupAlias):
	global totalBackupSucceed, totalBackupFail
	backupFileName=backupAlias+'full_'+get_datetime()+'.dmp'
	cmdStatus=''
	logWrite(myLogFile, False, 'INFO : Instance full backup is starting: File Name ->' +backupDir+backupFileName)
	backupStartTime=time()
	cmdResponse=''
	if (dbSuperPass=='' ):
		recStatus, recResponse=commands.getstatusoutput(binDir+'psql -p '+pgPort+' -t -c "SELECT pg_is_in_recovery()" ')
		if(recResponse.find("f") == -1):
			os.system(binDir+'psql -p '+pgPort+' -c "SELECT pg_wal_replay_pause() where pg_is_in_recovery()" ')
			cmdStatus, cmdResponse = commands.getstatusoutput(binDir+'pg_dumpall -p '+pgPort+' -f '+backupDir+backupFileName)
			os.system(binDir+'psql -p '+pgPort+' -c "SELECT pg_wal_replay_resume() " ')
		else:
			cmdStatus, cmdResponse = commands.getstatusoutput(binDir+'pg_dumpall -p '+pgPort+' -f '+backupDir+backupFileName)
	else:
		recStatus, recResponse=commands.getstatusoutput('export PGPASSWORD='+dbSuperPass+'; '+binDir+'psql -p '+pgPort+' -t -c "SELECT pg_is_in_recovery()" ')
		if(recResponse.find("f") == -1):
			os.system('export PGPASSWORD='+dbSuperPass+' ;'+binDir+'psql -p '+pgPort+' -c "SELECT pg_wal_replay_pause() where pg_is_in_recovery()" ')
			cmdStatus, cmdResponse = commands.getstatusoutput('export PGPASSWORD='+dbSuperPass+' ;'+binDir+'pg_dumpall -p '+pgPort+' -f '+backupDir+backupFileName)
			os.system('export PGPASSWORD='+dbSuperPass+' ;'+binDir+'psql -p '+pgPort+' -c "SELECT pg_wal_replay_resume() " ')
		else:
			cmdStatus, cmdResponse = commands.getstatusoutput('export PGPASSWORD='+dbSuperPass+' ;'+binDir+'pg_dumpall -p '+pgPort+' -f '+backupDir+backupFileName)
	backupEndTime=time()
	if(str(cmdStatus)=='0'):
		totalBackupSucceed+=1
		mystatutus,dbDize=commands.getstatusoutput("du -sh "+backupDir+backupFileName+" | awk '{print $1}'")
		logWrite(myLogFile, False, 'INFO : Instance full backup completed.\nTime -> '+str(backupEndTime-backupStartTime) +' second\nFile Name -> ' +backupDir+backupFileName+'\nFile Size -> '+str(dbDize))
		delOldBackupFiles(backupDir,'full',fullInstanceBackupKeepDay,'')
	else:
		totalBackupFail+=1
		logWrite(myLogFile, True,'ERROR : When Instance full backup proccess. Something went wrong. \nCheck proccess !!!\nFile Name ->' +backupDir+backupFileName)
		return False
def makeDBBackup( pgPort, backupDir, backupAlias,dbName,keepDay,schemaList,backupFormat,extraCommand):
	if(autoDiscover):
		getDBlist()		
	global totalBackupSucceed, totalBackupFail, totalDeletedOldBackup
	backupFileName=backupAlias+dbName+'_'+backupFormat+'_'+get_datetime()+'.dmp'
	cmdStatus=''
	cmdResponse=''	
	backupParams = ''
	if ( backupFormat == 'custom' ):
		backupParams += '--format=c '
	elif ( backupFormat == 'tar' ) :
		backupParams += '--format=t '
	elif ( backupFormat == 'directory' ) :
		backupParams += '--format=d '
	elif ( backupFormat == 'plain' ) :
		backupParams += '--format=p '
	
	if ( schemaList != 'all' ) :
		for schemaName in schemaList.split(','):
			backupParams += ' --schema='+schemaName+' '
	if ( extraCommand != '' ) :
		backupParams += ' '+extraCommand		
#	print backupParams
	logWrite(myLogFile, False, 'INFO : backup is starting: DB Name ->' +dbName)
	backupStartTime=time()
	if (dbSuperPass=='' ):
                recStatus, recResponse=commands.getstatusoutput(binDir+'psql -p '+pgPort+' -t -c "SELECT pg_is_in_recovery()" ')
                if(recResponse.find("f") == -1):
                        os.system(binDir+'psql -p '+pgPort+' -c "SELECT pg_wal_replay_pause() where pg_is_in_recovery()" ')
                        cmdStatus, cmdResponse = commands.getstatusoutput(binDir+'pg_dump -p '+pgPort+' --dbname='+dbName+' '+backupParams+' -f '+backupDir+backupFileName)
                        os.system(binDir+'psql -p '+pgPort+' -c "SELECT pg_wal_replay_resume() " ')
                else:
                        cmdStatus, cmdResponse = commands.getstatusoutput(binDir+'pg_dump -p '+pgPort+' --dbname='+dbName+' '+backupParams+' -f '+backupDir+backupFileName)
        else:
		recStatus, recResponse=commands.getstatusoutput('export PGPASSWORD='+dbSuperPass+'; '+binDir+'psql -p '+pgPort+' -t -c "SELECT pg_is_in_recovery()" ')
		if(recResponse.find("f") == -1):
			os.system('export PGPASSWORD='+dbSuperPass+' ;'+binDir+'psql -p '+pgPort+' -c "SELECT pg_wal_replay_pause() where pg_is_in_recovery()" ')
			cmdStatus, cmdResponse = commands.getstatusoutput('export PGPASSWORD='+dbSuperPass+' ;'+binDir+'pg_dump -p '+pgPort+' --dbname='+dbName+' '+backupParams+' -f '+backupDir+backupFileName)
			os.system('export PGPASSWORD='+dbSuperPass+' ;'+binDir+'psql -p '+pgPort+' -c "SELECT pg_wal_replay_resume() " ')
		else:
			cmdStatus, cmdResponse = commands.getstatusoutput('export PGPASSWORD='+dbSuperPass+' ;'+binDir+'pg_dump -p '+pgPort+' --dbname='+dbName+' '+backupParams+' -f '+backupDir+backupFileName)
	backupEndTime=time()
	if(str(cmdStatus)=='0'):
		totalBackupSucceed+=1
		mystatutus,dbDize=commands.getstatusoutput("du -sh "+backupDir+backupFileName+" | awk '{print $1}'")
		logWrite(myLogFile, False, 'INFO : DB backup completed.\nTime -> '+str(backupEndTime-backupStartTime) +' second\nFile Name -> ' +backupDir+backupFileName+'\nFile Size -> '+str(dbDize))
		return True
	else:
		totalBackupFail+=1
		logWrite(myLogFile, True,'ERROR : When DB backup proccess. Something went wrong. \nCheck proccess !!!\nFile Name ->' +backupDir+backupFileName)
		return False
def delOldBackupFiles(backupDir, dbName, keepDay, backupFormat):
	global totalDeletedOldBackup
	cmdStatus, delFileNameArrayRaw = commands.getstatusoutput('find '+backupDir+backupAlias+dbName+'_'+backupFormat+'_'+'*.dmp -mtime +'+keepDay)
	if ( cmdStatus == 0 and len(delFileNameArrayRaw) > 1 ):
		delFileNameArray=delFileNameArrayRaw.split("\n")
		for delFileName in  delFileNameArray:
			delResponse=os.system('rm -rf '+delFileName)
			if(str(delResponse)=='0'):
				totalDeletedOldBackup+=1
				logWrite(myLogFile, False, 'INFO : OLD (older than '+keepDay+' days ) DB backup file deleted : File Name ->' +delFileName)
			else:
				logWrite(myLogFile, True, 'ERROR : When DB backup file was deleting. Something went wrong. \nCheck proccess !!!\nFile Name ->' +delFileName)
#######################################################
############## AUXILIARY FUNCTIONS ##########
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
	return my_year+my_mounth+my_day+'_'+my_hour+my_min+my_sec
def fileAppendWrite(file, writeText):
	try :
		fp=open(file,'ab')
		fp.write(writeText+'\n')
		fp.close()
	except :
		print ('!!! An error is occurred while writing file !!!')
def fileRead(file):
	returnTEXT=""
	try :
		fp=open(file,'r')
		returnTEXT=fp.readlines()
		fp.close()
		return returnTEXT
	except :
		print ('!!! An error is occurred while reading file !!!')
		return ""
def fileReadFull(file):
	returnTEXT=""
	try :
		fp=open(file,'r')
		returnTEXT=fp.read()
		fp.close()
		return returnTEXT
	except :
		print ('!!! An error is occurred while reading file !!!')
		return ""
def fileClearWrite(file, writeText):
	try :
		fp=open(file,'w')
		fp.write(writeText+'\n')
		fp.close()
	except :
		print ('!!! An error is occurred while writing file !!!')
def logWrite(logFile, sendMail ,logText):
	logText=ctime()+' :'+logText
	if(writeLogFile):
		fileAppendWrite(logFile,logText)
		print ( logText )
		if ( sendMail ):
			os.system('echo "'+logText+'" | mailx -s "pgDumpMan ('+str(os.uname()[1])+')" '+mailTO+' ')
	else:
		print ( logText )
################ Main Function ############
def main():
	global totalBackupSucceed, totalBackupFail, totalBackupJob, totalDeletedOldBackup
#	getDBlist()
	if( RoleBackup ):
		makeRoleBackup(pgPort, backupDir, backupAlias)
		totalBackupJob+=1
	if ( fullInstanceBackup ) :
		makeFullBackup( pgPort, backupDir, backupAlias)
		totalBackupJob+=1
	for myDB in dbList:
		sleep(sleepTime)
		totalBackupJob+=1
		backupResult=makeDBBackup( pgPort, backupDir, backupAlias,myDB[0],myDB[1],myDB[2],myDB[3],myDB[4])
		if ( backupResult ):
			delOldBackupFiles(backupDir,myDB[0],myDB[1],myDB[3])
	logWrite(myLogFile, True, ' BACKUP SUMMARY \nTotal Backup Proccess    : '+str (totalBackupJob) + '\nTotal Succeed Backup     : '+str (totalBackupSucceed) + '\nTotal Failed Backup      : '+str (totalBackupFail) + '\nTotal Deleted Old Backup : '+str (totalDeletedOldBackup)  )
main()
