MODEL (
  name abfsslhdepotrr.mart_v4_vnew.dim_products,
  kind VIEW,
  owner 'rohitrajtmdcio',
  grain product_id,
  tags ('mart', 'view', 'depot'),
  description 'Depot-facing view over bigqueryrr.mart_v4_vnew.dim_products.'
);

SELECT * FROM bigqueryrr.mart_v4_vnew.dim_products;
