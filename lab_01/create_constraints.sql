

alter table labResearches.Laboratories
    add constraint establich_year_range check(
        establish_year >= 1600
        and establish_year <= 2020
    );

alter table labResearches.Scientists
    add  constraint age_range check(
        age >= 16
        and age <= 100
    );

alter table labResearches.Scientists
    add constraint fk_lab foreign key(lab_name) references labResearches.Laboratories(lab_name);

alter table labResearches.Animals
    add constraint a_name_check check(
        a_name ~ '\D+'
    );

alter table labResearches.Animals
    add constraint fk_an_lab foreign key(lab_name) references labResearches.Laboratories(lab_name);

alter table labResearches.Animals
    add constraint animal_age_range check(
        age >= 0
        and age <= 100
    );

alter table labResearches.Animals
    add constraint generation_range check(
        research_generation >= 1
        and research_generation <= 10
    );

alter table labResearches.Researches
    add constraint fk_res_s foreign key(s_surname, s_name, s_second_name) references labResearches.Scientists(s_surname, s_name, s_second_name);

alter table labResearches.Researches
    add constraint fk_res_a foreign key(a_id) references labResearches.Animals(a_id);

alter table labResearches.Researches
    add constraint fk_res_lab foreign key(lab_name) references labResearches.Laboratories(lab_name);

alter table labResearches.Researches
    add constraint start_year_range check(
        start_year >= 1600
        and start_year <= 2021
    );