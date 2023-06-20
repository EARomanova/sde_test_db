create table public.results (id INT, response text);


-- 1. Вывести максимальное кол-во человек в одном бронировании 

insert into results
select 1 as id, max(cnt_pass) as response 
	from (
		select 
			count(t.passenger_id) as cnt_pass, 
			b.book_ref 
		from 
			bookings b
		left join 
			tickets t 
			on t.book_ref = b.book_ref 
		group by b.book_ref ) as t1 ;
commit;
	
-- 2. Вывести количество бронирований с количеством людей больше среднего значения людей на одно бронирование

insert into results
with counter as 
(
select 
	count(t.passenger_id) as cnt_pass, 
	b.book_ref 
from 
	bookings b
left join 
	tickets t 
	on t.book_ref = b.book_ref 
group by 
	b.book_ref 
)
select 
	2 as id, count(book_ref) as response
from 
	counter 
where 
	cnt_pass > (select avg(cnt_pass) as avg_pass from counter);
commit;


-- 3. Вывести количество бронирований, у которых состав пассажиров повторялся два и более раза, среди бронирований с максимальным количеством людей (п.1)?

insert into results
with counter as 
	(
	select 
		count(t.passenger_id) as cnt_pass, 
		b.book_ref 
	from bookings b
	left join tickets t 
		on t.book_ref = b.book_ref 
	group by b.book_ref 
	), 
t2 as 
	(
	select 
		c.book_ref, 
		t.passenger_id
	from counter c, tickets t
	where cnt_pass = (select max(cnt_pass) as max_pass from counter)
		and c.book_ref = t.book_ref
		) 
select 
	3 as id, 
	count(t.book_ref) as response
from tickets t 
inner join t2 
	on t.book_ref != t2.book_ref
	and t.passenger_id = t2.passenger_id
having count(t.book_ref) >0;
commit;

-- 4. Вывести номера брони и контактную информацию по пассажирам в брони (passenger_id, passenger_name, contact_data) с количеством людей в брони = 3

insert into results
with counter as (
	select 
		count(t.passenger_id) as cnt_pass, 
		b.book_ref 
	from bookings b
	left join tickets t 
	on t.book_ref = b.book_ref 
	group by b.book_ref 
	)
select 4 as id, t.book_ref||'|'|| t.passenger_id||'|'||t.passenger_name||'|'||t.contact_data as response
from tickets t
inner join counter c
	on t.book_ref = c.book_ref
	and c.cnt_pass = 3
order by t.book_ref, t.passenger_id,t.passenger_name,t.contact_data ;
commit;

-- 5. Вывести максимальное количество перелётов на бронь

insert into results
with counter_fligts as (
	select 
		b.book_ref,
		count(tf.flight_id) as flights_cnt
	from bookings b
	left join tickets t 
		on t.book_ref = b.book_ref 
	left join ticket_flights tf 
		on t.ticket_no = tf.ticket_no 
	group by b.book_ref
	)
select 5 as id, 
	   max(flights_cnt) as response 
from counter_fligts;
commit;

-- 6. Вывести максимальное количество перелётов на пассажира в одной брони

insert into results
with counter_fligts as (
	select 
		b.book_ref,
		t.passenger_id,
		count(tf.flight_id) as flights_cnt
	from bookings b
	left join tickets t 
		on t.book_ref = b.book_ref 
	left join ticket_flights tf 
		on t.ticket_no = tf.ticket_no 
	group by b.book_ref, t.passenger_id
	)
select 6 as id, 
	   max(flights_cnt) as response 
from counter_fligts;
commit;

-- 7. Вывести максимальное количество перелётов на пассажира

insert into results
with counter_fligts as (
	select 
		t.passenger_id,
		count(tf.flight_id) as flights_cnt
	from tickets t 
	left join ticket_flights tf 
	on t.ticket_no = tf.ticket_no 
	group by t.passenger_id
	)
select 7 as id, 
	   max(flights_cnt) as response 
from counter_fligts;
commit;

-- 8. Вывести контактную информацию по пассажиру(ам) (passenger_id, passenger_name, contact_data) и общие траты на билеты, для пассажира потратившему 
-- минимальное количество денег на перелеты

