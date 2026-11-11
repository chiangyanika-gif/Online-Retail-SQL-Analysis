-- ============================================
-- Online Retail Analysis (SQLite)
-- Database: retail.db
-- Note: raw_sales was created by importing the CSV
-- ============================================

-- --------------------------------------------
-- STEP 1: Data check
-- --------------------------------------------
SELECT COUNT(*) AS total_rows,
       SUM(CASE WHEN CustomerID IS NULL THEN 1 ELSE 0 END) AS missing_customer_id,
       SUM(CASE WHEN InvoiceNo LIKE 'C%' THEN 1 ELSE 0 END) AS cancelled_rows,
       SUM(CASE WHEN Quantity <= 0 THEN 1 ELSE 0 END) AS nonpositive_quantity,
       SUM(CASE WHEN UnitPrice <= 0 THEN 1 ELSE 0 END) AS nonpositive_price
FROM raw_sales;

-- --------------------------------------------
-- STEP 2: Data cleaning (creates a view)
-- --------------------------------------------
CREATE VIEW clean_sales AS
SELECT InvoiceNo,
       StockCode,
       TRIM(Description) AS Description,
       Quantity,
       TRIM(InvoiceDate) AS InvoiceDate,
       UnitPrice,
       CustomerID,
       Country,
       Quantity * UnitPrice AS Revenue
FROM raw_sales
WHERE CustomerID IS NOT NULL
  AND InvoiceNo NOT LIKE 'C%'
  AND Quantity > 0
  AND UnitPrice > 0;

-- --------------------------------------------
-- STEP 3: Validate the cleaning
-- --------------------------------------------
SELECT COUNT(*) AS clean_rows,
       ROUND(SUM(Revenue), 2) AS total_revenue
FROM clean_sales;

-- --------------------------------------------
-- STEP 4: Monthly revenue
-- --------------------------------------------
SELECT SUBSTR(InvoiceDate, 1, 7) AS month,
       ROUND(SUM(Revenue), 2) AS revenue
FROM clean_sales
GROUP BY month
ORDER BY month;

-- --------------------------------------------
-- STEP 5: Month-over-month growth
-- --------------------------------------------
WITH monthly AS (
  SELECT SUBSTR(InvoiceDate, 1, 7) AS month,
         SUM(Revenue) AS revenue
  FROM clean_sales
  GROUP BY month
)
SELECT month,
       ROUND(revenue, 2) AS revenue,
       ROUND(LAG(revenue) OVER (ORDER BY month), 2) AS prev_revenue,
       ROUND((revenue - LAG(revenue) OVER (ORDER BY month))
             * 100.0 / LAG(revenue) OVER (ORDER BY month), 1) AS growth_pct
FROM monthly
ORDER BY month;

-- --------------------------------------------
-- STEP 6: Top countries by revenue
-- --------------------------------------------
SELECT Country,
       COUNT(DISTINCT CustomerID) AS customers,
       COUNT(DISTINCT InvoiceNo) AS orders,
       ROUND(SUM(Revenue), 2) AS revenue,
       ROUND(SUM(Revenue) * 100.0 /
             (SELECT SUM(Revenue) FROM clean_sales), 1) AS revenue_share_pct
FROM clean_sales
GROUP BY Country
ORDER BY revenue DESC
LIMIT 10;

-- --------------------------------------------
-- STEP 7: Top 10 customers by revenue
-- --------------------------------------------
SELECT CustomerID,
       Country,
       COUNT(DISTINCT InvoiceNo) AS orders,
       ROUND(SUM(Revenue), 2) AS revenue,
       ROUND(SUM(Revenue) * 100.0 /
             (SELECT SUM(Revenue) FROM clean_sales), 2) AS revenue_share_pct
FROM clean_sales
GROUP BY CustomerID, Country
ORDER BY revenue DESC
LIMIT 10;

