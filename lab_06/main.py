import psycopg2
from psycopg2 import Error

class Database:
    def __init__(self):
        self.__error = None
        try:
            self.__connection = psycopg2.connect(user="code",
                                                password="vscode",
                                                host="172.17.0.2",
                                                port="5432",
                                                database="db_labs")
            self.__cursor = self.__connection.cursor()
            print("Connection with database was opened successfully!")
        except (Exception, Error) as e:
            self.__error = e
    
    @property
    def error(self):
        return self.__error

    def __del__(self):
        print("Connection with database is closed!")
        self.__connection.close()

    def __exec(self, query, commit=False):
        self.__cursor.execute(query)
        if commit:
            self.__connection.commit()
            print("Successfully committed!")
        try:
            return self.__cursor.fetchall()
        except:
            pass
    
    # количество животных ученого
    def get_scientist_animals_amount(self, surname, name, second_name):
        self.__cursor.execute(f"""
        select count(*)
        from labresearches.animals
        where s_surname = '{surname}' and s_name = '{name}' and s_second_name = '{second_name}'
        """)
        return self.__cursor.fetchone()[0]

    def get_researches_and_scientists_by_country(self, country):
        self.__cursor.execute(f"""
        select r.r_name, r.science_field, s.s_surname, 
        s.s_name, s.s_second_name, s.degree, s.profession, l.lab_name, l.city, l.country
        from (labresearches.laboratories l join labresearches.scientists s on l.lab_name =s.lab_name)
		join labresearches.researches r 
		on s.s_surname = r.s_surname and s.s_name = r.s_name and s.s_second_name = r.s_second_name 
        where l.country = '{country}'
        """)
        return self.__cursor.fetchall()
    
    def get_amount_same_names_for_city(self):
        self.__cursor.execute("""
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
        """)
        return self.__cursor.fetchall()

    def get_tables_and_sizes(self):
        self.__cursor.execute("""        
        select tablename , pg_relation_size(schemaname||'.'||tablename)/1024 as size_Kb
        from pg_catalog.pg_tables pt 
        where pt.schemaname ='labresearches'
        """)
        return self.__cursor.fetchall()

    def get_avg_age(self):
        self.__cursor.execute("""
        select labresearches.getAvgScientistsAge() as average
        """)
        return self.__cursor.fetchone()[0]

    def get_sazans(self):
        self.__cursor.execute("""
        select * from labresearches.getSazans()
        """)
        return self.__cursor.fetchall()

    def correct_owners(self):
        self.__exec("""
        call labresearches.correct_owners_list();
        """, True)

    def get_server_pid(self):
        self.__cursor.execute("select pg_backend_pid() as pid")
        return self.__cursor.fetchone()[0]

    def create_lab_scientists_archive(self):
        self.__exec("""
                    drop table if exists labresearches.archive;
                    create table labresearches.archive(
                        lab_name name_domain,
                        s_surname surname_domain,
                        s_name name_domain,
                        s_second_name name_domain,
                        hire_date date,
                        dismissal_date date
                    );
                    """, True)
    
    def insert_into_scientists_archive(self):
        self.__exec("""
        insert into labresearches.archive values
        ('Лаборатория при университете Шеньян', 'Савелиев', 'Константин', 'Гавриилович', '2008-09-12', '2012-03-21'),
        ('Лаборатория 592', 'Лавров', 'Измаил', 'Тристанович', '1999-01-01', '2019-12-12'),
        ('Лаборатория им. Наркисов', 'Эдуардова', 'Изабелла', 'Марковна', '1980-12-31', '2020-05-15'),
        ('Лаборатория при университете Чиангмай', 'Глебова', 'Матильда', 'Степановна', '1971-06-11', '1985-02-28')
        """, True)
    
    def get_archive(self):
        self.__cursor.execute("select * from labresearches.archive;")
        return self.__cursor.fetchall()

    def delete_species(self, spec):
        self.__exec(f"delete from labresearches.researches r where a_id in (select a_id from labresearches.animals a where species = '{spec}');", True)
        self.__exec(f"delete from labresearches.animals where species = '{spec}'", True)

    #queries time

