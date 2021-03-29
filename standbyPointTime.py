##################### # PostgreSQL Standby PITR   (standbyPointTime.py)  ############
#!/usr/bin/python
#-*- coding: utf-8 -*-
## Author			: Mustafa YAVUZ
## E-mail			: msyavuz@gmail.com
## Version			: 0.1
## Date				: 14.07.2020
## OS System 		: Redhat/Centos 6-7, debian/Ubuntu
## pg Version 		: 9.x,10.x,11.x,12.x  
################## LIBRARIES ################################
import os
import commands
from time import *
from string import *
import sys
##################PARAMETERS##########################
myLogFile = 'pointTime.log'
mailTO = 'msyavuz@gmail.com'
writeLogFile = True
dataDir='/pgdata_fb/data/'
recoveryConfigFile='recovery.conf'
binDir = '/usr/pgsql-11/bin/'
##################PARAMETERS##########################
def restartInstance( binDir, dataDir ):
	cmdStatus=os.system (binDir+'pg_ctl restart -D ' + dataDir )
	if ( cmdStatus == 0 ):
		logWrite(myLogFile, True, 'INFO : Instance restart is OK , Result:\n' )
	else:
		logWrite(myLogFile, True, 'ERROR : Instance restart is NOT OK , Result:\n')		
def sedFileContent( dataDir, recoveryConfigFile ):
		os.system ('sed -i s/recovery_min_apply_delay/#recovery_min_apply_delay/g ' + dataDir + recoveryConfigFile )
		os.system ('sed -i s/recovery_target_timeline/#recovery_target_timeline/g ' + dataDir + recoveryConfigFile)

def setPointTime(pitrType,timeString):
###recovery_min_apply_delay = '1440min'
###recovery_min_apply_delay = '8h'
###recovery_target_timeline = '2016-01-22 23:05:10'
	if ( pitrType=='relativeTime' ):
		sedFileContent( dataDir, recoveryConfigFile )
		fileAppendWrite(dataDir + recoveryConfigFile, "recovery_min_apply_delay = '"+str(timeString)+"'")
		logWrite(myLogFile, True, 'INFO : Recovery Config File was changed.\nFile name -->'+dataDir + recoveryConfigFile+' \nContent --> "recovery_min_apply_delay = ' +str(timeString)+'"')
		return True
	elif (  pitrType=='exactTime' ) :
		sedFileContent( dataDir, recoveryConfigFile )
		fileAppendWrite(dataDir + recoveryConfigFile, "recovery_target_timeline = '"+str(timeString)+"'")
		logWrite(myLogFile, True, 'INFO : Recovery Config File was changed.\nFile name -->'+dataDir + recoveryConfigFile+' \nContent --> "recovery_target_timeline = ' +str(timeString)+'"')
		return True
	else:
		logWrite(LOG_FILE,"!!! Wrong input : pitr Type must be relativeTime or exactTime ")
############## AUXILIARY FUNCTIONS ##########
def fileAppendWrite(file, writeText):
	try :
		fp=open(file,'ab')
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
			os.system('echo "'+logText+'" | mailx -s "standbySetPointTime ('+str(os.uname()[1])+')" '+mailTO+' ')
	else:
		print ( logText )
################ Main Function ############
def main():
	try:
		myResult=setPointTime(sys.argv[1], sys.argv[2])
		if (myResult):
			restartInstance( binDir, dataDir )
	except:
		logWrite(myLogFile,True,"!!! Wrong input : must be that format:\n python standbyPointTime.py [pitrType(relativeTime/exactTime)] [time('24h'/'30min'/''2020-06-22 23:05:10'')] ")
main()
