MODEL (
  name abfsslhdepotrr.abfss_fed_v1.dim_customers,
  kind FULL,
  owner 'rohitrajtmdcio',
  grain customer_id,
  tags ('federated', 'abfss', 'dimension', 'customer'),
  description 'FULL copy of Spark-materialized abfsslhdepotrr.mart_v6_vnew.dim_customers (abfss-spark-dp).',
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
    no_null_region_tier
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
FROM abfsslhdepotrr.mart_v6_vnew.dim_customers;
