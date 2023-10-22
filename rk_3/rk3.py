from peewee import *
db = PostgresqlDatabase("db_labs", 
                        user="code",
                        password="vscode",
                        host="172.17.0.2",
                        port="5432")

class Driver(Model):
    DriverId = IntegerField(primary_key=True, column_name='driverid')
    DriverLicense = TextField(column_name='driverlicense')
    FIO = TextField(column_name='fio')
    Phone = TextField(column_name='phone')
        
    class Meta:
            database = db
            schema = 'rk3'
            table_name = 'drivers'

class Fine(Model):
    FineId = IntegerField(primary_key=True, column_name='fineid')
    DriverId  = ForeignKeyField(Driver, column_name='driverid', to_field='DriverId'),
    FineType = TextField(column_name='finetype')
    Amount = IntegerField(column_name='amount')
    FineDate = DateField(column_name='finedate')

    class Meta:
        database = db
        schema = 'rk3'
        table_name = 'fines'

class Car(Model):
    CarId = IntegerField(primary_key=True, column_name='carid')
    Model = TextField(column_name='model')
    Color = TextField(column_name='color')
    Year = TextField(column_name='year')
    RegistrationDate = DateField(column_name='registrationdate')

    class Meta:
        database = db
        schema = 'rk3'
        table_name = 'cars'

class DriverCar(Model):
    DriverId = ForeignKeyField(Driver, to_field='DriverId', column_name='driverid')
    CarId = ForeignKeyField(Car, to_field='CarId', column_name='carid')

    class Meta:
        database = db
        schema = 'rk3'
        table_name = 'driverscars'


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
    
    def get_fio_reg_sql(self):
        return self.__exec("""
        select FIO, RegistrationDate
        from rk3.drivers d join rk3.DriversCars dc on dc.DriverId=d.DriverId join rk3.cars c on dc.CarId=c.CarId
        """)

    def get_red_cars_own_sql(self):
        return self.__exec("""
        select DriverId, FIO, DriverLicense
        from rk3.drivers d 
        where DriverId in (select dc.DriverId
                            from rk3.DriversCars dc join rk3.cars c on c.CarId = dc.CarId
                            where c.Color = 'Red')
					""")

    def get_max_fine_am_sql(self):
        return self.__exec("""select FineType, max(Amount) as max_sum
            from rk3.fines
            group by FineType;
					""")
    
    def get_fio_reg(self):
        return Driver.select(Driver.FIO, Car.RegistrationDate).join(DriverCar, on=(DriverCar.DriverId==Driver.DriverId)).join(Car, on=(Car.CarId==DriverCar.CarId)).tuples()

    def get_red_cars_own(self):
        return Driver.select(Driver.DriverId, Driver.FIO, Driver.DriverLicense).where(Driver.DriverId.in_(DriverCar.select(DriverCar.DriverId).join(Car,on=(Car.CarId==DriverCar.CarId)).where(Car.Color == 'Red'))).tuples()

    def get_max_fine(self):
        return Fine.select(Fine.FineType, fn.max(Fine.Amount)).group_by(Fine.FineType).tuples()
    
class UI:
    def __init__(self):
        self.exit=False
        self.db = Database()
        self.error = self.db.error
        self.commands = [self.quit,
        self.get_fio_reg_sql,
        self.get_red_cars_own_sql,
        self.get_max_fine_am_sql,
        self.get_fio_reg, 
        self.get_red_cars_own,
        self.get_max_fine_am]
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

    def menu(self):
        print("""
Программа для работы с базой данных
0. Завершить работу.

--SQL
1. Найти все пары вида ФИО, дата регистрации авто
2. Найти водителей, у которых есть хотя бы 1 машина красного цвета
3. Для каждого типа нарушения вычислить сумму максимального выписанного штрафа

--peewee
4. Найти все пары вида ФИО, дата регистрации авто
5. Найти водителей, у которых есть хотя бы 1 машина красного цвета
6. Для каждого типа нарушения вычислить сумму максимального выписанного штрафа
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
    
    def get_fio_reg_sql(self):
        res = self.execute(self.db.get_fio_reg_sql)
        self.print_result_table(res)

    def get_red_cars_own_sql(self):
        res = self.execute(self.db.get_red_cars_own_sql)
        self.print_result_table(res)

    def get_max_fine_am_sql(self):
        res = self.execute(self.db.get_max_fine_am_sql)
        self.print_result_table(res)

    def get_fio_reg(self):
        res = self.execute(self.db.get_fio_reg)
        self.print_result_table(res)

    
    def get_red_cars_own(self):
        res = self.execute(self.db.get_red_cars_own)
        self.print_result_table(res)

    def get_max_fine_am(self):
        res = self.execute(self.db.get_max_fine)
        self.print_result_table(res)


    
if __name__ == '__main__':
    u = UI()
