##################### # PostgreSQL pgAgent Control   ############
#!/usr/bin/python
#-*- coding: utf-8 -*-
## Author			: Mustafa YAVUZ
## E-mail			: msyavuz@gmail.com
## Version			: 0.1
## Date				: 05.10.2020
## OS System 		: Redhat/Centos 6-7, debian/Ubuntu
## pg Version 		: 9.x,10.x,11.x,12.x  
################## LIBRARIES ################################
import os
import commands
from time import *
from string import *
import sys
##################PARAMETERS##########################
myLogFile = 'pgagentControl.log'
mailTO = 'msyavuz@gmail.com'
writeLogFile = True
##################PARAMETERS##########################
def serviceStatus( ):
	cmdStatus=os.system ('systemctl status pgagent_12.service' )
	if ( cmdStatus != 0 ):
		logWrite(myLogFile, True, 'INFO : pgagent service is OK , Result:\n' )
	else:
		logWrite(myLogFile, True, 'ERROR :  pgagent service is NOT OK  , Result:\n')
		cmdStatus=os.system ('systemctl start pgagent_12.service' )
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
		serviceStatus()
	except:
		logWrite(myLogFile,True,"!!! Some thing wrong : python pgagentControl.py  ")
main()