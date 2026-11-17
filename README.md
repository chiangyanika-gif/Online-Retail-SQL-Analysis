# Online Retail SQL Analysis

## Overview

This project analyzes about 540,000 transactions from a UK-based online retail dataset using SQL (SQLite). It looks at revenue trends, customer behavior, and customer value to support marketing and retention decisions.

## Tableau Dashboard

[View the interactive dashboard on Tableau Public](https://public.tableau.com/app/profile/yanika.benno/viz/OnlineRetailDashboard_17948977583650/OnlineRetailDashboard)

![Online Retail Dashboard](online%20retail%20dashboard.png)

The dashboard summarizes revenue trend, top countries, and RFM segments from the result files in `results/` (`04`, `06`, `11`). Total gross revenue is £8,911,407.90 across 4,338 customers. Cohort retention is not included in the dashboard because it is covered in the SQL results (`12_cohort_retention.csv`).

## Business Questions

1. How does revenue change month to month?
2. Which countries and customers generate the most revenue?
3. What share of customers make repeat purchases?
4. Which RFM customer segments drive the most revenue?
5. How well are customers retained after their first purchase?

## Tools

- SQLite (queried in DB Browser for SQLite)
- SQL: CTEs, window functions (`LAG`, `PERCENT_RANK`), joins, `CASE WHEN`, views, aggregation
- VS Code for organizing the query files

## Data

- **Source:** Online Retail transaction dataset (UK-based online retailer)
- **Size:** 541,909 rows
- **Columns:** `InvoiceNo`, `StockCode`, `Description`, `Quantity`, `InvoiceDate`, `UnitPrice`, `CustomerID`, `Country`
- **Period:** December 2010 to December 9, 2011
- **Currency:** assumed to be GBP (£). The dataset does not state the currency, so this is an assumption.

The raw CSV and the SQLite database are not included in this repository.

## Definitions

- **Gross revenue** = `Quantity * UnitPrice` from `clean_sales`. Cancellation invoices (starting with `C`) are excluded, but purchases that were cancelled later are **not** deducted.
- **Partial month:** the data ends on 2011-12-09, so December 2011 covers only 9 days.

## Data Cleaning

The raw table (`raw_sales`) is left unchanged. All analyses use a view called `clean_sales`.

| Issue found in raw data | Rows affected |
|---|---|
| Missing `CustomerID` | 135,080 |
| Cancelled invoices (start with `C`) | 9,288 |
| Quantity less than or equal to 0 | 10,624 |
| Unit price less than or equal to 0 | 2,517 |

These categories overlap, so the counts should not be added together.

`clean_sales` removes rows with a missing `CustomerID`, cancellation invoices, non-positive quantities, and non-positive prices. It also trims text fields and adds `Revenue = Quantity * UnitPrice`.

- **Rows after cleaning:** 397,884
- **Gross revenue after cleaning:** £8,911,407.90

## Key Findings

### 1. Monthly Revenue

- Gross revenue rose from August to November 2011 (£645,343.90 → £952,838.38 → £1,039,318.79 → **£1,161,817.38**).
- December 2011 (£518,192.79, -55.4% vs November) is a **partial month**. It is not a real decline and should not be compared with full months.

### 2. Revenue by Country

| Country | Customers | Orders | Gross revenue | Share |
|---|---|---|---|---|
| United Kingdom | 3,920 | 16,646 | £7,308,391.55 | 82.0% |
| Netherlands | 9 | 94 | £285,446.34 | 3.2% |
| EIRE | 3 | 260 | £265,545.90 | 3.0% |
| Germany | 94 | 457 | £228,867.14 | 2.6% |
| France | 87 | 389 | £209,024.05 | 2.3% |

- The business depends heavily on the UK market.
- Netherlands and EIRE revenue is concentrated in very few customers. Customer 14646 alone accounts for about 98% of Netherlands revenue, and customers 14911 and 14156 together account for about 98% of EIRE revenue. Read these country shares with care.

### 3. Top Customers

- The top 10 customers account for **£1,538,276.65, about 17.3%** of gross revenue.
- The top customer (ID 14646, Netherlands) spent **£280,206.02** (3.14%) over 73 orders.
- Customer 14911 (EIRE) placed 201 orders.
- Customers 16446 (£168,472.50, 2 orders) and 12346 (£77,183.60, 1 order) rank high on gross revenue. Their net revenue may be much lower if their orders were cancelled later. This is a preliminary observation and was not verified in these queries.

### 4. Repeat Purchase

| Customer type | Customers | Share |
|---|---|---|
| Repeat customers (2+ orders) | 2,845 | 65.6% |
| One-time customers | 1,493 | 34.4% |
| **Total** | **4,338** | **100%** |

This is the share of customers with more than one order within the data window. It is not the share of Champions. Orders cancelled later are still counted as orders.

### 5. RFM Segmentation

Customers were scored from 1 to 5 on Recency, Frequency, and Monetary value using `PERCENT_RANK()` split into five equal-width bands. Customers with identical values get identical scores, so the bands are **not** equal in size (for example, all customers with one order get F=1). Monetary is gross revenue. Recency is measured from the last date in the data (2011-12-09 12:50:00), not from today.

Segment rules are evaluated in this order:

1. **Champions:** R, F, M all ≥ 4
2. **At Risk:** R ≤ 2 and F ≥ 3
3. **Loyal Customers:** F ≥ 4
4. **Lost:** R ≤ 2 and F ≤ 2
5. **Others:** everyone else

At Risk is checked before Loyal so that frequent buyers who stopped buying are not labelled Loyal.

| Segment | Customers | % customers | Gross revenue | % revenue |
|---|---|---|---|---|
| Champions | 902 | 20.8% | £5,660,235.18 | 63.5% |
| Others | 1,310 | 30.2% | £1,047,250.49 | 11.8% |
| Loyal Customers | 388 | 8.9% | £849,464.91 | 9.5% |
| Lost | 1,340 | 30.9% | £685,877.00 | 7.7% |
| At Risk | 398 | 9.2% | £668,580.32 | 7.5% |

- Champions are about 21% of customers but generate about 64% of gross revenue.
- The segment rules are my own choices, and different rules would give different segment sizes.

### 6. Cohort Retention

Customers are grouped by the month of their first purchase in the data. The query reports month 1, month 3, and month 6.

- Each value is the share of the cohort active in **exactly** that month, not cumulative retention.
- Empty cells (NULL) mean the target month is after the last month in the data (2011-12).
- Cells whose target month is December 2011 cover only 9 days, so they are understated and should not be read as a drop: 2011-11 cohort month 1 (11.1%), 2011-09 cohort month 3 (11.4%), and 2011-06 cohort month 6 (9.5%).
- The 2010-12 cohort (885 customers; 36.6%, 38.4%, 36.3% in months 1, 3, 6) is not purely new customers, because the data starts that month. Some may have bought before the dataset begins.
- The 2011-12 cohort has only 41 customers observed in 9 days, so it has no retention values.

## Limitations

- **Currency is assumed.** Amounts are treated as GBP (£), but the dataset does not confirm it.
- **Short time window.** About 13 months, so seasonality and long-term retention cannot be assessed.
- **Partial December 2011.** Data ends on December 9.
- **Customer ID only.** One person may have more than one ID, and 135,080 rows without an ID were excluded.
- **Subjective RFM rules.** Score bands and segment rules are analyst choices.
- **No causal claims.** This analysis describes patterns, not causes.
- **Cancellations not netted.** Cancellation invoices are excluded, but the purchases they may have reversed are kept. During exploration, cancellation rows with a CustomerID were found to total 8,905 rows and -£611,342.09 (this check is not included in the SQL files). It is not confirmed that these should be deducted directly, so gross revenue, top customers, and RFM monetary values may be overstated.

## Project Structure

```
online-retail-sql-analysis/
├── README.md
├── images/
│   └── online_retail_dashboard.png
├── results/
│   ├── 04_monthly_revenue.csv
│   ├── 05_monthly_growth.csv
│   ├── 06_top_countries.csv
│   ├── 07_top_customers.csv
│   ├── 08_repeat_purchase_rate.csv
│   ├── 09_rfm_raw_top10.csv
│   ├── 11_rfm_segment_summary.csv
│   └── 12_cohort_retention.csv
└── sql/
    ├── 02_create_clean_sales.sql
    ├── 04_monthly_revenue.sql
    ├── 05_monthly_growth.sql
    ├── 06_top_countries.sql
    ├── 07_top_customers.sql
    ├── 08_repeat_purchase_rate.sql
    ├── 09_rfm_raw_top10.sql
    ├── 10_create_rfm_segments.sql
    ├── 11_rfm_segment_summary.sql
    ├── 12_cohort_retention.sql
    └── retail_analysis_all.sql
```

File numbers 01 and 03 are not used as separate files. The data check (STEP 1) and the cleaning validation (STEP 3) are included only in `retail_analysis_all.sql`. File 10 creates the `rfm_segments` view and has no CSV output.

## How to Rerun

1. Download the Online Retail dataset (CSV) and import it into a SQLite database as a table named `raw_sales`.
2. Run `sql/02_create_clean_sales.sql` to create the `clean_sales` view. It starts with `DROP VIEW IF EXISTS`, so it is safe to rerun.
3. Run `sql/04` to `sql/09` one at a time.
4. Run `sql/10_create_rfm_segments.sql` **before** `sql/11_rfm_segment_summary.sql`, because file 11 reads the `rfm_segments` view.
5. Run `sql/12_cohort_retention.sql`.
6. `sql/retail_analysis_all.sql` contains STEP 1 to 12 in one file. DB Browser for SQLite shows only the result of the last statement when you run everything, so use the separate files to see each result.
