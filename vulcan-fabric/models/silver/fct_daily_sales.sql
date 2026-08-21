MODEL (
  name silverv1.fct_daily_sales,
  kind FULL,
  cron '0 */3 * * *',
  owner 'shreyasikarwartmdcio',
  grains (order_date, region_id, customer_id, product_id),
  description 'Daily sales fact table by order date, customer, product, and region with shipment flag.',
  tags ('silver', 'fact', 'daily-sales', 'revenue', 'retail-intelligence'),
  terms ('sales.daily_metrics', 'revenue.analytics', 'retail.daily_performance'),
  columns (
    order_date TIMESTAMP,
    region_id INTEGER,
    region_name VARCHAR(255),
    customer_id INTEGER,
    product_id INTEGER,
    category VARCHAR(255),
    total_orders INTEGER,
    total_items_sold INTEGER,
    total_revenue NUMERIC(15, 2),
    avg_order_value NUMERIC(15, 2),
    total_shipments INTEGER,
    shipment_rate NUMERIC(10, 4),
    has_shipment BIT
  ),
  column_descriptions (
    order_date = 'Order date at daily grain',
    region_id = 'Customer region identifier',
    region_name = 'Customer region name',
    customer_id = 'Customer identifier',
    product_id = 'Product identifier',
    category = 'Product category',
    total_orders = 'Distinct orders at this grain',
    total_items_sold = 'Units sold',
    total_revenue = 'Gross revenue from line items',
    avg_order_value = 'Revenue divided by order count',
    total_shipments = 'Distinct shipped orders at this grain',
    shipment_rate = 'Shipped orders divided by total orders',
    has_shipment = 'True if at least one order in this row was shipped'
  ),
  column_tags (
    order_date = ('temporal', 'grain', 'time-series'),
    region_id = ('identifier', 'geography'),
    region_name = ('categorical', 'geography'),
    customer_id = ('identifier', 'customer'),
    product_id = ('identifier', 'product'),
    category = ('categorical', 'merchandising'),
    total_orders = ('numeric', 'volume'),
    total_items_sold = ('numeric', 'volume'),
    total_revenue = ('numeric', 'revenue', 'financial'),
    avg_order_value = ('numeric', 'basket-value'),
    total_shipments = ('numeric', 'fulfillment'),
    shipment_rate = ('numeric', 'rate', 'fulfillment'),
    has_shipment = ('boolean', 'fulfillment')
  ),
  column_terms (
    order_date = ('sales.order_date', 'retail.transaction_date'),
    region_id = ('geography.region_id', 'sales.territory_id'),
    region_name = ('geography.region_name', 'sales.territory'),
    customer_id = ('customer.id', 'sales.customer_ref'),
    product_id = ('product.id', 'sales.product_ref'),
    category = ('product.category', 'retail.merchandise_category'),
    total_orders = ('sales.total_orders', 'retail.order_count'),
    total_items_sold = ('sales.total_units', 'retail.unit_volume'),
    total_revenue = ('sales.total_revenue', 'retail.gross_revenue'),
    avg_order_value = ('sales.avg_order_value', 'retail.average_basket'),
    total_shipments = ('fulfillment.total_shipments', 'sales.shipped_orders'),
    shipment_rate = ('fulfillment.shipment_rate', 'sales.fulfillment_rate'),
    has_shipment = ('sales.has_shipment', 'fulfillment.shipped_flag')
  ),
  assertions (
    not_null(columns := (order_date, region_id, region_name, customer_id, product_id, category)),
    forall(criteria := (total_orders >= 0, total_items_sold >= 0, total_revenue >= 0, total_shipments >= 0))
  )
);

WITH order_metrics AS (
  SELECT
    CAST(o.order_date AS DATE) AS order_date,
    c.region_id,
    r.region_name,
    o.customer_id,
    oi.product_id,
    p.category,
    CAST(COUNT(DISTINCT o.order_id) AS INTEGER) AS total_orders,
    CAST(SUM(oi.quantity) AS INTEGER) AS total_items_sold,
    CAST(SUM(oi.quantity * oi.unit_price) AS DECIMAL(15, 2)) AS total_revenue
  FROM bronzev1.orders AS o
  INNER JOIN bronzev1.customers AS c ON o.customer_id = c.customer_id
  INNER JOIN bronzev1.regions AS r ON c.region_id = r.region_id
  INNER JOIN bronzev1.order_items AS oi ON o.order_id = oi.order_id
  INNER JOIN bronzev1.products AS p ON oi.product_id = p.product_id
  WHERE @revenue_order_filter(o.order_status)
  GROUP BY CAST(o.order_date AS DATE), c.region_id, r.region_name, o.customer_id, oi.product_id, p.category
),
shipment_metrics AS (
  SELECT
    CAST(o.order_date AS DATE) AS order_date,
    c.region_id,
    o.customer_id,
    oi.product_id,
    CAST(COUNT(DISTINCT s.shipment_id) AS INTEGER) AS total_shipments
  FROM bronzev1.orders AS o
  INNER JOIN bronzev1.customers AS c ON o.customer_id = c.customer_id
  INNER JOIN bronzev1.order_items AS oi ON o.order_id = oi.order_id
  LEFT JOIN bronzev1.shipments AS s ON o.order_id = s.order_id
  WHERE @revenue_order_filter(o.order_status)
  GROUP BY CAST(o.order_date AS DATE), c.region_id, o.customer_id, oi.product_id
)
SELECT
  CAST(om.order_date AS TIMESTAMP) AS order_date,
  om.region_id,
  om.region_name,
  om.customer_id,
  om.product_id,
  om.category,
  om.total_orders,
  om.total_items_sold,
  ROUND(om.total_revenue, 2) AS total_revenue,
  @safe_ratio(om.total_revenue, om.total_orders, 2) AS avg_order_value,
  COALESCE(sm.total_shipments, 0) AS total_shipments,
  @safe_ratio(COALESCE(sm.total_shipments, 0), om.total_orders, 4) AS shipment_rate,
  @boolean_flag(COALESCE(sm.total_shipments, 0) > 0) AS has_shipment
FROM order_metrics AS om
LEFT JOIN shipment_metrics AS sm
  ON om.order_date = sm.order_date
  AND om.region_id = sm.region_id
  AND om.customer_id = sm.customer_id
  AND om.product_id = sm.product_id;
