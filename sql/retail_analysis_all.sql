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
DROP VIEW IF EXISTS clean_sales;

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
-- Expected: 397,884 rows; 8,911,407.90 gross revenue
-- (Revenue = Quantity * UnitPrice; 'C%' invoices are excluded,
-- but purchases cancelled later are NOT deducted)
-- --------------------------------------------
SELECT COUNT(*) AS clean_rows,
       ROUND(SUM(Revenue), 2) AS gross_revenue
FROM clean_sales;

-- --------------------------------------------
-- STEP 4: Monthly revenue (gross)
-- Note: 2011-12 is a partial month (data ends 2011-12-09)
-- --------------------------------------------
SELECT SUBSTR(InvoiceDate, 1, 7) AS month,
       ROUND(SUM(Revenue), 2) AS revenue
FROM clean_sales
GROUP BY month
ORDER BY month;

-- --------------------------------------------
-- STEP 5: Month-over-month growth (gross revenue)
-- Note: 2011-12 is a partial month (data ends 2011-12-09),
-- so its -55.4% is NOT a real decline; do not interpret it as one.
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
-- STEP 6: Top countries by revenue (gross)
-- Note: gross revenue; purchases cancelled later are NOT deducted.
-- Netherlands (9 customers) and EIRE (3 customers) are highly
-- concentrated in a few customers, so read their share with care.
-- UK includes customers 12346 and 16446 (gross 245,656.10 combined),
-- which may be overstated if their orders were cancelled later
-- (preliminary observation, not verified in this query).
-- UK accounts for 82.0% of gross revenue.
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
-- STEP 7: Top 10 customers by revenue (gross)
-- Note: gross revenue; purchases cancelled later are NOT deducted.
-- Customers 16446 (2 orders) and 12346 (1 order) rank high on gross
-- revenue, but their net revenue may be much lower if their orders
-- were cancelled later (preliminary observation, not verified
-- in this query).
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
-- Note: repeat rate = customers with more than 1 order in the data
-- window (2010-12 to 2011-12-09) / all customers with a CustomerID.
-- It is NOT the share of Champions in the RFM segmentation.
-- Orders cancelled later are still counted as orders.
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
-- STEP 9: RFM raw values per customer (top 10 by monetary)
-- Note: recency_days = days from the last date in the data
-- (2011-12-09 12:50:00), not from today. CAST AS INTEGER truncates
-- to whole days, so 0 means less than 1 full day, not necessarily
-- the same calendar day. monetary is gross revenue.
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
-- STEP 10: RFM scoring and segments
-- Note: scores use PERCENT_RANK() split into 5 equal-width bands
-- (0-0.2 -> 1, ..., 0.8-1.0 -> 5). Customers with identical values
-- get identical scores, so band sizes are NOT equal (e.g. all
-- customers with 1 order get F=1).
-- R: fewer days since last purchase = higher score.
-- F, M: higher value = higher score. M is gross revenue.
-- Segment rules are evaluated in order; At Risk is checked
-- before Loyal so that frequent buyers who stopped buying are
-- not labelled Loyal.
-- This step only creates the rfm_segments view; no CSV is exported.
-- --------------------------------------------
DROP VIEW IF EXISTS rfm_segments;

CREATE VIEW rfm_segments AS
WITH rfm AS (
    SELECT CustomerID,
           CAST(julianday((SELECT MAX(InvoiceDate) FROM clean_sales))
                - julianday(MAX(InvoiceDate)) AS INTEGER) AS recency_days,
           COUNT(DISTINCT InvoiceNo) AS frequency,
           SUM(Revenue) AS monetary
    FROM clean_sales
    GROUP BY CustomerID
),
pr AS (
    SELECT *,
           PERCENT_RANK() OVER (ORDER BY recency_days DESC) AS r_pr,
           PERCENT_RANK() OVER (ORDER BY frequency ASC)     AS f_pr,
           PERCENT_RANK() OVER (ORDER BY monetary ASC)      AS m_pr
    FROM rfm
),
scored AS (
    SELECT CustomerID, recency_days, frequency, monetary,
           CASE WHEN r_pr < 0.2 THEN 1 WHEN r_pr < 0.4 THEN 2
                WHEN r_pr < 0.6 THEN 3 WHEN r_pr < 0.8 THEN 4 ELSE 5 END AS r_score,
           CASE WHEN f_pr < 0.2 THEN 1 WHEN f_pr < 0.4 THEN 2
                WHEN f_pr < 0.6 THEN 3 WHEN f_pr < 0.8 THEN 4 ELSE 5 END AS f_score,
           CASE WHEN m_pr < 0.2 THEN 1 WHEN m_pr < 0.4 THEN 2
                WHEN m_pr < 0.6 THEN 3 WHEN m_pr < 0.8 THEN 4 ELSE 5 END AS m_score
    FROM pr
)
SELECT *,
       CASE
           WHEN r_score >= 4 AND f_score >= 4 AND m_score >= 4 THEN 'Champions'
           WHEN r_score <= 2 AND f_score >= 3 THEN 'At Risk'
           WHEN f_score >= 4 THEN 'Loyal Customers'
           WHEN r_score <= 2 AND f_score <= 2 THEN 'Lost'
           ELSE 'Others'
       END AS segment
