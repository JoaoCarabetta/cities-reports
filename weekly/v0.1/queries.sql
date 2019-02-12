/*
query to retrive streets with most interaction (thumbs_up + alerts) with {Alert (sub)type} in last week (sat-sun) and compare with the week before. Ordered by interecations in last week

Accidents:
AND type = 'ACCIDENT'

Pot Holes:
AND subtype = 'HAZARD_ON_ROAD_POT_HOLE'

Traffic Lights Fault:
AND subtype = 'HAZARD_ON_ROAD_TRAFFIC_LIGHT_FAULT'

Flood:
AND subtype = 'HAZARD_WEATHER_FLOOD'

*/

WITH s1 AS 
    (WITH p AS
         (SELECT uuid, street, MAX(nthumbsup) + 1 AS interactions
         FROM cities.br_saopaulo_waze_alerts
         WHERE ( (day BETWEEN 28 AND 31 AND month = 1)                  
                OR   
                 (day BETWEEN 1 AND 3 AND month = 2 ))
              AND year = 2019
              AND subtype = 'HAZARD_WEATHER_FLOOD'
              AND city = 'São Paulo'
         GROUP BY  uuid, street)
     SELECT street, SUM(interactions) AS interactions_s1, 
       ROUND(CAST(SUM(interactions) AS double)/ (SELECT SUM(interactions) FROM p), 4) AS share_of_total_interactions_s1
     FROM p
     GROUP BY street),
     
     s2 AS 
     (WITH p AS
         (SELECT uuid, street, MAX(nthumbsup) + 1 AS interactions
          FROM cities.br_saopaulo_waze_alerts
          WHERE day BETWEEN 20 AND 26
              AND month = 1
              AND year = 2019
              AND subtype = 'HAZARD_WEATHER_FLOOD'
              AND city = 'São Paulo'
          GROUP BY  uuid, street)
     SELECT street, SUM(interactions) AS interactions_s2, 
       ROUND(CAST(SUM(interactions) AS double)/ (SELECT SUM(interactions) FROM p), 4) AS share_of_total_interactions_s2
     FROM p
     GROUP BY street)

SELECT s1.street, 
       interactions_s1, share_of_total_interactions_s1, 
       interactions_s2, share_of_total_interactions_s2,
       CAST(interactions_s1 AS double)/interactions_s2 - 1 AS variation
FROM s1 LEFT JOIN s2 on s1.street=s2.street
ORDER BY  interactions_s1 DESC


/*
Heatmap query | process csv in Kepler

OBS: it queries null streets
*/

WITH p AS
         (SELECT uuid, street, MAX(nthumbsup) + 1 AS interactions, arbitrary(latitude) as latitude,
          arbitrary(longitude) as longitude
         FROM cities.br_saopaulo_waze_alerts
         WHERE ( (day BETWEEN 28 AND 31 AND month = 1)                  
                OR   
                 (day BETWEEN 1 AND 3 AND month = 2 ))
              AND year = 2019
              AND subtype = 'HAZARD_ON_ROAD_TRAFFIC_LIGHT_FAULT'
              AND city = 'São Paulo'
         GROUP BY  uuid, street)
     
SELECT uuid, latitude, longitude, street
FROM p 
WHERE street IN (
    SELECT street
    FROM 
        (SELECT street, SUM(interactions) AS interactions
        FROM p
        GROUP BY street
        ORDER BY interactions DESC)
    LIMIT 15)



/*
Very cheap query for testing (95 MB)
*/

WITH s1 AS 
    (WITH p AS
         (SELECT uuid, street, MAX(nthumbsup) + 1 AS interactions
         FROM cities.br_saopaulo_waze_alerts
         WHERE day = 31 AND month = 1 AND hour = 10            
              AND year = 2019
              AND subtype = 'ACCIDENTS'
              AND city = 'São Paulo'
         GROUP BY  uuid, street)
     SELECT street, SUM(interactions) AS interactions_s1, 
       ROUND(CAST(SUM(interactions) AS double)/ (SELECT SUM(interactions) FROM p), 4) AS share_of_total_interactions_s1
     FROM p
     GROUP BY street),
     
     s2 AS 
     (WITH p AS
         (SELECT uuid, street, MAX(nthumbsup) + 1 AS interactions
          FROM cities.br_saopaulo_waze_alerts
          WHERE day = 28 AND month = 1 AND hour = 10            
              AND year = 2019
              AND subtype = 'ACCIDENTS'
              AND city = 'São Paulo'
          GROUP BY  uuid, street)
     SELECT street, SUM(interactions) AS interactions_s2, 
       ROUND(CAST(SUM(interactions) AS double)/ (SELECT SUM(interactions) FROM p), 4) AS share_of_total_interactions_s2
     FROM p
     GROUP BY street)

SELECT s1.street, 
       interactions_s1, share_of_total_interactions_s1, 
       interactions_s2, share_of_total_interactions_s2,
       CAST(interactions_s1 AS double)/interactions_s2 - 1 AS variation
FROM s1 LEFT JOIN s2 on s1.street=s2.street
ORDER BY  interactions_s1 DESC