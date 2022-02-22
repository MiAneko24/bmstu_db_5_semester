-- экспортируем в json таблицу animals

copy (select row_to_json(t) from (select * from labresearches.animals) t) to '/tmp/animals.json';
select * from labresearches.animals a ;

-- создаем таблицу new_animals, заполняем на основе полученного в прошлом пункте json
drop table if exists labresearches.new_animals;
create table labresearches.new_animals (
	a_id int primary key,
    a_name varchar,
    lab_name varchar not null,
    species name_domain not null,
    age int not null,
    gender name_domain not null,
    health_state varchar not null,
    research_generation int,
    s_surname surname_domain,
    s_name name_domain,
    s_second_name name_domain
);

alter table labResearches.new_animals 
    add constraint fk_new_scientists foreign key(s_surname, s_name, s_second_name) 
    references labResearches.Scientists(s_surname, s_name, s_second_name);
  

alter table labResearches.new_animals
    add constraint a_name_check check(
        a_name ~ '\D+'
    );

alter table labResearches.new_animals
    add constraint fk_an_lab foreign key(lab_name) references labResearches.Laboratories(lab_name);

alter table labResearches.new_animals
    add constraint animal_age_range check(
        age >= 0
        and age <= 100
    );

alter table labResearches.new_animals
    add constraint generation_range check(
        research_generation >= 1
        and research_generation <= 10
    );


drop table if exists json_data;
create temp table json_data(dat json);
copy json_data from '/tmp/animals.json';

create or replace procedure fill_from_json()
as $$
declare 
	json_row json;
begin
	for json_row in (select dat from json_data)
	loop
		insert into labresearches.new_animals
		select * from json_populate_record(null::labresearches.new_animals, json_row);
	end loop;
end;
$$ language plpgsql;

call fill_from_json(); 

select * from json_data;

select * from labresearches.new_animals;
select * from labresearches.animals a;


--создаем табличку запросов на публикацию исследований
drop table if exists labresearches.requests;
create table labresearches.requests(
	req_id int primary key,
	req_date date,
	req_body json
);

select s_surname, s_name, s_second_name, lab_name
from labresearches.scientists s 
where age between 30 and 70;

select a_id, lab_name
from labresearches.animals a 
where lab_name = 'Лаборатория им. Ипполитов' or lab_name = 'Лаборатория при университете Берн' or lab_name = 'Лаборатория им. Янов' or lab_name = 'Лаборатория 1203';


insert into labresearches.requests(req_id, req_date, req_body) 
values(1, '1997-10-10', '[{"s_surname": "Карлов", "s_name": "Илларион", "s_second_name": "Потапович"}, {"lab_name": "Лаборатория им. Ипполитов", "a_id": 65242, "r_name": "Изучение рефлексов"}]'::json),
(2, '2002-12-31', '[{"s_surname": "Якимов", "s_name": "Пахом", "s_second_name": "Филатович"}, {"lab_name": "Лаборатория при университете Берн", "a_id": 2142, "r_name": "Изучение световосприятия беспозвоночных"}]'::json),
(3, '2009-01-01', '[{"s_surname": "Акакиева", "s_name": "Офелия", "s_second_name": "Дионисиевна"}, {"lab_name": "Лаборатория им. Янов", "a_id": 90652, "r_name": "Разработка лекарства от заболеваний нервной системы"}]'::json),
(4, '2018-05-23', '[{"s_surname": "Юриева", "s_name": "Аграфена", "s_second_name": "Спартаковна"}, {"lab_name": "Лаборатория 1203", "a_id": 214, "r_name": "Исследование супергидрофобности"}]'::json)

select * from labresearches.requests

-- извлекаем json фрагмент из json документа
-- получаем все строки json, в которых встречается сочетание букв 'анте'
--create temp table labresearches.animals_from_London(
--	a_id int primary key,
--	a_name text,
--	lab_name text foreign key references labresearches.laboratories,
--	city text,
--	species text
--);

drop table if exists json_data;
create temp table json_data(dat json);
copy json_data from '/tmp/animals.json';


select * 
from json_data j 
where cast(dat as text) like '%анте%'

-- получаем всех животных, лаборатория которых находится в Фукусиме
select cast(dat->>'a_id' as integer) as a_id, dat->>'a_name' as a_name, dat->>'lab_name' as lab_name, dat->>'species' as species, 'Лондон' as city
from json_data j
where dat->>'lab_name' in (select lab_name from labresearches.laboratories l where city = 'Фукусима');

