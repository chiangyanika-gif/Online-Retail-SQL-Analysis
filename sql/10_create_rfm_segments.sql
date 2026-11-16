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
-- Requires the clean_sales view (see 02_create_clean_sales.sql).
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