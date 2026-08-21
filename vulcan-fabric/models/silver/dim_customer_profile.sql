MODEL (
  name silverv1.dim_customer_profile,
  kind FULL,
  cron '0 */3 * * *',
  owner 'shreyasikarwartmdcio',
  grains [customer_id],
  description 'Customer profile dimension with lifetime purchase, shipment metrics, and retail segmentation flags.',
  tags ('silver', 'dimension', 'customer-profile', 'segmentation', 'retail-intelligence'),
  terms ('customer.profile_analytics', 'customer.lifetime_value', 'retail.customer_segmentation'),
  columns (
    customer_id INTEGER,
    customer_name VARCHAR(255),
    email VARCHAR(255),
    signup_date TIMESTAMP,
    region_id INTEGER,
    region_name VARCHAR(255),
    first_order_date TIMESTAMP,
    last_order_date TIMESTAMP,
    days_since_first_order INTEGER,
    days_since_last_order INTEGER,
    total_orders INTEGER,
    total_items_purchased INTEGER,
    total_revenue NUMERIC(15, 2),
    avg_order_value NUMERIC(15, 2),
    favorite_category VARCHAR(255),
    total_shipments_received INTEGER,
    customer_segment VARCHAR(255),
    is_new_customer BIT,
    is_high_value_customer BIT,
    is_active_customer BIT
  ),
  column_descriptions (
    customer_id = 'Unique customer identifier',
    customer_name = 'Full display name of the customer (PII)',
    email = 'Customer email address (PII)',
    signup_date = 'Date the customer first registered',
    region_id = 'Sales region identifier',
    region_name = 'Sales region name (North, South, East, West)',
    first_order_date = 'Timestamp of the customer first qualifying order',
    last_order_date = 'Timestamp of the customer most recent qualifying order',
    days_since_first_order = 'Days elapsed since first order; 0 for new customers',
    days_since_last_order = 'Days elapsed since last order; 9999 for new customers',
    total_orders = 'Lifetime count of qualifying orders',
    total_items_purchased = 'Lifetime units purchased across all orders',
    total_revenue = 'Gross lifetime revenue attributed to this customer',
    avg_order_value = 'Average order value across the customer order history',
    favorite_category = 'Product category most frequently purchased',
    total_shipments_received = 'Total shipments received by this customer',
    customer_segment = 'Value segment: New, Low Value, Medium Value, High Value, or Churned',
    is_new_customer = 'True for customers who have placed no orders yet',
    is_high_value_customer = 'True for customers with lifetime revenue >= 1000 and active within 180 days',
    is_active_customer = 'True for customers who ordered within the last 90 days'
  ),
  column_tags (
    customer_id = ('identifier', 'grain'),
    customer_name = ('pii', 'customer'),
    email = ('pii', 'contact'),
    signup_date = ('temporal', 'acquisition'),
    region_id = ('identifier', 'geography'),
    region_name = ('categorical', 'geography'),
    first_order_date = ('temporal', 'order'),
    last_order_date = ('temporal', 'recency'),
    days_since_first_order = ('numeric', 'tenure'),
    days_since_last_order = ('numeric', 'recency'),
    total_orders = ('numeric', 'frequency'),
    total_items_purchased = ('numeric', 'volume'),
    total_revenue = ('numeric', 'revenue', 'ltv'),
    avg_order_value = ('numeric', 'basket-value'),
    favorite_category = ('categorical', 'preference', 'merchandising'),
    total_shipments_received = ('numeric', 'fulfillment'),
    customer_segment = ('categorical', 'segmentation'),
    is_new_customer = ('boolean', 'activation'),
    is_high_value_customer = ('boolean', 'high-value'),
    is_active_customer = ('boolean', 'recency')
  ),
  column_terms (
    customer_id = ('customer.id', 'identity.customer_id'),
    customer_name = ('customer.display_name', 'identity.full_name'),
    email = ('customer.email', 'contact.email_address'),
    signup_date = ('customer.signup_date', 'acquisition.registration_date'),
    region_id = ('geography.region_id', 'customer.region'),
    region_name = ('geography.region_name', 'sales.territory'),
    first_order_date = ('customer.first_order_date', 'retail.first_purchase'),
    last_order_date = ('customer.last_order_date', 'retail.last_purchase'),
    days_since_first_order = ('customer.tenure_days', 'retail.days_since_first_order'),
    days_since_last_order = ('customer.recency_days', 'retail.days_since_last_order'),
    total_orders = ('customer.total_orders', 'retail.order_count'),
    total_items_purchased = ('customer.total_items', 'retail.unit_volume'),
    total_revenue = ('customer.total_ltv', 'retail.lifetime_revenue'),
    avg_order_value = ('customer.avg_order_value', 'retail.average_basket'),
    favorite_category = ('customer.favorite_category', 'product.preferred_category'),
    total_shipments_received = ('customer.shipments_received', 'fulfillment.received_count'),
    customer_segment = ('customer.segment', 'retail.ltv_segment'),
    is_new_customer = ('customer.is_new', 'retail.unactivated'),
    is_high_value_customer = ('customer.is_high_value', 'retail.premium_customer'),
    is_active_customer = ('customer.is_active', 'retail.active_buyer')
  ),
  column_mask_expressions (
    customer_name = '***redacted***',
    email = '****',
    total_revenue = CAST(0 AS NUMERIC(15, 2))
  ),
  column_classifications (
    customer_name = restricted,
    email = restricted,
    region_name = internal,
    total_revenue = confidential
  ),
  assertions (
    unique_values(columns := (customer_id)),
    not_null(columns := (customer_id, customer_name, email, signup_date, region_id, region_name)),
    accepted_values(column := customer_segment, is_in := ('High Value', 'Medium Value', 'Low Value', 'Churned', 'New'))
  )
);

