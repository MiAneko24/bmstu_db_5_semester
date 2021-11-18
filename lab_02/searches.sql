--- Select с предикатом сравнения
--- Вывести имена и номера ученых, у которых есть животные и которым меньше 20 лет
select s_name, phone_number from labResearches.Scientists
where (has_pets 
and age < 20);

--- Select с предикатом BETWEEN
--- Вывести информацию об авторе, названии, годе начала и лаборатории
--- проведения исследования, начало которого лежит в промежутке с 2018 по 2020 г.
select labResearches.scientists.s_surname, labresearches.scientists .s_name, labresearches.scientists.degree, labresearches.researches.r_name, labresearches.researches.start_year, labresearches.researches.lab_name 
from labResearches.Scientists, labResearches.Researches
where (labResearches.Researches.start_year between 2018 and 2020
and labResearches.researches.s_surname = labResearches.scientists.s_surname)
order by labresearches.researches.start_year ;

--- Select с предикатом LIKE
--- Получить список животных, болеющих каким-либо заболеванием в тяжелой форме
select a_id, a_name, health_state 
from labresearches.animals 
where (health_state like('%тяжелая форма%'));

--- Select, использующий in с вложенным подзапросом
--- Вывести информацию об ученых, проводивших исследование в сфере бионика
select s_surname, s_name, s_second_name, degree, phone_number 
from labresearches.scientists
where s_surname in (select s_surname 
								from labresearches.researches 
								where science_field = 'Бионика')
	and s_name in (select s_name 
											from labresearches.researches 
											where science_field = 'Бионика')
	and s_second_name in (select s_second_name 
											from labresearches.researches 
											where science_field = 'Бионика');

--- Select с exists с вложенным подзапросом
--- Вывести все номера и клички сазанов таких, что у хозяина нет никаких других животных, кроме сазанов
select A.a_id, A.a_name
from labresearches.animals as A
where not exists(select s_name, s_surname, s_second_name from labresearches.animals
				where A.s_name = labresearches.animals.s_name
					and A.s_surname = labresearches.animals.s_surname
					and A.s_second_name = labresearches.animals.s_second_name
					and A.species != labresearches.animals.species)
				and A.species='Сазан';

--- Select с предикатом сравнения с квантором
--- Выбрать такие лаборатории, которые спонсируются государством
--- и были созданы позже начала исследований по разработке каких-либо лекарств
select * 
from labresearches.laboratories 
where establish_year > all(select start_year
from labresearches.researches 
where r_name like '%лекарств%')
	and sponsored_by_gov;

--- Select с агрегатными функциями в выражениях столбцов
--- Вычислить средний возраст не умерших животных каждого вида
select avg(age) as avg_age, species
from labresearches.animals as A
where A.health_state != 'Умер' 
group by species;

--- Select со скалярными подзапросами в выражениях столбцов
--- Вывести лаборатории, которые были основаны позже 2000 года, количество ученых и лошадей в них
select lab_name, city, (select count(*)
						from labresearches.scientists as S
						where labresearches.laboratories.lab_name = S.lab_name) as ScientistsAmount
						(select count(*)
						from labResearches.animals as A
						where labResearches.laboratories.lab_name = A.lab_name
							and A.species='Лошадь') as HorsesAmount
from labresearches.laboratories
where establish_year > 2000;

--- Select с простым выражением case
--- Вывести больных животных, указав их поколение
select a_id, a_name, species,
	case research_generation
		when 1 then 'Первое поколение'
		when 2 then 'Второе поколение'
		when 3 then 'Третье поколение'
		else 'N-ное поколение, исследуется давно'
	end as Generation
from labresearches.animals as A
where A.health_state != 'Умер' and A.health_state != 'Здоров';

--- Select с поисковым выражением CASE
--- Вывести ученых, специальность которых оканчивается на "олог" и которые
--- работают в лаборатории имени ученого, определив их к возрастным категориям
select s_surname, s_name, s_second_name,
		case 
			when age <= 30 then 'Молодой'
			when age < 60 and gender = 'Женский' 
			or age < 65 then 'Взрослый'
			when age < 100 then 'Пенсионер'
			else 'Столько не живут'
		end as age_cathegory
from labresearches.scientists
where profession like('%олог') and lab_name like('%им.%');

--- Создание новой временной локальной таблицы 
--- из результирующего набора данных инструкции SELECT
--- Создать новую таблицу из id и кличек умерших животных и контактных данных их владельцев, 
--- которым нет 80 лет
select A.a_id, A.a_name, S.s_surname, S.s_name, S.s_second_name, phone_number
into TEMP table notify_owners
from labresearches.animals as A left join labresearches.scientists as S on A.s_surname = S.s_surname and A.s_name = S.s_name and A.s_second_name = S.s_second_name
where A.health_state='Умер' and S.age < 80;

---Инструкция SELECT, использующая вложенные коррелированные
-- подзапросы в качестве производных таблиц в предложении FROM
--- Вывести лаборатории, среднее количество принимающих участие в исследованиях животных,
--- общее количество проводимых над животными лаборатории исследований и год начала
--- последнего исследования
select lab_name, count(A.a_id) as amount_of_animals, sum(count_of_researches) as amount_of_researches, max(latest_research) as latest_research
from labResearches.animals as A join (select a_id, count(*) as count_of_researches, max(start_year) as latest_research
									from labResearches.researches as R
									group by a_id) as AR on AR.a_id = A.a_id
