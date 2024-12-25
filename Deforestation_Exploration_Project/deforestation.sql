-- CREATE VIEW forestation joining all three tables
CREATE VIEW forestation AS
    SELECT f.country_code,
           f.country_name,
           f.year,
           f.forest_area_sqkm,
           l.total_area_sq_mi,
           l.total_area_sq_mi * 2.59 AS total_area_sqkm,
           (f.forest_area_sqkm/(l.total_area_sq_mi * 2.59))*100 as forest_percentage,
           r.region,
           r.income_group
    FROM forest_area f
    JOIN land_area l ON f.country_code = l.country_code AND f.year = l.year
    JOIN regions r ON r.country_code = f.country_code;


-- 1.GLOBAL SITUATION
--a. What was the total forest area (in sq km) of the world in 1990? Please keep in mind that you can use the country record denoted as “World" in the region table.
SELECT SUM(forest_area_sqkm)
FROM forestation
WHERE year = '1990' AND region='World'

--b. What was the total forest area (in sq km) of the world in 2016? Please keep in mind that you can use the country record in the table is denoted as “World.”
SELECT SUM(forest_area_sqkm)
FROM forestation
WHERE year = '2016' AND region='World'

--c. What was the change (in sq km) in the forest area of the world from 1990 to 2016?
SELECT (f1.forest_area_sqkm - f2.forest_area_sqkm) AS forest_area_loss
FROM forestation f1 , forestation f2
WHERE f1.year = '1990' AND 
f1.region='World' AND
f2.year = '2016' AND 
f2.region='World'

--d. What was the percent change in forest area of the world between 1990 and 2016?
SELECT (f1.forest_area_sqkm - f2.forest_area_sqkm)*100/f1.forest_area_sqkm AS forest_area_loss
FROM forestation f1 , forestation f2
WHERE f1.year = '1990' AND 
f1.region='World' AND
f2.year = '2016' AND 
f2.region='World'

--e. If you compare the amount of forest area lost between 1990 and 2016, to which country's total area in 2016 is it closest to?
SELECT 
    country_name,
    total_area_sqkm
FROM forestation
WHERE year = 2016 
AND total_area_sqkm < (
    SELECT (f1.forest_area_sqkm - f2.forest_area_sqkm) AS forest_area_loss
    FROM forestation f1 
    JOIN forestation f2
    ON f1.region = f2.region
    WHERE f1.year = '1990' 
    AND f1.region = 'World' 
    AND f2.year = '2016' 
    AND f2.region = 'World'
)
ORDER BY total_area_sqkm DESC 
LIMIT 1;

-- 2.Regional Outlook
--a. What was the percent forest of the entire world in 2016? Which region had the HIGHEST percent forest in 2016, and which had the LOWEST, to 2 decimal places?
SELECT 
    region,
    year,
    ROUND(CAST(forest_percentage AS NUMERIC), 2) as forest_percentage
FROM forestation
WHERE year = 2016 
AND region = 'World';

SELECT 
    region,
    ROUND(CAST((SUM(forest_area_sqkm)/SUM(total_area_sqkm)*100) AS NUMERIC), 2) as forest_percentage
FROM forestation
WHERE year = 2016 
AND region != 'World'
GROUP BY region
ORDER BY forest_percentage DESC
LIMIT 1;

SELECT 
    region,
    ROUND(CAST((SUM(forest_area_sqkm)/SUM(total_area_sqkm)*100) AS NUMERIC), 2) as forest_percentage
FROM forestation
WHERE year = 2016 
AND region != 'World'
GROUP BY region
ORDER BY forest_percentage ASC
LIMIT 1;
--b. What was the percent forest of the entire world in 1990? Which region had the HIGHEST percent forest in 1990, and which had the LOWEST, to 2 decimal places?
SELECT 
    region,
    year,
    ROUND(CAST(forest_percentage AS NUMERIC), 2) as forest_percentage
FROM forestation
WHERE year = 1990 
AND region = 'World';

SELECT 
    region,
    ROUND(CAST((SUM(forest_area_sqkm)/SUM(total_area_sqkm)*100) AS NUMERIC), 2) as forest_percentage
FROM forestation
WHERE year = 1990 
AND region != 'World'
GROUP BY region
ORDER BY forest_percentage DESC
LIMIT 1;

