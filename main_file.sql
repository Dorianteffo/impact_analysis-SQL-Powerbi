SET search_path = data_mart;
---DATA CLEANING
CREATE TABLE clean_weekly_sales(
	week_date DATE,
	week_number INT,
	month_number INT, 
	calendar_year INT, 
	region VARCHAR(13),
	platform VARCHAR(7),
	segment VARCHAR(10),
	age_band VARCHAR(20),
	demographic VARCHAR(15), 
	customer_type VARCHAR(8),
	transactions INT,
	sales INT, 
	avg_transaction DECIMAL
);

INSERT INTO clean_weekly_sales(week_date,region,platform,segment,customer_type,transactions,sales)
SELECT 
	TO_DATE(week_date,'YYYY-MM-DD'),
	region,
	platform,
	segment,
	customer_type,
	transactions,
	sales
FROM weekly_sales;

UPDATE clean_weekly_sales 
SET week_number = EXTRACT(WEEK FROM week_date),
	month_number = EXTRACT(MONTH FROM week_date),
	calendar_year = EXTRACT(YEAR FROM week_date),
	segment = CASE 
		WHEN segment LIKE '%null%' THEN 'unknown'
		ELSE segment
		END,
	age_band = CASE 
		WHEN segment LIKE '%1%' THEN 'Young Adults'
		WHEN segment LIKE '%2%' THEN 'Middle Aged'
		WHEN segment LIKE '%3%' OR segment LIKE '%4%' THEN 'Retires'
		ELSE 'unknown'
		END, 
	demographic = CASE 
		WHEN segment LIKE '%C%' THEN 'Couples'
		WHEN segment LIKE '%F%' THEN 'Families'
		ELSE 'unknown'
		END,
	avg_transaction = ROUND(sales/transactions,2);
		
	
---EDA
---What day of the week is used for each week_date value?
	SELECT DISTINCT week_date,(EXTRACT(DAY FROM week_date)) days
	FROM clean_weekly_sales;
	
	
---What range of week numbers are missing from the dataset for each year?
SELECT calendar_year , 
1 AS min_of_first_range, MIN(week_number)-1 AS max_of_first_range,
MAX(week_number)+1 AS min_of_second_range, 52 as max_of_second_range
FROM clean_weekly_sales
GROUP BY calendar_year;


---How many total transactions were there for each year in the dataset
SELECT calendar_year, SUM(transactions) AS total_transactions
FROM clean_weekly_sales
GROUP BY calendar_year
ORDER BY calendar_year;


---What is the total sales for each region for each month?
SELECT month_number,region , SUM(sales) AS total_sales
FROM clean_weekly_sales
GROUP BY region,month_number
ORDER BY  month_number;


---What is the total count of transactions for each platform
SELECT platform, SUM(transactions) AS total_transactions
FROM clean_weekly_sales
GROUP BY platform;


---What is the percentage of sales for Retail vs Shopify for each month
SELECT  x.month_number,x.platform,
x.total_sales,x.sales_platform, 
ROUND((CAST(x.sales_platform AS DECIMAL)/CAST(x.total_sales AS DECIMAL))*100,2) AS percentage_platform
FROM  (SELECT DISTINCT month_number, platform, 
	  	SUM(sales) OVER (PARTITION BY month_number) AS total_sales, 
		SUM(sales) OVER(PARTITION BY month_number,platform) AS sales_platform
	  FROM clean_weekly_sales
	  ) x
ORDER BY x.month_number;


---What is the percentage of sales by demographic for each year in the dataset
SELECT x.calendar_year, x.demographic, 
x.total_sales_demo , x.sales_demo,
ROUND((CAST(x.sales_demo AS DECIMAL)/CAST(x.total_sales_demo AS DECIMAL))*100,2)  AS percentage_demographic
FROM  (SELECT DISTINCT calendar_year, demographic, 
	  	SUM(sales) OVER (PARTITION BY calendar_year) AS total_sales_demo, 
		SUM(sales) OVER(PARTITION BY calendar_year,demographic) AS sales_demo
	  FROM clean_weekly_sales
		) x
ORDER BY x.calendar_year;