WITH customer_orders AS (
  SELECT
    c.customer_id,
    c.name AS customer_name,
    c.email,
    c.signup_date,
    c.region_id,
    r.region_name,
    MIN(o.order_date) AS first_order_date,
    MAX(o.order_date) AS last_order_date,
    CAST(COUNT(DISTINCT o.order_id) AS INTEGER) AS total_orders,
    CAST(COALESCE(SUM(oi.quantity), 0) AS INTEGER) AS total_items_purchased,
    CAST(COALESCE(SUM(oi.quantity * oi.unit_price), 0) AS DECIMAL(15, 2)) AS total_revenue
  FROM bronzev1.customers AS c
  INNER JOIN bronzev1.regions AS r ON c.region_id = r.region_id
  LEFT JOIN bronzev1.orders AS o
    ON c.customer_id = o.customer_id
    AND @revenue_order_filter(o.order_status)
  LEFT JOIN bronzev1.order_items AS oi ON o.order_id = oi.order_id
  GROUP BY c.customer_id, c.name, c.email, c.signup_date, c.region_id, r.region_name
),
favorite_categories AS (
  SELECT
    c.customer_id,
    p.category,
    ROW_NUMBER() OVER (PARTITION BY c.customer_id ORDER BY SUM(oi.quantity) DESC ) AS category_rank
  FROM bronzev1.customers AS c
  LEFT JOIN bronzev1.orders AS o
    ON c.customer_id = o.customer_id
    AND @revenue_order_filter(o.order_status)
  LEFT JOIN bronzev1.order_items AS oi ON o.order_id = oi.order_id
  LEFT JOIN bronzev1.products AS p ON oi.product_id = p.product_id
  GROUP BY c.customer_id, p.category
),
customer_shipments AS (
  SELECT
    c.customer_id,
    CAST(COUNT(DISTINCT s.shipment_id) AS INTEGER) AS total_shipments_received
  FROM bronzev1.customers AS c
  LEFT JOIN bronzev1.orders AS o ON c.customer_id = o.customer_id
  LEFT JOIN bronzev1.shipments AS s ON o.order_id = s.order_id
  GROUP BY c.customer_id
)
SELECT
  co.customer_id,
  co.customer_name,
  co.email,
  CAST(co.signup_date AS DATETIME2(6)) AS signup_date,
  co.region_id,
  co.region_name,
  co.first_order_date,
  co.last_order_date,
  COALESCE(DATEDIFF(day, CAST(co.first_order_date AS DATE), CAST(GETDATE() AS DATE)), 0) AS days_since_first_order,
  COALESCE(DATEDIFF(day, CAST(co.last_order_date AS DATE), CAST(GETDATE() AS DATE)), 9999) AS days_since_last_order,
  COALESCE(co.total_orders, 0) AS total_orders,
  COALESCE(co.total_items_purchased, 0) AS total_items_purchased,
  ROUND(COALESCE(co.total_revenue, 0), 2) AS total_revenue,
  @safe_ratio(COALESCE(co.total_revenue, 0), co.total_orders, 2) AS avg_order_value,
  COALESCE(fc.category, 'None') AS favorite_category,
  COALESCE(cs.total_shipments_received, 0) AS total_shipments_received,
  CASE
    WHEN co.total_orders = 0 THEN 'New'
    WHEN DATEDIFF(day, CAST(co.last_order_date AS DATE), CAST(GETDATE() AS DATE)) > 180 THEN 'Churned'
    WHEN co.total_revenue >= 1000 THEN 'High Value'
    WHEN co.total_revenue >= 500 THEN 'Medium Value'
    ELSE 'Low Value'
  END AS customer_segment,
  CAST(CASE WHEN co.total_orders = 0 THEN 1 ELSE 0 END AS BIT) AS is_new_customer,
  CAST(CASE WHEN
    co.total_orders > 0
    AND DATEDIFF(day, CAST(co.last_order_date AS DATE), CAST(GETDATE() AS DATE)) <= 180
    AND COALESCE(co.total_revenue, 0) >= 1000
  THEN 1 ELSE 0 END AS BIT) AS is_high_value_customer,
  CAST(CASE WHEN
    co.total_orders > 0
    AND DATEDIFF(day, CAST(co.last_order_date AS DATE), CAST(GETDATE() AS DATE)) <= 90
  THEN 1 ELSE 0 END AS BIT) AS is_active_customer
FROM customer_orders AS co
LEFT JOIN favorite_categories AS fc
  ON co.customer_id = fc.customer_id
  AND fc.category_rank = 1
LEFT JOIN customer_shipments AS cs ON co.customer_id = cs.customer_id;
