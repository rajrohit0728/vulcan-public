AUDIT (
  name region_tier_lookup_consistency
);

-- Re-derives the region_tier join inside the audit itself, rather than
-- checking an already-joined column (no_null_region_tier does the latter) —
-- catches drift even if the upstream join in int_customers_enriched were
-- ever removed or miswired.
SELECT c.*
FROM @this_model AS c
LEFT JOIN gcslhdepot.staging_v6_vnew.stg_region_tier AS t
  ON c.region = t.region
WHERE t.region IS NULL