---Which age_band and demographic values contribute the most to Retail sales
SELECT platform, age_band, demographic,SUM(sales) total_sales
FROM clean_weekly_sales
WHERE platform LIKE '%Retail%' and age_band NOT LIKE '%unknown%'
and demographic NOT LIKE '%unknown%'
GROUP BY platform,age_band,demographic
ORDER BY total_sales DESC
LIMIT 1;


---Can we use the avg_transaction column to find the average transaction size for each 
---year for Retail vs Shopify? If not - how would you calculate it instead?

SELECT DISTINCT platform,calendar_year,
COUNT(calendar_year) OVER(PARTITION BY calendar_year,platform) AS count_operation_year, 
SUM(avg_transaction) OVER(PARTITION BY calendar_year, platform) AS sum_avg_trasaction_year, 
ROUND(SUM(avg_transaction) OVER(PARTITION BY calendar_year, platform)/
	  COUNT(transactions) OVER(PARTITION BY calendar_year,platform),2) AS avg_transac_year
FROM clean_weekly_sales
ORDER BY calendar_year;
---We can't use the avg_transaction column to find the avg transaction size for each year, because 
---the right way to do it, is to divide the total sales for each year by total number of transaction, like this : 

SELECT x.platform, x.calendar_year,
x.total_transaction_year,x.total_sales,
ROUND(CAST(x.total_sales AS DECIMAL)/CAST(x.total_transaction_year AS DECIMAL),2) AS avg_transaction_year
FROM (SELECT DISTINCT platform, calendar_year, 
	  SUM(transactions) OVER(PARTITION BY calendar_year,platform) AS total_transaction_year, 
	  SUM(sales) OVER(PARTITION BY calendar_year,platform) AS total_sales
	  FROM clean_weekly_sales) x 
ORDER BY x.calendar_year;


---BEFORE & AFTER ANALYSIS 
---This technique is usually used when we inspect an important event and want to inspect the 
--impact before and after a certain point in time.

---Taking the week_date value of 2020-06-15 as the baseline week where the Data Mart sustainable
---packaging changes came into effect.

---We would include all week_date values for 2020-06-15 as the start of the period after the change
---and the previous week_date values would be before

---What is the total sales for the 4 weeks before and after 2020-06-15? What is the growth or reduction 
---rate in actual values and percentage of sales?
WITH week_tab (week_concern) AS (
			SELECT DISTINCT week_number
			FROM clean_weekly_sales
			WHERE week_date = DATE('2020-06-15')
			), 
  	weeks_before(total_sales_before) AS (
			SELECT SUM(sales) 
			FROM clean_weekly_sales
			JOIN week_tab
			ON clean_weekly_sales.week_number BETWEEN week_tab.week_concern - 4 AND week_tab.week_concern -1
			AND calendar_year=2020
			),
	weeks_after(total_sales_after) AS (
			SELECT SUM(sales)
			FROM clean_weekly_sales
			JOIN week_tab
			ON clean_weekly_sales.week_number BETWEEN week_tab.week_concern AND week_tab.week_concern + 3
			AND calendar_year = 2020
			)
SELECT *, 
ROUND((CAST((wa.total_sales_after-wb.total_sales_before) AS DECIMAL)/wb.total_sales_before)*100,2) AS percentage_growth
FROM weeks_before wb,weeks_after wa;


--- What about the entire 12 weeks before and after?
WITH week_tab (week_concern) AS (
			SELECT DISTINCT week_number
			FROM clean_weekly_sales
			WHERE week_date = DATE('2020-06-15')
			), 
  	weeks_before(total_sales_before) AS (
			SELECT SUM(sales) 
			FROM clean_weekly_sales
			JOIN week_tab
			ON clean_weekly_sales.week_number BETWEEN week_tab.week_concern - 12 AND week_tab.week_concern -1
			AND calendar_year = 2020
			),
	weeks_after(total_sales_after) AS (
			SELECT SUM(sales)
			FROM clean_weekly_sales
			JOIN week_tab
			ON clean_weekly_sales.week_number BETWEEN week_tab.week_concern AND week_tab.week_concern + 11
			AND calendar_year = 2020
			)
