# Executive summary

* In this project, we used SQL (With clause, Window functions,Inner Join, Group By, Order by, ) for the data cleaning step, the EDA, and the Impact analysis (before & after)of the changes. We also used PowerBI (DAX) to build the visualizations.
* We found the impact in percentage of changes introduced in June 2020, and the part of the business which were the most impacted by those changes.
*  We also gave advices to the business for future introduction of similar updates.

# Introduction

Data Mart is Danny’s latest venture and after running international operations for his online supermarket that specialises in fresh produce. Danny is asking for your support to analyse his sales performance.

In June 2020 - large scale supply changes were made at Data Mart. All Data Mart products now use sustainable packaging methods in every single step from the farm all the way to the customer.

Danny needs your help to quantify the impact of this change on the sales performance for Data Mart and it’s separate business areas.

The key business question he wants you to help him answer are the following:

- **What was the quantifiable impact of the changes introduced in June 2020?**
- **Which platform, region, segment and customer types were the most impacted by this change?**
- **What can we do about future introduction of similar sustainability updates to the business to minimise impact on sales?**

# Methodology

## Available Data

For this case study there is only a single table: weekly_sales (17117 rows)

Dataset : https://drive.google.com/file/d/1bJdhfVPC0KSfXxvGJgvcuFd105m2GD7W/view?usp=sharing

The Entity Relationship diagram is shown below with the data types made clear, please note that there is only this one table.

![diagram.png](diagram_EA.png)

The columns are pretty self-explanatory based on the column names but here are some further details about the dataset:

1. Data Mart has international operations using a multi-region strategy
2. Data Mart has both, a retail and online platform in the form of a Shopify store front to serve their customers
3. Customer segment and customer_type data relates to personal age and demographics information that is shared with Data Mart
4. transactions is the count of unique purchases made through Data Mart and sales is the actual dollar amount of purchases

Each record in the dataset is related to a specific aggregated slice of the underlying sales data rolled up into a week_date value which represents the start of the sales week.

## Data cleaning

For this part, we have created a new table named clean_weekly_sales with :

- the initial week_date column
- a week_number column, which represents the associated week for each week_date row
- a month_number column for each week_date row
- a calendar_year column which is the year extracts from each week_date row
- the region column
- platform column
- segment column
- age_band column using the following mapping on the number inside the segment value:
    - If it is 1 then age_band = Young Adults
    - If 2 then age_band = Middle Aged
    - If 3 or 4 then age_band = Retires
- a demographic column using the following mapping on the first letter of the segment value;
    - If “C” then demographic = Couples
    - If “F” then Families = Families
- replace all the “null” values in the segment, demographic and age_band column by “unknown”
- the initial customer_type column
- the transactions column
- the sales column
- the avg_transaction as the sales value divided by the transaction rounded to 2 decimal

## Data Exploration

For this step, we have answered many questions : 

1. What range of week numbers are missing from the dataset?
2. How many total transactions were there for each year in the dataset?
3. What is the total sales for each region for each month?
4. What is the total count of transactions for each platform
5. What is the percentage of sales for Retail vs Shopify for each month?
6. What is the percentage of sales by demographic for each year in the dataset?
7. Which age_band and demographic values contribute the most to Retail sales?
8. Can we use the avg_transaction column to find the average transaction size for each year for Retail vs Shopify? If not - how would you calculate it instead?

## Impact Analysis( Before & After)

This technique is usually used when we inspect an important event and want to inspect the impact before and after a certain point in time.

Taking the week_date value of 2020-06-15 as the baseline week where the Data Mart sustainable packaging changes came into effect.

We would include all week_date values for 2020-06-15 as the start of the period **after** the change and the previous week_date values would be **before.**

Using this analysis approach - we have answered the following questions:

1. What is the total sales for the 4 weeks before and after 2020-06-15?  What is the growth or reduction rate in actual values and percentage of sales?
2. What about the entire 12 weeks before and after?
3. How do the sale metrics for these 2 periods before and after compare with the previous years in 2018 and 2019?

# Results

After the EDA, we have found this : 

- For each year in the dataset(2018, 2019, 2020) there are 24 weeks of data (from week 13 to week 36)
- The number of transactions increase every year

![transactions_by_Year.PNG](graph/transactions_by_Year.PNG)

- Oceania has the highest number of sales made each month, followed by Africa and Asia. Europe has the lowest total sales made each month.

![sales_by_month_and_region.PNG](graph/sales_by_month_and_region.PNG)

- 99.46%(1Billion) of total transactions were made in Retail platform

![transactions_by_platform.PNG](graph/transactions_by_platform.PNG)

- Retail platform have the highest total sales each month.

