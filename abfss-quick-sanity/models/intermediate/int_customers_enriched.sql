MODEL (
  name abfsslhdepotrr.intermediate_v6_vnew.int_customers_enriched,
  kind FULL,
  owner 'rohitrajtmdcio',
  grain customer_id,
  tags ('intermediate', 'customer'),
  description 'Customers enriched with their region tier/priority from the region_tier seed lookup.',
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
    not_null(columns := (customer_id, region))
  )
);

SELECT
  c.customer_id,
  c.name,
  c.email,
  c.region,
  c.customer_tier,
  c.signup_date,
  t.region_tier,
  t.priority_rank
FROM abfsslhdepotrr.staging_v6_vnew.stg_customers AS c
LEFT JOIN abfsslhdepotrr.staging_v6_vnew.stg_region_tier AS t
  ON c.region = t.region;