SELECT *, 
ROUND((CAST((wa.total_sales_after-wb.total_sales_before) AS DECIMAL)/wb.total_sales_before)*100,2) AS percentage_growth
FROM weeks_before wb,weeks_after wa; 


---How do the sale metrics for these 2 periods before and after compare with the previous years in 2018 and 2019?
---(assuming that the week_number associate to the week_date is the same each year)
WITH week_tab (week_concern) AS (
			SELECT DISTINCT week_number
			FROM clean_weekly_sales
			WHERE week_date = DATE('2020-06-15')
			), 
  	weeks_before AS (
			SELECT DISTINCT calendar_year,
			SUM(sales) OVER(PARTITION BY calendar_year) AS total_sales_before
			FROM clean_weekly_sales
			JOIN week_tab
			ON clean_weekly_sales.week_number BETWEEN week_tab.week_concern - 12 AND week_tab.week_concern -1
			),
	weeks_after AS (
			SELECT DISTINCT calendar_year, 
			SUM(sales) OVER(PARTITION BY calendar_year) AS total_sales_after
			FROM clean_weekly_sales
			JOIN week_tab
			ON clean_weekly_sales.week_number BETWEEN week_tab.week_concern  AND week_tab.week_concern + 11
			)
SELECT wb.calendar_year,wb.total_sales_before, wa.total_sales_after,
ROUND((CAST((wa.total_sales_after-wb.total_sales_before) AS DECIMAL)/wb.total_sales_before)*100,2) AS percentage_growth
FROM weeks_before wb
JOIN weeks_after wa
ON wb.calendar_year = wa.calendar_year; 


---Which areas of the business have the highest negative impact in sales metrics performance in 2020 
---for the 12 week before and after period?
--- BY REGION 
WITH week_tab (week_concern) AS (
			SELECT DISTINCT week_number
			FROM clean_weekly_sales
			WHERE week_date = DATE('2020-06-15') 
			), 
  	weeks_before AS (
			SELECT DISTINCT region,
			SUM(sales) OVER(PARTITION BY region) AS total_sales_before 
			FROM clean_weekly_sales
			JOIN week_tab
			ON clean_weekly_sales.week_number BETWEEN week_tab.week_concern - 12 AND week_tab.week_concern -1
			WHERE calendar_year = 2020
			),
	weeks_after AS (
			SELECT DISTINCT region,
			SUM(sales) OVER(PARTITION BY region) AS total_sales_after
			FROM clean_weekly_sales
			JOIN week_tab
			ON clean_weekly_sales.week_number BETWEEN week_tab.week_concern AND week_tab.week_concern + 11
			WHERE calendar_year = 2020
			)
SELECT DISTINCT wb.region, wb.total_sales_before, wa.total_sales_after,
ROUND((CAST((wa.total_sales_after-wb.total_sales_before) AS DECIMAL)/wb.total_sales_before)*100,2) AS percentage_growth
FROM weeks_before wb
JOIN weeks_after wa
ON wb.region = wa.region;


---BY PLATFORM 
WITH week_tab (week_concern) AS (
			SELECT DISTINCT week_number
			FROM clean_weekly_sales
			WHERE week_date = DATE('2020-06-15') 
			), 
  	weeks_before AS (
			SELECT DISTINCT platform,
			SUM(sales) OVER(PARTITION BY platform) AS total_sales_before 
			FROM clean_weekly_sales
			JOIN week_tab
			ON clean_weekly_sales.week_number BETWEEN week_tab.week_concern - 12 AND week_tab.week_concern -1
			WHERE calendar_year = 2020
			),
	weeks_after AS (
			SELECT DISTINCT platform,
			SUM(sales) OVER(PARTITION BY platform) AS total_sales_after
			FROM clean_weekly_sales
			JOIN week_tab
			ON clean_weekly_sales.week_number BETWEEN week_tab.week_concern  AND week_tab.week_concern + 11
			WHERE calendar_year = 2020
			)
SELECT DISTINCT wb.platform, wb.total_sales_before, wa.total_sales_after,
ROUND((CAST((wa.total_sales_after-wb.total_sales_before) AS DECIMAL)/wb.total_sales_before)*100,2) AS percentage_growth
FROM weeks_before wb
JOIN weeks_after wa
ON wb.platform = wa.platform;


