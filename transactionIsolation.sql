create table test1 (a int, b int); 
insert into  test1 select *,* from generate_series(1,10);
select * from test1 ;

testdb=# begin ;										testdb=# begin;
BEGIN													BEGIN
testdb=# update test1 set b=100 where a=1;				testdb=# select * from test1 ;



process A: BEGIN TRANSACTION ISOLATION LEVEL REPEATABLE READ;
process A: SELECT sum(value) FROM purchases;
process A: INSERT INTO purchases (value) VALUES (100);
process B: BEGIN TRANSACTION ISOLATION LEVEL REPEATABLE READ;
process B: SELECT sum(value) FROM purchases;
process B: INSERT INTO purchases (id, value);
process B: COMMIT;
process A: COMMIT;
With Repeatable Reads everything works, but if we run the same thing with a Serializable isolation mode, process A will error out.

process A: BEGIN TRANSACTION ISOLATION LEVEL SERIALIZABLE;
process A: SELECT sum(value) FROM purchases;
process A: INSERT INTO purchases (value) VALUES (100);
process B: BEGIN TRANSACTION ISOLATION LEVEL SERIALIZABLE;
process B: SELECT sum(value) FROM purchases;
process B: INSERT INTO purchases (id, value);
process B: COMMIT;
process A: COMMIT;
ERROR: could not serialize access due to read/write
dependencies among transactions
DETAIL: Reason code: Canceled on identification as
a pivot, during commit attempt.
HINT: The transaction might succeed if retried.




select ctid,tableoid,xmin,xmax,cmin,cmax,* from test1 ;

