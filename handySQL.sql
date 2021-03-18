--- Total schema data size ---
SELECT schemaname, pg_size_pretty(sum(pg_relation_size(quote_ident(schemaname) || '.' || quote_ident(tablename)))::bigint)
FROM pg_tables  group by schemaname;

------------------------------
select tablePriv.grantee::text as rolename, tablePriv.table_name::text as objname, 
tablePriv.privilege_type::text as privname, tablePriv.table_schema::text as schemaname 
			 FROM information_schema.table_privileges tablePriv 
             join pg_roles on (pg_roles.rolname = tablePriv.grantee)
             where tablePriv.grantee = nvl(rname, grantee)
               and  pg_roles.rolcanlogin='f';


--- big Table Sizes---

SELECT  nspname, relname AS "relation",    pg_size_pretty (   pg_total_relation_size (C .oid)    ) AS "total_size"
FROM     pg_class C  LEFT JOIN pg_namespace N ON (N.oid = C .relnamespace)
WHERE    nspname NOT IN ( 'pg_catalog',  'information_schema'    )
AND C .relkind <> 'i' AND nspname !~ '^pg_toast' ORDER BY    pg_total_relation_size (C .oid) DESC LIMIT 100;


-- VACUUM Problems -----

SELECT schemaname, relname, n_live_tup, n_dead_tup, last_autovacuum
FROM pg_stat_all_tables
ORDER BY n_dead_tup
    / (n_live_tup
       * current_setting('autovacuum_vacuum_scale_factor')::float8
          + current_setting('autovacuum_vacuum_threshold')::float8)
     DESC
LIMIT 30;


SELECT pid, datname, usename, state, backend_xmin
FROM pg_stat_activity
WHERE backend_xmin IS NOT NULL
ORDER BY age(backend_xmin) DESC;

SELECT slot_name, slot_type, database, xmin
FROM pg_replication_slots
ORDER BY age(xmin) DESC;

SELECT gid, prepared, owner, database, transaction AS xmin
FROM pg_prepared_xacts
ORDER BY age(transaction) DESC;


--- Lock Queries ---
SELECT blocked_locks.pid     AS blocked_pid,
         blocked_activity.usename  AS blocked_user,
         blocking_locks.pid     AS blocking_pid,
         blocking_activity.usename AS blocking_user,
         blocked_activity.query    AS blocked_statement,
         blocking_activity.query   AS current_statement_in_blocking_process,
         blocked_activity.application_name AS blocked_application,
         blocking_activity.application_name AS blocking_application
   FROM  pg_catalog.pg_locks         blocked_locks
    JOIN pg_catalog.pg_stat_activity blocked_activity  ON blocked_activity.pid = blocked_locks.pid
    JOIN pg_catalog.pg_locks         blocking_locks 
        ON blocking_locks.locktype = blocked_locks.locktype
        AND blocking_locks.DATABASE IS NOT DISTINCT FROM blocked_locks.DATABASE
        AND blocking_locks.relation IS NOT DISTINCT FROM blocked_locks.relation
        AND blocking_locks.page IS NOT DISTINCT FROM blocked_locks.page
        AND blocking_locks.tuple IS NOT DISTINCT FROM blocked_locks.tuple
        AND blocking_locks.virtualxid IS NOT DISTINCT FROM blocked_locks.virtualxid
        AND blocking_locks.transactionid IS NOT DISTINCT FROM blocked_locks.transactionid
        AND blocking_locks.classid IS NOT DISTINCT FROM blocked_locks.classid
        AND blocking_locks.objid IS NOT DISTINCT FROM blocked_locks.objid
        AND blocking_locks.objsubid IS NOT DISTINCT FROM blocked_locks.objsubid
        AND blocking_locks.pid != blocked_locks.pid 
    JOIN pg_catalog.pg_stat_activity blocking_activity ON blocking_activity.pid = blocking_locks.pid
   WHERE NOT blocked_locks.GRANTED and blocking_activity.usename<>'postgres';

--	SELECT pg_cancel_backend(PID);
--  SELECT pg_terminate_backend(PID);
  
--- Dublicate indexes ---

SELECT indrelid::regclass relname, indkey, amname
FROM pg_index i, pg_opclass o, pg_am a
WHERE o.oid = ALL (indclass)
AND a.oid = o.opcmethod
GROUP BY relname, indclass, amname, indkey
HAVING count(*) > 1;


-------- Partition table list --

WITH RECURSIVE partition_info
      (relid,
       relname,
       relsize,
       relispartition,
       relkind) AS (
    SELECT oid AS relid,
           relname,
           pg_relation_size(oid) AS relsize,
           relispartition,
           relkind
    FROM pg_catalog.pg_class
WHERE relname = 'population' AND
      relkind = 'p'
  UNION ALL
    SELECT
         c.oid AS relid,
         c.relname AS relname,
         pg_relation_size(c.oid) AS relsize,
         c.relispartition AS relispartition,
         c.relkind AS relkind
    FROM partition_info AS p,
         pg_catalog.pg_inherits AS i,
         pg_catalog.pg_class AS c
    WHERE p.relid = i.inhparent AND
         c.oid = i.inhrelid AND
         c.relispartition
  ) SELECT * FROM partition_info;


------- VACUMM NEEDS ------------------

WITH rel_set AS
(
    SELECT
        oid,
        CASE split_part(split_part(array_to_string(reloptions, ','), 'autovacuum_vacuum_threshold=', 2), ',', 1)
            WHEN '' THEN NULL
        ELSE split_part(split_part(array_to_string(reloptions, ','), 'autovacuum_vacuum_threshold=', 2), ',', 1)::BIGINT
        END AS rel_av_vac_threshold,
        CASE split_part(split_part(array_to_string(reloptions, ','), 'autovacuum_vacuum_scale_factor=', 2), ',', 1)
            WHEN '' THEN NULL
        ELSE split_part(split_part(array_to_string(reloptions, ','), 'autovacuum_vacuum_scale_factor=', 2), ',', 1)::NUMERIC
        END AS rel_av_vac_scale_factor
    FROM pg_class
) 
SELECT
    PSUT.relname,
    to_char(PSUT.last_vacuum, 'YYYY-MM-DD HH24:MI')     AS last_vacuum,
    to_char(PSUT.last_autovacuum, 'YYYY-MM-DD HH24:MI') AS last_autovacuum,
    to_char(C.reltuples, '9G999G999G999')               AS n_tup,
    to_char(PSUT.n_dead_tup, '9G999G999G999')           AS dead_tup,
    to_char(coalesce(RS.rel_av_vac_threshold, current_setting('autovacuum_vacuum_threshold')::BIGINT) + coalesce(RS.rel_av_vac_scale_factor, current_setting('autovacuum_vacuum_scale_factor')::NUMERIC) * C.reltuples, '9G999G999G999') AS av_threshold,
    CASE
        WHEN (coalesce(RS.rel_av_vac_threshold, current_setting('autovacuum_vacuum_threshold')::BIGINT) + coalesce(RS.rel_av_vac_scale_factor, current_setting('autovacuum_vacuum_scale_factor')::NUMERIC) * C.reltuples) < PSUT.n_dead_tup
        THEN '*'
    ELSE ''
    END AS expect_av
FROM
    pg_stat_user_tables PSUT
    JOIN pg_class C
        ON PSUT.relid = C.oid
    JOIN rel_set RS
        ON PSUT.relid = RS.oid
ORDER BY C.reltuples DESC;


--  tables sizes -----
SELECT   pg_size_pretty (pg_total_relation_size ('test.test'));
SELECT   pg_size_pretty (pg_indexes_size('test.test'));


----- user role list -----------
SELECT r.rolname,   r.rolsuper,   r.rolinherit,  r.rolcreaterole,  r.rolcreatedb,
      r.rolcanlogin,     r.rolconnlimit, r.rolvaliduntil,
  ARRAY(SELECT b.rolname
        FROM pg_catalog.pg_auth_members m
        JOIN pg_catalog.pg_roles b ON (m.roleid = b.oid)
        WHERE m.member = r.oid) as memberof
, r.rolreplication
FROM pg_catalog.pg_roles r
ORDER BY 1;

-------------------------------------

--- PSQL queries which also duplicated from https://github.com/anvk/AwesomePSQLList/blob/master/README.md
--- some of them taken from https://www.slideshare.net/alexeylesovsky/deep-dive-into-postgresql-statistics-54594192

-- I'm not an expert in PSQL. Just a developer who is trying to accumulate useful stat queries which could potentially explain problems in your Postgres DB.

------------
-- Basics --
------------

-- Get indexes of tables
select
    t.relname as table_name,
    i.relname as index_name,
    string_agg(a.attname, ',') as column_name
from
    pg_class t,
    pg_class i,
    pg_index ix,
    pg_attribute a
where
    t.oid = ix.indrelid
    and i.oid = ix.indexrelid
    and a.attrelid = t.oid
    and a.attnum = ANY(ix.indkey)
    and t.relkind = 'r'
    and t.relname not like 'pg_%'
group by  
    t.relname,
    i.relname
order by
    t.relname,
    i.relname;


-----------------------
-- Right this second --
-----------------------

-- Show running queries
SELECT pid, age(query_start, clock_timestamp()), usename, query  FROM pg_stat_activity WHERE query != '<IDLE>' AND query NOT ILIKE '%pg_stat_activity%' ORDER BY query_start desc;

-- Queries which are running for more than 2 minutes
SELECT now() - query_start as "runtime", usename, datname, waiting, state, query FROM pg_stat_activity WHERE now() - query_start > '2 minutes'::interval ORDER BY runtime DESC;

-- Queries which are running for more than 9 seconds
SELECT now() - query_start as "runtime", usename, datname, waiting, state, query FROM pg_stat_activity WHERE now() - query_start > '9 seconds'::interval ORDER BY runtime DESC;

-- Kill running query
SELECT pg_cancel_backend(procpid);

-- Kill idle query
SELECT pg_terminate_backend(procpid);

-- Vacuum Command
VACUUM (VERBOSE, ANALYZE);

--------------------
-- Data Integrity --
--------------------

-- Cache Hit Ratio
select sum(blks_hit)*100/sum(blks_hit+blks_read) as hit_ratio from pg_stat_database;
-- (perfectly )hit_ration should be > 90%

-- Anomalies
select datname, (xact_commit100)/nullif(xact_commit+xact_rollback,0) as c_commit_ratio, (xact_rollback100)/nullif(xact_commit+xact_rollback, 0) as c_rollback_ratio, deadlocks, conflicts, temp_files, pg_size_pretty(temp_bytes) from pg_stat_database;

-- c_commit_ratio should be > 95%
-- c_rollback_ratio should be < 5%
-- deadlocks should be close to 0
-- conflicts should be close to 0
-- temp_files and temp_bytes watch out for them

-- Table Sizes
select relname, pg_size_pretty(pg_total_relation_size(relname::regclass)) as full_size, pg_size_pretty(pg_relation_size(relname::regclass)) as table_size, pg_size_pretty(pg_total_relation_size(relname::regclass) - pg_relation_size(relname::regclass)) as index_size from pg_stat_user_tables order by pg_total_relation_size(relname::regclass) desc limit 10;

-- Another Table Sizes Query
SELECT nspname || '.' || relname AS "relation", pg_size_pretty(pg_total_relation_size(C.oid)) AS "total_size" FROM pg_class C LEFT JOIN pg_namespace N ON (N.oid = C.relnamespace) WHERE nspname NOT IN ('pg_catalog', 'information_schema') AND C.relkind <> 'i' AND nspname !~ '^pg_toast' ORDER BY pg_total_relation_size(C.oid) DESC;

-- Database Sizes
select datname, pg_size_pretty(pg_database_size(datname)) from pg_database order by pg_database_size(datname);

-- Unused Indexes
select * from pg_stat_all_indexes where idx_scan = 0;
-- idx_scan should not be = 0

-- Write Activity(index usage)
select s.relname, pg_size_pretty(pg_relation_size(relid)), coalesce(n_tup_ins,0) + 2 * coalesce(n_tup_upd,0) - coalesce(n_tup_hot_upd,0) + coalesce(n_tup_del,0) AS total_writes, (coalesce(n_tup_hot_upd,0)::float * 100 / (case when n_tup_upd > 0 then n_tup_upd else 1 end)::float)::numeric(10,2) AS hot_rate, (select v[1] FROM regexp_matches(reloptions::text,E'fillfactor=(d+)') as r(v) limit 1) AS fillfactor from pg_stat_all_tables s join pg_class c ON c.oid=relid order by total_writes desc limit 50;
-- hot_rate should be close to 100

