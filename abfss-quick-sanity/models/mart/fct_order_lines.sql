MODEL (
  name abfsslhdepotrr.mart_v8_vnew.fct_order_lines,
  kind FULL,
  owner 'rohitrajtmdcio',
  grain order_item_id,
  tags ('mart', 'fact', 'order'),
  description 'Order-line grain fact table. Excludes cancelled orders and adds a TIMESTAMP copy of order_date (order_timestamp) for time-series metrics, alongside the original DATE column used by DQ/summary grouping.',
  columns (
    order_item_id    VARCHAR,
    order_id         VARCHAR,
    order_date       DATE,
    order_timestamp  TIMESTAMP,
    order_status     VARCHAR,
    channel          VARCHAR,
    customer_id      INT,
    region           VARCHAR,
    product_id       VARCHAR,
    product_name     VARCHAR,
    category         VARCHAR,
    quantity         INT,
    unit_price       DECIMAL(10, 2),
    discount_pct     DECIMAL(5, 2),
    net_amount       DECIMAL(12, 2),
    order_value_tier VARCHAR
  ),
  assertions (
    unique_values(columns := (order_item_id)),
    not_null(columns := (order_item_id, order_id, product_id)),
    no_negative_quantity,
    no_negative_net_amount,
    net_amount_consistency
  )
);

SELECT
  order_item_id,
  order_id,
  order_date,
  CAST(order_date AS TIMESTAMP) AS order_timestamp,
  order_status,
  channel,
  customer_id,
  region,
  product_id,
  product_name,
  category,
  quantity,
  unit_price,
  discount_pct,
  net_amount,
  order_value_tier
FROM abfsslhdepotrr.intermediate_v8_vnew.int_order_lines_enriched
WHERE order_status != 'Cancelled';