insert into results
with fligts_amount as (
	select 
		t.passenger_id,
		sum(tf.amount) as flight_amount
	from tickets t 
	left join ticket_flights tf 
	on t.ticket_no = tf.ticket_no 
	group by t.passenger_id
	) 
select 
	8 as id, 
	concat_ws('|',f.passenger_id, t.passenger_name, t.contact_data, f.flight_amount) as response 
from fligts_amount f 
join tickets t 
	on f.passenger_id = t.passenger_id
where f.flight_amount = (select min(flight_amount) from fligts_amount)
order by f.passenger_id, t.passenger_name, t.contact_data, f.flight_amount;
commit;

-- 9. Вывести контактную информацию по пассажиру(ам) (passenger_id, passenger_name, contact_data) и общее время в полётах, для пассажира, который провёл максимальное время 
-- в полётах

insert into results
with flight_duration as (
	select 
		t.passenger_id ,
		sum(fv.actual_duration) as flight_dur
	from flights_v fv  
	join ticket_flights tf 
		on fv.flight_id = tf.flight_id 
	join tickets t 
		on t.ticket_no = tf.ticket_no 
	group by t.passenger_id 
	)
select 
	9 as id, 
		concat_ws('|',fd.passenger_id, t.passenger_name, t.contact_data, fd.flight_dur) as response 
from flight_duration fd
join tickets t 
	on fd.passenger_id = t.passenger_id
where fd.flight_dur = (select max(flight_dur) from flight_duration)
order by fd.passenger_id, t.passenger_name, t.contact_data, fd.flight_dur;
commit;

-- 10. Вывести город(а) с количеством аэропортов больше одного

insert into results
select 10 as id, city as response
from airports a 
group by city
having count(airport_code)>1
order by city;
commit;

-- 11. Вывести город(а), у которого самое меньшее количество городов прямого сообщения

insert into results
with all_flights as  
	(
	select distinct 
		departure_airport as airp1,
		arrival_airport as airp2
	from flights f 
	union 
	select distinct 
		arrival_airport as airp1,
		departure_airport as airp2
	from flights f 
	order by 1,2
	) , 
t2 as (
	select 
		a.city, 
		count(a.city) as city_cnt
	from all_flights af
	left join airports a 
		on a.airport_code = af.airp1
	group by a.city
	) 
select 
	11 as id, 
	city as response
from t2
where city_cnt = (select min(city_cnt) from t2);
commit;

-- 12. Вывести пары городов, у которых нет прямых сообщений исключив реверсные дубликаты

insert into results
-- определяем все существующие перелеты туда-обратно
with all_flights as (
	select distinct 
		departure_airport as airp1,
		arrival_airport as airp2
	from flights f 
	union 
	select distinct 
		arrival_airport as airp1,
		departure_airport as airp2
	from flights f 
	order by 1,2
		), 
-- джойним название города
cities as 
	(
	select distinct 
		a.city as city1, 
		b.city as city2
	from all_flights t1 
	left join airports a 
		on a.airport_code = t1.airp1
	left join airports b 
		on b.airport_code = t1.airp2
	), 
-- смотрим все возможные варианты сочетаний городов
all_cities as 
	(
	select distinct 
			a.city as city1, 
			b.city as city2
	from airports a , airports b
	where a.city != b.city
	) , 
-- исключаем из возможных сочетаний городов существующие перелеты
results as 
	(
	select * 
	from all_cities 
	where city1<city2
	except select * from cities
	order by 1,2
	)
select 
	12 as id, 
	concat_ws('|',city1,city2) as response
from results;
commit;


-- 13. Вывести города, до которых нельзя добраться без пересадок из Москвы

insert into results
with all_flights as 
	(
	select distinct 
		departure_airport as airp1,
		arrival_airport as airp2
	from flights f 
	union 
	select distinct 
		arrival_airport as airp1,
		departure_airport as airp2
	from flights f 
	order by 1,2
	), 
-- джойним название города
cities as 
	(
	select distinct 
		a.city as city1, 
		b.city as city2
	from all_flights t1 
	left join airports a 
		on a.airport_code = t1.airp1
	left join airports b 
		on b.airport_code = t1.airp2
	), 
