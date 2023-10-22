import re
from typing import Text
from peewee import *

db = PostgresqlDatabase("db_labs", 
                        user="code",
                        password="vscode",
                        host="172.17.0.2",
                        port="5432")

class Laboratory(Model):
    lab_name = TextField(primary_key=True, column_name='lab_name')
    sponsored_by_gov = BooleanField()
    city = TextField()
    country = TextField()
    establish_year = IntegerField(constraints=[Check('establish_year >= 1600 and establish_year <= 2020')])

    class Meta:
        database = db
        schema = 'labresearches'
        table_name = 'laboratories'

class Scientist(Model):
    s_surname = TextField()
    s_name = TextField()
    s_second_name = TextField()
    age = IntegerField(constraints=[Check('age >= 16 and age <= 100')])
    gender = TextField()
    lab_name = ForeignKeyField(Laboratory, to_field='lab_name', column_name='lab_name')
    profession = TextField()
    degree = TextField()
    phone_number = TextField(constraints=[Check("phone_number ~ '\+{1}\d+'")])
    has_pets = BooleanField()

    class Meta:
        primary_key = CompositeKey('s_surname', 's_name', 's_second_name')
        database = db
        schema = 'labresearches'
        table_name = 'scientists'

class Animal(Model):
    a_id = IntegerField(primary_key=True)
    a_name = TextField()
    lab_name = ForeignKeyField(Laboratory, to_field='lab_name', column_name='lab_name')
    species = TextField()
    age = IntegerField(constraints=[Check('age >= 0 and age <= 100')])
    gender = TextField()
    health_state = TextField()
    research_generation = IntegerField(constraints=[Check('research_generation >= 1 and research_generation <= 10')])
    s_surname = ForeignKeyField(Scientist, to_field='s_surname', column_name='s_surname')
    s_name = ForeignKeyField(Scientist, to_field='s_name', column_name='s_name')
    s_second_name = ForeignKeyField(Scientist, to_field='s_second_name', column_name='s_second_name')

    class Meta:
        database = db
        schema = 'labresearches'
        table_name = 'animals'

class Research(Model):
    s_surname = ForeignKeyField(Scientist, to_field='s_surname', column_name='s_surname')
    s_name = ForeignKeyField(Scientist, to_field='s_name', column_name='s_name')
    s_second_name = ForeignKeyField(Scientist, to_field='s_second_name', column_name='s_second_name')
    a_id = ForeignKeyField(Animal, to_field='a_id', column_name='a_id')
    lab_name = ForeignKeyField(Laboratory, to_field='lab_name', column_name='lab_name')
    science_field = TextField()
    r_name = TextField()
    start_year = IntegerField(constraints=[Check('start_year >= 1600 and start_year <= 2021')])
    
    class Meta:
        primary_key = CompositeKey('s_surname', 's_name', 's_second_name', 'a_id')
        database = db
        schema = 'labresearches'
        table_name = 'researches'
  


