##################### # PostgreSQL Backup Smart Backuper (pgSmartConfig.py) ############
#!/usr/bin/python
#-*- coding: utf-8 -*-
## Author			: Mustafa YAVUZ
## E-mail			: mustafa.yavuz@turkcell.com.tr
## Version			: 0.2
## Date				: 07.10.2020
## OS System 		: Redhat/Centos 6-7, debian/Ubuntu
## pg Version 		: 9.2+  
################## LIBRARIES ################################
import os
import commands
from time import *
from string import *
##################PARAMETERS##########################
myLogFile = 'backup.log'
writeLogFile = True
dbName="testdb"
dbSuperUser = 'postgres'
dbSuperPass	= ''
usePasswordLessCon=True
pgPort='5432'
backupDir='/backup/copy_data/'
keepDay = '2'
maxParalelZipping = 5
totalDeletedOldFiles = 0
## select date_part('day', now()); 
#backupKeepDay='5'
includeSchemaList="'partition_1','partition_2','partition_3'"
includeTableAliasList = []
binDirectory="/usr/pgsql-12/bin/"
##################PARAMETERS##########################
def pgRunQuery(myQuery):
	getResponse=""
	if (usePasswordLessCon):
		getStatus,getResponse = commands.getstatusoutput(binDirectory+"psql -t  -d "+dbName+" -U "+dbSuperUser+" -p "+pgPort+" -c \""+myQuery+"\"")
	else :
		getStatus,getResponse = commands.getstatusoutput("export PGPASSWORD="+dbSuperPass+" ;"+binDirectory+"psql -t  -d "+dbName+" -U "+dbSuperUser+" -p "+pgPort+" -c \""+myQuery+"\"")
	return getResponse.strip()
def smartCopyMakerDaily():
	current_year=localtime()[0]
	current_mounth=localtime()[1]
	current_day=localtime()[2]
	dayCounter=1
	while ( dayCounter < current_day ):
		includeTableAliasList.append("_"+str(current_year)+"_"+str(current_mounth)+"_"+str(dayCounter))
		dayCounter+=1
	while ( current_day < 31 ):
		if ( current_mounth == 1 ) :
			includeTableAliasList.append("_"+str(current_year-1)+"_12_"+str(current_day))
			current_day+=1
		else :
			includeTableAliasList.append("_"+str(current_year)+"_"+str(current_mounth-1)+"_"+str(current_day))
			current_day+=1
	
#	backupFileName=backupAlias+get_datetime()+'.dmp'
	searchQuery="select schemaname,tablename  from pg_tables where schemaname  in ("+includeSchemaList+") and ("
	for includeTableAlias in includeTableAliasList:
		if ( includeTableAlias==includeTableAliasList[len(includeTableAliasList)-1] ):
			searchQuery+=" tablename like '%"+includeTableAlias+"')"
		else:
			searchQuery+=" tablename like '%"+includeTableAlias+"' or "
	includeTableList=pgRunQuery(searchQuery).split("\n")
	includeTableCopyTable=""
	includeTableCopyFile=""
	for includeTable in includeTableList:
		includeArray=includeTable.split("|")
		includeTableCopyTable="\""+includeArray[0].strip()+"\".\""+includeArray[1].strip()+"\""
		includeTableCopyFile=backupDir+get_datetime()+"-"+includeArray[0].strip()+"_"+includeArray[1].strip()+".data"
		copyCommand="COPY "+includeTableCopyTable+" TO '"+includeTableCopyFile+"'"
		print (copyCommand)	
		pgRunQuery(copyCommand)	
		zipCStatus,zipCount = commands.getstatusoutput("ps -ef | grep gzip | grep -v 'grep' | wc -l")
		print "current zipping :"+str(zipCount)
		while ( int (zipCount) > maxParalelZipping ) :		
			print "Max parallel zipping limit has been reached -> "+str(zipCount) + " Waiting  30 minutes  ... "
			sleep(30)
			zipCStatus,zipCount = commands.getstatusoutput("ps -ef | grep gzip | grep -v 'grep' | wc -l")		
		gzipBackupFile(includeTableCopyFile)
#	print (backupCommand)

def delOldFiles():
        global totalDeletedOldFiles
        cmdStatus, delFileNameArrayRaw = commands.getstatusoutput('find '+backupDir+'*.data.gz -mtime +'+keepDay)
        if ( cmdStatus == 0  and len(delFileNameArrayRaw) > 1):
                delFileNameArray=delFileNameArrayRaw.split("\n")
                for delFileName in  delFileNameArray:
                        delResponse=os.system('rm -rf '+delFileName)
                        if(str(delResponse)=='0'):
                                totalDeletedOldFiles+=1
                                logWrite(myLogFile, False, 'INFO : OLD (older than '+keepDay+' days ) DB backup file deleted : File Name ->' +delFileName)
                        else:
                                logWrite(myLogFile, True, 'ERROR : When DB backup file was deleting. Something went wrong. \nCheck proccess !!!\nFile Name ->' +delFileName)
##################PARAMETERS##########################
def gzipBackupFile(copyFile):
	cmdStatus = os.system('nohup gzip '+copyFile+' &')
#	if(str(cmdStatus)=='0'):
#		logWrite(myLogFile, False, 'INFO : DB Copy file was zipped: File Name ->' +copyFile+'.gz')
#		return True
#	else:
#		logWrite(myLogFile, True,'ERROR : When DB Copy file was zipping. Something went wrong. \nCheck proccess !!!\nFile Name ->' +copyFile)
#		return False		
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
def logWrite(logFile, sendMail ,logText):
	if(writeLogFile):
		print (logText)
		logText='* ('+get_datetime()+') '+logText
		fileAppendWrite(logFile,logText)
		if ( sendMail ):
			print ('mail sended')
	else:
		print (logText)
################ Main Function ############
def main():
	smartCopyMakerDaily()
	delOldFiles()
main()