SELECT 
    region,
    ROUND(CAST((SUM(forest_area_sqkm)/SUM(total_area_sqkm)*100) AS NUMERIC), 2) as forest_percentage
FROM forestation
WHERE year = 1990 
AND region != 'World'
GROUP BY region
ORDER BY forest_percentage ASC
LIMIT 1;
--c. Based on the table you created, which regions of the world DECREASED in forest area from 1990 to 2016?
SELECT 
    region,
    ROUND(CAST((SUM(CASE WHEN year = 1990 THEN forest_area_sqkm END)/
                SUM(CASE WHEN year = 1990 THEN total_area_sqkm END)*100) AS NUMERIC), 2) as forest_percentage_1990,
    ROUND(CAST((SUM(CASE WHEN year = 2016 THEN forest_area_sqkm END)/
                SUM(CASE WHEN year = 2016 THEN total_area_sqkm END)*100) AS NUMERIC), 2) as forest_percentage_2016
FROM forestation
WHERE year IN (1990, 2016) 
AND region != 'World'
GROUP BY region
ORDER BY forest_percentage_1990 DESC;

SELECT 
    region,
    ROUND(CAST((SUM(CASE WHEN year = 1990 THEN forest_area_sqkm END)/
                SUM(CASE WHEN year = 1990 THEN total_area_sqkm END)*100) AS NUMERIC), 2) as forest_percentage_1990,
    ROUND(CAST((SUM(CASE WHEN year = 2016 THEN forest_area_sqkm END)/
                SUM(CASE WHEN year = 2016 THEN total_area_sqkm END)*100) AS NUMERIC), 2) as forest_percentage_2016
FROM forestation
WHERE year IN (1990, 2016) 
AND region = 'World'
GROUP BY region
ORDER BY forest_percentage_1990 DESC;

-- 3.Country-Level Detail
-- A.SUCCESS STORIES
SELECT f2.country_name,  
  ROUND(CAST(f1.forest_area_sqkm - f2.forest_area_sqkm  AS NUMERIC),2) AS difference 
FROM forest_area AS f1 
JOIN forest_area AS f2 
  ON  (f1.year = '2016' AND f2.year = '1990') 
  AND f1.country_name = f2.country_name 
ORDER BY difference DESC; 

SELECT f2.country_name,  
  ROUND(CAST((f1.forest_area_sqkm - f2.forest_area_sqkm)/f2.forest_area_sqkm *100  AS NUMERIC),2) AS percentage 
FROM forest_area AS f1 
JOIN forest_area AS f2 
  ON  (f1.year = '2016' AND f2.year = '1990') 
  AND f1.country_name = f2.country_name 
ORDER BY percentage DESC; 

-- B.LARGEST CONCERNS
SELECT f2.country_name,  f2.region,
  ROUND(CAST(f1.forest_area_sqkm - f2.forest_area_sqkm  AS NUMERIC),2) AS area_change 
FROM forestation AS f1 
JOIN forestation AS f2 
  ON  (f1.year = '2016' AND f2.year = '1990') 
  AND f1.country_name = f2.country_name
  WHERE f2.country_name != 'World'
ORDER BY area_change ASC
LIMIT 5;

SELECT f2.country_name, f2.region, 
  ROUND(CAST((f1.forest_area_sqkm - f2.forest_area_sqkm)/f2.forest_area_sqkm *100  AS NUMERIC),2) AS percentage 
FROM forestation AS f1 
JOIN forestation AS f2 
  ON  (f1.year = '2016' AND f2.year = '1990') 
  AND f1.country_name = f2.country_name 
ORDER BY percentage ASC
LIMIT 5;

--C.QUARTILES
SELECT distinct(quartiles), COUNT(country_name) OVER (PARTITION BY quartiles) 
FROM (SELECT country_name, 
  CASE WHEN forest_percentage <= 25 THEN '0-25%' 
  WHEN forest_percentage <= 75 AND forest_percentage > 50 THEN '50-75%' 
  WHEN forest_percentage <= 50 AND forest_percentage > 25 THEN '25-50%' 
  ELSE '75-100%' 
END AS quartiles FROM forestation 
WHERE forest_percentage IS NOT NULL AND year = 2016) quart; 

SELECT country_name, region ,forest_percentage 
FROM forestation 
WHERE forest_percentage > 75 AND year = 2016
ORDER BY forest_percentage DESC;