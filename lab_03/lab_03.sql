-- скалярная функция
-- получить средний возраст ученых и отклонение возраста каждого ученого от этого значения

create or replace function labresearches.getDiffScientistsAge(certain_age int) returns real as '
		select avg(age) - certain_age as difference from labresearches.scientists
' language sql;

create or replace function labresearches.getAvgScientistsAge() returns real as '
		select avg(age) from labresearches.scientists
' language sql;

select s_surname, s_name, s_second_name, age, labresearches.getAvgScientistsAge() as average, labresearches.getDiffScientistsAge(age) as difference
from labresearches.scientists s;

-- подставляемая табличная функция
-- получить идентификатор и кличку сазанов, у владельцев которых есть только питомцы такого же вида
drop function labresearches.getSazans();
create or replace function labresearches.getSazans() 
returns table (
	a_id int,
	a_name varchar
)
as $$
begin
	return query select A.a_id, A.a_name
	from labresearches.animals as A
	where not exists(select s_name, s_surname, s_second_name from labresearches.animals
					where A.s_name = labresearches.animals.s_name
						and A.s_surname = labresearches.animals.s_surname
						and A.s_second_name = labresearches.animals.s_second_name
						and A.species != labresearches.animals.species)
					and A.species='Сазан';
end;
$$ language plpgsql;

select *
from labresearches.getSazans();


-- многооператорная функция
-- получить информацию об исследованиях в указанных лабораториях, 
-- которые проводили ученые указанной ученой степени и животные, 
-- принимавшие участие в которых, умерли
create or replace function labresearches.degree_researches_dead_aimals(lab_names_query text, s_degree text)
returns table (
	s_surname surname_domain,
	s_name name_domain,
	s_second_name name_domain, 
	degree text,
	a_id int,
	a_name name_domain,
	r_name text,
	lab_name text
) as $$
	declare 
		l_name text;
	begin
		create temp table info_tab(
			s_surname surname_domain,
			s_name name_domain,
			s_second_name name_domain, 
			degree text,
			a_id int,
			a_name name_domain,
			r_name text,
			lab_name text);
		for l_name in execute lab_names_query loop
			insert into info_tab(s_surname, s_name, s_second_name, degree, a_id, a_name, r_name, lab_name)
			select s.s_surname, s.s_name, s.s_second_name, s.degree, a.a_id, a.a_name, r.r_name, s.lab_name
			from (labresearches.scientists as s join labresearches.researches as r 
				on s.s_surname = r.s_surname and s.s_name =r.s_name and s.s_second_name = r.s_second_name) join labresearches.animals as a 
				on r.a_id = a.a_id 
			where a.health_state ='Умер' and s."degree" = s_degree and s.lab_name =l_name;
		end loop;
		return query 
		select * from info_tab;
	end;
$$ language plpgsql;

