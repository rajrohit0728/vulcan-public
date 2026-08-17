AUDIT (
  name no_null_region_tier
);

SELECT * FROM @this_model WHERE region_tier IS NULL
