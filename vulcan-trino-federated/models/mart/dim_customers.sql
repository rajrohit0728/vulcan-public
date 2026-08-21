MODEL (
  name bigqueryrr.mart_v4_vnew.dim_customers,
  kind FULL,
  owner 'rohitrajtmdcio',
  grain customer_id,
  tags ('mart', 'dimension', 'customer'),
  description 'Customer dimension for reporting.',
  columns (
    customer_id   INT,
    name          VARCHAR,
    email         VARCHAR,
    region        VARCHAR,
    customer_tier VARCHAR,
    signup_date   DATE,
    region_tier   VARCHAR,
    priority_rank INT
  ),
  assertions (
    unique_values(columns := (customer_id)),
    not_null(columns := (customer_id)),
    no_null_region_tier,
    region_tier_lookup_consistency
  )
);

SELECT
  customer_id,
  name,
  email,
  region,
  customer_tier,
  signup_date,
  region_tier,
  priority_rank
FROM bigqueryrr.intermediate_v4_vnew.int_customers_enriched;
