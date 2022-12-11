
select *
from olympics_history;

exec sp_help '[dbo].[olympics_history]';

ALTER Table [dbo].[olympics_history]
ALTER Column ID int(50),
ALTER Column Name Varchar(50),
ALTER Column Sex Varchar(50),
ALTER Column Weight Varchar(50),
ALTER Column Height Varchar(50),
ALTER Column Team Varchar(50),
ALTER Column NOC Varchar(50),
ALTER Column Games Varchar(50),
ALTER Column Year Varchar(50),
ALTER Column Age Varchar(50),
ALTER Column Age Varchar(50),

select *
from olympics_history_noc_regions

----1.How many olympics games have been held?

    select count(distinct games) as total_olympic_games
    from olympics_history;




----2. List all Olympics games held so far. (Data issue at 1956-"Summer"-"Stockholm")

    select distinct year,season,city
    from olympics_history
    order by year;




----3. Mention the total no of nations who participated in each olympics game?

    with all_countries as
        (select games, nr.region
        from olympics_history oh
        join olympics_history_noc_regions nr ON nr.noc = oh.noc
        group by games, nr.region)
    select games, count(1) as total_countries
    from all_countries
    group by games
    order by games;




----4. Which year saw the highest and lowest no of countries participating in olympics

	with all_countries as
			(select games, nr.region
			from olympics_history oh
			join olympics_history_noc_regions nr ON nr.noc=oh.noc
			group by games, nr.region),
		tot_countries as
			(select games, count(1) as total_countries
			from all_countries
			group by games)
	select distinct
	concat(first_value(games) over(order by total_countries),' - ', first_value(total_countries) over(order by total_countries)) as Lowest_Countries,
	concat(first_value(games) over(order by total_countries desc), ' - ', first_value(total_countries) over(order by total_countries desc)) as Highest_Countries
	from tot_countries
	order by 1;



Select distinct
      concat(first_value(games) over(order by total_countries),' - ', first_value(total_countries) over(order by total_countries)) as Lowest_Countries,
      concat(first_value(games) over(order by total_countries desc), ' - ', first_value(total_countries) over(order by total_countries desc)) as Highest_Countries
from(
	Select games, count(region) Total_countries
	from(
		select games, region
        from olympics_history oh
        join olympics_history_noc_regions nr 
		ON nr.noc=oh.noc
        group by games, region)sub
	group by games) sub2




----5. Which nation has participated in all of the olympic games
	with tot_games as
			(select count(distinct games) as total_games
			from olympics_history),
		countries as
			(select games, nr.region as country
			from olympics_history oh
			join olympics_history_noc_regions nr ON nr.noc=oh.noc
			group by games, nr.region),
		countries_participated as
			(select country, count(games) as total_participated_games
			from countries
			group by country)
	select cp.*
	from countries_participated cp
	join tot_games tg on tg.total_games = cp.total_participated_games
	order by country;




----6. Identify the sport which was played in all summer olympics.
      with t1 as
          	(select count(distinct games) as total_games
          	from olympics_history where season = 'Summer'),
          t2 as
          	(select distinct games, sport
          	from olympics_history where season = 'Summer'),
          t3 as
          	(select sport, count(1) as no_of_games
          	from t2
          	group by sport)
      select Sport, no_of_games
      from t3
      join t1 on t1.total_games = t3.no_of_games;



----7. Which Sports were played only once in the olympics.
      with t1 as
          	(select distinct games, sport
          	from olympics_history),
          t2 as
          	(select sport, count(1) as no_of_games
          	from t1
          	group by sport)
      select t2.*, t1.games
      from t2
      join t1 on t1.sport = t2.sport
      where no_of_games = 1
      order by t1.sport;




----8. Fetch the total no of sports played in each olympic games.
      with t1 as
      	(select distinct games, sport
      	from olympics_history),
        t2 as
      	(select games, count(1) as no_of_sports
      	from t1
      	group by games)
      select * from t2
      order by no_of_sports desc;




----9. Fetch oldest athletes to win a gold medal
with temp as
    (select name,sex, cast(case when age = 'NA' then '0' else age end as int) as age
        ,team,games,city,sport, event, medal
    from olympics_history),
ranking as
    (select *, rank() over(order by age desc) as rnk
    from temp
    where medal='Gold')
select *
from ranking
where rnk = 1;





----10. Find the Ratio of male and female athletes participated in all olympic games.

With T1 As 
	(Select Count(Sex) Female
	From olympics_history 
	Where Sex = 'F'),
T2 As 
	(Select Count(Sex) Male
	From olympics_history
	Where Sex = 'M')
Select CONCAT('1:', Cast(Round(Male/Cast(Female As decimal(7,2)),2) As Float)) As Ratio From T1,T2




----11. Top 5 athletes who have won the most gold medals.

	with t1 as
		(select name, team, count(Medal) as total_gold_medals
		from olympics_history
		where medal = 'Gold'
		group by name, team),
	t2 as
		(select *, dense_rank() over (order by total_gold_medals desc) as rnk
		from t1)
	select name, team, total_gold_medals, rnk
	from t2
	where rnk <= 5
	order by total_gold_medals desc;



----12. Top 5 athletes who have won the most medals (gold/silver/bronze).
with t1 as
    (select name, team, count(Medal) as total_medals
    from olympics_history
    where medal in ('Gold', 'Silver', 'Bronze')
    group by name, team),
t2 as
    (select *, dense_rank() over (order by total_medals desc) as rnk
    from t1)
select name, team, total_medals
from t2
where rnk <= 5
order by total_medals desc;