select city from labresearches.laboratories l 
where (select count(*) as cnt from labresearches.laboratories l2 where l2.city = l.city group by city) = (select max(cnt) from (select count(*) as cnt from labresearches.laboratories group by city) as cnt_gr)
group by city;


-- изменяем json документ
insert into json_data
values('{"a_id":1433,"a_name":"Мэйсон","gender":"Мужской","health_state":"Болеет <неизвестная болезнь> (тяжелая форма)","research_generation":3,"s_surname":"Пантелеймонов","s_name":"Адам","s_second_name":"Мефодиевич"}'),
('{"a_id":45878,"a_name":"Анубис","age":6,"gender":"Женский","health_state":"Здоров","research_generation":2,"s_surname":"Мисаилов","s_name":"Максимилиан"}');

copy(select row_to_json(js) #>'{dat}'
	from (select dat from json_data) as js)
--		where dat->>'species' is null) 
to '/tmp/animals.json';

drop table if exists json_data;
create temp table json_data(dat json);
copy json_data from '/tmp/animals.json';

select * from json_data;

-- проверяем существование атрибута
-- выводим строки, в которых нет атрибута 'species'

select dat 
from json_data
where dat ->> 'species' is null

-- разделяем json документ на несколько строк по узлам

select json_array_elements(req_body)
from labresearches.requests reqs


-- (Защита) Сделать врача-специалиста. Триггер, который будет отправлять всех животных с определенным заболеванием к одному выбранному ученому. И распечатайте животных этого ученого в JSON 

create extension plpython3u;

select * from labresearches.scientists s 
where has_pets and (s_surname, s_name, s_second_name) not in (select s_surname, s_name, s_second_name from labresearches.animals a group by s_surname, s_name, s_second_name) 

create or replace function labresearches.check_owner_by_health_state()
returns trigger 
as $$
	if 'COVID-19' in TD["new"]["health_state"]:
		TD["new"]['s_surname'] = 'Августов'
		TD["new"]['s_name'] = 'Гордей'
		TD["new"]['s_second_name'] = 'Пётрович'
		owner_lab = plpy.execute("select lab_name from labresearches.scientists where s_surname = \'{}\' and s_name = \'{}\' and s_second_name= \'{}\';".format(TD['new']['s_surname'], TD['new']['s_name'], TD['new']['s_second_name']))
		TD["new"]['lab_name'] = owner_lab[0]['lab_name']
		return "MODIFY"
	return "OK"
$$ language plpython3u;


drop trigger if exists check_state on labresearches.animals;

create trigger check_state
before insert on labresearches.animals 
for row execute procedure labresearches.check_owner_by_health_state();

select * from labresearches.scientists s ;
select * from labresearches.animals a where a_id = 91 or a_id = 77 or a_id = 82 or a_id = 12;


insert into labresearches.animals(a_id, a_name, lab_name, species, age, gender, health_state, research_generation, s_surname, s_name, s_second_name)
values(77, 'Шарик', 'Лаборатория при университете Лутраки', 'Улитка', 2, 'Мужской', 'Болеет ОРВИ (легкая форма)', 1, 'Мстиславов', 'Георгий', 'Робертович'),
(82, 'Луи', 'Лаборатория при университете Лутраки', 'Кошка', 4, 'Женский', 'Болеет COVID-19 (легкая форма)', 1, 'Мстиславов', 'Георгий', 'Робертович'),
(12, 'Чичи', 'Лаборатория при университете Лутраки', 'Сазан', 1, 'Мужской', 'Здоров', 2, 'Мстиславов', 'Георгий', 'Робертович'),
(91, 'Минди', 'Лаборатория при университете Лутраки', 'Собака', 6, 'Мужской', 'Болеет COVID-19 (тяжелая форма)', 1, 'Мстиславов', 'Георгий', 'Робертович');


copy(select row_to_json(t) from (select * from labresearches.animals a where s_surname = 'Августов' and s_name = 'Гордей' and s_second_name = 'Пётрович') t) to '/tmp/covid_animals.json';

drop table covid_animals;
create temp table covid_animals(
	data json
)

copy covid_animals from '/tmp/covid_animals.json';
select * from covid_animals;
