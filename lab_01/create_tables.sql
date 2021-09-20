
create schema labResearches;
create domain name_domain as varchar
check(
    value ~ '[А-Я, Ё, A-Z]{1}[а-я, ё, a-z]+'
);

create domain surname_domain as varchar
check(
    value ~ '[А-Я, Ё, A-Z]{1}[а-я, ё, a-z]+(\-[А-Я, Ё, A-Z]{1}[а-я, ё, a-z]+)?'
);
create domain phone_number_domain as varchar(11)
check(
    value ~ '\+{1}\d+'
);
create domain science_field_domain as varchar
check(
    value ~ '[А-Я, Ё, A-Z]{1}[а-я, ё, a-z]+( [а-я, ё, a-z]+)?'
);
create domain countries_and_cities_domain as varchar
check(
    value ~ '\D+'
);
create table labResearches.Laboratories(
    lab_name varchar primary key,
    sponsored_by_gov boolean not null,
    country countries_and_cities_domain not null,
    city countries_and_cities_domain not null,
    establish_year int not null
);
create table labResearches.Scientists(
    s_surname surname_domain not null,
    s_name name_domain not null,
    s_second_name name_domain not null,
    age int not null,
    gender name_domain not null,
    lab_name varchar not null,
    profession varchar,
    degree varchar,
    phone_number phone_number_domain,
    primary key(s_surname, s_name, s_second_name)
);
create table labResearches.Animals(
    a_id int primary key,
    a_name varchar,
    lab_name varchar not null,
    species name_domain not null,
    age int not null,
    gender name_domain not null,
    health_state varchar not null,
    research_generation int
);
create table labResearches.Researches(
    s_surname surname_domain not null,
    s_name name_domain not null,
    s_second_name name_domain not null,
    a_id int not null,
    lab_name varchar not null,
    foreign key(lab_name) references labResearches.Laboratories(lab_name),
    science_field science_field_domain not null,
    r_name varchar not null,
    start_year int not null,
    primary key(s_surname, s_name, s_second_name, a_id)
);