/*
* Query distintcs alerts and main features
*/

SELECT DISTINCT uuid, MIN(pub_utc_date) AT TIME ZONE 'America/Sao_Paulo' as start_time, 
                MAX(pub_utc_date) AT TIME ZONE 'America/Sao_Paulo' as end_time, 
                AVG(longitude) as location_x, AVG(latitude) as location_y,
                MIN(reliability) as reliability_min, MAX(reliability) as reliability_max,
                MIN(confidence) as confidence_min, MAX(confidence) as confidence_max,
                MAX(nthumbsup) as thumbs_up
FROM cities.br_saopaulo_waze_alerts
WHERE day = 4
    AND month = 2
    AND year = 2019
    AND subtype = 'HAZARD_WEATHER_FLOOD'
    AND city = 'São Paulo'
GROUP BY uuid


/*
* Join Alerts, Jams and Irregularities by hour and maximum values of each
*/

SELECT hour, irre_length, irre_geojson, null as jams_length, null as jams_geojson, null as nthumbsup,null as latitude,null as longitude
FROM (
SELECT DISTINCT a.hour, a.id, a.length, max(a.nthumbsup) as irre_length, 
arbitrary('{"type":"LineString", "coordinates":' ||
'[' || array_join(transform(a.line, loc -> '[' || CAST(loc.x AS VARCHAR) || ',' || CAST(loc.y AS VARCHAR) || ']'), ',') || ']}') as irre_geojson
FROM 
    (SELECT *
    FROM cities.br_saopaulo_waze_irregularities
    WHERE day = 4
            AND month = 2) a
INNER JOIN 
    (SELECT id,
         hour,
         MAX(length) length
    FROM cities.br_saopaulo_waze_irregularities
    WHERE day = 4
            AND month = 2
    GROUP BY  id, hour) b
    ON b.id = a.id
        AND a.length = b.length AND a.hour = b.hour 
GROUP BY a.hour, a.id, a.length
ORDER BY a.hour, a.id, a.length)
UNION ALL
SELECT hour, null as irre_length, null as irre_geojson, null as jams_length, null as jams_geojson,
 nthumbsup, latitude, longitude
FROM (
SELECT DISTINCT a.hour, a.uuid, a.nthumbsup, arbitrary(a.latitude) as latitude , arbitrary(a.longitude) as longitude
FROM 
    (SELECT *
    FROM cities.br_saopaulo_waze_alerts
    WHERE day = 4
            AND month = 2) a
INNER JOIN 
    (SELECT uuid,
         hour,
         MAX(nthumbsup) nthumbsup
    FROM cities.br_saopaulo_waze_alerts
    WHERE day = 4
            AND month = 2
    GROUP BY  uuid, hour) b
    ON b.uuid = a.uuid
        AND a.nthumbsup = b.nthumbsup AND a.hour = b.hour
  WHERE subtype = 'HAZARD_WEATHER_FLOOD'
GROUP BY a.hour, a.uuid, a.nthumbsup
ORDER BY a.hour, a.uuid, a.nthumbsup)
UNION ALL
SELECT hour, null as irre_length, null as irre_geojson,  jams_length,  jams_geojson,
  null as nthumbsup,null as latitude,null as longitude
FROM (
SELECT DISTINCT a.hour, a.uuid, a.length as jams_length, 
arbitrary('{"type":"LineString", "coordinates":' ||
'[' || array_join(transform(a.line, loc -> '[' || CAST(loc.x AS VARCHAR) || ',' || CAST(loc.y AS VARCHAR) || ']'), ',') || ']}') as jams_geojson
FROM 
    (SELECT *
    FROM cities.br_saopaulo_waze_jams
    WHERE day = 4
            AND month = 2) a
INNER JOIN 
    (SELECT uuid,
         hour,
         MAX(length) length
    FROM cities.br_saopaulo_waze_jams
    WHERE day = 4
            AND month = 2
    GROUP BY  uuid, hour) b
    ON b.uuid = a.uuid
        AND a.length = b.length AND a.hour = b.hour 
GROUP BY a.hour, a.uuid, a.length
ORDER BY a.hour, a.uuid, a.length)

/*
* Get irregularities ids maximum interaction and time range
*/

SELECT a.id, min(hour) - 2 as min_hour, max(hour) - 2 as max_hour,
arbitrary(street) as street, max(length) as length, a.nthumbsup, max(driverscount) as driverscount,
arbitrary('{"type":"LineString", "coordinates":' ||
'[' || array_join(transform(a.line, loc -> '[' || CAST(loc.x AS VARCHAR) || ',' || CAST(loc.y AS VARCHAR) || ']'), ',') || ']}') as irre_geojson
FROM 
(SELECT *
    FROM cities.br_saopaulo_waze_irregularities
    WHERE day = 4
            AND month = 2
AND city = 'São Paulo') a
INNER JOIN 
    (SELECT street,
         MAX(nthumbsup) nthumbsup
    FROM cities.br_saopaulo_waze_irregularities
    WHERE day = 4
            AND month = 2
    GROUP BY  street) b
    ON b.street = a.street
        AND a.nthumbsup = b.nthumbsup
GROUP BY  a.id, a.nthumbsup 
ORDER BY  a.nthumbsup DESC