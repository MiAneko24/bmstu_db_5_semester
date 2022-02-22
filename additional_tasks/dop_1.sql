drop schema if exists dop_1 cascade;
create schema dop_1;
create table dop_1.table1(
	id integer,
	var1 varchar,
	valid_from_dttm date,
	valid_to_dttm date
);

create table dop_1.table2(
	id integer,
	var2 varchar,
	valid_from_dttm date,
	valid_to_dttm date
);

insert into dop_1.table1 
values(1, 'A', '2018-09-01', '2018-09-15');

insert into dop_1.table1 
values(1, 'B', '2018-09-16', '5999-12-31');

insert into dop_1.table1 
values(1, 'A', '2018-09-01', '2018-09-18');

insert into dop_1.table1 
values(1, 'B', '2018-09-19', '5999-12-31');

insert into dop_1.table1 
values(2, 'A', '2018-08-22', '2018-09-01');

insert into dop_1.table1 
values(2, 'B', '2018-09-02', '2018-10-15');

insert into dop_1.table1 
values(2, 'C', '2018-10-16', '2018-10-19');

insert into dop_1.table1 
values(2, 'D', '2018-10-20', '2020-02-20');

insert into dop_1.table2
values(2, 'A', '2018-08-19', '2018-08-25');

insert into dop_1.table2 
values(2, 'B', '2018-08-26', '2018-09-13');

insert into dop_1.table2 
values(2, 'C', '2018-09-14', '2018-11-20');

insert into dop_1.table2 
values(2, 'D', '2018-11-21', '2025-02-20');


--insert into dop_1.table1 
--values(1, 'A', '2018-09-01', '2018-09-15'),
--(1, 'B', '2018-09-16', '5999-12-31'),
--(1, 'A', '2018-09-01', '2018-09-18'),
--(1, 'B', '2018-09-19', '5999-12-31'),
--(2, 'A', '2018-08-22', '2018-09-01'),
--(2, 'B', '2018-09-02', '2018-10-15'),
--(2, 'C', '2018-10-16', '2018-10-19'),
--(2, 'D', '2018-10-20', '2020-02-20'),
--(2, 'A', '2018-08-19', '2018-08-25'),
--(2, 'B', '2018-08-26', '2018-09-13'),
--(2, 'C', '2018-09-14', '2018-11-20'),
--(2, 'D', '2018-11-21', '2025-02-20');


insert into dop_1.table1 
values(10, 'a', '2021-01-01', '2021-01-10');

insert into dop_1.table1 
values(10, 'b', '2021-01-11', '5999-12-31');


insert into dop_1.table2 
values(10, 'a', '2021-01-01', '2021-01-11');

insert into dop_1.table2 
values(10, 'b', '2021-01-12', '5999-12-31');



select T1.id, T1.var1, T2.var2, 
	case 
		when T1.valid_from_dttm >= T2.valid_from_dttm then T1.valid_from_dttm
		else T2.valid_from_dttm
	end as valid_from_dttm,
	case 
		when T1.valid_to_dttm <= T2.valid_to_dttm then T1.valid_to_dttm
		else T2.valid_to_dttm
	end as valid_to_dttm
--into temp table dop_1.table3
from dop_1.table1 as T1 join dop_1.table2 as T2 
on T1.id = T2.id
where T1.valid_from_dttm <= T2.valid_to_dttm and T2.valid_from_dttm <= T1.valid_to_dttm 
