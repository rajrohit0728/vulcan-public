MODEL (
  name abfsslhdepotrr.mart_v7_vnew.region_order_summary,
  kind FULL,
  owner 'rohitrajtmdcio',
  grain region,
  tags ('mart', 'summary', 'region', 'demo'),
  description 'Order and revenue totals by customer region — quick demo model for Explore.',
  columns (
    region              VARCHAR,
    customer_count      INT,
    order_count         INT,
    total_net_amount    DECIMAL(14, 2),
    avg_order_value     DECIMAL(14, 2)
  ),
  assertions (
    not_null(columns := (region))
  )
);

SELECT
  region,
  COUNT(DISTINCT customer_id) AS customer_count,
  COUNT(DISTINCT order_id) AS order_count,
  CAST(SUM(net_amount) AS DECIMAL(14, 2)) AS total_net_amount,
  CAST(
    SUM(net_amount) / NULLIF(COUNT(DISTINCT order_id), 0) AS DECIMAL(14, 2)
  ) AS avg_order_value
FROM abfsslhdepotrr.mart_v7_vnew.fct_order_lines
GROUP BY region;
