MODEL (
  name bronzev1.suppliers,
  kind FULL,
  cron '0 */3 * * *',
  owner 'shreyasikarwartmdcio',
  grains [supplier_id],
  tags ('generated-data', 'bronze', 'supplier'),
  description 'Generated supplier reference data for product sourcing analysis.',
  columns (
    supplier_id INTEGER,
    region_id INTEGER,
    name VARCHAR(255)
  ),
  column_descriptions (
    supplier_id = 'Unique supplier identifier',
    region_id = 'Region where the supplier operates',
    name = 'Supplier display name'
  ),
  column_tags (
    supplier_id = ('identifier', 'grain'),
    region_id = ('identifier', 'geography'),
    name = ('categorical', 'supplier')
  ),
  column_terms (
    supplier_id = ('supplier.id', 'vendor.supplier_id'),
    region_id = ('geography.region_id', 'supplier.region_ref'),
    name = ('supplier.name', 'vendor.display_name')
  ),
  assertions (
    unique_values(columns := (supplier_id)),
    not_null(columns := (supplier_id, region_id, name))
  )
);

SELECT
  supplier_id,
  region_id,
  name
FROM public_shreya.suppliers_ext;
