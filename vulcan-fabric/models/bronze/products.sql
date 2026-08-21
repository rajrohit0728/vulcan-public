MODEL (
  name bronzev1.products,
  kind FULL,
  cron '0 */3 * * *',
  owner 'shreyasikarwartmdcio',
  grains [product_id],
  tags ('generated-data', 'bronze', 'product', 'pricing'),
  description 'Generated product catalog data with supplier, category, and list price.',
  columns (
    product_id INTEGER,
    supplier_id INTEGER,
    name VARCHAR(255),
    category VARCHAR(255),
    price NUMERIC(10, 2)
  ),
  column_descriptions (
    product_id = 'Unique product identifier',
    supplier_id = 'Supplier who provides this product',
    name = 'Product display name',
    category = 'Product category (Widgets, Gadgets, Doohickeys, Thingamajigs)',
    price = 'Current list price of the product'
  ),
  column_tags (
    product_id = ('identifier', 'grain'),
    supplier_id = ('identifier', 'supplier'),
    name = ('categorical', 'product'),
    category = ('categorical', 'merchandising'),
    price = ('numeric', 'financial', 'pricing')
  ),
  column_terms (
    product_id = ('product.id', 'inventory.product_id'),
    supplier_id = ('supplier.id', 'product.supplier_ref'),
    name = ('product.name', 'retail.sku_name'),
    category = ('product.category', 'retail.merchandise_category'),
    price = ('pricing.list_price', 'product.unit_price')
  ),
  assertions (
    unique_values(columns := (product_id)),
    not_null(columns := (product_id, supplier_id, name, category, price)),
    accepted_values(column := category, is_in := ('Widgets', 'Gadgets', 'Doohickeys', 'Thingamajigs'))
  )
);

SELECT
  product_id,
  supplier_id,
  name,
  category,
  price
FROM public_shreya.products_ext;
