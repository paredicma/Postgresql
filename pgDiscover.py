#-*- coding: utf-8 -*-
## Author				: Mustafa YAVUZ 	## E-mail				: msyavuz@gmail.com
## Version  			: 0.1				## Date					: 07.04.20120
## OS System 			: Redhat/Centos 7	## DB Systems 			: Postgresql,EDB
## System Requirement	: python
import os
import commands
##################PARAMETERS##################
OUTPUT_FILE="/tmp/pg.list"
HOST_NAME=os.uname()[1]
##################PARAMETERS##################
def lastCharChecker(dName):#### AUX FUNCTION ########
	if(dName[len(dName)-1]=='/'):
		return dName
	else:
		return dName+'/'
def pgDiscover(): ##### GENERAL FUNCTIONS #####
	getStatus,getResponse = commands.getstatusoutput('ps -ef | grep -e "postgres " -e "postmaster " | grep " -D " | grep  -v "edb-post" | grep -v "grep " | awk \'{print $10}\'')
	if ( len(getResponse) > 1):
		pgDirList=getResponse.split('\n')
		for pgDir in pgDirList:
			pgDir=pgDir.rstrip()
			getStatus,getVersion = commands.getstatusoutput('more '+lastCharChecker(pgDir)+'PG_VERSION')
			os.system('echo "'+HOST_NAME+' Postgresql '+getVersion.rstrip()+'" >> '+OUTPUT_FILE)
def edbDiscover():
	getStatus,getResponse = commands.getstatusoutput('ps -ef | grep -e "edb-postgres -D" -e "edb-postmaster -D" | grep -e " -D " | grep -v "grep " | awk \'{print $10}\'')
	if ( len(getResponse) > 1):
		pgDirList=getResponse.split('\n')
		for pgDir in pgDirList:
			pgDir=pgDir.rstrip()
			getStatus,getVersion = commands.getstatusoutput('more '+lastCharChecker(pgDir)+'PG_VERSION')
			os.system('echo "'+HOST_NAME+' EDB-Postgres '+getVersion.rstrip()+'" >> '+OUTPUT_FILE)
def Discover(): ##### MAIN FUNCTION #####
	if ( os.path.exists ( OUTPUT_FILE ) ):
		os.remove ( OUTPUT_FILE )
	pgDiscover()
	edbDiscover()
def main():
	Discover()
main()
