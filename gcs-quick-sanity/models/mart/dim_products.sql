MODEL (
  name gcslhdepot.mart_v5_vnew.dim_products,
  kind FULL,
  owner 'rohitrajtmdcio',
  grain product_id,
  tags ('mart', 'dimension', 'product'),
  description 'Product catalog dimension with a computed margin percentage.',
  columns (
    product_id   VARCHAR,
    product_name VARCHAR,
    category     VARCHAR,
    brand        VARCHAR,
    unit_cost    DECIMAL(10, 2),
    list_price   DECIMAL(10, 2),
    margin_pct   DECIMAL(5, 2)
  ),
  assertions (
    unique_values(columns := (product_id)),
    not_null(columns := (product_id, product_name))
  )
);

SELECT
  product_id,
  product_name,
  category,
  brand,
  CAST(unit_cost AS DECIMAL(10, 2)) AS unit_cost,
  CAST(list_price AS DECIMAL(10, 2)) AS list_price,
  CAST(ROUND((list_price - unit_cost) / NULLIF(list_price, 0) * 100, 2) AS DECIMAL(5, 2)) AS margin_pct
FROM gcslhdepot.staging_v5_vnew.stg_products;
