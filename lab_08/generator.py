from time import sleep
from random import randint, choice

def get_countries():
    f = open("/home/mianeko/university_stuff/bmstu_db_5_semester/lab_01/countries.txt", "r")
    countries = [cntry[:-1] for cntry in f.readlines()]
    f.close()

    return countries

def get_cities():
    f = open("/home/mianeko/university_stuff/bmstu_db_5_semester/lab_01/cities.txt", "r")
    cities = [city[:-1] for city in f.readlines()]
    f.close()
    return cities


def get_laboratories(lab_names, cities, countries, cnt):
    new_l_names = []
    laboratory = 'Лаборатория '
    while(len(new_l_names) < 3):
        name_type = randint(1, 2)
        lab_name = laboratory
        if name_type == 1:
            lab_name += str(randint(2001, 5000))
        elif name_type == 2:
            lab_name += "при университете " + choice(countries)
        if lab_name not in lab_names:
            lab_names.append(lab_name)
            new_l_names.append(lab_name)

    f = open("/home/mianeko/university_stuff/bmstu_db_5_semester/lab_08/src/new_labs" + str(cnt) + ".csv", "w")
    f.write('lab_name,sponsored_by_gov,city,country,establish_year\n')
    for i in range(len(new_l_names)):
        f.write(new_l_names[i] + "," + str(bool(randint(0, 1))) + "," + "Aaaa" + "," + choice(countries) + "," + str(randint(1600, 2020)) + "\n")
    f.close()
    print("Done")
    cnt+=1
    return lab_names, cnt

if __name__=="__main__":
    cities = get_cities()
    countries = get_countries()
    lab_names = []
    cnt = 0
    while(cnt < 10):
        lab_names, cnt = get_laboratories(lab_names, cities, countries, cnt)
        sleep(1)
