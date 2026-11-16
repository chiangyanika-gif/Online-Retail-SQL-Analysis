-- --------------------------------------------
-- STEP 2: Data cleaning (creates a view)
-- Removes rows with missing CustomerID, cancelled invoices
-- (InvoiceNo starting with 'C') and non-positive quantity or price.
-- Trims text and adds Revenue = Quantity * UnitPrice (gross).
-- Currency is assumed to be GBP; the data does not state it.
-- Safe to re-run: the view is dropped first.
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