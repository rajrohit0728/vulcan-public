MODEL (
  name bronzev1.regions,
  kind VIEW,
  owner 'shreyasikarwartmdcio',
  grains [region_id],
  tags ('generated-data', 'bronze', 'geography'),
  description 'Generated reference data for sales and fulfillment regions.',
  columns (
    region_id INTEGER,
    region_name VARCHAR(255)
  ),
  column_descriptions (
    region_id = 'Unique region identifier',
    region_name = 'Human-readable region name (North, South, East, West)'
  ),
  column_tags (
    region_id = ('identifier', 'grain'),
    region_name = ('categorical', 'geography')
  ),
  column_terms (
    region_id = ('geography.region_id', 'sales.territory_id'),
    region_name = ('geography.region_name', 'sales.territory_name')
  ),
  assertions (
    unique_values(columns := (region_id)),
    not_null(columns := (region_id, region_name))
  )
);

SELECT
  region_id,
  region_name
FROM public_shreya.regions_ext;
