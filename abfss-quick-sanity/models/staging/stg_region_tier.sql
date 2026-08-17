MODEL (
  name abfsslhdepotrr.staging_v3_vnew.stg_region_tier,
  kind SEED (
    path '../../seeds/region_tier.csv'
  ),
  owner 'rohitrajtmdcio',
  grain region,
  tags ('staging', 'seed', 'lookup'),
  description 'Business tier/priority lookup for sales regions (hand-curated reference table, not derived from the customer/order seed data).',
  columns (
    region        VARCHAR,
    region_tier   VARCHAR,
    priority_rank INT
  ),
  assertions (
    unique_values(columns := (region)),
    not_null(columns := (region))
  )
);
