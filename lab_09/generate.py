from peewee import *
from random import choice, randint
db = PostgresqlDatabase("db_labs", 
                        user="code",
                        password="vscode",
                        host="172.17.0.2",
                        port="5432")


a_ids = [3768, 64820, 69853, 88229, 93870, 73820, 1998, 91800, 67179, 62339, 87793, 89274, 10493, 4427, 10493]
for i in range(4000):
    db.execute_sql(f"""
        insert into labresearches.battles(a_id, points)
        values ({choice(a_ids)}, {randint(10, 10000)});""")
    db.commit()

