truncate table labResearches.Researches, labResearches.Animals, labResearches.Scientists;

alter table labResearches.Animals add
    s_surname surname_domain;

alter table labResearches.Animals add
    s_name name_domain;

alter table labResearches.Animals add
    s_second_name name_domain;

alter table labResearches.Scientists add
    has_pets bool;


-- update labResearches.Scientists set has_pets=True;

-- update labResearches.Animals set s_surname='Модестова', s_name='Клара', s_second_name='Семёновна';

copy labResearches.Scientists
    from '/home/extended_scientists.txt';

copy labResearches.Animals
    from '/home/extended_animals.txt';

copy labResearches.Researches
    from '/home/researches.txt';

alter table labResearches.Animals 
    add constraint fk_scientists foreign key(s_surname, s_name, s_second_name) 
    references labResearches.Scientists(s_surname, s_name, s_second_name);