class Database:
    def __init__(self):
        self.__error = None
        try:
            self.db = db
            print("Connection with database was opened successfully!")
        except (Exception) as e:
            self.__error = e
    
    @property
    def error(self):
        return self.__error

    def __del__(self):
        print("Connection with database is closed!")
        self.db.close()

    def __exec(self, query, commit=False):
        try:
            cur = self.db.execute_sql(query)
        except BaseException as e:
            print(e)
        if commit:
            self.db.commit()
            print("Successfully committed!")
        try:
            return cur.fetchall()
        except:
            pass
    
    #
    def get_info_about_res_and_scientists_for_animal(self, a_id):
        return self.__exec(f"""select s.s_surname, s.s_name, s.s_second_name, s.age, s.degree, s.profession, s.phone_number
                                from (labresearches.scientists s join labresearches.researches r on s.s_surname = r.s_surname and s.s_name = r.s_name and s.s_second_name = r.s_second_name) join labresearches.animals a on r.a_id = a.a_id
                                where r.a_id = {a_id};""")
    #
    def get_scientist_with_max_amount_of_researches(self):
        return self.__exec(f"""with get_cnt_res as(
                                select s.s_surname, s.s_name, s.s_second_name,  s."degree", s.age , count(*) as cnt
                                from  labresearches.researches r join labresearches.scientists s on s.s_surname =r.s_surname and s.s_name =r.s_name and s.s_second_name =r.s_second_name 
                                group by s.s_surname, s.s_name, s.s_second_name,  s."degree", s.age 
                                )
                                select q.s_surname, q.s_name, q.s_second_name, q.degree, q.age, q.cnt
                                from (select s_surname, s_name, s_second_name, degree, age, cnt
                                        from get_cnt_res) q
                                where cnt = (select max(cnt)
                                                from get_cnt_res);
                                """)

    # количество животных ученого
    def get_scientist_animals_amount(self, surname, name, second_name, species):
        return self.__exec(f"""
        select count(*)
        from labresearches.animals
        where s_surname = '{surname}' and s_name = '{name}' and s_second_name = '{second_name}' and species = '{species}'
        """)[0]

    def get_animals_and_res_by_city(self, city):
        return self.__exec(f"""
        select r.r_name, r.science_field, a.a_id, a.species, a.health_state, l.lab_name, l.city, l.country
        from (labresearches.laboratories l join labresearches.animals a on l.lab_name =a.lab_name)
		join labresearches.researches r 
		on a.a_id = r.a_id
        where l.city = '{city}'
        """)

    def get_amount_dead_animals_for_sc_in_lab(self, l_name):
        return self.__exec(f"""
        select s.s_surname, s.s_name, s.s_second_name, s.phone_number, count(*)
        from labresearches.scientists s join labresearches.animals a on a.s_surname = s.s_surname and a.s_name = s.s_name and a.s_second_name = s.s_second_name
        where s.lab_name = '{l_name}'
        group by s.s_surname, s.s_name, s.s_second_name, a.health_state
        having a.health_state = 'Здоров'""")

    def delete_ill_animals(self, illness):
        self.__exec(f"""delete from labresearches.researches r where a_id in (select a_id from labresearches.animals a where health_state like('%%{illness}%%')); 
        """, commit=True)
        self.__exec(f"""delete from labresearches.animals a where health_state like('%%{illness}%%');""", commit=True)
        print("Success")


    def create_new_animals_json(self):
        self.__exec("""
copy (select row_to_json(t) from (select * from labresearches.animals) t) to '/tmp/animals.json';
select * from labresearches.animals a;""", commit=True)

    def read_from_json(self):
        return self.__exec("""
        drop table if exists new_animals;
create temp table new_animals (
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

alter table new_animals
    add constraint a_name_check check(
        a_name ~ '\D+'
    );

alter table new_animals
    add constraint animal_age_range check(
        age >= 0
        and age <= 100
    );

alter table new_animals
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
		insert into new_animals
		select * from json_populate_record(null::new_animals, json_row);
	end loop;
end;
$$ language plpgsql;

call fill_from_json(); 

select * from new_animals;
""")

    def update_json(self, a_id, new_name):
        try:
            return self.__exec(f"""
            update new_animals
            set a_name = '{new_name}'
            where a_id = {a_id};
            select * from new_animals;""", commit=True)
        except BaseException as e:
            print("eror, ", e)
            return None

    #queries time
    #однотабличный запрос на выборку
    # --- Получить список животных, болеющих каким-либо заболеванием в тяжелой форме
    """select a_id, a_name, health_state 
    from labresearches.animals 
    where (health_state like('%тяжелая форма%'));
    """
    def get_ill_animals(self):
        return Animal.select(Animal.a_id, Animal.a_name, Animal.health_state).where(Animal.health_state.contains('тяжелая форма')).tuples()

    #многотабличный запрос
    # получить информацию об исследованиях в указанных лабораториях, 
    # -- которые проводили ученые указанной ученой степени и животные, 
    # -- принимавшие участие в которых, умерли
    # select s.s_surname, s.s_name, s.s_second_name, s.degree, a.a_id, a.a_name, r.r_name, s.lab_name
    # from (labresearches.scientists as s join labresearches.researches as r 
    # 	on s.s_surname = r.s_surname and s.s_name =r.s_name and s.s_second_name = r.s_second_name) join labresearches.animals as a 
    # 	on r.a_id = a.a_id 
    # where a.health_state ='Умер' and s."degree" = s_degree and s.lab_name =l_name;
    
    def get_researches_with_dead_animals(self, l_name, degree):
        return Scientist.select(Scientist.s_surname, Scientist.s_name, Scientist.s_second_name, Scientist.degree, Animal.a_id, \
            Animal.a_name, Research.r_name, Scientist.lab_name).join(Research, on=((Research.s_surname == Scientist.s_surname) & (Research.s_name == Scientist.s_name) \
                & (Research.s_second_name == Scientist.s_second_name))).join(Animal, on=(Research.a_id == Animal.a_id)).where((Research.lab_name == l_name) & (Animal.health_state.contains('легкая форма'))\
                        & (Scientist.degree==degree)).tuples()
    #Добавление записи
    def add_laboratory(self, l_name, spons, cty, cntry, e_year):
        m = Laboratory.create(lab_name=l_name, sponsored_by_gov=spons, city=cty, country=cntry, establish_year=e_year)
        return Laboratory.select().where(Laboratory.lab_name==l_name)
    
    def update_placement(self, l_name, n_city, n_country):
        return [Laboratory.update(city=n_city, country=n_country).where(Laboratory.lab_name==l_name).execute()]
    
    def delete_labs_from_city(self, n_city):
        return [Laboratory.delete().where(Laboratory.city == n_city).execute()]
    
    def get_scientist_by_initials(self, s_surname, s_name, s_second_name):
        self.db.execute_sql(f"call labresearches.get_scientists_by_abbreviature('{s_surname}', '{s_name}', '{s_second_name}');")

