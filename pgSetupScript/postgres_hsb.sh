/usr/pgsql-11/bin/pg_basebackup -h 10.20.30.40 -D /data01/data -U rep_user -p 5432 -v -P --wal-method=stream

sed -i "s/wal_level = replica/#wal_level = replica/g"  $PGDATA/postgresql.conf
sed -i "s/archive_mode =/#archive_mode =/g"  $PGDATA/postgresql.conf
sed -i "s/archive_mode =/#archive_command =/g"  $PGDATA/postgresql.conf
sed -i "s/max_wal_senders =/#max_wal_senders =/g"  $PGDATA/postgresql.conf
sed -i "s/wal_keep_segments =/#wal_keep_segments =/g"  $PGDATA/postgresql.conf
sed -i "s/max_replication_slots =/#max_replication_slots =/g"  $PGDATA/postgresql.conf

echo "restore_command = 'cp /data01/ARCH/%f %p'" >> $PGDATA/recovery.conf
echo "archive_cleanup_command = '/usr/pgsql-11/bin/pg_archivecleanup /data01/ARCH/%r'" >> $PGDATA/recovery.conf
echo "standby_mode = on" >> $PGDATA/recovery.conf
echo "primary_conninfo = 'host=10.20.30.40  port=5432 user=rep_user' # password=rep_userpass'" >> $PGDATA/recovery.conf
echo "trigger_file = '/data01/data/failover.uygula'" >> $PGDATA/recovery.conf

/usr/pgsql-11/bin/pg_ctl start -D /data01/data/