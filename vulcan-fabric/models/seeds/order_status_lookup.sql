MODEL (
  name bronzev1.order_status_lookup,
  kind SEED (
    path '../../seeds/order_status_lookup.csv'
  ),
  columns (
    order_status VARCHAR(255),
    status_group VARCHAR(255),
    is_fulfilled BIT,
    is_active_sort INTEGER,
    description VARCHAR(255)
  ),
  column_descriptions (
    order_status = 'Order status value as stored in the orders table (Confirmed, Shipped, Cancelled)',
    status_group = 'Higher-level group that this status belongs to',
    is_fulfilled = 'True if this status indicates a completed fulfillment',
    is_active_sort = 'Sort order for active status filtering (1 = active, 0 = inactive)',
    description = 'Human-readable explanation of what this order status means'
  ),
  column_tags (
    order_status = ('categorical', 'grain', 'lookup'),
    status_group = ('categorical', 'classification'),
    is_fulfilled = ('boolean', 'fulfillment'),
    is_active_sort = ('numeric', 'sort'),
    description = ('categorical', 'documentation')
  ),
  column_terms (
    order_status = ('order.status', 'sales.order_lifecycle'),
    status_group = ('order.status_group', 'sales.status_classification'),
    is_fulfilled = ('fulfillment.is_complete', 'order.fulfilled_flag'),
    is_active_sort = ('order.active_sort', 'sales.status_sort_order'),
    description = ('order.status_description', 'documentation.status_meaning')
  ),
  grains [order_status],
  owner 'shreyasikarwartmdcio',
  tags ('seed-data', 'bronze', 'lookup', 'order-status'),
  description 'Static lookup table for order status classification used by order analytics models.',
  assertions (
    unique_values(columns := (order_status)),
    not_null(columns := (order_status, status_group, is_fulfilled, is_active_sort, description)),
    accepted_values(column := order_status, is_in := ('Confirmed', 'Shipped', 'Cancelled'))
  )
);
