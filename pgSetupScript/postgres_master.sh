source .bash_profile

/usr/pgsql-11/bin/initdb -D /data01/data/


sed -i "s/#listen_addresses = 'localhost'/listen_addresses = '*'/g"  $PGDATA/postgresql.conf
sed -i "s/max_connections = 100/max_connections = 500/g"  $PGDATA/postgresql.conf
sed -i "s/shared_buffers = 128MB/shared_buffers = 8GB/g"  $PGDATA/postgresql.conf
sed -i "s/#work_mem = 4MB/work_mem = 16MB/g"  $PGDATA/postgresql.conf
sed -i "s/#maintenance_work_mem = 64MB/maintenance_work_mem = 2GB/g"  $PGDATA/postgresql.conf
sed -i "s/#effective_cache_size = 4GB/effective_cache_size = 20GB/g"  $PGDATA/postgresql.conf
sed -i "s/#log_connections = off/log_connections = on/g"  $PGDATA/postgresql.conf
sed -i "s/#log_disconnections = off/log_disconnections = on/g"  $PGDATA/postgresql.conf
sed -i "s/#log_hostname = off/log_hostname = on/g"  $PGDATA/postgresql.conf
sed -i "s/log_line_prefix = '%m [%p] '/log_line_prefix = '%m [%p] %h %d %u %i '/g"  $PGDATA/postgresql.conf
sed -i "s/#shared_preload_libraries = ''/shared_preload_libraries = 'tcellpasswordcheck, pg_qualstats, pg_buffercache, pg_stat_statements, timescaledb'/g"  $PGDATA/postgresql.conf


sed -i "s/#wal_level = replica/wal_level = replica/g"  $PGDATA/postgresql.conf
sed -i "s/#archive_mode = off/archive_mode = on/g"  $PGDATA/postgresql.conf
sed -i "s/#archive_command = ''/archive_command = 'rsync -a %p postgres@10.20.30.40:/data01/ARCH/%f'/g"  $PGDATA/postgresql.conf
sed -i "s/#max_wal_senders = 10/max_wal_senders = 10/g"  $PGDATA/postgresql.conf
sed -i "s/#wal_keep_segments = 0/wal_keep_segments = 500/g"  $PGDATA/postgresql.conf
sed -i "s/#max_replication_slots = 10/max_replication_slots = 10/g"  $PGDATA/postgresql.conf

###Master

/usr/pgsql-11/bin/pg_ctl start -D /data01/data/
/usr/pgsql-11/bin/createuser rep_user -c 10 -replication

echo "host    replication     rep_user        10.20.30.40/32       trust" >> $PGDATA/pg_hba.conf
echo "host    replication     rep_user        10.20.30.41/32       trust" >> $PGDATA/pg_hba.conf

