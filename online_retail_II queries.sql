/* SALES 2009 - 2010 */

SELECT *
FROM `online-retail-analysis-502202.Sales.Sales_2009_2010`;


SELECT COUNT(*)
FROM `online-retail-analysis-502202.Sales.Sales_2009_2010`;

/* SALES 2010 - 2011 */

SELECT *
FROM `online-retail-analysis-502202.Sales.Sales_2010_2011`;


SELECT COUNT(*)
FROM `online-retail-analysis-502202.Sales.Sales_2010_2011`;



/* Merge Tables */
CREATE TABLE `online-retail-analysis-502202.Sales.Sales_Data` AS
SELECT *
FROM `online-retail-analysis-502202.Sales.Sales_2009_2010`
WHERE NOT (
  Invoice IS NULL AND StockCode IS NULL AND Description IS NULL AND Quantity IS NULL AND
  InvoiceDate IS NULL AND InvoiceTime IS NULL AND Price IS NULL AND `Customer ID` IS NULL AND Country IS NULL
)

UNION ALL

SELECT *
FROM `online-retail-analysis-502202.Sales.Sales_2010_2011`
WHERE NOT (
  Invoice IS NULL AND StockCode IS NULL AND Description IS NULL AND Quantity IS NULL AND
  InvoiceDate IS NULL AND InvoiceTime IS NULL AND Price IS NULL AND `Customer ID` IS NULL AND Country IS NULL
);

-- Select all columns
SELECT *
FROM online-retail-analysis-502202.Sales.Sales_Data;

-- Count records
SELECT COUNT(*) AS total_records
FROM online-retail-analysis-502202.Sales.Sales_Data;


-- Calculate monthly revenue
SELECT EXTRACT(MONTH FROM InvoiceDate) AS Month, ROUND(SUM(price * quantity),2) AS revenue 
FROM online-retail-analysis-502202.Sales.Sales_Data
GROUP BY Month
ORDER BY Month;

-- Year-Over-Year (YOY) Growth 
WITH yearly_sales AS (
SELECT 
  EXTRACT(YEAR FROM InvoiceDate) AS year, 
  SUM(Price * Quantity) AS current_year_sales
FROM online-retail-analysis-502202.Sales.Sales_Data
GROUP BY year
), previous_sales AS (
  SELECT 
    year, 
    current_year_sales, 
    LAG(current_year_sales) OVER(ORDER BY year) AS previous_year_sales
  FROM yearly_sales
), yoy_growth AS (
  SELECT 
    year, 
    ((current_year_sales - previous_year_sales)/previous_year_sales) * 100 AS yoy_growth
  FROM previous_sales
)

SELECT * FROM yoy_growth;


-- Month-Over-Month (YOY) Growth 
WITH monthly_sales AS (
SELECT 
  EXTRACT(YEAR FROM InvoiceDate) AS year,
  EXTRACT(MONTH FROM InvoiceDate) AS month, 
  SUM(Price * Quantity) AS current_month_sales
FROM online-retail-analysis-502202.Sales.Sales_Data
GROUP BY year, month
ORDER BY year, month
), previous_sales AS (
  SELECT 
    year,
    month, 
    current_month_sales, 
    LAG(current_month_sales) OVER(ORDER BY year,month) AS previous_month_sales
  FROM monthly_sales
), mom_growth AS (
  SELECT 
    year,
    month, 
    ((current_month_sales - previous_month_sales)/previous_month_sales) * 100 AS mom_growth
  FROM previous_sales
)

SELECT * FROM mom_growth;

