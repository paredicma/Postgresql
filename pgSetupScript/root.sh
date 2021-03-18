yum install -y postgresql11-libs-11.6*
yum install -y postgresql11-11.6*     
yum install -y postgresql11-server-11.6*
yum install -y postgresql11-contrib-11.6* 
yum install -y pg_catcheck11-1*      
yum install -y pg_qualstats11-1.0.9*      		
yum install -y pg_stat_kcache11-2*
yum install -y postgresql11-plpython-11.6-2*
yum install -y postgresql11-turkcellPasswordChecker*
yum install -y timescaledb_11-1.5*

mkdir -p /data01/data;mkdir -p /data01/ARCH ;mkdir -p /data01/backup; chown postgres. -R /data01
sed -i 's/\/var\/lib\/pgsql\/11\/data/\/data01\/data/g' /usr/lib/systemd/system/postgresql-11.service
systemctl daemon-reload ; systemctl enable postgresql-11.service

echo "export PGDATA=/data01/data" >> /var/lib/pgsql/.bash_profile
echo "export PGHOST=localhost" >> /var/lib/pgsql/.bash_profile
echo "export PGPORT=5432" >> /var/lib/pgsql/.bash_profile
echo "export PGUSER=postgres" >> /var/lib/pgsql/.bash_profile
echo "export PATH=$PATH:/usr/pgsql-11/bin/" >> /var/lib/pgsql/.bash_profile