-- --------------------------------------------
-- STEP 8: Repeat purchase rate
-- --------------------------------------------
WITH customer_orders AS (
    SELECT CustomerID,
           COUNT(DISTINCT InvoiceNo) AS orders
    FROM clean_sales
    GROUP BY CustomerID
)
SELECT COUNT(*) AS total_customers,
       SUM(CASE WHEN orders > 1 THEN 1 ELSE 0 END) AS repeat_customers,
       ROUND(SUM(CASE WHEN orders > 1 THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 1) AS repeat_rate_pct
FROM customer_orders;

-- --------------------------------------------
-- STEP 9: RFM raw values per customer
-- --------------------------------------------
SELECT CustomerID,
       CAST(julianday((SELECT MAX(InvoiceDate) FROM clean_sales))
            - julianday(MAX(InvoiceDate)) AS INTEGER) AS recency_days,
       COUNT(DISTINCT InvoiceNo) AS frequency,
       ROUND(SUM(Revenue), 2) AS monetary
FROM clean_sales
GROUP BY CustomerID
ORDER BY monetary DESC
LIMIT 10;

-- --------------------------------------------
-- STEP 10: RFM scores (1-5)
-- --------------------------------------------
WITH rfm AS (
    SELECT CustomerID,
           CAST(julianday((SELECT MAX(InvoiceDate) FROM clean_sales))
                - julianday(MAX(InvoiceDate)) AS INTEGER) AS recency_days,
           COUNT(DISTINCT InvoiceNo) AS frequency,
           ROUND(SUM(Revenue), 2) AS monetary
    FROM clean_sales
    GROUP BY CustomerID
)
SELECT CustomerID,
       recency_days,
       frequency,
       monetary,
       NTILE(5) OVER (ORDER BY recency_days DESC) AS r_score,
       NTILE(5) OVER (ORDER BY frequency ASC)     AS f_score,
       NTILE(5) OVER (ORDER BY monetary ASC)      AS m_score
FROM rfm
ORDER BY monetary DESC
LIMIT 10;

-- --------------------------------------------
-- STEP 11: RFM segments
-- --------------------------------------------
WITH rfm AS (
    SELECT CustomerID,
           CAST(julianday((SELECT MAX(InvoiceDate) FROM clean_sales))
                - julianday(MAX(InvoiceDate)) AS INTEGER) AS recency_days,
           COUNT(DISTINCT InvoiceNo) AS frequency,
           ROUND(SUM(Revenue), 2) AS monetary
    FROM clean_sales
    GROUP BY CustomerID
),
scored AS (
    SELECT CustomerID, recency_days, frequency, monetary,
           NTILE(5) OVER (ORDER BY recency_days DESC) AS r_score,
           NTILE(5) OVER (ORDER BY frequency ASC)     AS f_score,
           NTILE(5) OVER (ORDER BY monetary ASC)      AS m_score
    FROM rfm
),
segmented AS (
    SELECT *,
           CASE
               WHEN r_score >= 4 AND f_score >= 4 AND m_score >= 4 THEN 'Champions'
               WHEN f_score >= 4 THEN 'Loyal Customers'
               WHEN r_score <= 2 AND f_score >= 3 THEN 'At Risk'
               WHEN r_score = 1 AND f_score <= 2 THEN 'Lost'
               ELSE 'Others'
           END AS segment
    FROM scored
)
SELECT segment,
       COUNT(*) AS customers,
       ROUND(SUM(monetary), 2) AS revenue,
       ROUND(SUM(monetary) * 100.0 / (SELECT SUM(monetary) FROM segmented), 1) AS revenue_pct
FROM segmented
GROUP BY segment
ORDER BY revenue DESC;

-- --------------------------------------------
-- STEP 12: Cohort retention
-- --------------------------------------------
WITH first_purchase AS (
    SELECT CustomerID,
           SUBSTR(MIN(InvoiceDate), 1, 7) AS cohort_month
    FROM clean_sales
    GROUP BY CustomerID
),
activity AS (
    SELECT DISTINCT CustomerID,
           SUBSTR(InvoiceDate, 1, 7) AS active_month
    FROM clean_sales
),
joined AS (
    SELECT f.CustomerID,
           f.cohort_month,
           (CAST(SUBSTR(a.active_month, 1, 4) AS INTEGER) * 12 + CAST(SUBSTR(a.active_month, 6, 2) AS INTEGER))
         - (CAST(SUBSTR(f.cohort_month, 1, 4) AS INTEGER) * 12 + CAST(SUBSTR(f.cohort_month, 6, 2) AS INTEGER)) AS month_number
    FROM first_purchase f
    JOIN activity a ON f.CustomerID = a.CustomerID
)
SELECT cohort_month,
       COUNT(DISTINCT CASE WHEN month_number = 0 THEN CustomerID END) AS cohort_size,
       COUNT(DISTINCT CASE WHEN month_number = 1 THEN CustomerID END) AS month_1,
       COUNT(DISTINCT CASE WHEN month_number = 3 THEN CustomerID END) AS month_3,
       COUNT(DISTINCT CASE WHEN month_number = 6 THEN CustomerID END) AS month_6
FROM joined
GROUP BY cohort_month
ORDER BY cohort_month;