| Month  | Platform | Percentage_sales |
| --- | --- | --- |
| March  | Retail  | 97.54% |
| March  | Shopify  | 2.46% |
| April | Retail  | 97.59% |
| April | Shopify  | 2.41% |
| May  | Retail  | 97.3% |
| May  | Shopify  | 2.7% |
| June  | Retail  | 97.27% |
| June  | Shopify  | 2.73% |
| July | Retail  | 97.29 |
| July  | Shopify  | 2.71% |
| August  | Retail  | 97.08% |
| August  | Shopify  | 2.92% |
| September | Retail  | 97.38% |
| September | Shopify  | 2.62% |

![sales_by_month_and_platform.PNG](graph/sales_by_month_and_platform.PNG)

- Percentage of sales by demographic each year

| Year | Demographic  | Percentage_Sales |
| --- | --- | --- |
| 2018 | unknown  | 41.63% |
| 2018 | Couples | 26.38% |
| 2018 | Families  | 31.99% |
| 2019 | unknown  | 40.25% |
| 2019 | Couples  | 27.28% |
| 2019 | Families  | 32.47% |
| 2020 | unknown  | 38.55% |
| 2020 | Couples | 28.72% |
| 2020 | Families  | 32.73% |

![sales_by_year_and_demographic.PNG](graph/sales_by_year_and_demographic.PNG)

- The age_band Retires and the demographic Families contribute the most in Retail Sales, with a total of 6.63 billion sales.
- The average transaction size each year by platform:

| Year | Platform | Avg_transaction |
| --- | --- | --- |
| 2018 | Retail  | 36.56 |
| 2018 | Shopify  | 192.48 |
| 2019 | Retail  | 36.83 |
| 2019 | Shopify  | 183.36 |
| 2020 | Retail  | 36.56 |
| 2020 | Shopify  | 179.03 |

At the end of the Before & After changes analysis, he have figured out many things : 

- There were a total of 2.35 Billion sales 4 weeks before the supply changes, and 2.32 Billion, the 4 weeks after, which represent a reduction of 1.15%.

![Untitled](graph/sales_4_week_beforeafter.PNG)

- For the 12 weeks before, there total of sales were 7.13 Billion and 6.97 Billion the 12 weeks after. That represent a reduction of 2.14% in sales.

![Untitled](graph/sales_12_weeks_beforeafter.PNG)

- ASIA and EUROPE were the most impacted by the changes, with an increase of 4.73% of sales in EUROPE and a reduction of 3.26% in ASIA.

![Untitled](graph/sales_before&after_region.PNG)

- Retail platform had a reduction of 2.43% in sales versus an increase of 7.18% on Shopify

![Untitled](graph/sales_before&after_platform.PNG)

- In age_band, the Middle Aged was the most impacted by changes, with a reduction of 1.97%

![Untitled](graph/sales_before&after_ageband.PNG)

- In demographic, Families were the most impacted by the changes, with a reduction in -1.82% in sale.

![Untitled](graph/sales_before&after_demographic.PNG)

- Guest customers and new customers were the most impacted by the changes with a reduction of -3.00% in sales for Guest customers and an increase of 1.01% for guest customers.

![Untitled](graph/sales_before&after_customer.PNG)

# Discussion Findings,Implications and Conclusion

In conclusion, in response to the key business questions, we have many findings :

- After the changes introduced in June 2020, the total sales decreased by 2.14%.
- Impact on Region:

 

| Region | Impact  |
| --- | --- |
| ASIA | -3.26% |
| OCEANIA | -3.03% |
| SOUTH AMERICA  | -2.15% |
| CANADA | -1.92% |
| USA | -1.60% |
| AFRICA | -0.54% |
| EUROPE | +4.73% |
- Impact on platform

| Platform | Impact |
| --- | --- |
| Retail | -2.43% |
| Shopify | +7.18% |
- Impact on age_band

| Age Band  | Impact  |
| --- | --- |
| Middle Aged | -1.97% |
| Retires | -1.23% |
| Young Adults | -0.92% |

- Impact on demographic

| Demographic | Impact  |
| --- | --- |
| Families | -1.82% |
| Couples | -0.87% |
- Impact on customer_type

| Customer_type | Impact |
| --- | --- |
| Guest | -3.03% |
| Existing | -2.27% |
| New | +1.01% |

Despite the large scale supply changes have impacted the total sales, with a reduction of 2.14%, we have found that those changes have positively impacted the Shopify sales with an increase of 7.18%, and also New customers, with an increase of 1.01%. 

With further anlysis , we have also found that the sales in Europe has gained 4.73% increase in sales, with +7.07% in Shopify sales, and +13.49% in new customer sales.

Also, although Asia sales have decreased, the Shopify sales in Asia increased  with +11.20%.

# Recommendations 
In future introduction of similar sustainability updates to the business, i highly recommend Data mart to : 
### Increase the total number of transactions made on Shopify : that would increase the total sales, because the average transaction size on Shopify each year is more than twice that of Retail). 
### Increase the total number of transactions made in Europe : as we have seen, Europe has the lowest total sales each month, so Data mart should increase the number of transactions made there.
### Do more advertising campaigns to attract more new customers


