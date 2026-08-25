MODEL (
  name abfsslhdepotrr.abfss_fed_v1.mart_sales_summary,
  kind FULL,
  owner 'rohitrajtmdcio',
  grains (order_date, region, category),
  tags ('federated', 'abfss', 'summary', 'sales'),
  description 'FULL copy of Spark-materialized abfsslhdepotrr.mart_v6_vnew.mart_sales_summary (abfss-spark-dp).',
  columns (
    order_date           DATE,
    region               VARCHAR,
    category             VARCHAR,
    order_count          INT,
    line_count           INT,
    total_quantity       DECIMAL(12, 2),
    total_net_amount_usd DECIMAL(14, 2)
  ),
  assertions (
    not_null(columns := (order_date, region, category)),
    no_negative_total_net_amount
  )
);

SELECT
  order_date,
  region,
  category,
  order_count,
  line_count,
  total_quantity,
  total_net_amount_usd
FROM abfsslhdepotrr.mart_v6_vnew.mart_sales_summary;
