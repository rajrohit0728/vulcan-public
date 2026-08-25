MODEL (
  name abfsslhdepotrr.trino_fed_v1.mart_sales_summary,
  kind FULL,
  owner 'rohitrajtmdcio',
  grains (order_date, region, category),
  tags ('mart', 'summary', 'sales', 'federated', 'cross-engine'),
  description 'Spark FULL copy of Trino-materialized abfsslhdepotrr.abfss_fed_v1.mart_sales_summary — DATAOS-4249 cross-engine read check: proves a Trino-written gzip-metadata Iceberg table is readable by Spark.',
  columns (
    order_date       DATE,
    region           VARCHAR,
    category         VARCHAR,
    order_count      INT,
    line_count       INT,
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
FROM abfsslhdepotrr.abfss_fed_v1.mart_sales_summary;