group by lab_name;

--- Инструкция SELECT, использующая вложенные подзапросы с уровнем
-- вложенности 3
--- Вывести информацию об ученых, которые проводят исследования над своими питомцами-кошками
select s_surname, s_name, s_second_name, degree, profession 
from labresearches.scientists
where has_pets and
	(s_surname, s_name, s_second_name ) in (select s_surname, s_name, s_second_name
												from labresearches.animals
												where a_id in (select a_id
																from labresearches.researches
																group by a_id, s_surname, s_name, s_second_name)
													and species = 'Кошка');

-- Инструкция SELECT, консолидирующая данные с помощью предложения
-- GROUP BY, но без предложения HAVING
-- Вывести средний возраст и количество ученый каждой из возможных ученых степеней
-- для лабораторий Генуи
select lab_name, degree, min(age), count(*)
from labresearches.scientists
where lab_name in (select lab_name 
					from labresearches.laboratories 
					where city = 'Генуя')
group by lab_name, degree;

-- Инструкция SELECT, консолидирующая данные с помощью предложения
-- GROUP BY и предложения HAVING
-- Вывести имя, фамилию, средний возраст и количество тезок
select s_surname, s_name, avg(age), count(*)
from labresearches.scientists
group by s_surname, s_name
having count(*) > 1;

-- Однострочная инструкция INSERT, выполняющая вставку в таблицу одной
-- строки значений.
insert into labresearches.laboratories
	values('НИИ какое-то', False, 'Москва', 'Российская Фередация', 2021);

-- Многострочная инструкция INSERT, выполняющая вставку в таблицу
-- результирующего набора данных вложенного подзапроса
insert into labResearches.animals
select 10 * a_id, a_name, lab_name, species, age, gender, health_state, 11, (select s_surname
															from labResearches.scientists
															where degree='Бакалавр' and age < 18 and not has_pets limit 1),
															(select s_name
															from labResearches.scientists
															where degree='Бакалавр' and age < 18 and not has_pets limit 1),
															(select s_second_name
															from labResearches.scientists
															where degree='Бакалавр' and age < 18 and not has_pets limit 1)
from labResearches.animals
where species like('Са%') and 10 * a_id not in (select a_id from labresearches.animals) and health_state = 'Здоров';

-- Простая инструкция UPDATE.
update labResearches.scientists
set has_pets = True
where s_surname in (select s_surname
					from labResearches.scientists
					where degree='Бакалавр' and age < 18 and not has_pets limit 1)
	and s_name in (select s_name
					from labResearches.scientists
					where degree='Бакалавр' and age < 18 and not has_pets limit 1)
	and s_second_name in (select s_second_name
					from labResearches.scientists
					where degree='Бакалавр' and age < 18 and not has_pets limit 1);

-- Инструкция UPDATE со скалярным подзапросом в предложении SET.

update labResearches.animals
set research_generation = (select count(*)
							from labResearches.researches
							where a_id between 20000 and 20500)
where a_id between 20000 and 20500;

--Простая инструкция DELETE
delete from labResearches.animals
where research_generation=11;

-- Инструкция DELETE с вложенным коррелированным подзапросом в
-- предложении WHERE
delete from labResearches.researches as R
where a_id in (select A.a_id
				from labResearches.animals as A
					on R.a_id = A.a_id
					where A.health_state = 'Умер' and R.start_year < 1900);

-- Инструкция select с простым обобщенным табличным выражением
with same_names_animal_species (lab_name, amount) as (
	select lab_name , count(distinct a_name) as amount
	from labresearches.animals as A
	where a.health_state = 'Здоров'
	group by lab_name
)
select city, avg(amount) 
from same_names_animal_species as S join labresearches.laboratories as L 
on L.lab_name = S.lab_name
where sponsored_by_gov
group by city;

-- Инструкция select, использующая рекурсивное ОТВ
with recursive smth (lab_name, year) as
(	
	select lab_name, establish_year
	from labresearches.laboratories  
	where city like('%ми%')
	union 
	select s.lab_name, start_year
	from smth as s join labresearches.researches r 
	on s.lab_name = r.lab_name
)
select * from smth;

-- Оконные функции
select S.s_surname, S.s_name, S.s_second_name, S.age, A.species, AVG(S.age) over (partition by A.species) as average_age,
min(S.age) over (partition by A.species), max(S.age) over (partition by A.species)
from labresearches.scientists as S join labresearches.animals as A 
on A.s_surname = S.s_surname and A.s_name = S.s_name and A.s_second_name = S.s_second_name
where A.health_state like('%(легкая%'); 

-- Оконные функции для устранения дублей

select lab_name, s_surname, s_name, s_second_name 
from (
	select lab_name, s_surname, s_name, s_second_name, row_number() over(partition by s_surname, s_name, s_second_name) as rep
	from (select lab_name, s_surname, s_name, s_second_name
		from labresearches.scientists as L
		where degree='Аспирант' and age > 50
		union all 
		select lab_name, s_surname, s_name, s_second_name
		from labresearches.researches as R
		where start_year > 2000) as scientists
		) as repeated_data
where rep = 1;