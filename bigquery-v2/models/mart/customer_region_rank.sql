MODEL (
  name bigqueryrr.mart_v3_vnew.customer_region_rank,
  kind FULL,
  owner 'rohitrajtmdcio',
  grain customer_id,
  tags ('mart', 'analytics', 'customer', 'ranking'),
  description 'Ranks each customer by total net spend within their region and compares against the regional average (window functions).',
  columns (
    customer_id          INT,
    region               VARCHAR,
    total_spent          DECIMAL(14, 2),
    spend_rank_in_region INT,
    region_avg_spent     DECIMAL(14, 2)
  ),
  assertions (
    not_null(columns := (customer_id, region))
  )
);

SELECT
  customer_id,
  region,
  total_spent,
  CAST(RANK() OVER (PARTITION BY region ORDER BY total_spent DESC) AS INT) AS spend_rank_in_region,
  CAST(AVG(total_spent) OVER (PARTITION BY region) AS DECIMAL(14, 2)) AS region_avg_spent
FROM (
  SELECT
    c.customer_id,
    c.region,
    CAST(COALESCE(SUM(f.net_amount), 0) AS DECIMAL(14, 2)) AS total_spent
  FROM bigqueryrr.mart_v3_vnew.dim_customers AS c
  LEFT JOIN bigqueryrr.mart_v3_vnew.fct_order_lines AS f
    ON c.customer_id = f.customer_id
  GROUP BY c.customer_id, c.region
) AS base;
