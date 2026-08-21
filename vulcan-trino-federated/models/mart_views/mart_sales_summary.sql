MODEL (
  name abfsslhdepotrr.mart_v4_vnew.mart_sales_summary,
  kind VIEW,
  owner 'rohitrajtmdcio',
  grains (order_date, region, category),
  tags ('mart', 'view', 'depot'),
  description 'Depot-facing view over bigqueryrr.mart_v4_vnew.mart_sales_summary.'
);

SELECT * FROM bigqueryrr.mart_v4_vnew.mart_sales_summary;
