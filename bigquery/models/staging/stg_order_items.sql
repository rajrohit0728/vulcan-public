MODEL (
  name bigqueryrr.staging_v4_vnew.stg_order_items,
  kind SEED (
    path '../../seeds/raw_order_items.csv'
  ),
  owner 'rohitrajtmdcio',
  grain order_item_id,
  tags ('staging', 'seed', 'order'),
  description 'Order line items loaded from a mock CSV seed (sample/demo data, no external source system).',
  columns (
    order_item_id VARCHAR,
    order_id      VARCHAR,
    product_id    VARCHAR,
    quantity      INT,
    unit_price    DECIMAL(10, 2),
    discount_pct  DECIMAL(5, 2)
  ),
  assertions (
    unique_values(columns := (order_item_id)),
    not_null(columns := (order_item_id, order_id, product_id))
  )
);
