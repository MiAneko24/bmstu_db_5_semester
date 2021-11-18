-- определяемая пользователем скалярная функция clr
-- вывести количество ученых-однофамильцев в лаборатории

create extension plpython3u

create or replace function labresearches.amount_of_equal_surnames_in_lab(lab_name text)
returns int
as $$
	scientists = plpy.execute("select * from labresearches.scientists")
	cnt_same_names = 0
	for i in range(len(scientists)):
		for j in range(i + 1, len(scientists), 1):
			if scientists[i]['s_surname'] == scientists[j]['s_surname'] and scientists[i]['lab_name'] == scientists[j]['lab_name'] == lab_name:
				cnt_same_names += 1
	return cnt_same_names
$$ language PLPYTHON3U;

select * from labresearches.amount_of_equal_surnames_in_lab('Лаборатория при университете Лондон')


--
--select  s1.s_surname, s1.s_name, s1.s_second_name, s1.lab_name , s2.s_surname , s2.s_name , s2.s_second_name 
--from labresearches.scientists s1 join labresearches.scientists s2 
--on s1.s_surname = s2.s_surname and (s1.s_name != s2.s_name or s1.s_second_name != s2.s_second_name )
--where s1.lab_name = s2.lab_name and s1.lab_name = 'Лаборатория при университете Лондон' 


-- пользовательская агрегатная функция clr
-- среднее количество исследований каждого исследователя в лаборатории
create or replace function labresearches.avg_researches_by_scientist_in_laboratory(lab_name text)
returns real
as $$
	def update_res_amount(res_amounts, scientist):
		if scientist in res_amounts.keys():
			res_amounts[scientist] += 1
		else:
			res_amounts[scientist] = 1		
	
	researches = plpy.execute("select * from labresearches.researches")
	res = dict()
	for research in researches:
		if research['lab_name'] == lab_name:
			update_res_amount(res, research['s_surname'] + research['s_name'] + research['s_second_name'])
	return sum(res.values()) / len(res)
$$ language plpython3u;

--select * from labresearches.laboratories l 

select * from labresearches.avg_researches_by_scientist_in_laboratory('Лаборатория им. Авериев')

--определяемая пользователем табличная функция clr
-- вывести информацию обо всех питомцах ученого, в том числе, участвовали ли они в исследованиях
drop function labresearches.get_scientist_animals_info(surname_domain, name_domain, name_domain);
create or replace function labresearches.get_scientist_animals_info(s_surname surname_domain, s_name name_domain, s_second_name name_domain)
returns table(
	a_id int,
	a_name name_domain,
	species text,
	gender text,
	age int, 
	took_part_in_research bool
) language plpython3u as $$
	animals = plpy.execute("select * from labresearches.animals")
	res = []
	params = ['a_id', 'a_name', 'species', 'gender', 'age']
	for animal in animals:
		if animal['s_surname'] == s_surname and animal['s_name'] == s_name and animal['s_second_name'] == s_second_name:
			tmp_res = dict()
			for param in params:
				tmp_res[param] = animal[param]

			tmp_res['took_part_in_research'] = True if len(plpy.execute("select a_id from labresearches.researches where a_id = " + str(animal['a_id']) + ";")) != 0 else False
			res.append(tmp_res)
	return res	
$$;


select * from labresearches.get_scientist_animals_info('Митрофанова', 'Дорофея', 'Борисовна')

select s_surname, s_name, s_second_name
from labresearches.animals a 
group by s_surname , s_name , s_second_name 
having (select count(*) 
			from labresearches.animals a2
			group by s_surname, s_name, s_second_name 
			having a2.s_surname = a.s_surname and a2.s_name = a.s_name and a2.s_second_name = a.s_second_name) = (select max(cnt)
																												from (select count(*) as cnt
																													from labresearches.animals a3
																													group by s_surname, s_name, s_second_name) smth)  
and (s_surname, s_name, s_second_name) in (																													
select s_surname, s_name, s_second_name from labresearches.animals a 
where a_id not in (select a_id from labresearches.researches r))
												
-- хранимая процедура clr
-- Понизить ученую степень ученых, у которых нет ни одного исследования и которые старше заданного возраста, до бакалавра
create or replace procedure labresearches.downgrade_scientists(age int)
as $$
	wrong_scientists = plpy.execute("select s_surname, s_name, s_second_name from labresearches.scientists s where (s_surname, s_name, s_second_name) not in (select s_surname, s_name, s_second_name from labresearches.researches r group by s_surname, s_name , s_second_name );")
	plan = plpy.prepare("update labresearches.scientists set degree = 'Бакалавр' where s_surname = $1 and s_name = $2 and s_second_name = $3 and age > $4", ["text", "text", "text", "int"])
	for sc in wrong_scientists:
		plan.execute([sc['s_surname'], sc['s_name'], sc['s_second_name'], age])
