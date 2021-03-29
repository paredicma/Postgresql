 Partition Example;
 
 create table test (id serial, name varchar(32), mdate timestamp) PARTITION BY RANGE (date_trunc('month', mdate ));
 
create table test_2020_05 (id serial, name varchar(32), mdate timestamp);  

create table test_2019_02 (id serial, name varchar(32), mdate timestamp);   

create table test_2019_03 (id serial, name varchar(32), mdate timestamp); 

create schema test

create table test.test_2019_04 (id serial, name varchar(32), mdate timestamp); 

create table test.test_2019_05 (id serial, name varchar(32), mdate timestamp); 

create table test.test_2019_06 (id serial, name varchar(32), mdate timestamp); 

alter table test attach partition test.test_2019_04 FOR VALUES FROM ('01-APR-19 00:00:00') TO ('01-MAY-19 00:00:00');

alter table test attach partition test.test_2019_05 FOR VALUES FROM ('01-MAY-19 00:00:00') TO ('01-JUN-19 00:00:00'); 

alter table test attach partition test.test_2019_06 FOR VALUES FROM ('01-JUN-19 00:00:00') TO ('01-JUL-19 00:00:00');     

alter table test attach partition test_2019_02 FOR VALUES FROM ('01-FEB-19 00:00:00') TO ('01-MAR-19 00:00:00');            

alter table test attach partition test_2019_03 FOR VALUES FROM ('01-MAR-19 00:00:00') TO ('01-APR-19 00:00:00');       

alter table test attach partition test_2020_05 FOR VALUES FROM ('01-MAY-20 00:00:00') TO ('01-JUN-20 00:00:00');  