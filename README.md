# Online Retail SQL Analysis

## Overview

This project analyzes about 540,000 transactions from a UK-based online retail dataset using SQL (SQLite). The goal is to understand revenue trends, customer behavior, and customer value to support marketing and retention decisions.

## Business Questions

1. How does revenue change month to month?
2. Which countries and customers generate the most revenue?
3. What share of customers make repeat purchases?
4. Which customer segments (RFM) drive the most revenue?
5. How well are customers retained after their first purchase?

## Tools

- SQLite (queried in DB Browser for SQLite)
- SQL: CTEs, window functions (`NTILE`), joins, `CASE WHEN`, aggregation
- VS Code for organizing the query files

## Data

- **Source:** Online Retail transaction dataset (UK-based online retailer)
- **Size:** 541,909 rows
- **Columns:** `InvoiceNo`, `StockCode`, `Description`, `Quantity`, `InvoiceDate`, `UnitPrice`, `CustomerID`, `Country`
- **Period:** about 13 months, ending December 9, 2011
- **Currency:** assumed to be GBP (£). The dataset does not state the currency, so this is an assumption.

The raw CSV and the SQLite database are not included in this repository.

## Data Cleaning

The raw table (`raw_sales`) is left unchanged. All analyses use a view called `clean_sales`.

| Issue found in raw data | Rows affected |
|---|---|
| Missing `CustomerID` | 135,080 |
| Cancelled invoices (start with `C`) | 9,288 |
| Quantity less than or equal to 0 | 10,624 |
| Unit price less than or equal to 0 | 2,517 |

These categories overlap, so the counts should not be added together.

`clean_sales` removes these rows, trims text fields, and adds `Revenue = Quantity * UnitPrice`.

- **Rows after cleaning:** 397,884
- **Total revenue after cleaning:** £8,911,407.90

## Key Findings

### 1. Monthly Revenue

- Revenue rose steadily from August to November 2011 and peaked in **November 2011 at £1,161,817.38**.
- December 2011 (£518,192.79) is **incomplete**, because the data ends on December 9. It should not be compared with full months.

### 2. Revenue by Country

| Country | Revenue | Note |
|---|---|---|
| United Kingdom | £7,308,391.55 | 82.0% of total revenue, 3,920 customers, 16,646 orders |
| Netherlands | £285,446.34 | Very few buyers |
| EIRE | £265,545.90 | Very few buyers |
| Germany | £228,867.14 | Broader customer base |
| France | £209,024.05 | Broader customer base |

- The business depends heavily on the UK market.
- Netherlands and EIRE revenue comes from very few buyers, which may indicate wholesale customers. Germany and France have broader customer bases and may be better candidates for steady growth.


### 3. Top Customers

- The top 10 customers account for about **17.3%** of total revenue.
- The top customer (ID 14646, Netherlands) spent **£280,206.02**.
- Customer 14911 (EIRE) placed 201 orders, which suggests a frequent buyer.
- Customers 16446 (£168,472.50) and 12346 (£77,183.60) each placed a large order that was cancelled in full shortly afterwards (invoices C581484 and C541433). Because `clean_sales` removes cancellation invoices but keeps the original purchases, their revenue is overstated. Their true net revenue is close to zero.

### 4. Repeat Purchase

| Customer type | Customers | Share |
|---|---|---|
| Repeat customers (2+ orders) | 2,845 | 65.6% |
| One-time customers | 1,493 | 34.4% |
| **Total** | **4,338** | **100%** |

Interpret with caution: the data covers only about 13 months, and customers are identified by ID only.

### 5. RFM Segmentation

Customers were scored from 1 to 5 on Recency, Frequency, and Monetary value using `NTILE(5)`, then grouped into segments.

| Segment | Customers | Revenue | Share of revenue |
|---|---|---|---|
| Champions | 1,001 | £5.86M | 65.8% |
| Loyal Customers | 733 | £1.54M | 17.3% |
| Others | 1,556 | £0.93M | 10.5% |
| At Risk | 363 | £0.29M | 3.3% |
| Lost | 685 | £0.29M | 3.2% |

- Champions are about 23% of customers but generate about two thirds of revenue.
- Segment rules are subjective and can be adjusted. For example, Loyal Customers is defined by the Frequency score only.

### 6. Cohort Retention

Customers were grouped by the month of their first purchase, then tracked by the months in which they were active again.

- The retention figures show activity in each exact month, not cumulative retention.
- Zeros in late cohorts reflect too little observation time, not lost customers.
- December 2011 is partial, and the December 2010 cohort may include customers who bought before the dataset begins.

## Limitations

- **Currency is assumed.** Amounts are treated as GBP (£), but the dataset does not confirm the currency.
- **Short time window.** The data covers about 13 months, so seasonality and long-term retention cannot be assessed.
- **Partial December 2011.** Data ends on December 9, so December figures are incomplete.
- **Customer ID only.** Customers are identified by `CustomerID`. One person may have more than one ID, and 135,080 rows without an ID were excluded.
- **Subjective RFM rules.** Segment definitions are my own choices and different rules would give different segment sizes.
- **No causal claims.** This analysis describes patterns. It does not show why they happen.
- **Cancellations not netted.** Cancelled invoices were removed, but the purchases they reversed were kept. Revenue, top customers, and RFM figures may be overstated, especially for customers 16446 and 12346.


## Project Structure

```
online-retail-sql-analysis/
├── README.md
├── results/
└── sql/
    ├── 03_create_clean_sales.sql
    ├── 04_monthly_revenue.sql
    ├── 05_monthly_growth.sql
    ├── 06_top_countries.sql
    ├── 07_top_customers.sql
    ├── 08_repeat_purchase_rate.sql
    ├── 09_rfm_raw_top10.sql
    ├── 10_rfm_scores_top10.sql
    ├── 11_rfm_segment_summary.sql
    ├── 12_cohort_retention.sql
    └── retail_analysis_all.sql
```

## How to Rerun

1. Download the Online Retail dataset (CSV) and import it into a SQLite database as a table named `raw_sales`.
2. Run `sql/03_create_clean_sales.sql` once to create the `clean_sales` view. Do not run it again unless you drop the view first.
3. Run the numbered files in `sql/` one query at a time (04 to 12) in DB Browser for SQLite.
4. `retail_analysis_all.sql` is a combined backup. Do not run it as a whole, because it contains `CREATE VIEW clean_sales`.
