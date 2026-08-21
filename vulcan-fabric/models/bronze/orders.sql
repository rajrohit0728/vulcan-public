MODEL (
  name bronzev1.orders,
  kind INCREMENTAL_BY_TIME_RANGE (
    time_column order_date
  ),
  start '2025-01-01',
  cron '0 */3 * * *',
  owner 'shreyasikarwartmdcio',
  grains [order_id],
  tags ('generated-data', 'bronze', 'orders', 'sales'),
  description 'Generated order transactions with customer, warehouse, status, and timestamp.',
  columns (
    order_id INTEGER,
    customer_id INTEGER,
    order_date TIMESTAMP,
    warehouse_id INTEGER,
    order_status VARCHAR(255)
  ),
  column_descriptions (
    order_id = 'Unique order identifier',
    customer_id = 'Customer who placed the order',
    order_date = 'Timestamp when the order was placed',
    warehouse_id = 'Fulfillment warehouse assigned to the order',
    order_status = 'Current order lifecycle status (Confirmed, Shipped, Cancelled)'
  ),
  column_tags (
    order_id = ('identifier', 'grain'),
    customer_id = ('identifier', 'customer'),
    order_date = ('temporal', 'event'),
    warehouse_id = ('identifier', 'fulfillment'),
    order_status = ('categorical', 'lifecycle')
  ),
  column_terms (
    order_id = ('order.id', 'sales.order_id'),
    customer_id = ('customer.id', 'order.customer_ref'),
    order_date = ('sales.order_date', 'event.order_timestamp'),
    warehouse_id = ('fulfillment.warehouse_id', 'logistics.warehouse_ref'),
    order_status = ('order.status', 'sales.order_lifecycle')
  ),
  assertions (
    unique_values(columns := (order_id)),
    not_null(columns := (order_id, customer_id, order_date, warehouse_id, order_status)),
    accepted_values(column := order_status, is_in := ('Confirmed', 'Shipped', 'Cancelled')),
    order_status_lookup_consistency()
  )
);

SELECT
  order_id,
  customer_id,
  order_date,
  warehouse_id,
  order_status
FROM public_shreya.orders_ext
WHERE order_date >= @start_date AND order_date < @end_date;