---BY age_band 
WITH week_tab (week_concern) AS (
			SELECT DISTINCT week_number
			FROM clean_weekly_sales
			WHERE week_date = DATE('2020-06-15') 
			), 
  	weeks_before AS (
			SELECT DISTINCT age_band,
			SUM(sales) OVER(PARTITION BY age_band) AS total_sales_before 
			FROM clean_weekly_sales
			JOIN week_tab
			ON clean_weekly_sales.week_number BETWEEN week_tab.week_concern - 12 AND week_tab.week_concern -1
			WHERE calendar_year = 2020
			),
	weeks_after AS (
			SELECT DISTINCT age_band,
			SUM(sales) OVER(PARTITION BY age_band) AS total_sales_after
			FROM clean_weekly_sales
			JOIN week_tab
			ON clean_weekly_sales.week_number BETWEEN week_tab.week_concern AND week_tab.week_concern + 11
			WHERE calendar_year = 2020
			)
SELECT DISTINCT wb.age_band, wb.total_sales_before, wa.total_sales_after,
ROUND((CAST((wa.total_sales_after-wb.total_sales_before) AS DECIMAL)/wb.total_sales_before)*100,2) AS percentage_growth
FROM weeks_before wb
JOIN weeks_after wa
ON wb.age_band = wa.age_band;


---BY DEMOGRAPHIC 
WITH week_tab (week_concern) AS (
			SELECT DISTINCT week_number
			FROM clean_weekly_sales
			WHERE week_date = DATE('2020-06-15') 
			), 
  	weeks_before AS (
			SELECT DISTINCT demographic,
			SUM(sales) OVER(PARTITION BY demographic) AS total_sales_before 
			FROM clean_weekly_sales
			JOIN week_tab
			ON clean_weekly_sales.week_number BETWEEN week_tab.week_concern - 12 AND week_tab.week_concern -1
			WHERE calendar_year = 2020
			),
	weeks_after AS (
			SELECT DISTINCT demographic,
			SUM(sales) OVER(PARTITION BY demographic) AS total_sales_after
			FROM clean_weekly_sales
			JOIN week_tab
			ON clean_weekly_sales.week_number BETWEEN week_tab.week_concern  AND week_tab.week_concern + 11
			WHERE calendar_year = 2020
			)
SELECT DISTINCT wb.demographic, wb.total_sales_before, wa.total_sales_after,
ROUND((CAST((wa.total_sales_after-wb.total_sales_before) AS DECIMAL)/wb.total_sales_before)*100,2) AS percentage_growth
FROM weeks_before wb
JOIN weeks_after wa
ON wb.demographic = wa.demographic;


---BY CUSTOMER_TYPE
WITH week_tab (week_concern) AS (
			SELECT DISTINCT week_number
			FROM clean_weekly_sales
			WHERE week_date = DATE('2020-06-15') 
			), 
  	weeks_before AS (
			SELECT DISTINCT customer_type,
			SUM(sales) OVER(PARTITION BY customer_type) AS total_sales_before 
			FROM clean_weekly_sales
			JOIN week_tab
			ON clean_weekly_sales.week_number BETWEEN week_tab.week_concern - 12 AND week_tab.week_concern -1
			WHERE calendar_year = 2020
			),
	weeks_after AS (
			SELECT DISTINCT customer_type,
			SUM(sales) OVER(PARTITION BY customer_type) AS total_sales_after
			FROM clean_weekly_sales
			JOIN week_tab
			ON clean_weekly_sales.week_number BETWEEN week_tab.week_concern  AND week_tab.week_concern + 11
			WHERE calendar_year = 2020
			)
SELECT DISTINCT wb.customer_type, wb.total_sales_before, wa.total_sales_after,
ROUND((CAST((wa.total_sales_after-wb.total_sales_before) AS DECIMAL)/wb.total_sales_before)*100,2) AS percentage_growth
FROM weeks_before wb
JOIN weeks_after wa
ON wb.customer_type = wa.customer_type;