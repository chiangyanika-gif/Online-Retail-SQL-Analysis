-- Query: Create the cleaned view used by all analyses
-- Purpose: Remove missing customer IDs, cancelled invoices and
-- nonpositive quantity or price. Trim text and add Revenue.
-- Note: Run this ONCE. If clean_sales already exists, run
-- DROP VIEW clean_sales; first. Currency assumed GBP.

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