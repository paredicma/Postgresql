#-*- coding: utf-8 -*-
#!/usr/bin/python
import os
import commands
from time import *
from string import *
##################PARAMETERS##########################
ARCH_DIR = '/pgdata/WAL_ARCHIVE/'
BIN_DIR = '/usr/pgsql-12/bin/'
KEEP_MINUTES='1440'
DB_PORT='5432'
DB_NAME='postgres'
DB_USER='postgres'  ## superuser.
PASSWORDLESS_CONN=True
DB_PASSWORD=''
def delArchive():
	cmdStatus=''
	isMaster=''
	if(PASSWORDLESS_CONN):
		cmdStatus, isMaster = commands.getstatusoutput(BIN_DIR+"psql -t -d "+DB_NAME+" -U "+DB_USER+" -p "+DB_PORT+" -c  'select pg_is_in_recovery()'")
	else:
		cmdStatus, isMaster = commands.getstatusoutput("export PGPASSWORD="+DB_PASSWORD+" ; "+ BIN_DIR+"psql -t  -d "+DB_NAME+" -U "+DB_USER+" -p "+DB_PORT+" -c 'select pg_is_in_recovery()'")
	if (isMaster[:3].find('f') >-1):
		print (' I am master')
		os.system("find "+ARCH_DIR+"* -mmin +"+KEEP_MINUTES+" -exec rm {} \;")
def main():
	delArchive()
main()
