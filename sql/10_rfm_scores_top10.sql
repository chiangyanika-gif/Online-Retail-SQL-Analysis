-- Query: RFM scores (1-5) per customer
-- Purpose: Convert raw Recency, Frequency, Monetary values into quintile scores using NTILE(5)
-- Output: results/10_rfm_scores_top10.csv
-- Note: Higher score is better for all three. Recency is sorted DESC so recent buyers get 5.
-- Ties can be split across different scores. Sample export of the top 10 customers. Currency assumed GBP.

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