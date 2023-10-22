import collections
from re import S
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
    s_surname = ForeignKeyField(Scientist, field='s_surname')
    s_name = ForeignKeyField(Scientist, field='s_name')
    s_second_name = ForeignKeyField(Scientist, field='s_second_name')

    class Meta:
        database = db
        schema = 'labresearches'
        table_name = 'animals'

class Research(Model):
    s_surname = ForeignKeyField(Scientist, to_field='s_surname', field='s_surname')
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
        table_name = 'animals'
    
l = Scientist.select().where(Scientist.s_surname=='Ff').objects()
for r in l:
    print(Scientist.delete().where(Scientist.s_surname == r.s_surname).execute())

# for r in l:
    # print(r['s_surname'])
# m = Scientist.create(s_surname='Ff', s_name='Ff', gender='Женский', s_second_name='Ff', age=17, lab_name='Лаборатория 621', degree='Бакалавр', phone_number='+7823747432', has_pets=True)
# m.save()
# m.save()
# print(m.s_name)