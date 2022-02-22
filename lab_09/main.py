
from peewee import *
import time
import redis
from random import choice, randint
import matplotlib.pyplot as plt

db = PostgresqlDatabase("db_labs", 
                        user="code",
                        password="vscode",
                        host="172.17.0.2",
                        port="5432")

r = redis.Redis('localhost')
cached_key = 'cached'
TTL = 9

a_ids = [3768, 64820, 69853, 88229, 93870, 73820, 1998, 91800, 67179, 62339, 87793, 89274, 10493, 4427, 10493]


def db_request():
    return db.execute_sql("""select a_id, sum(points) as s
from labresearches.battles
group by a_id
order by s desc 
limit 10;""").fetchall()


def redis_request():
    value = r.get(cached_key)
    if value is None:
        value = db_request()
        value = str(value)
        r.set(cached_key, value)
        r.expire(cached_key, time=TTL)
    else:
        value.decode()

    return value


def insert():
    db.execute_sql(f"""
    insert into labresearches.battles(a_id, points)
    values ({choice(a_ids)}, {randint(10, 10000)});""")
    db.commit()


def update():
    db.execute_sql(f"""
    update labresearches.battles
    set points= points+100
    where b_id={randint(1, 3000)};""")
    db.commit()


def delete():
    db.execute_sql(f"""delete from labresearches.battles
    where b_id = (select max(b_id) from labresearches.battles);""")
    db.commit()


def measure(f):
    t1 = time.time()
    f()
    t2 = time.time()
    return t2 - t1


if __name__ == '__main__':
    func = insert

    counter = 0
    time_cached = []
    time_uncached = []

    minutes_wait = 0.5
    iterations = int(minutes_wait * 60) // 5
    x = []
    for i in range(iterations):
        if i % 2:
            if func:
                func()

        time_cached.append(measure(redis_request))
        time_uncached.append(measure(db_request))
        x.append(i*5)
        time.sleep(5)

    print(time_cached)
    print(time_uncached)
    plt.plot(x, time_cached, label="Redis")
    plt.plot(x, time_uncached, label="Postgresql")
    plt.legend(loc="upper left")
    plt.show()
    db.close()