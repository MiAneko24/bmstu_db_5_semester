
from os import write
from random import choice, random, randrange, randint

def additional_data_for_scientists():
    f = open("scientists.txt", "r")
    fio_from_file = [fio[:-1] for fio in f.readlines()]
    fios = [fio.split("\t")[:3] for fio in fio_from_file]
    f.close()
    f = open("extended_scientists.txt", "w")
    for i in range(len(fios)):
        fios[i].append(bool(randint(0, 1)))
        f.write(fio_from_file[i] + "\t" + str(fios[i][3]) + "\n")
    
    f.close()
    fios_new = [fio for fio in fios if fio[3]]
    return fios

def get_animals_id():
    f = open("animals.txt", "r")
    old_data = [an[:-1] for an in f.readlines()]
    ids = [a.split("\t")[:1] for a in old_data]
    f.close()
    return ids, old_data

def get_owners(s_names, animals, old_data):
    for animal in animals:
        animal.extend(choice(s_names))
    f = open("extended_animals.txt", "w")
    for i in range(len(animals)):
        f.write(old_data[i] + "\t" + animals[i][1] + "\t" + animals[i][2]+ "\t" + animals[i][3]+ "\n")
    f.close()

s_names = additional_data_for_scientists()
animals, old_data = get_animals_id()
get_owners(s_names, animals, old_data)