/* Monthly Seasonality Index */
WITH total_revenue_per_year AS (
  SELECT 
    EXTRACT(YEAR FROM InvoiceDate) AS year,
    SUM(price * quantity) AS yearly_revenue
  FROM online-retail-analysis-502202.Sales.Sales_Data
  GROUP BY year
  ORDER BY year
), total_revenue_per_month AS (
  SELECT 
    EXTRACT(YEAR FROM InvoiceDate) AS year, 
    EXTRACT(MONTH FROM InvoiceDate) AS month_number,
    FORMAT_DATE('%B', InvoiceDate) AS month, 
    SUM(price * quantity) AS monthly_revenue
  FROM online-retail-analysis-502202.Sales.Sales_Data
  GROUP BY year, month_number, month
  ORDER BY year, month_number, month

), months_per_year AS (
  SELECT 
    year, 
    COUNT(DISTINCT month) AS total_months
  FROM total_revenue_per_month
  GROUP BY year
), total_monthly_average AS (
  SELECT 
    mpy.year, 
    mpy.total_months AS total_months,
    tpm.month,
    tpm.monthly_revenue,
    tpy.yearly_revenue / mpy.total_months AS overall_monthly_avg,
    tpm.monthly_revenue / (tpy.yearly_revenue / mpy.total_months) AS seasonality_index
  FROM months_per_year AS mpy
  JOIN total_revenue_per_year AS tpy
  ON mpy.year = tpy.year
  JOIN total_revenue_per_month AS tpm
  ON tpy.year = tpm.year 
  ORDER BY mpy.year, tpm.month_number
)

SELECT * FROM total_monthly_average;


/* Recency, Frequency, and Monetary (RFM) Analysis */
WITH rfm AS (
  SELECT 
    `Customer ID`, 
    MAX(InvoiceDate) AS most_recent_purchase, 
    COUNT(Invoice) AS purchase_frequency, 
    SUM(price * quantity) AS monetary_value 
  FROM online-retail-analysis-502202.Sales.Sales_Data
  GROUP BY `Customer ID`
), rfm_score AS (
  SELECT
    `Customer ID`,
    NTILE(5) OVER(ORDER BY most_recent_purchase) AS recency_score,
    NTILE(5) OVER(ORDER BY purchase_frequency) AS frequency_score,
    NTILE(5) OVER(ORDER BY monetary_value) AS monetary_score
  FROM rfm
  ORDER BY recency_score DESC, frequency_score DESC, monetary_score DESC
), rfm_rating AS (
  SELECT
    (CASE 
      WHEN recency_score = 5 THEN "purchased very recently"
      WHEN recency_score = 4 THEN "purchased recently"
      WHEN recency_score = 3 THEN "moderate recency"
      WHEN recency_score = 2 THEN "hasn't purchased in a while"
      WHEN recency_score = 1 THEN "very old purchase / inactive" 
    END) AS recency_rating,
    (CASE 
      WHEN frequency_score = 5 THEN "buys very often"
      WHEN frequency_score = 4 THEN "buys frequently"
      WHEN frequency_score = 3 THEN "average purchase count"
      WHEN frequency_score = 2 THEN "buys infrequently"
      WHEN frequency_score = 1 THEN "rarely buys"
    END) AS monetary_rating,
    (CASE 
      WHEN monetary_score = 5 THEN "highest spenders"
      WHEN monetary_score = 4 THEN "high spenders"
      WHEN monetary_score = 3 THEN "average spend"
      WHEN monetary_score = 2 THEN "low spend"
      WHEN monetary_score = 1 THEN "very low spend"
    END) AS frequency_rating
  FROM rfm_score
)

SELECT * FROM rfm_rating;


/* Product Performance Analysis */
SELECT 
  Description, 
  ROUND(SUM(price * quantity),2) AS revenue,
  ROUND(SUM(price * quantity) / COUNT(invoice),2) AS average_order_value_per_product,
  ROUND(SUM(price * quantity) / (SELECT SUM(price * quantity) FROM online-retail-analysis-502202.Sales.Sales_Data),5) AS product_contribution
FROM online-retail-analysis-502202.Sales.Sales_Data
GROUP BY Description
ORDER BY revenue DESC, average_order_value_per_product DESC, product_contribution DESC;


-- Pareto (80/20) Revenue Concentration Analysis
WITH revenue_per_customer AS (
  SELECT
    `Customer ID`,
    SUM(price * quantity) AS revenue
  FROM online-retail-analysis-502202.Sales.Sales_Data
  GROUP BY `Customer ID`
  ORDER BY revenue DESC
), cume_revenue AS(
  SELECT
    `Customer ID`,
    revenue,
    SUM(revenue) OVER(ORDER BY revenue DESC) AS cumulative_revenue,
    SUM(revenue) OVER() AS total_revenue
  FROM revenue_per_customer

), cumulative_distribution AS (
  SELECT
    `Customer ID`,
    (cumulative_revenue / total_revenue) AS revenue_contribution
  FROM cume_revenue
  WHERE (cumulative_revenue / total_revenue) <= 0.80
  ORDER BY revenue_contribution DESC
), revenue_drivers AS (
  SELECT
    (COUNT(*) / (SELECT COUNT(DISTINCT `Customer ID`) FROM revenue_per_customer)) * 100 AS pareto_customer_percentage
  FROM cumulative_distribution 
)


