from os import name
from random import choice, random, randrange, randint

vowels = ['ё', 'у', 'е', 'ы', 'а', 'о', 'э', 'я', 'и', 'ю']
illnesses = ['тахикардия', 'астма', 'ОРВИ', '<неизвестная болезнь>', 'COVID-19', 'туберкулез', 'вич', 'рак']

max_amount_per_lab = 25
min_amount_per_lab = 5
max_amount = 1000

def get_women_names():
    f = open("women_names.txt", "r")
    women_names = [name[:-1] for name in f.readlines()]
    f.close()
    return women_names

def get_men_names():
    f = open("men_names.txt", "r")
    men_names = [name[:-1] for name in f.readlines()]
    f.close()
    return men_names

def get_men_surnames(men_names):
    surnames = []
    for name in men_names:
        if name[-1] == 'й' or name[-1] == 'ь':
            surnames.append(name[:-1] + "ев")
        elif name[-1] in vowels:
            surnames.append(name[:-1] + 'ин')
        else:
            surnames.append(name + 'ов')
    return surnames

def get_women_surnames(surnames):
    women_surnames = []
    for surname in surnames:
        women_surnames.append(surname + 'а')
    return women_surnames

def get_men_second_names(men_names):
    men_second_names = []
    for name in men_names:
        if name[-1] == 'й' or name[-1] == 'ь':
            men_second_names.append(name[:-1] + "евич")
        elif name[-1] in vowels:
            men_second_names.append(name[:-1] + 'ич')
        else:
            men_second_names.append(name + 'ович')
        
    return men_second_names

def get_women_second_names(men_names):
    women_second_names = []    

    for name in men_names:
        if name[-1] == 'й' or name[-1] == 'ь':
            women_second_names.append(name[:-1] + "евна")
        elif name[-1] in vowels:
            women_second_names.append(name[:-1] + 'ична')
        else:
            women_second_names.append(name + 'овна')
    return women_second_names

def generate_phone_number():
    phone_num = "+" + str(randrange(10 ** 9, 10 ** 10))
    return phone_num


def generate_scientists(men_surnames, men_names, laboratory, fio_list):
    women_surnames = get_women_surnames(men_surnames)
    women_names = get_women_names()
    women_second_names = get_women_second_names(men_names)
    men_second_names = get_men_second_names(men_names)

    fios = []

    amount = randint(min_amount_per_lab, max_amount_per_lab)
    gender = ["Женский", "Мужской"]
    degree = ['Бакалавр', 'Магистр', 'Специалист', 'Аспирант', 'Кандидат наук', 'Доктор наук']
    f = open("professions.txt", "r")
    professions = [prof[:-1] for prof in f.readlines()]
    f.close()
    i = 0
    f = open("scientists.txt", "a")
    while(i < amount):
        scientist_gender = choice(gender)
        if scientist_gender == "Женский":
            fio = choice(women_surnames) + "\t" + choice(women_names) + "\t" + choice(women_second_names)
        else:
            fio = choice(men_surnames) + "\t" + choice(men_names) + "\t" + choice(men_second_names)
        if fio in fio_list or fio in fios:
            continue
        fios.append(fio)
        f.write(fio + "\t" + str(randint(16, 100)) + "\t" + scientist_gender + "\t" + laboratory + "\t" + \
            choice(professions) + "\t" + choice(degree) + "\t" + generate_phone_number() + "\n")
        i += 1
    f.close()
    return fios

def get_animal_species():
    f = open("animal_species.txt", "r")
    species_file = f.readlines()
    f.close()
    species = []
    for i in range(len(species_file)):
        if i % 2 == 0:
            species.append([species_file[i][:-1]])
        else:
            species[-1].append(int(species_file[i][:-1]))
        
    return species


def generate_animals(lab, numbers):
    species = get_animal_species()
    health = ['Здоров', 'Болеет', 'Умер']
    illness_forms = ['(легкая форма)', '(средняя форма)', '(тяжелая форма)']
    gender = ['Женский', "Мужской"]
    f = open("animal_names.txt", "r")
    names = [name[:-1] for name in f.readlines()]
    f.close()
    f = open("animals.txt", "a")
    i = 0
    nums = []
    amount = randint(min_amount_per_lab, max_amount_per_lab)
    while (i < amount):
        number = randrange(1, 100000)
        if number in numbers or number in nums:
            continue
        nums.append(number)
        spec = choice(species)
        age = randint(0, spec[1])
        health_state = choice(health)
        if health_state == 'Болеет':
            health_state += " " + choice(illnesses) + " " + choice(illness_forms)
        f.write(str(number) + "\t" + choice(names) + "\t" + lab + "\t" + spec[0] + "\t" + str(age) + "\t" + choice(gender) + "\t" + health_state + "\t" + str(randint(1, 10)) + "\n")
        i += 1
    return nums

def get_science_fields():
    f = open("science_fields.txt", "r")
    fields = [field[:-1] for field in f.readlines()]
    return fields

def get_research(animal_numbers, scientists, lab):
    science_fields = get_science_fields()
    names = ['Исследование болезни', 'Разработка лекарства от', "Исследование в сфере"]
    i = 0
    pairs = []
    f = open("researches.txt", "a")
    amount = randint(1, len(animal_numbers) * len(scientists))
    while i < amount:
        pair = [choice(scientists), choice(animal_numbers)]
        if pair in pairs:
            continue
        pairs.append(pair)
        field = choice(science_fields)
        name = choice(names)
        if name == 'Исследование в сфере':
            name += " " + field
        else:
            name += " " + choice(illnesses)
        year = randrange(1600, 2020)
        f.write(pair[0] + "\t" + str(pair[1]) + "\t" + lab + "\t" + field + "\t" + name + "\t" + str(year) + "\n")
        i += 1
    f.close()



def get_countries():
    f = open("countries.txt", "r")
    countries = [cntry[:-1] for cntry in f.readlines()]
    f.close()

    return countries

def get_cities():
    f = open("cities.txt", "r")
    cities = [city[:-1] for city in f.readlines()]
    f.close()
    return cities

def get_laboratories():
    lab_names = []
    laboratory = 'Лаборатория '
    while(len(lab_names) < max_amount):
        name_type = randint(1, 3)
        lab_name = laboratory
        if name_type == 1:
            lab_name += str(randint(1, 2000))
        elif name_type == 2:
            lab_name += "при университете " + choice(cities)
        else:
            lab_name += "им. " + choice(surnames)
        if lab_name not in lab_names:
            lab_names.append(lab_name)

    f = open("laboratories.txt", "a")
    for i in range(len(lab_names)):
        f.write(lab_names[i] + "\t" + str(bool(randint(0, 1))) + "\t" + choice(cities) + "\t" + choice(countries) + "\t" + str(randint(1600, 2020)) + "\n")
    f.close()
    return lab_names

def clear_files():
    f = open("laboratories.txt", "w")
    f.close()

    f = open("scientists.txt", "w")
    f.close()

    f = open("animals.txt", "w")
    f.close()

    f = open("researches.txt", "w")
    f.close()


clear_files()
countries = get_countries()
cities = get_cities()
men_names = get_men_names()
surnames = get_men_surnames(men_names)
laboratories = get_laboratories()
fio = []
animals = []
numbers = []
fio_list = []
i = 0
for lab in laboratories:
    print("turn of lab ", i)
    fio = generate_scientists(surnames, men_names, lab, fio_list)
    animals = generate_animals(lab, numbers)
    numbers.extend(animals)
    fio_list.extend(fio)
    get_research(animals, fio, lab)
    i += 1


# f = fopen()

