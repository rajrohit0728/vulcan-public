MODEL (
  name abfsslhdepotrr.intermediate_v6_vnew.int_order_lines_enriched,
  kind FULL,
  owner 'rohitrajtmdcio',
  grain order_item_id,
  tags ('intermediate', 'order'),
  description 'Order line items enriched with order header, customer, and product attributes; computes net_amount and order_value_tier via macros.',
  columns (
    order_item_id    VARCHAR,
    order_id         VARCHAR,
    order_date       DATE,
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
    not_null(columns := (order_item_id, order_id, product_id))
  )
);

SELECT
  order_item_id,
  order_id,
  order_date,
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
  @order_value_tier(net_amount) AS order_value_tier
FROM (
  SELECT
    oi.order_item_id,
    oi.order_id,
    o.order_date,
    o.order_status,
    o.channel,
    o.customer_id,
    c.region,
    oi.product_id,
    p.product_name,
    p.category,
    oi.quantity,
    CAST(oi.unit_price AS DECIMAL(10, 2)) AS unit_price,
    CAST(oi.discount_pct AS DECIMAL(5, 2)) AS discount_pct,
    CAST(@net_amount(oi.quantity, oi.unit_price, oi.discount_pct) AS DECIMAL(12, 2)) AS net_amount
  FROM abfsslhdepotrr.staging_v6_vnew.stg_order_items AS oi
  JOIN abfsslhdepotrr.staging_v6_vnew.stg_orders AS o
    ON oi.order_id = o.order_id
  JOIN abfsslhdepotrr.staging_v6_vnew.stg_customers AS c
    ON o.customer_id = c.customer_id
  JOIN abfsslhdepotrr.staging_v6_vnew.stg_products AS p
    ON oi.product_id = p.product_id
) AS base;
