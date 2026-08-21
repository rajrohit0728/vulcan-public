MODEL (
  name bigqueryrr.staging_v3_vnew.stg_products,
  kind SEED (
    path '../../seeds/raw_products.csv'
  ),
  owner 'rohitrajtmdcio',
  grain product_id,
  tags ('staging', 'seed', 'product'),
  description 'Product catalog loaded from a mock CSV seed (sample/demo data, no external source system).',
  columns (
    product_id   VARCHAR,
    product_name VARCHAR,
    category     VARCHAR,
    brand        VARCHAR,
    unit_cost    DECIMAL(10, 2),
    list_price   DECIMAL(10, 2)
  ),
  assertions (
    unique_values(columns := (product_id)),
    not_null(columns := (product_id, product_name))
  )
);