class UI:
    def __init__(self):
        self.exit=False
        self.db = Database()
        self.error = self.db.error
        self.commands = [self.quit,
        self.get_info_about_res_and_scientists_for_animal,
        self.get_scientist_with_max_amount_of_researches,
        self.find_scientist_animals_amount,
        self.find_animals_and_res_by_city,
        self.get_amount_dead_animals_for_sc_in_lab,
        self.create_json,
        self.read_json,
        self.update_json,
        self.get_ill_animals, 
        self.get_res_info, 
        self.create_lab,
        self.update_lab,
        self.delete_labs,
        self.get_scientists_by_initials, 
        self.delete_animals]
        if self.error is None:
            while not self.exit:
                self.menu()
        else:
            self.db_error()
        
    def db_error(self):
        print(f"Не удалось подключиться к базе данных: {self.error}")

    def delete_animals(self):
        illness = input('Введите название болезни для удаления: ')
        self.execute(self.db.delete_ill_animals, illness)
        # self.print_result(res)

    def menu(self):
        # print(self.db.db.execute_sql("""SELECT "t1"."a_id", "t1"."a_name", "t1"."lab_name", "t1"."species", "t1"."age", "t1"."gender", "t1"."health_state", "t1"."research_generation", "t1"."s_surname", "t1"."s_name", "t1"."s_second_name" FROM labresearches.animals AS "t1" """))
        print("""
Программа для работы с базой данных исследований
0. Завершить работу.
LINQ to Object:
1. Вывести информацию об ученых, проводивших исследования над животным.
2. Вывести ученых, которые провели наибольшее количество исследований.
3. Получить количество животных ученого определенного вида.
4. Получить информацию об исследованиях и животных определенного города.
5. Получить информацию об ученых, питомцы которых здоровы, для лаборатории.

JSON:
6. Запись в JSON документ
7. Чтение из JSON документа
8. Изменение JSON документа

LINQ to SQL:
9. Получить список животных, болеющих каким-либо заболеванием в тяжелой форме
10. получить информацию об исследованиях в указанной лаборатории, 
которые проводили ученые указанной ученой степени и животные, 
принимавшие участие в которых, болеют в легкой форме
11. Добавить лабораторию
12. Изменить местоположение лаборатории
13. Удалить лаборатории из определенного города
14. Вывести список ученых по имеющимся инициалам

-----
15. Удалить животных, которые болеют определенным заболеванием.
Введите номер команды:
        """)
        try:
            a = int(input())
            if 0 <= a <= len(self.commands):
                self.commands[a]()
            else:
                raise Exception
        except:
            print("Некорректный ввод!")
    
    def quit(self):
        self.exit = True

    def wait_next(self):
        print("Нажмите любую клавишу чтобы продолжить:")
        input()

    def print_result(self, res):
        if res is not None:
            print("Результат: ", res)
            self.wait_next()

    def print_result_table(self, res):
        if res is not None:
            print("Результат:")
            for r in res:
                print(r)
            self.wait_next()
        
    def execute(self, f, arg1=None, arg2=None, arg3=None, arg4=None, arg5=None):
        try:
            if arg1 is None:
                return f()
            elif arg2 is None:
                return f(arg1)
            elif arg3 is None:
                return f(arg1, arg2)
            elif arg4 is None:
                return f(arg1, arg2, arg3)
            elif arg5 is None:
                return f(arg1, arg2, arg3, arg4)
            else:
                return f(arg1, arg2, arg3, arg4, arg5)
        except (Exception) as e:
            print("Ошибка при работе с базой данных: ", e)
        return None
        
    def get_amount_dead_animals_for_sc_in_lab(self):
        l_name = input("Введите название лаборатории: ")
        res = self.execute(self.db.get_amount_dead_animals_for_sc_in_lab, l_name)
        self.print_result(res)
        
    def get_info_about_res_and_scientists_for_animal(self):
        try:
            a_id = int(input("Введите идентификатор животного: "))
            res = self.execute(self.db.get_info_about_res_and_scientists_for_animal, a_id)
            self.print_result_table(res)
        except BaseException:
            print("Индентификатор питомца должен быть целым числом")
            
    def get_scientist_with_max_amount_of_researches(self):
        res = self.execute(self.db.get_scientist_with_max_amount_of_researches)
        self.print_result_table(res)
        
    def find_scientist_animals_amount(self):
        surname = input("Введите фамилию ученого: ")
        name = input("Введите имя ученого: ")
        second_name = input("Введите отчество ученого: ")
        species = input("Введите вид животных, количество которых нужно найти: ")
        res = self.execute(self.db.get_scientist_animals_amount, surname, name, second_name, species)
        self.print_result(res)
        
    def find_animals_and_res_by_city(self):
        city = input("Введите название города: ")
        res = self.execute(self.db.get_animals_and_res_by_city, city)
        self.print_result_table(res)

    def create_json(self):
        self.execute(self.db.create_new_animals_json)
        print("Файл json успешно создан!")
    
    def read_json(self):
        try:
            res = self.execute(self.db.read_from_json)
            self.print_result_table(res)
        except BaseException as e:
            print("Произошла ошибка, ", e)
    
    def update_json(self):
        try:
            a_id = int(input("Введите идентификатор животного, имя которого нужно изменить: "))
            new_name = input("Введите новую кличку животного: ")
            res = self.execute(self.db.update_json, a_id, new_name)
            self.print_result_table(res)
        except ValueError:
            print("Ошибка, идентификатор животного - целое число")
        except BaseException as e:
            print("Произошла ошибка, ", e)

    def get_ill_animals(self):
        res = self.execute(self.db.get_ill_animals)
        self.print_result_table(res)
    
    def get_res_info(self):
        try:
            l_name = input("Введите название лаборатории: ")
            degree = input("Введите ученую степень: ")
            res = self.execute(self.db.get_researches_with_dead_animals, l_name, degree)
            self.print_result_table(res)
        except BaseException as e:
            print(e)

    def create_lab(self):
        try:
            l_name = input("Введите имя лаборатории: ")
            sponsored_by_gov = 'yes' == input("Спонсируется ли лаборатория государством? (введите yes, если да) ")
            city = input("Введите название города: ")
            country = input("Введите название страны: ")
            est_year = int(input("Введите год основания лаборатории (от 1600 до 2020): "))
            if not 1600 <= est_year <= 2020:
                raise ValueError
            res = self.execute(self.db.add_laboratory, l_name, sponsored_by_gov, city, country, est_year)
            self.print_result_table(res)
        except BaseException:
            print("Некорректные данные")
    
    def update_lab(self):
        l_name = input("Введите имя лаборатории: ")
        city = input("Введите новое название города: ")
        country = input("Введите новое название страны: ")
        res = self.execute(self.db.update_placement, l_name, city, country)
        self.print_result_table(res)
    
    def delete_labs(self):
        city = input("Введите название города: ")
        res = self.execute(self.db.delete_labs_from_city, city)
        self.print_result_table(res)
    
    def get_scientists_by_initials(self):
        surname = input("Введите известную часть фамилии ученого: ")
        name = input("Введите часть имени ученого: ")
        second_name = input("Введите часть отчества ученого: ")
        res = self.execute(self.db.get_scientist_by_initials, surname, name, second_name)
        self.print_result_table(res)


    
if __name__ == '__main__':
    u = UI()