-- смотрим все возможные варианты сочетаний городов
all_cities as 
	(
	select distinct 
			a.city as city1, 
			b.city as city2
	from airports a , airports b
	where a.city != b.city
	) , 
-- исключаем из возможных сочетаний городов существующие перелеты, оставляем только вылеты из г. Москва
results as 
(
	select *
	from all_cities 
	where city1 = 'Москва'
	except select * from cities
	order by 1,2
)
select 
	13 as id, 
	city2 as response
from results;
commit;

-- 14. Вывести модель самолета, который выполнил больше всего рейсов

insert into results
with air_codes as 
	(
	select 
		aircraft_code, 
		count(flight_id) as cnt_fligthts  
	from flights f 
	group by aircraft_code
	) 
select 
	14 as id, 
	a.model as response
from air_codes ac
left join aircrafts a
	on ac.aircraft_code = a.aircraft_code
where cnt_fligthts = (select max(cnt_fligthts) from air_codes);
commit;

-- 15. Вывести модель самолета, который перевез больше всего пассажиров

insert into results
with all_passengers as 
	(
	select 
		count(passenger_id) as pass_cnt , 
		f.aircraft_code 
	from tickets t 
	join ticket_flights tf 
		on t.ticket_no = tf.ticket_no 
	join flights f 
		on f.flight_id = tf.flight_id 
	group by f.aircraft_code 
	) 
select 
	15 as id, 
	a.model as response
from all_passengers ac
left join aircrafts a
	on ac.aircraft_code = a.aircraft_code
where pass_cnt = (select max(pass_cnt) from all_passengers) ;
commit;

-- 16. Вывести отклонение в минутах суммы запланированного времени перелета от фактического по всем перелётам

insert into results
select 
16 as id, 
extract (epoch from sum(actual_duration)- sum(scheduled_duration))/60 as response
from flights_v fv ;
commit;

-- 17. Вывести города, в которые осуществлялся перелёт из Санкт-Петербурга 2017-08-13

insert into results
select distinct 
	17 as id, 
	arrival_city as response 
from flights_v f 
where departure_city = 'Санкт-Петербург'
and date_trunc('day',actual_departure_local) = '2017-08-13'
order by 1,2;
commit;

-- 18. Вывести перелёт(ы) с максимальной стоимостью всех билетов

insert into results
with flight_amount as 
	(
	select 
		flight_id , 
		sum(amount) as sum_amnt
	from ticket_flights tf 
	group by flight_id
	)
select 
	18 as id, 
	flight_id as response
from flight_amount 
where sum_amnt = (select max(sum_amnt) from flight_amount);
commit;

-- 19. Выбрать дни в которых было осуществлено минимальное количество перелётов

insert into results
with all_dates as 
	( 
	select 
		date_trunc('day',actual_departure_local) as actual_day, 
		count(flight_id) as cnt_fligths
	from flights_v
	where actual_departure_local is not null 
	group by date_trunc('day',actual_departure_local)
	) 
select 
	19 as id, 
	actual_day as response 
from all_dates 
where cnt_fligths = (select min(cnt_fligths) from all_dates);
commit;

-- 20. Вывести среднее количество вылетов в день из Москвы за 08 месяц 2017 года

insert into results
with all_days as 
( 
	select 
		date_trunc('day',actual_departure_local) as actual_day, 
		count(flight_id) as cnt_fligths
	from flights_v
	where actual_departure_local is not null 
		and departure_city = 'Москва'
		and status = 'Arrived'
	group by date_trunc('day',actual_departure_local)
) 
select 
	20 as id, 
	round(avg(cnt_fligths)) as response 
from all_days;
commit;

-- 21. Вывести топ 5 городов у которых среднее время перелета до пункта назначения больше 3 часов

insert into results
with t1 as 
	(
	select departure_city, 
		   extract (epoch from avg(actual_duration))/60/60 as avg_dur, 
		   count(flight_id) as cnt_flights
	from flights_v
	where status = 'Arrived'
	group by departure_city
	having extract (epoch from avg(actual_duration))/60/60 > 3
	order by 3 desc
	limit 5
	)
select 
	21 as id, 
	departure_city as response
from t1
order by 2;
commit;



