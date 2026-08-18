MODEL (
  name abfsslhdepotrr.staging_v5_vnew.stg_orders,
  kind SEED (
    path '../../seeds/raw_orders.csv'
  ),
  owner 'rohitrajtmdcio',
  grain order_id,
  tags ('staging', 'seed', 'order'),
  description 'Order headers loaded from a mock CSV seed (sample/demo data, no external source system).',
  columns (
    order_id     VARCHAR,
    customer_id  INT,
    order_date   DATE,
    order_status VARCHAR,
    channel      VARCHAR
  ),
  assertions (
    unique_values(columns := (order_id)),
    not_null(columns := (order_id, customer_id, order_date))
  )
);
