-- запрос 1
SELECT tariff,
       view-orders as first_step,
       orders-driver_time as second_step,
       driver_time - car_time as third_step,
       car_time - client_time as fourth_step,
       client_time - finish_time as fifth_step
FROM
(
    SELECT v.tariff as tariff,
           countIf(v.idhash_view, v.idhash_view > 0)   as view,
           countIf(ord.idhash_order, ord.idhash_order > 0) as orders,
           countIf(ord.da_dttm, ord.da_dttm > 0)           as driver_time,
           countIf(ord.rfc_dttm, ord.rfc_dttm > 0)         as car_time,
           countIf(ord.cc_dttm, ord.cc_dttm > 0)           as client_time,
           countIf(ord.finish_dttm, ord.finish_dttm > 0)   as finish_time
    FROM data_analysis.orders ord
             RIGHT JOIN data_analysis.views v using idhash_order
    GROUP BY tariff
    ORDER BY view DESC
)
--Итог: больше всего теряется на людей на первых двух шагах: просмотр цены - заказ и заказ - водитель назначен


-- запрос 2, агрегатные функции

SELECT id_client,
       groupArray(tariff) AS array_tariff,
       --arrayUniq(array_tariff) as tariffs_used,
       count(tariff) as count_tariff
FROM(
        SELECT idhash_client as id_client,
        tariff as tariff,
        count(tariff) AS all_tariff_desc
        FROM data_analysis.views
        GROUP BY idhash_client, tariff
        ORDER BY idhash_client ASC, count(tariff) DESC
    ) as a
GROUP BY id_client
ORDER BY id_client ASC;

-- Запрос 3  Вывести топ 10 гексагонов (размер 7) из которых уезжают
-- с 7 до 10 утра и в которые едут с 18-00 до 20-00 в сумме
-- по всем дням
--Использую сс_dttm и finish_dttm т.к. смотри время как оттуда уезжают и во сколько туда приезжают

SELECT h3,
       sum(orders) as sum_orders
FROM (
         SELECT geoToH3(longitude, latitude, 7) as h3,
                count(idhash_order)             as orders
         FROM data_analysis.views
                  INNER JOIN data_analysis.orders using idhash_order
         WHERE (toHour(cc_dttm) >= 7 and toHour(cc_dttm) <= 10)
         GROUP BY h3
         UNION all
         SELECT geoToH3(del_longitude, del_latitude, 7) as h3,
                count(idhash_order)                     as orders
         FROM data_analysis.views
                  INNER JOIN data_analysis.orders using idhash_order
         WHERE toHour(finish_dttm) >= 19
           and toHour(finish_dttm) <= 20
         GROUP BY h3
         )
GROUP BY h3
ORDER BY sum_orders DESC
LIMIT 10;



-- Запрос 4 МЕДИАНА И 95 квантиль

SELECT median(find_driver) as median_time,
        quantile(0.95)(find_driver) as percentile_95_time,
       --quantile(0.5)(find_driver) as med_time, --At level=0.5 the function calculates median.
       median(find_driver_sec) as median_time_sec,
       quantile(0.95)(find_driver_sec) as percentile_95_time_sec
FROM (SELECT order_dttm,
             da_dttm,
             dateDiff('minute', order_dttm, da_dttm) as find_driver,
             dateDiff('second', order_dttm, da_dttm) as find_driver_sec
      FROM data_analysis.orders
      ORDER BY find_driver desc

      );

--
SELECT idhash_order,
       dateDiff('hour', finish_dttm, da_dttm) as drive_hour
FROM data_analysis.orders
WHERE finish_dttm > 0 and da_dttm > 0
ORDER by drive_hour desc


