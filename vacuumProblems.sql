select  pg_size_pretty (pg_relation_size('testSchema.myTable'));


SELECT schemaname, relname, n_live_tup, n_dead_tup, last_autovacuum
FROM pg_stat_all_tables
ORDER BY n_dead_tup
    / (n_live_tup
       * current_setting('autovacuum_vacuum_scale_factor')::float8
          + current_setting('autovacuum_vacuum_threshold')::float8)
     DESC
LIMIT 10;

-- idle transaction
SELECT pid, datname, usename, state, backend_xmin
FROM pg_stat_activity
WHERE backend_xmin IS NOT NULL
ORDER BY age(backend_xmin) DESC;

-- replication
SELECT slot_name, slot_type, database, xmin
FROM pg_replication_slots
ORDER BY age(xmin) DESC;


-- two phase commit
SELECT gid, prepared, owner, database, transaction AS xmin
FROM pg_prepared_xacts
ORDER BY age(transaction) DESC;


--- https://www.cybertec-postgresql.com/en/reasons-why-vacuum-wont-remove-dead-rows/?gclid=EAIaIQobChMItaaK47m57wIVQp3VCh25fAubEAAYASAAEgI-svD_BwE