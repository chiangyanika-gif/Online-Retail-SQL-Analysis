-- --------------------------------------------
-- STEP 11: Segment summary
-- Revenue is gross revenue (cancelled invoices excluded, but
-- later cancellations of earlier purchases are not netted out).
-- Shares are based on the rfm_segments view (PERCENT_RANK scoring).
-- Requires the rfm_segments view (see 10_create_rfm_segments.sql).
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