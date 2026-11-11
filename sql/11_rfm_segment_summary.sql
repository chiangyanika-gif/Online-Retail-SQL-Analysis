-- Query: RFM customer segments summary
-- Purpose: Group customers into Champions, Loyal Customers, At Risk, Lost and Others,
-- then show customers, revenue and revenue share per segment
-- Output: results/11_rfm_segment_summary.csv
-- Note: Segment rules are subjective and applied in order (first match wins).
-- Loyal Customers only checks the F score. Currency assumed GBP.

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