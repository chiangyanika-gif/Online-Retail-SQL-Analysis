-- Query: RFM raw values per customer
-- Purpose: Recency (days since last purchase), Frequency (orders), Monetary (revenue)
-- Output: results/09_rfm_raw_top10.csv
-- Note: Recency is measured from the latest date in the dataset (lower is better).
-- Sample export of the top 10 customers by monetary value. Currency assumed GBP.

SELECT CustomerID,
       CAST(julianday((SELECT MAX(InvoiceDate) FROM clean_sales))
            - julianday(MAX(InvoiceDate)) AS INTEGER) AS recency_days,
       COUNT(DISTINCT InvoiceNo) AS frequency,
       ROUND(SUM(Revenue), 2) AS monetary
FROM clean_sales
GROUP BY CustomerID
ORDER BY monetary DESC
LIMIT 10;