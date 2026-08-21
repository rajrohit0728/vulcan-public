MODEL (
  name bronzev1.warehouses,
  kind FULL,
  cron '0 */3 * * *',
  owner 'shreyasikarwartmdcio',
  grains [warehouse_id],
  tags ('generated-data', 'bronze', 'warehouse', 'fulfillment'),
  description 'Generated warehouse reference data by fulfillment region.',
  columns (
    warehouse_id INTEGER,
    region_id INTEGER,
    name VARCHAR(255)
  ),
  column_descriptions (
    warehouse_id = 'Unique warehouse identifier',
    region_id = 'Region the warehouse serves',
    name = 'Warehouse display name'
  ),
  column_tags (
    warehouse_id = ('identifier', 'grain'),
    region_id = ('identifier', 'geography'),
    name = ('categorical', 'fulfillment')
  ),
  column_terms (
    warehouse_id = ('fulfillment.warehouse_id', 'logistics.facility_id'),
    region_id = ('geography.region_id', 'fulfillment.region_ref'),
    name = ('fulfillment.warehouse_name', 'logistics.facility_name')
  ),
  assertions (
    unique_values(columns := (warehouse_id)),
    not_null(columns := (warehouse_id, region_id, name))
  )
);

SELECT
  warehouse_id,
  region_id,
  name
FROM public_shreya.warehouses_ext;
