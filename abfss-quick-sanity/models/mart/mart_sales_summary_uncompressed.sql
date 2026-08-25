MODEL (
  name abfsslhdepotrr.compression_none_v1.mart_sales_summary,
  kind FULL,
  owner 'rohitrajtmdcio',
  grains (order_date, region, category),
  tags ('mart', 'summary', 'sales', 'compression-check'),
  description 'DATAOS-4249 edge case: same shape as mart_sales_summary but with write.metadata.compression-codec explicitly set to none via physical_properties, to confirm the model-level override beats the engine-adapter gzip default.',
  physical_properties (
    'write.metadata.compression-codec' = 'none'
  ),
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
  COUNT(DISTINCT order_id) AS order_count,
  COUNT(*) AS line_count,
  CAST(SUM(quantity) AS DECIMAL(12, 2)) AS total_quantity,
  CAST(SUM(net_amount) AS DECIMAL(14, 2)) AS total_net_amount_usd
FROM abfsslhdepotrr.mart_v8_vnew.fct_order_lines
GROUP BY order_date, region, category;
