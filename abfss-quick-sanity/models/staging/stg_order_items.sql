MODEL (
  name abfsslhdepotrr.staging_v3_vnew.stg_order_items,
  kind SEED (
    path '../../seeds/raw_order_items.csv'
  ),
  owner 'rohitrajtmdcio',
  grain order_item_id,
  tags ('staging', 'seed', 'order'),
  description 'Order line items loaded from a mock CSV seed (sample/demo data, no external source system).',
  assertions (
    unique_values(columns := (order_item_id)),
    not_null(columns := (order_item_id, order_id, product_id))
  )
);