SELECT * FROM revenue_drivers;



-- Geographic Market Analysis
SELECT
Country, SUM(price * quantity) AS revenue_per_country
FROM online-retail-analysis-502202.Sales.Sales_Data
GROUP BY Country
ORDER BY revenue_per_country DESC;



/* Create Fact and Dimension Tables */
CREATE TABLE online-retail-analysis-502202.Sales.dim_Customer AS
SELECT 
  `Customer ID`,
  Country
FROM 
(
  SELECT DISTINCT `Customer ID`, Country
  FROM `online-retail-analysis-502202.Sales.Sales_Data`
);

CREATE TABLE `online-retail-analysis-502202.Sales.dim_Product` AS
SELECT 
  GENERATE_UUID() AS ProductID,
  Description AS ProductDescription
FROM 
(
  SELECT DISTINCT Description
  FROM `online-retail-analysis-502202.Sales.Sales_Data`
);


CREATE TABLE online-retail-analysis-502202.Sales.dim_Date AS
SELECT 
  FORMAT_DATE('%Y%m%d', InvoiceDate) AS DateID,
  InvoiceDate AS FullDate,
  EXTRACT(YEAR FROM InvoiceDate) AS Year,
  EXTRACT(QUARTER FROM InvoiceDate) AS Quarter,
  EXTRACT(MONTH FROM InvoiceDate) AS Month,
  FORMAT_DATE('%B', InvoiceDate) AS MonthName,
  EXTRACT(DAY FROM InvoiceDate) AS Day,
  EXTRACT(DAYOFWEEK FROM InvoiceDate) AS DayOfWeek,
  CASE WHEN EXTRACT(DAYOFWEEK FROM InvoiceDate) IN (1,7) THEN TRUE ELSE FALSE 
  END AS IsWeekend
FROM 
(
  SELECT DISTINCT InvoiceDate
  FROM `online-retail-analysis-502202.Sales.Sales_Data`
);

CREATE TABLE online-retail-analysis-502202.Sales.dim_Time AS
SELECT 
  FORMAT_TIME('%H%M%S', InvoiceTime) AS TimeID,
  InvoiceTime AS FullTime,
  EXTRACT(HOUR FROM InvoiceTime) AS Hour,
  EXTRACT(MINUTE FROM InvoiceTIme) AS Minute,
  EXTRACT(SECOND FROM InvoiceTime) AS Second,
  CASE 
    WHEN EXTRACT(HOUR FROM InvoiceTime) BETWEEN 5 AND 11 THEN 'Morning'
    WHEN EXTRACT(HOUR FROM InvoiceTime) BETWEEN 12 AND 16 THEN 'Afternoon'
    WHEN EXTRACT(HOUR FROM InvoiceTime) BETWEEN 17 AND 20 THEN 'Evening'
    ELSE 'Night'
  END AS TimeOfDay
FROM 
(
  SELECT DISTINCT InvoiceTime
  FROM `online-retail-analysis-502202.Sales.Sales_Data`
);

CREATE TABLE online-retail-analysis-502202.Sales.fact_Transactions AS
  SELECT 
    f.Invoice,
    f.StockCode,
    p.ProductID,
    f.`Customer ID`,
    d.DateID,
    t.TimeID,
    f.Quantity,
    f.Price,
    (f.Price * f.Quantity) AS TotalAmount
  FROM `online-retail-analysis-502202.Sales.Sales_Data` f
  LEFT JOIN `online-retail-analysis-502202.Sales.dim_Product` p  
  ON f.Description = p.ProductDescription 
  LEFT JOIN `online-retail-analysis-502202.Sales.dim_Date` d    
  ON f.InvoiceDate = d.FullDate   
  LEFT JOIN `online-retail-analysis-502202.Sales.dim_Time` t
  ON f.InvoiceTime = t.FullTime;

