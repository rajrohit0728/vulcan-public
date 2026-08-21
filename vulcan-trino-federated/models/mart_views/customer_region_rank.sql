MODEL (
  name abfsslhdepotrr.mart_v4_vnew.customer_region_rank,
  kind VIEW,
  owner 'rohitrajtmdcio',
  grain customer_id,
  tags ('mart', 'view', 'depot'),
  description 'Depot-facing view over bigqueryrr.mart_v4_vnew.customer_region_rank.'
);

SELECT * FROM bigqueryrr.mart_v4_vnew.customer_region_rank;