$$ language plpython3u;


drop table if exists old_degrees;
create temp table old_degrees(
	s_surname surname_domain,
	s_name name_domain,
	s_second_name name_domain,
	degree text
);


insert into old_degrees
select s_surname, s_name, s_second_name, degree 
from labresearches.scientists s 
where (s_surname, s_name, s_second_name) not in (select s_surname, s_name, s_second_name 
												from labresearches.researches r 
												group by s_surname, s_name , s_second_name )
		and age > 70;
	
select * from old_degrees

call labresearches.downgrade_scientists(70)

update labresearches.scientists s
set degree = (select "degree" 
				from (select *, row_number() over(partition by s_surname, s_name, s_second_name) as num
						from old_degrees) tab
				where s.s_surname = tab.s_surname and s.s_name = tab.s_name and s.s_second_name = tab.s_second_name and num = 1)
where (s_surname, s_name, s_second_name) in (select s_surname, s_name, s_second_name from old_degrees);
						


--select *, row_number() over(partition by s_surname, s_name, s_second_name)
--from old_degrees

-- триггер clr
-- после добавления нового животного проверяем совпадение с лабораторией хозяина
-- если есть различия, лабораторию животного меняем на лабораторию хозяина


create or replace function labresearches.check_animal_lab()
returns trigger 
as $$
	owner_lab = plpy.execute("select lab_name from labresearches.scientists where s_surname = \'{}\' and s_name = \'{}\' and s_second_name= \'{}\';".format(TD['new']['s_surname'], TD['new']['s_name'], TD['new']['s_second_name']))
	if TD["new"]['lab_name'] != owner_lab[0]['lab_name']:
		TD['new']['lab_name'] = owner_lab[0]['lab_name']
		return "MODIFY"
	return "OK"
$$ language plpython3u;

drop trigger if exists check_animal on labresearches.animals;

create trigger check_animal
before insert on labresearches.animals 
for row execute procedure labresearches.check_animal_lab();

select * from labresearches.scientists s 
where s_surname = 'Захаров' and s_name = 'Алексей' and s_second_name = 'Данилович';

select * from labresearches.animals a where a_id = 98765

delete from labresearches.animals 
where a_id = 98765

select * from labresearches.laboratories l where lab_name = 'Лаборатория им. Федотов'


insert into labresearches.animals(a_id, a_name, lab_name, species, age, gender, health_state, research_generation, s_surname, s_name, s_second_name)
values (98765, 'Fuo', 'Лаборатория 55', 'Улитка', 2, 'Женский', 'Здоров', 4, 'Захаров', 'Алексей', 'Данилович');

-- определяемый пользователем тип данных clr
-- вывести информацию об исследованиях, проводившихся над конкретным животным, и ученых, проводивших их
drop type if exists labresearches.scientists_and_researches_info cascade;
create type labresearches.scientists_and_researches_info as (
	s_surname surname_domain,
	s_name name_domain,
	s_second_name name_domain,
	phone_number phone_number_domain,
	profession text,
	r_name text,
	science_field text
);

create or replace function labresearches.get_scientists_and_researches_info_for_animal(a_id int)
returns setof labresearches.scientists_and_researches_info
as $$
	researches = plpy.execute('select * from labresearches.researches')
	scientists = plpy.execute('select * from labresearches.scientists')
	res_sc = dict()
	info = []
	for research in researches:
		if research['a_id'] == a_id:
			row_i = dict()
			s_surname = research['s_surname']
			s_name = research['s_name']
			s_second_name = research['s_second_name']
			row_i['s_surname'] = s_surname
			row_i['s_name'] = s_name
			row_i['s_second_name'] = s_second_name
			row_i['r_name'] = research['r_name']
			row_i['science_field'] = research['science_field']
			for sc in scientists:
				if s_surname == sc['s_surname'] and s_name == sc['s_name'] and s_second_name == sc['s_second_name']:
					row_i['phone_number'] = sc['phone_number']
					row_i['profession'] = sc['profession']
					break
			info.append(row_i)
	return info
$$ language plpython3u;

select * from labresearches.researches r 
where a_id = 11111

select * from labresearches.get_scientists_and_researches_info_for_animal(11111)


