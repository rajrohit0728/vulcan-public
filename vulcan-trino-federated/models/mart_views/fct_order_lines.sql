MODEL (
  name abfsslhdepotrr.mart_v4_vnew.fct_order_lines,
  kind VIEW,
  owner 'rohitrajtmdcio',
  grain order_item_id,
  tags ('mart', 'view', 'depot'),
  description 'Depot-facing view over bigqueryrr.mart_v4_vnew.fct_order_lines.'
);

SELECT * FROM bigqueryrr.mart_v4_vnew.fct_order_lines;
