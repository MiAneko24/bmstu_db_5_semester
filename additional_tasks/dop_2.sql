with prepare as
(
select fio, date, status,
lag(status, 1, status) over (partition by fio order by date) as prev_status,
lag(date, 1, date) over (partition by fio, status order by date) as prev_day,
max(date) over (partition by fio) as last_day
from emplvisits
)
select fio, date as datefrom,
lead(date - 1, 1, last_day) over (partition by fio order by date) as dateto,
status
from prepare
where status != prev_status or date = prev_day;

-- За этот запрос спасибо IThror10 c:
