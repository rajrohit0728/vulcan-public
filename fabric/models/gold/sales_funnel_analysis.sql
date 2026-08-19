MODEL (
  name goldv1.sales_funnel_analysis,
  kind FULL,
  cron '0 */3 * * *',
  owner 'shreyasikarwartmdcio',
  grains (funnel_date, region_id),
  description 'Regional sales funnel conversion from customer registration to shipped order. funnel_date is the most recent qualifying order date per region.',
  tags ('gold', 'funnel', 'conversion', 'fulfillment'),
  terms ('analytics.sales_funnel', 'conversion.performance'),
  columns (
    funnel_date TIMESTAMP,
    region_id INTEGER,
    region_name VARCHAR(255),
    registered_customers INTEGER,
    customers_with_orders INTEGER,
    orders_placed INTEGER,
    orders_with_items INTEGER,
    orders_shipped INTEGER,
    registration_to_order_rate NUMERIC(10, 4),
    order_to_items_rate NUMERIC(10, 4),
    order_to_shipment_rate NUMERIC(10, 4),
    overall_conversion_rate NUMERIC(10, 4),
    drop_off_after_registration INTEGER,
    drop_off_orders_not_shipped INTEGER,
    avg_items_per_order NUMERIC(10, 2),
    avg_time_to_ship_days NUMERIC(10, 2)
  ),
  column_descriptions (
    funnel_date = 'Snapshot date anchored to the most recent qualifying order date per region',
    region_id = 'Sales region identifier',
    region_name = 'Sales region name (North, South, East, West)',
    registered_customers = 'Total registered customer count for this region',
    customers_with_orders = 'Customers who placed at least one qualifying order',
    orders_placed = 'Total qualifying orders placed in this region',
    orders_with_items = 'Orders that contained at least one line item',
    orders_shipped = 'Orders that were shipped in this region',
    registration_to_order_rate = 'Share of registered customers who placed an order (0-1)',
    order_to_items_rate = 'Share of orders containing at least one item (0-1)',
    order_to_shipment_rate = 'Share of orders that were shipped (0-1)',
    overall_conversion_rate = 'End-to-end funnel conversion rate from registration to shipment (0-1)',
    drop_off_after_registration = 'Registered customers who never placed an order',
    drop_off_orders_not_shipped = 'Orders placed but never shipped (unfulfilled)',
    avg_items_per_order = 'Average line items per order in this region',
    avg_time_to_ship_days = 'Average days from order placement to shipment'
  ),
  column_tags (
    funnel_date = ('temporal', 'grain', 'snapshot'),
    region_id = ('identifier', 'geography'),
    region_name = ('categorical', 'geography'),
    registered_customers = ('numeric', 'acquisition', 'funnel-top'),
    customers_with_orders = ('numeric', 'conversion', 'funnel-mid'),
    orders_placed = ('numeric', 'volume', 'funnel-mid'),
    orders_with_items = ('numeric', 'basket', 'funnel-mid'),
    orders_shipped = ('numeric', 'fulfillment', 'funnel-bottom'),
    registration_to_order_rate = ('numeric', 'rate', 'conversion'),
    order_to_items_rate = ('numeric', 'rate', 'basket'),
    order_to_shipment_rate = ('numeric', 'rate', 'fulfillment'),
    overall_conversion_rate = ('numeric', 'rate', 'overall-conversion'),
    drop_off_after_registration = ('numeric', 'drop-off', 'funnel-leakage'),
    drop_off_orders_not_shipped = ('numeric', 'drop-off', 'unfulfilled'),
    avg_items_per_order = ('numeric', 'basket-size', 'volume'),
    avg_time_to_ship_days = ('numeric', 'fulfillment', 'speed')
  ),
  column_terms (
    funnel_date = ('funnel.snapshot_date', 'retail.funnel_date'),
    region_id = ('geography.region_id', 'sales.territory_id'),
    region_name = ('geography.region_name', 'sales.territory'),
    registered_customers = ('funnel.total_registered', 'retail.registered_customers'),
    customers_with_orders = ('funnel.ordering_customers', 'retail.purchasing_customers'),
    orders_placed = ('funnel.total_orders', 'retail.orders_placed'),
    orders_with_items = ('funnel.orders_with_items', 'retail.itemized_orders'),
    orders_shipped = ('funnel.total_shipped', 'retail.shipped_orders'),
    registration_to_order_rate = ('funnel.avg_reg_to_order', 'retail.registration_conversion'),
    order_to_items_rate = ('funnel.order_to_items_rate', 'retail.basket_fill_rate'),
    order_to_shipment_rate = ('funnel.avg_fulfillment_rate', 'retail.order_to_ship'),
    overall_conversion_rate = ('funnel.avg_conversion', 'retail.e2e_conversion_rate'),
    drop_off_after_registration = ('funnel.registration_dropoff', 'retail.unconverted_registrations'),
    drop_off_orders_not_shipped = ('funnel.unfulfilled_orders', 'retail.open_backlog'),
    avg_items_per_order = ('funnel.avg_basket_size', 'retail.average_items_per_order'),
    avg_time_to_ship_days = ('funnel.avg_fulfillment_speed', 'retail.avg_ship_days')
  )
);

WITH snapshot_dates AS (
  SELECT
    c.region_id,
    CAST(MAX(CAST(o.order_date AS DATE)) AS DATETIME2(6)) AS funnel_date
  FROM bronzev1.orders AS o
  INNER JOIN bronzev1.customers AS c ON o.customer_id = c.customer_id
  WHERE @revenue_order_filter(o.order_status)
  GROUP BY c.region_id
),
registered AS (
  SELECT
    sd.funnel_date,
    c.region_id,
    r.region_name,
    CAST(COUNT(DISTINCT c.customer_id) AS INTEGER) AS registered_customers
  FROM bronzev1.customers AS c
  INNER JOIN bronzev1.regions AS r ON c.region_id = r.region_id
  INNER JOIN snapshot_dates AS sd ON c.region_id = sd.region_id
  GROUP BY sd.funnel_date, c.region_id, r.region_name
),
orders AS (
  SELECT
    c.region_id,
    CAST(COUNT(DISTINCT o.customer_id) AS INTEGER) AS customers_with_orders,
    CAST(COUNT(DISTINCT o.order_id) AS INTEGER) AS orders_placed,
    ROUND(AVG(CASE WHEN s.shipped_date IS NOT NULL THEN DATEDIFF(day, CAST(o.order_date AS DATE), s.shipped_date) END), 2) AS avg_time_to_ship_days
  FROM bronzev1.orders AS o
  INNER JOIN bronzev1.customers AS c ON o.customer_id = c.customer_id
  LEFT JOIN bronzev1.shipments AS s ON o.order_id = s.order_id
  WHERE @revenue_order_filter(o.order_status)
  GROUP BY c.region_id
),
orders_with_items AS (
  SELECT
    c.region_id,
    CAST(COUNT(DISTINCT o.order_id) AS INTEGER) AS orders_with_items,
    ROUND(AVG(item_counts.item_count), 2) AS avg_items_per_order
  FROM bronzev1.orders AS o
  INNER JOIN bronzev1.customers AS c ON o.customer_id = c.customer_id
  INNER JOIN (
    SELECT order_id, CAST(COUNT(*) AS DECIMAL(15, 2)) AS item_count
    FROM bronzev1.order_items
    GROUP BY order_id
  ) AS item_counts ON o.order_id = item_counts.order_id
  WHERE @revenue_order_filter(o.order_status)
  GROUP BY c.region_id
),
shipped AS (
  SELECT
    c.region_id,
    CAST(COUNT(DISTINCT s.order_id) AS INTEGER) AS orders_shipped
  FROM bronzev1.shipments AS s
  INNER JOIN bronzev1.orders AS o ON s.order_id = o.order_id
  INNER JOIN bronzev1.customers AS c ON o.customer_id = c.customer_id
  GROUP BY c.region_id
)
SELECT
  registered.funnel_date,
  registered.region_id,
  registered.region_name,
  registered.registered_customers,
  COALESCE(orders.customers_with_orders, 0) AS customers_with_orders,
  COALESCE(orders.orders_placed, 0) AS orders_placed,
  COALESCE(orders_with_items.orders_with_items, 0) AS orders_with_items,
  COALESCE(shipped.orders_shipped, 0) AS orders_shipped,
  @safe_ratio(COALESCE(orders.customers_with_orders, 0), registered.registered_customers, 4) AS registration_to_order_rate,
  @safe_ratio(COALESCE(orders_with_items.orders_with_items, 0), orders.orders_placed, 4) AS order_to_items_rate,
  @safe_ratio(COALESCE(shipped.orders_shipped, 0), orders.orders_placed, 4) AS order_to_shipment_rate,
  @safe_ratio(COALESCE(shipped.orders_shipped, 0), registered.registered_customers, 4) AS overall_conversion_rate,
  registered.registered_customers - COALESCE(orders.customers_with_orders, 0) AS drop_off_after_registration,
  COALESCE(orders.orders_placed, 0) - COALESCE(shipped.orders_shipped, 0) AS drop_off_orders_not_shipped,
  COALESCE(orders_with_items.avg_items_per_order, 0) AS avg_items_per_order,
  COALESCE(orders.avg_time_to_ship_days, 0) AS avg_time_to_ship_days
FROM registered
LEFT JOIN orders ON registered.region_id = orders.region_id
LEFT JOIN orders_with_items ON registered.region_id = orders_with_items.region_id
LEFT JOIN shipped ON registered.region_id = shipped.region_id;
