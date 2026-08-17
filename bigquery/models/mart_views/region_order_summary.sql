MODEL (
  name abfsslhdepotrr.mart_v4_vnew.region_order_summary,
  kind VIEW,
  owner 'rohitrajtmdcio',
  grain region,
  tags ('mart', 'view', 'depot'),
  description 'Depot-facing view over bigqueryrr.mart_v4_vnew.region_order_summary.'
);

SELECT * FROM bigqueryrr.mart_v4_vnew.region_order_summary;
