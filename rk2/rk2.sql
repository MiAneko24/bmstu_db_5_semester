drop database RK2;
create database RK2;
 
drop table drivers;
drop table automobile;
drop table fine;
drop table drivers_fines ;
 
create table driver(
    id int primary key,
    licence_number int,
    phone text,
    FIO text,
    a_id int
);
 
create table automobile (
    id int primary key,
    brand text,
    model text,
    prod_date date,
    reg_date date
);
 
create table fine (
    id int primary key,
    violation_type text,
    fine int,
    warning text
);
 
create table drivers_fines(
    d_id int,
    f_id int,
    primary key(d_id, f_id)
);
 
alter table drivers_fines
add constraint fk_d_f foreign key(d_id) references driver(id);
 
alter table drivers_fines
add constraint fk_d_f_fines foreign key(f_id) references fine(id);
 
 
 
alter table driver
add constraint fk_a_d foreign key(a_id) references automobile(id);
 
insert into automobile values
(1, 'BMW', 'X5', '2008-12-10', '2010-12-12'),
(2, 'Porshe', 'Caene', '2019-01-13', '2019-03-22'),
(3, 'Kia', 'Rio', '2015-10-03', '2020-12-09'),
(4, 'Kia', 'Soul', '2017-07-17', '2018-07-09'),
(5, 'Porshe', 'Panamera', '2019-01-01', '2019-01-21'),
(6, 'Schkoda', 'Octavia', '2015-12-12', '2016-11-08'),
(7, 'Kia', 'K5', '2020-07-01', '2021-05-17'),
(8, 'Porshe', 'Caene', '2020-12-20', '2021-12-20'),
(9, 'Volkswagen', 'Polo', '2016-08-12', '2020-11-10'),
(10, 'BMW', 'X5', '2012-12-12', '2021-11-11');
 
 
insert into driver values
(1, 1526, '89236472361', 'Сергеев Сергей Сергеевич',1),
(2, 77123, '87273479231', 'User user useR', 6),
(3, 28374, '89237423862', 'Something very clever', 1),
(4, 8263, '72343679323', 'Акакиев Акакий Акакиевич', 3),
(5, 32645, '62357236512', 'Иванов Иван Иванович', 5),
(6, 7263, '72656824523', 'Ладанов Ладан Ладанович', 7),
(7, 62325, '73465634652', 'Щукин Щука Щукович', 10),
(8, 2346, '74656734522', 'Николаев Николай Николаевич', 5),
(9, 3654, '83847536442', 'Денисов Денис Денисович', 9),
(10, 723, '89273642562', 'Денисова Дария Даниловна', 9);
 
insert into fine values
(1, 'ДТП', 20000, 'Отбираем права'),
(2, 'Обгон', 500, 'Забираем деньги'),
(3, 'Езда в состоянии алкогольного опьянения', 2000, 'Отбираем права'),
(4, 'Проезд на красный', 500, 'Пусть живет'),
(5, 'Парковка в неположенном месте', 5000, 'Забираем на штрафстоянку'),
(6, 'Езда по пешеходной зоне', 1000, 'Просто а-та-та'),
(7, 'Я не знаю', 10000, 'Отбираем машину '),
(8, 'Какие еще', 200000, 'Уезжаем в закат'),
(9, 'Есть нарушения', 5000, 'Пьем сок'),
(10, 'У меня прав нет))', 1000, 'Радуемся жизни');
 
insert into drivers_fines values
(1, 4),
(1, 3),
(5, 7),
(8, 10),
(6, 2),
(7, 2),
(8, 5),
(5, 5),
(2, 1),
(2, 6);
 
-- Задание 2
 
-- 1) select с предикатом сравнения
-- Получить имена, водительские удостоверения, марку, модель, даты производства и регистрации их автомобилей
-- тех водителей, автомобиль которых был зарегистрирован в ГАИ в течение года с момента производства
select FIO, licence_number, brand, model, reg_date, prod_date
from automobile a join driver d on d.a_id = a.id
where reg_date - prod_date < 365;
 
-- 2) Инструкция, использующая оконную функцию
-- Получить количество штрафов, пришедших для каждой машины, и максимальную сумму
select distinct a.id, brand, model, count(f.id) over (partition by a.id), max(f.fine) over (partition by a.id)
from automobile a join driver d on a.id = d.a_id
    join drivers_fines df on df.d_id  = d.id
    join fine f on df.f_id =f.id ;
 
-- 3) Инструкция select, использующая коррелированные подзапросы в качестве производных таблиц в предложении from
-- Вывести информацию и машинах, владельцы которого не получили ни одного штрафа
select distinct a.id, brand, model
from automobile a join (select * from
                        driver d
                        where id not in (select d1.id from
                                            driver d1 join drivers_fines df on d1.id= df.d_id)) cd on cd.a_id=a.id ;
 
                                        
-- Задание 3
 
create or replace function tr1()
returns trigger
as $$
begin
    raise notice 'Tr1';
end;
$$ language plpgsql;
 
create or replace function tr2()
returns trigger
as $$
begin
    raise notice 'Tr2';
end;
$$language plpgsql;
 
create or replace function tr3()
returns trigger
as $$
begin
    raise notice 'Tr3';
end;
$$ language plpgsql;
 
create or replace function tr4()
returns trigger
as $$
begin
    raise notice 'Tr4';
end;
$$language plpgsql;
 
create trigger trig1 before delete on driver
    for each row
    execute procedure tr1();
 
create trigger trig2 after update on fine
    for each row
    execute procedure tr2();
 
create trigger trig3 after insert on automobile
    for each row
    execute procedure tr3();
 
create trigger trig4 before delete on driver
    for each row
    execute procedure tr4();
 
CREATE OR REPLACE FUNCTION snitch() RETURNS event_trigger AS $$
BEGIN
    RAISE NOTICE 'Произошло событие: % %', tg_event, tg_tag;
END;
$$ LANGUAGE plpgsql;
 
CREATE EVENT TRIGGER snitch ON ddl_command_start EXECUTE PROCEDURE snitch();
 
select * from pg_catalog.pg_trigger pt ;
select * from information_schema.triggers t
 
create or replace procedure delete_dml_triggers(inout amount int default 0)
as $$
    declare
        trig_name text;
        tr_table text;
    begin
        for trig_name, tr_table in (select trigger_name, event_object_table
                            from information_schema.triggers)
        loop
            execute 'drop trigger ' || trig_name || ' on ' || tr_table || ';';
            amount = amount + 1;
            raise notice 'trig name %', trig_name;
        end loop;
    end;
$$ language plpgsql;
 
            
 
call delete_dml_triggers();
