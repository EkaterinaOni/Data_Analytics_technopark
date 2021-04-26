
--Запрос 1
--За все матчи какого героя чаще всего брали за все матчи

with play as (
    SELECT m.match_id as match_id,
           pl.hero_id as hero_id,
           gamer.localized_name as loc_name
    FROM match m, players pl, hero_names gamer
    WHERE pl.match_id = m.match_id and pl.hero_id = gamer.hero_id
    ORDER BY m.match_id ASC
)

select hero_id,
       loc_name,
       count(loc_name) as count_in_play_tabel
from play
GROUP BY hero_id, loc_name
ORDER BY count_in_play_tabel DESC
LIMIT 1;

-------------------
--Запрос 2
--Количество убийств у Windranger
with killing as (
    select  match_id,
            hero_id,
            sum(kills)  over(partition by hero_id order by hero_id desc) as sum_kills
    FROM players
    where hero_id > 0
    GROUP BY match_id, hero_id, kills
    order by hero_id asc

)

select  DISTINCT  k.hero_id,
                  gamer.localized_name,
                  k.sum_kills as sum_killing
FROM killing k INNER JOIN hero_names gamer ON k.hero_id = gamer.hero_id
WHERE gamer.localized_name = 'Windranger';


----------------
--Запрос 3
--Рейтинг персонажей по совершенным убийствам  +
 with ray as (select match_id,
                     hero_id,
                     sum(kills) over (partition by hero_id order by hero_id desc) as sum_kills
              FROM players
              where hero_id > 0
              GROUP BY match_id, hero_id, kills
              order by sum_kills DESC
)

select ray.hero_id,
       h.localized_name,
       ray.sum_kills,
       row_number() over (order by ray.sum_kills desc) as kills_rating
FROM ray INNER JOIN hero_names h ON ray.hero_id = h.hero_id
GROUP BY ray.hero_id,h.localized_name, ray.sum_kills;

--Запрос 4
-- К какой команде принадлежал персонаж силе тьмы или силе света

with teams as(
    SELECT  pl.match_id as matches,
           pl.hero_id as gamer,
           pl.player_slot,
           case when pl.player_slot >= 128 then 'Dire' else 'Radiant' end as team_hero
           FROM players pl
           WHERE pl.hero_id = 21
    )

SELECT  team_hero,
        count(team_hero)
FROM teams
GROUP BY team_hero;

--Запрос 5
-- Процент побед во всех матчах за этого героя (Windranger hero_id = 21)

with teams as(
    SELECT  pl.match_id as matches,
           pl.hero_id as gamer,
           case when m.radiant_win = 'TRUE' then 'Radiant' else 'Dire' end as winner,
           pl.player_slot,
           case when pl.player_slot >= 128 then 'Dire' else 'Radiant' end as team_hero
           FROM players pl, match m
           WHERE pl.match_id = m.match_id and pl.hero_id = 21
    ),
     wins as(
         SELECT *, case when teams.winner = teams.team_hero then 'Победа' else 'Поражение' end as victor
         FROM teams
     ),
     allwins as (
         SELECT count(victor) as all_matches
         FROM wins
     )

SELECT  w.victor,
       ROUND((count(w.victor) * 100 / aw.all_matches),2) as percentage
FROM wins w, allwins aw
WHERE w.victor = 'Победа'
GROUP BY w.victor, aw.all_matches;

---------------------

--Запрос 6
-- Какой предмет чаще всего брали для этого героя (Windranger hero_id = 21)

with item_all as (
    SELECT   pl.match_id,
             pl.hero_id,
             pl.item_0 as item_0,
             pl.item_1 as item_1,
             pl.item_2 as item_2,
             pl.item_3 as item_3,
             pl.item_4 as item_4,
             pl.item_5 as item_5
    FROM players pl
    WHERE hero_id = 21
    )

SELECT  a.item,
       ids.item_name,
        sum(a.count_item)  as all_count_item
FROM (
         SELECT item_0 as item,
                count(item_0) as count_item
         FROM item_all
         GROUP BY item
         UNION
         SELECT item_1 as item,
                count(item_1) as count_item
         FROM item_all
         GROUP BY item
         UNION
         SELECT item_2 as item,
                count(item_2) as count_item
         FROM item_all
         GROUP BY item
         UNION
         SELECT item_3 as item,
                count(item_3) as count_item
         FROM item_all
         GROUP BY item
         UNION
         SELECT item_4 as item,
                count(item_4) as count_item
         FROM item_all
         GROUP BY item
         UNION
         SELECT item_5 as item,
                count(item_5) as count_item
         FROM item_all
         GROUP BY item
) as a, item_ids ids
WHERE ids.item_id = a.item
GROUP BY a.item, ids.item_id
ORDER BY all_count_item DESC
limit 1;

--Вывод: Для этого героя больше всего покупали phase_boots


--Запрос 7
--Разнице во времени когда произошла первая кровь по матчам где учавствовал этот персонаж
--Рейтинг предыдущего матча

with match_first_blood as (
            SELECT  pl.match_id,
                    pl.kills AS kills,
                    m.first_blood_time AS first_blood_time
            FROM players pl INNER JOIN match m on m.match_id = pl.match_id
            WHERE hero_id = 21
            ORDER BY pl.match_id ASC
),
     raiting as (
         SELECT  match_id,
                 first_blood_time,
                 row_number() OVER (ORDER BY first_blood_time DESC) AS RankByFirstBlood
        FROM match_first_blood
    )

SELECT  *,
        lag(first_blood_time) over (order by first_blood_time desc) as lag_first_blood_time,
        lag(RankByFirstBlood) over (order by first_blood_time desc) as lag_raiting,
        lead(first_blood_time, -1) over (order by first_blood_time desc) - first_blood_time as first_blood_time_diff
FROM raiting r;