----13. Top 5 most successful countries in olympics. Success is defined by no of medals won.
with t1 as
    (select nr.region, count(medal) as total_medals
    from olympics_history oh
    join olympics_history_noc_regions nr on nr.noc = oh.noc
    where medal <> 'NA'
    group by nr.region),
t2 as
    (select *, dense_rank() over(order by total_medals desc) as rnk
    from t1)
select *
from t2
where rnk <= 5
order by total_medals desc;



----14. List the total gold, silver and bronze medals won by each country.

SELECT nr.region as country, 
	sum(case when Medal='Gold' then 1 else 0 end) as Gold,
	sum(case when Medal= 'Silver' then 1 else 0 end) as Silver,
	sum(case when Medal= 'Bronze' then 1 else 0 end) as Bronze
FROM olympics_history oh
JOIN olympics_history_noc_regions nr 
ON nr.noc = oh.noc
where medal <> 'NA'
GROUP BY nr.region
ORDER BY Gold desc, Silver desc, Bronze desc




----15. List the total gold, silver and broze medals won by each country corresponding to each olympic games.


SELECT games, nr.region as country,
	sum(case when Medal='Gold' then 1 else 0 end) as Gold,
	sum(case when Medal= 'Silver' then 1 else 0 end) as Silver,
	sum(case when Medal= 'Bronze' then 1 else 0 end) as Bronze
FROM olympics_history oh
JOIN olympics_history_noc_regions nr 
ON nr.noc = oh.noc
where medal <> 'NA'
GROUP BY games, nr.region
ORDER BY games, country, Gold desc, Silver desc, Bronze desc



----16. Identify which country won the most gold, most silver and most bronze medals in each olympic games.


SELECT Distinct games
    	, concat(first_value(country) over(partition by games order by gold desc) , ' - ', first_value(gold) over(partition by games order by gold desc)) as Max_Gold
    	, concat(first_value(country) over(partition by games order by silver desc), ' - ', first_value(silver) over(partition by games order by silver desc)) as Max_Silver
    	, concat(first_value(country) over(partition by games order by bronze desc), ' - ', first_value(bronze) over(partition by games order by bronze desc)) as Max_Bronze
FROM(
	SELECT games, nr.region as country,
		sum(case when Medal='Gold' then 1 else 0 end) as Gold,
		sum(case when Medal= 'Silver' then 1 else 0 end) as Silver,
		sum(case when Medal= 'Bronze' then 1 else 0 end) as Bronze
	FROM olympics_history oh
	JOIN olympics_history_noc_regions nr 
	ON nr.noc = oh.noc
	where medal <> 'NA'
	GROUP BY games, nr.region) sub
ORDER BY games



----17. Identify which country won the most gold, most silver, most bronze medals and the most medals in each olympic games. 


SELECT Distinct games
    	, concat(first_value(country) over(partition by games order by gold desc) , ' - ', first_value(gold) over(partition by games order by gold desc)) as Max_Gold
    	, concat(first_value(country) over(partition by games order by silver desc), ' - ', first_value(silver) over(partition by games order by silver desc)) as Max_Silver
    	, concat(first_value(country) over(partition by games order by bronze desc), ' - ', first_value(bronze) over(partition by games order by bronze desc)) as Max_Bronze
		, concat(first_value(country) over(partition by games order by total_medals desc), ' - ', first_value(total_medals) over(partition by games order by total_medals desc)) as Max_Medals
FROM(
	SELECT games, nr.region as country,
		sum(case when Medal='Gold' then 1 else 0 end) as Gold,
		sum(case when Medal= 'Silver' then 1 else 0 end) as Silver,
		sum(case when Medal= 'Bronze' then 1 else 0 end) as Bronze,
		sum(case when medal<>'NA'then 1 else 0 end) as Total_Medals
	FROM olympics_history oh
	JOIN olympics_history_noc_regions nr 
	ON nr.noc = oh.noc
	where medal <> 'NA'
	GROUP BY games, nr.region) sub
ORDER BY games




----18. Which countries have never won gold medal but have won silver/bronze medals?
    
SELECT *
FROM(
	SELECT country, coalesce(gold, 0) as Gold, coalesce(silver, 0) as Silver, coalesce(bronze, 0) as Bronze
	FROM(
		SELECT country, 
					SUM(CASE WHEN Medal = 'Gold' THEN total_medals ELSE NULL END) AS Gold,
					SUM(CASE WHEN Medal = 'Silver' THEN total_medals ELSE NULL END) AS Silver,
					SUM(CASE WHEN Medal = 'Bronze' THEN total_medals ELSE NULL END) AS Bronze
		FROM 
			(SELECT nr.region as country, medal, count(1) as total_medals ---
			FROM olympics_history oh
				JOIN olympics_history_noc_regions nr 
				ON nr.noc = oh.noc
				where medal <> 'NA'
				GROUP BY nr.region,medal) sub
		Group by country) Sub2) sub3
WHERE gold = 0 and (silver > 0 or bronze > 0)
ORDER BY Gold desc, Silver desc, Bronze desc




----19. In which Sport did India win highest medals.
	
	SELECT *
	FROM(
		SELECT *, RANK() over (order by Total_medals desc) as rnk
		FROM(
			SELECT Sport, COUNT(medal) as Total_medals
			FROM olympics_history
			WHERE medal<> 'NA' and Team='India'
			GROUP BY Sport)sub
		Group by sport, Total_medals) sub2
	WHERE rnk='1'
	Order by Total_medals



----20. Break down all olympic games where india won medal for Hockey and how many medals in each olympic games
 
	SELECT Games, Sport, Team, count(medal) as total_medals
	FROM olympics_history
	WHERE Team = 'india' and sport='Hockey' and medal<> 'NA'
	Group by Games, Sport, Team
	Order by total_medals desc