select * from labresearches.degree_researches_dead_aimals(
	'select lab_name 
	from labresearches.laboratories l
	where not l.sponsored_by_gov and l.establish_year between 2000 and 2005;', 'Бакалавр');

-- рекурсивная функция / функция с рекурсивным ОТВ
-- Поулчить пары предполагаемых родителей и детей животных по поколениям исследования
create or replace function labresearches.get_parentship_animals(generation int)
returns table(
	parent_id int,
	parent_name varchar,
	parent_generation int,
	kid_id int,
	kid_name varchar,
	kid_generation int,
	species name_domain,
	lab_name varchar
) as $$
	begin
	if (generation <= 0) then 
		raise notice 'Parent generation % is incorrect, must be in interval [1; 9]', generation;
	else
		return query 
		select a1.a_id as parent_id, a1.a_name as parent_name, a1.research_generation as parent_gen, a2.a_id as kid_id, a2.a_name as kid_name, a2.research_generation as kid_gen, a1.species, a1.lab_name 
		from labresearches.animals a1 join labresearches.animals a2 on a1.research_generation = a2.research_generation - 1 and a1.species = a2.species and a1.lab_name = a2.lab_name 
		where a1.research_generation = generation and a1.age > a2.age;
	
		if (generation < 9) then 
			return query
				select * from labresearches.get_parentship_animals(generation + 1);
		end if;
	end if;
	end;
$$ language plpgsql;

select * from labresearches.get_parentship_animals(2);


	
--with recursive parentship(parent_id, parent_name, kid_id, kid_name, species, parent_gen) as (
--	select a1.a_id as parent_id, a1.a_name as parent_name, a2.a_id as kid_id, a2.a_name as kid_name, a1.species, 1 as parent_gen
--	from labresearches.animals a1 join labresearches.animals a2 on a1.research_generation = a2.research_generation - 1 and a1.species = a2.species 
--	where a1.research_generation = 1 and a1.age > a2.age and a1.lab_name = a2.lab_name 
--	
--	union 
--	
--	select a1.a_id as parent_id, a1.a_name as parent_name, a2.a_id as kid_id, a2.a_name as kid_name, a2.species, parent_gen + 1 
--	from labresearches.animals a1 join labresearches.animals a2 on a1.research_generation = a2.research_generation - 1 and a1.species = a2.species 
--		join parentship as p on a1.research_generation = p.parent_gen + 1 
--	where a1.age > a2.age and a1.lab_name = a2.lab_name 
--	
--)
--select * from parentship;

-- хранимая процедура без параметров
-- обновить статус наличия питомца тех ученых, у которых не нашлось питомцев, сохранить ФИО таких ученых во временной таблице
create or replace procedure labresearches.correct_owners_list()
as $$
begin 
	drop table if exists owners_without_pets;

	create temp table owners_without_pets(
		s_surname surname_domain,
		s_name name_domain,
		s_second_name name_domain
	);

	insert into owners_without_pets
	select s_surname, s_name, s_second_name
	from labresearches.scientists s 
	where s.has_pets and not exists (select * 
								from labresearches.animals a
								where s.s_surname = a.s_surname and s.s_name  = a.s_name and s.s_second_name = a.s_second_name);
	

	update labresearches.scientists as s
	set has_pets = false 
	where s.has_pets and not exists (select * 
								from labresearches.animals a
								where s.s_surname = a.s_surname and s.s_name  = a.s_name and s.s_second_name = a.s_second_name);
end;
$$ language plpgsql;

select * 
from labresearches.scientists s 
where s.has_pets and not exists (select * 
								from labresearches.animals a
								where s.s_surname = a.s_surname and s.s_name  = a.s_name and s.s_second_name = a.s_second_name);

							
							
call labresearches.correct_owners_list();

select * from owners_without_pets


update labresearches.scientists 
set has_pets = true  
where (s_surname, s_name, s_second_name) in (select * from owners_without_pets);

-- рекурсивная процедура
-- генерируем возможные цепочки родственных связей, начиная с конкретного поколения,
-- и сохраняем во временную таблицу

create or replace procedure labresearches._get_animals_parentship_chain(start_gen int)
as $$
begin 
	if (start_gen <= 9)
	then
		insert into relations
		select a1.a_id as parent_id, a1.a_name as parent_name, a1.research_generation as parent_gen, a2.a_id as kid_id, a2.a_name as kid_name, a2.research_generation as kid_gen, a1.species, a1.lab_name 
				from labresearches.animals a1 join labresearches.animals a2 on a1.research_generation = a2.research_generation - 1 and a1.species = a2.species and a1.lab_name = a2.lab_name 
				where a1.research_generation = start_gen and a1.age > a2.age and (a1.a_id in (select kid_id
																							from relations) or not exists(select kid_id
																							from relations));
				call labresearches._get_animals_parentship_chain(start_gen + 1);
	end if;										
end;
$$ language plpgsql;

create or replace procedure labresearches.get_animals_parentship_chain(start_gen int)
as $$
	begin
		if (start_gen <= 0) then 
			raise notice 'Parent generation % is incorrect, must be in interval [1; 9]', start_gen;
		else
			drop table if exists relations;
			create temp table relations(
				parent_id int,
				parent_name varchar,
				parent_generation int,
				kid_id int,
				kid_name varchar,
				kid_generation int,
				species name_domain,
				lab_name varchar
			);
			call labresearches._get_animals_parentship_chain(start_gen);
		end if;
	end;
$$ language plpgsql;


call labresearches.get_animals_parentship_chain(2);
select * from relations;

-- хранимая процедура с курсором
-- вывести список ученых по имеющимся инициалам
create or replace procedure labresearches.get_scientists_by_abbreviature(part_surname text, part_name text, part_sec_name text) 
as $$
	declare 
		cur_row record;
		cur cursor for
		select *
		from labresearches.scientists
		where s_surname like part_surname || '%' and s_name like part_name || '%' and s_second_name like part_sec_name || '%';
	begin
		for scientist in cur loop
			raise notice '% % %, age: %, degree: %', scientist.s_surname, scientist.s_name, scientist.s_second_name, scientist.age, scientist.degree;
		end loop;
	end;
		
$$ language plpgsql;

call labresearches.get_scientists_by_abbreviature('Гер', 'М', 'А');

-- хранимая процедура доступа к метаданным
-- вывести таблицы и их размеры из схемы, название которой содержит последовательность
-- и размер которых находится в заданном в кБ диапазоне

create or replace procedure labresearches.show_tables_from_schema_size_between(schema_mask text, start_size int, end_size int)
as $$
	declare 
		s_name text;
		t_name text;
		t_size int;
	begin
		start_size := start_size * 1024;
		end_size := end_size * 1024;
		for s_name, t_name in 
			select schemaname, tablename 
			from pg_catalog.pg_tables
			where schemaname like '%' || schema_mask || '%' and 
		(select pg_relation_size(schemaname || '.' || tablename))
		between start_size and end_size
		loop 
			select pg_relation_size(s_name || '.' || t_name) into t_size;
			raise notice 'Schema: %, table: %, size: % kB', s_name, t_name, t_size / 1024;
		end loop;
	end;
$$ language plpgsql;
	
call labresearches.show_tables_from_schema_size_between('lab', 10, 5000);
	

-- триггер AFTER
-- проверка поля "есть питомец" у хозяина после добавления нового животного и после удаления существующего
create or replace function labresearches.update_has_pets()
returns trigger 
as $$
begin 
	if not (select has_pets
			from labresearches.scientists
			where new.s_surname = s_surname and new.s_name = s_name and new.s_second_name = s_second_name)
			then update labresearches.scientists 
				set has_pets = true 
				where new.s_surname = s_surname and new.s_name = s_name and new.s_second_name = s_second_name;
	end if;
	return new;
end;
$$ language plpgsql;

create or replace function labresearches.update_tables_after_animal_delete()
returns trigger 
as $$
begin 
	if (select has_pets
			from labresearches.scientists
			where old.s_surname = s_surname and old.s_name = s_name and old.s_second_name = s_second_name
			and (s_name, s_surname, s_second_name) not in (select s_surname, s_name, s_second_name
													from labresearches.animals
													group by s_surname, s_name, s_second_name))
			then update labresearches.scientists 
				set has_pets = false 
				where old.s_surname = s_surname and old.s_name = s_name and old.s_second_name = s_second_name;
	end if;
	delete from labresearches.researches
	where a_id = old.a_id;
	return old;
end;
$$ language plpgsql;

drop trigger if exists check_owner on labresearches.animals;
drop trigger if exists check_animal_delete on labresearches.animals;


create trigger check_owner
after insert on labresearches.animals 
for row execute procedure labresearches.update_has_pets();

create trigger check_animal_delete
after delete on labresearches.animals 
for row execute procedure labresearches.update_tables_after_animal_delete();

select * from labresearches.scientists s 
where not has_pets ;

select * 
from labresearches.animals a 
where s_surname = 'Алексеев' and s_name = 'Герман' and s_second_name = 'Матвеевич';

select * 
from labresearches.scientists s 
where s_surname = 'Алексеев' and s_name = 'Герман' and s_second_name = 'Матвеевич';


insert into labresearches.animals values(22212, 'Кличка', 'Лаборатория им. Пантелеймонов', 'Сом', '1', 'Мужской', 'Здоров', 1, 'Алексеев', 'Герман', 'Матвеевич');

delete from labresearches.animals 
where a_id = 22212;
--
--update labresearches.scientists 
--set has_pets = true 
--where not has_pets and (s_surname, s_name, s_second_name) in (select s_surname, s_name, s_second_name 
--																from labresearches.animals a
--																group by s_surname, s_name, s_second_name);
--

-- триггер INSTEAD OF
-- Проверка, что добавляемое исследование проводится в той же лаборатории, где находятся ученый и животное
drop view if exists labresearches.researchesView;

create view labresearches.researchesView as
select * from labresearches.researches;

create or replace function labresearches.insert_research_check()
returns trigger 
as $$
begin 
	if (not exists(select * 
					from labresearches.researchesView as r
					where new.s_surname = s_surname and new.s_name = s_name and new.s_second_name = s_second_name and 
					new.a_id = a_id and new.r_name = r_name))
	then 
		if (new.lab_name = (select lab_name
							from labresearches.scientists
							where new.s_surname = s_surname and new.s_name = s_name and 
							new.s_second_name = s_second_name) and new.lab_name = (
							select lab_name
							from labresearches.animals
							where new.a_id = a_id and health_state != 'Умер') and new.start_year > 
							(select establish_year
							from labresearches.laboratories
							where new.lab_name = lab_name))
		then 
			insert into labresearches.researches 
			values(new.s_surname, new.s_name, new.s_second_name, new.a_id, new.lab_name, new.science_field, new.r_name, new.start_year);
			raise notice 'Record is added successfully!';
			return new;
		else
			raise notice 'Scientists can start researches only inside of their laboratories on alive animals' 
			' in the same laboratory after the laboratory was established';
		end if;
	else
		raise notice 'This research already exists.';
	end if;
	return null;
end;
$$ language plpgsql;

drop trigger if exists labresearch.add_research;

create trigger add_research
instead of insert on labresearches.researchesView
for row execute function labresearches.insert_research_check();


select * from labresearches.researchesView limit 1;

insert into labresearches.researchesView
select * from labresearches.researchesView limit 1;

insert into labresearches.researchesView
select s.s_surname, s.s_name, s.s_second_name, a.a_id, s.lab_name, 'Гео', 'Умное название', 2000
from labresearches.scientists s join labresearches.animals a on s.lab_name != a.lab_name
limit 1;

select * from labresearches.scientists s where lab_name = 'Лаборатория при университете Алеппо'

insert into labresearches.researchesView
select s.s_surname, s.s_name, s.s_second_name, a.a_id, s.lab_name, 'Гео', 'Умное название', 2020
from labresearches.scientists s join labresearches.animals a on s.lab_name = a.lab_name
where a.health_state != 'Умер' and s.s_surname = 'Саввина'and s.s_name= 'Альбина'and s.s_second_name= 'Михаиловна' and a.a_id = 73615;


select s_surname, s_name, s_second_name, a_id, lab_name, 'Гео', 'Умное название', 2020
from labresearches.researches r 
where s_surname = 'Саввина' and s_name= 'Альбина' and s_second_name= 'Михаиловна' and a_id = 34718
limit 1;

select * from labresearches.researchesView
where r_name = 'Умное название';

--delete from labresearches.researches 
--where s_surname = 'Саввина'and s_name= 'Альбина'and s_second_name= 'Михаиловна' and a_id = 73615;

select * from labresearches.researches
where r_name = 'Умное название';



delete from labresearches.researches 
where r_name ='Умное название';

-- процедура по имени животного изменить состояние здоровья на другое

create or replace procedure labresearches.change_health_state(animal_name text)
as $$
begin
	drop table if exists old_states;
	create temp table old_states(
		a_name name_domain, 
		a_id int,
		health_state text
	);
	
	insert into old_states
	select a_name, a_id, health_state 
	from labresearches.animals 
	where a_name = animal_name;

	update labresearches.animals a
	set health_state = case
					when health_state = 'Здоров'
					then (select a2.health_state 
						from labresearches.animals a2
						where a2.health_state != 'Здоров'
						group by health_state
						limit 1)
					else 'Здоров'
					end
--	set health_state = (select a2.health_state 
--						from labresearches.animals a2
--						where a2.health_state != a.health_state
--						group by health_state
--						limit 1)
	where a_name = animal_name;
	
end;
$$ language plpgsql;

call labresearches.change_health_state('Шарик');

insert into old_states
	select a_name, a_id, health_state 
	from labresearches.animals 
	where a_name = 'Шарик';

update labresearches.animals a
set health_state = (select health_state 
					from old_states o
					where o.a_id = a.a_id)
where a.a_name = 'Шарик'



select a_id, a_name, health_state
from labresearches.animals a 
where a_name = 'Шарик';