class UI:
    def __init__(self):
        self.exit=False
        self.db = Database()
        self.error = self.db.error
        self.commands = [self.quit,
        self.find_scientist_animals_amount,
        self.find_researches_and_scientists_by_country,
        self.find_amount_same_names_for_labs,
        self.find_tables_and_sizes,
        self.find_avg_age,
        self.find_sazans,
        self.update_scientists_owners,
        self.find_pid,
        self.create_table,
        self.fill_table,
        self.show_table,
        self.delete_spec]
        if self.error is None:
            while not self.exit:
                self.menu()
        else:
            self.db_error()
        
    def db_error(self):
        print(f"Не удалось подключиться к базе данных: {self.error}")

    def menu(self):
        print("""
Программа для работы с базой данных исследований
0. Завершить работу.
1. Вывести количество животных ученого
2. Вывести исследования, ученых, их ученые степени, профессии 
для лабораторий заданной страны
3. Вывести среднее количество здоровых животных
с одинаковыми кличками в городах
4. Получить все таблицы основной схемы и их размер
5. Вывести средний возраст ученых
6. Получить идентификатор и кличку сазанов, у владельцев 
которых есть питомцы только такого же вида
7. Обновить статус наличия питомца ученых, у которых не нашлось питомцев
в таблице животных, сохранить ФИО во временной таблице
8. Получить код серверного процесса, обслуживающего текущий сеанс
9. Создание архивной таблицы, содержащей сроки работы ученого в иных лабораториях
10. Вставка данных в созданную таблицу с insert
11. Показать созданную таблицу
12. Удалить всех животных заданного вида

Введите номер команды:
        """)
        try:
            a = int(input())
            if 0 <= a <= 12:
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
        
    def execute(self, f, arg1=None, arg2=None, arg3=None):
        try:
            if arg1 is None:
                return f()
            elif arg2 is None:
                return f(arg1)
            elif arg3 is None:
                return f(arg1, arg2)
            else:
                return f(arg1, arg2, arg3)
        except (Exception) as e:
            print("Ошибка при работе с базой данных: ", e)
        return None
    
    def find_scientist_animals_amount(self):
        surname = input("Введите фамилию ученого: ")
        name = input("Введите имя ученого: ")
        second_name = input("Введите отчество ученого: ")
        res = self.execute(self.db.get_scientist_animals_amount, surname, name, second_name)
        self.print_result(res)

    def find_researches_and_scientists_by_country(self):
        country = input("Введите название страны: ")
        res = self.execute(self.db.get_researches_and_scientists_by_country, country)
        self.print_result_table(res)
    
    def find_amount_same_names_for_labs(self):
        res = self.execute(self.db.get_amount_same_names_for_city)
        self.print_result(res)

    def find_tables_and_sizes(self):
        res = self.execute(self.db.get_tables_and_sizes)
        self.print_result_table(res)

    def find_avg_age(self):
        res = self.execute(self.db.get_avg_age)
        self.print_result(res)
    
    def find_sazans(self):
        res = self.execute(self.db.get_sazans)
        self.print_result_table(res)
    
    def update_scientists_owners(self):
        self.execute(self.db.correct_owners)

    def find_pid(self):
        res = self.execute(self.db.get_server_pid)
        self.print_result(res)
    
    def create_table(self):
        self.execute(self.db.create_lab_scientists_archive)
    
    def fill_table(self):
        self.execute(self.db.insert_into_scientists_archive)

    def show_table(self):
        res = self.execute(self.db.get_archive)
        self.print_result_table(res)

    def delete_spec(self):
        spec = input("Введите вид животных: ")
        self.execute(self.db.delete_species, spec)

if __name__ == '__main__':
    UI()


#Защита - 12 пункт: ввод типа животных для удаления