FROM scored;

-- --------------------------------------------
-- STEP 11: Segment summary
-- Revenue is gross revenue (cancelled invoices excluded, but
-- later cancellations of earlier purchases are not netted out).
-- Shares are based on the rfm_segments view (PERCENT_RANK scoring).
-- --------------------------------------------
SELECT segment,
       COUNT(*) AS customers,
       ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 1) AS pct_customers,
       ROUND(SUM(monetary), 2) AS gross_revenue,
       ROUND(100.0 * SUM(monetary) / SUM(SUM(monetary)) OVER (), 1) AS pct_revenue,
       ROUND(AVG(monetary), 2) AS avg_gross_revenue
FROM rfm_segments
GROUP BY segment
ORDER BY gross_revenue DESC;

-- --------------------------------------------
-- STEP 12: Cohort retention
-- cohort = month of a customer's first purchase in the data.
-- month_N = customers active in EXACTLY month N after the cohort month
--           (not cumulative retention).
-- NULL = target month is after the last month in the data (2011-12).
-- Cells whose target month is 2011-12 cover only 9 days (partial month).
-- The 2010-12 cohort is not purely new customers: the data starts that month.
-- --------------------------------------------
WITH activity AS (
    SELECT DISTINCT CustomerID,
           CAST(SUBSTR(InvoiceDate, 1, 4) AS INTEGER) * 12
         + CAST(SUBSTR(InvoiceDate, 6, 2) AS INTEGER) AS month_idx
    FROM clean_sales
),
first_purchase AS (
    SELECT CustomerID, MIN(month_idx) AS cohort_idx
    FROM activity
    GROUP BY CustomerID
),
data_end AS (
    SELECT MAX(month_idx) AS end_idx FROM activity
),
joined AS (
    SELECT f.CustomerID,
           f.cohort_idx,
           a.month_idx - f.cohort_idx AS month_number
    FROM first_purchase f
    JOIN activity a ON f.CustomerID = a.CustomerID
),
counts AS (
    SELECT cohort_idx,
           COUNT(DISTINCT CASE WHEN month_number = 0 THEN CustomerID END) AS cohort_size,
           COUNT(DISTINCT CASE WHEN month_number = 1 THEN CustomerID END) AS c1,
           COUNT(DISTINCT CASE WHEN month_number = 3 THEN CustomerID END) AS c3,
           COUNT(DISTINCT CASE WHEN month_number = 6 THEN CustomerID END) AS c6
    FROM joined
    GROUP BY cohort_idx
)
SELECT printf('%04d-%02d', (c.cohort_idx - 1) / 12, (c.cohort_idx - 1) % 12 + 1) AS cohort_month,
       c.cohort_size,
       CASE WHEN d.end_idx - c.cohort_idx >= 1 THEN c.c1 END AS month_1,
       CASE WHEN d.end_idx - c.cohort_idx >= 3 THEN c.c3 END AS month_3,
       CASE WHEN d.end_idx - c.cohort_idx >= 6 THEN c.c6 END AS month_6,
       CASE WHEN d.end_idx - c.cohort_idx >= 1
            THEN ROUND(100.0 * c.c1 / c.cohort_size, 1) END AS month_1_pct,
       CASE WHEN d.end_idx - c.cohort_idx >= 3
            THEN ROUND(100.0 * c.c3 / c.cohort_size, 1) END AS month_3_pct,
       CASE WHEN d.end_idx - c.cohort_idx >= 6
            THEN ROUND(100.0 * c.c6 / c.cohort_size, 1) END AS month_6_pct
FROM counts c
CROSS JOIN data_end d
ORDER BY c.cohort_idx;