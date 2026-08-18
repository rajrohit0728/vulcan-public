MODEL (
  name abfsslhdepotrr.staging_v5_vnew.stg_customers,
  kind SEED (
    path '../../seeds/raw_customers.csv'
  ),
  owner 'rohitrajtmdcio',
  grain customer_id,
  tags ('staging', 'seed', 'customer'),
  description 'Customer master data loaded from a mock CSV seed (sample/demo data, no external source system).',
  columns (
    customer_id   INT,
    name          VARCHAR,
    email         VARCHAR,
    region        VARCHAR,
    customer_tier VARCHAR,
    signup_date   DATE
  ),
  assertions (
    unique_values(columns := (customer_id)),
    not_null(columns := (customer_id, name, email))
  )
);
