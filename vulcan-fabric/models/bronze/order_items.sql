MODEL (
  name bronzev1.order_items,
  kind FULL,
  cron '0 */3 * * *',
  owner 'shreyasikarwartmdcio',
  grains (order_id, item_id),
  tags ('generated-data', 'bronze', 'line-items', 'sales'),
  description 'Generated order line item data at product grain.',
  columns (
    order_id INTEGER,
    item_id INTEGER,
    product_id INTEGER,
    quantity INTEGER,
    unit_price NUMERIC(10, 2)
  ),
  column_descriptions (
    order_id = 'Parent order identifier',
    item_id = 'Line item sequence within the order',
    product_id = 'Product SKU reference for this line item',
    quantity = 'Number of units ordered for this line item',
    unit_price = 'Per-unit selling price at time of order'
  ),
  column_tags (
    order_id = ('identifier', 'sales'),
    item_id = ('identifier', 'grain'),
    product_id = ('identifier', 'product'),
    quantity = ('numeric', 'volume'),
    unit_price = ('numeric', 'financial', 'pricing')
  ),
  column_terms (
    order_id = ('order.id', 'sales.order_ref'),
    item_id = ('order.line_item_id', 'sales.item_sequence'),
    product_id = ('product.id', 'order.product_ref'),
    quantity = ('order.quantity', 'sales.units_ordered'),
    unit_price = ('pricing.unit_price', 'sales.selling_price')
  ),
  assertions (
    unique_combination_of_columns(columns := (order_id, item_id)),
    not_null(columns := (order_id, item_id, product_id, quantity, unit_price)),
    forall(criteria := (quantity > 0, unit_price >= 0))
  )
);

SELECT
  order_id,
  item_id,
  product_id,
  quantity,
  unit_price
FROM public_shreya.order_items_ext;