-- Does table needs an Index
SELECT relname, seq_scan-idx_scan AS too_much_seq, CASE WHEN seq_scan-idx_scan>0 THEN 'Missing Index?' ELSE 'OK' END, pg_relation_size(relname::regclass) AS rel_size, seq_scan, idx_scan FROM pg_stat_all_tables WHERE schemaname='public' AND pg_relation_size(relname::regclass)>80000 ORDER BY too_much_seq DESC;

-- Index % usage
SELECT relname, 100 * idx_scan / (seq_scan + idx_scan) percent_of_times_index_used, n_live_tup rows_in_table FROM pg_stat_user_tables ORDER BY n_live_tup DESC;

-- How many indexes are in cache
SELECT sum(idx_blks_read) as idx_read, sum(idx_blks_hit) as idx_hit, (sum(idx_blks_hit) - sum(idx_blks_read)) / sum(idx_blks_hit) as ratio FROM pg_statio_user_indexes;

-- Dirty Pages
select buffers_clean, maxwritten_clean, buffers_backend_fsync from pg_stat_bgwriter;
-- maxwritten_clean and buffers_backend_fsyn better be = 0

-- Sequential Scans
select relname, pg_size_pretty(pg_relation_size(relname::regclass)) as size, seq_scan, seq_tup_read, seq_scan / seq_tup_read as seq_tup_avg from pg_stat_user_tables where seq_tup_read > 0 order by 3,4 desc limit 5;
-- seq_tup_avg should be < 1000

-- Checkpoints
select 'bad' as checkpoints from pg_stat_bgwriter where checkpoints_req > checkpoints_timed;

--------------
-- Activity --
--------------

-- Most CPU intensive queries (PGSQL v9.4)
SELECT substring(query, 1, 50) AS short_query, round(total_time::numeric, 2) AS total_time, calls, rows, round(total_time::numeric / calls, 2) AS avg_time, round((100 * total_time / sum(total_time::numeric) OVER ())::numeric, 2) AS percentage_cpu FROM pg_stat_statements ORDER BY total_time DESC LIMIT 20;

-- Most time consuming queries (PGSQL v9.4)
SELECT substring(query, 1, 100) AS short_query, round(total_time::numeric, 2) AS total_time, calls, rows, round(total_time::numeric / calls, 2) AS avg_time, round((100 * total_time / sum(total_time::numeric) OVER ())::numeric, 2) AS percentage_cpu FROM pg_stat_statements ORDER BY avg_time DESC LIMIT 20;

-- Maximum transaction age
select client_addr, usename, datname, clock_timestamp() - xact_start as xact_age, clock_timestamp() - query_start as query_age, query from pg_stat_activity order by xact_start, query_start;
-- Long-running transactions are bad because they prevent Postgres from vacuuming old data. This causes database bloat and, in extreme circumstances, shutdown due to transaction ID (xid) wraparound. Transactions should be kept as short as possible, ideally less than a minute.

-- Bad xacts
select * from pg_stat_activity where state in ('idle in transaction', 'idle in transaction (aborted)');

-- Waiting Clients
select * from pg_stat_activity where waiting;

-- Waiting Connections for a lock
SELECT count(distinct pid) FROM pg_locks WHERE granted = false;

-- Connections
select client_addr, usename, datname, count(*) from pg_stat_activity group by 1,2,3 order by 4 desc;

-- User Connections Ratio
select count(*)*100/(select current_setting('max_connections')::int) from pg_stat_activity;

-- Average Statement Exec Time
select (sum(total_time) / sum(calls))::numeric(6,3) from pg_stat_statements;

-- Most writing (to shared_buffers) queries
select query, shared_blks_dirtied from pg_stat_statements where shared_blks_dirtied > 0 order by 2 desc;

-- Block Read Time
select * from pg_stat_statements where blk_read_time <> 0 order by blk_read_time desc;

---------------
-- Vacuuming --
---------------

-- Last Vacuum and Analyze time
select relname,last_vacuum, last_autovacuum, last_analyze, last_autoanalyze from pg_stat_user_tables;

-- Total number of dead tuples need to be vacuumed per table
select n_dead_tup, schemaname, relname from pg_stat_all_tables;

-- Total number of dead tuples need to be vacuumed in DB
select sum(n_dead_tup) from pg_stat_all_tables;


