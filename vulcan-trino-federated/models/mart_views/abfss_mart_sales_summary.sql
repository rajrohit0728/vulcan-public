MODEL (
  name abfsslhdepotrr.mart_v4_vnew.abfss_mart_sales_summary,
  kind VIEW,
  owner 'rohitrajtmdcio',
  grains (order_date, region, category),
  tags ('mart', 'view', 'depot', 'federated', 'abfss'),
  description 'Trino-federated view over the Spark-materialized Iceberg table abfsslhdepotrr.mart_v6_vnew.mart_sales_summary (abfss-spark-dp).',
  columns (
    order_date           DATE,
    region               VARCHAR,
    category             VARCHAR,
    order_count          INT,
    line_count           INT,
    total_quantity       DECIMAL(12, 2),
    total_net_amount_usd DECIMAL(14, 2)
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
