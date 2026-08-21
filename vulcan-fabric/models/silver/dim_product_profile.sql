MODEL (
  name silverv1.dim_product_profile,
  kind FULL,
  cron '0 */3 * * *',
  owner 'shreyasikarwartmdcio',
  grains [product_id],
  description 'Product profile dimension with lifetime sales, customer reach metrics, and retail performance flags.',
  tags ('silver', 'dimension', 'product-profile', 'merchandising', 'retail-intelligence'),
  terms ('product.profile_analytics', 'inventory.sales_velocity', 'retail.product_performance'),
  columns (
    product_id INTEGER,
    product_name VARCHAR(255),
    category VARCHAR(255),
    supplier_id INTEGER,
    supplier_name VARCHAR(255),
    current_price NUMERIC(10, 2),
    first_sale_date TIMESTAMP,
    last_sale_date TIMESTAMP,
    total_orders INTEGER,
    total_quantity_sold INTEGER,
    total_revenue NUMERIC(15, 2),
    avg_quantity_per_order NUMERIC(15, 2),
    avg_price_sold NUMERIC(15, 2),
    unique_customers INTEGER,
    product_performance VARCHAR(255),
    is_premium_product BIT,
    is_best_seller BIT,
    is_active_product BIT
  ),
  column_descriptions (
    product_id = 'Unique product identifier',
    product_name = 'Product display name',
    category = 'Product category (Widgets, Gadgets, Doohickeys, Thingamajigs)',
    supplier_id = 'Supplier who provides this product',
    supplier_name = 'Supplier display name',
    current_price = 'Current list price of the product',
    first_sale_date = 'Date of the first qualifying sale',
    last_sale_date = 'Date of the most recent qualifying sale',
    total_orders = 'Lifetime count of orders containing this product',
    total_quantity_sold = 'Lifetime units sold',
    total_revenue = 'Gross lifetime revenue from this product',
    avg_quantity_per_order = 'Average units per order for this product',
    avg_price_sold = 'Average actual selling price across all orders',
    unique_customers = 'Distinct customers who purchased this product',
    product_performance = 'Revenue tier: Best Seller, Good Performer, Slow Mover, or New',
    is_premium_product = 'True for products with current price >= 50',
    is_best_seller = 'True for products classified as Best Seller by revenue',
    is_active_product = 'True for products with at least one recorded sale'
  ),
  column_tags (
    product_id = ('identifier', 'grain'),
    product_name = ('categorical', 'product'),
    category = ('categorical', 'merchandising'),
    supplier_id = ('identifier', 'supplier'),
    supplier_name = ('categorical', 'supplier'),
    current_price = ('numeric', 'financial', 'pricing'),
    first_sale_date = ('temporal', 'launch'),
    last_sale_date = ('temporal', 'recency'),
    total_orders = ('numeric', 'frequency'),
    total_quantity_sold = ('numeric', 'volume'),
    total_revenue = ('numeric', 'revenue', 'ltv'),
    avg_quantity_per_order = ('numeric', 'basket-size'),
    avg_price_sold = ('numeric', 'pricing'),
    unique_customers = ('numeric', 'reach'),
    product_performance = ('categorical', 'performance'),
    is_premium_product = ('boolean', 'pricing'),
    is_best_seller = ('boolean', 'performance'),
    is_active_product = ('boolean', 'inventory')
  ),
  column_terms (
    product_id = ('product.id', 'inventory.product_id'),
    product_name = ('product.name', 'retail.sku_name'),
    category = ('product.category', 'retail.merchandise_category'),
    supplier_id = ('supplier.id', 'product.supplier_ref'),
    supplier_name = ('supplier.name', 'vendor.display_name'),
    current_price = ('pricing.list_price', 'product.unit_price'),
    first_sale_date = ('product.first_sale_date', 'retail.product_launch_date'),
    last_sale_date = ('product.last_sale_date', 'retail.latest_product_sale'),
    total_orders = ('product.total_orders', 'retail.order_volume'),
    total_quantity_sold = ('product.total_units', 'retail.unit_volume'),
    total_revenue = ('product.total_revenue', 'retail.merchandise_revenue'),
    avg_quantity_per_order = ('product.avg_basket_size', 'retail.avg_units_per_order'),
    avg_price_sold = ('product.avg_realized_price', 'retail.average_sell_price'),
    unique_customers = ('product.customer_reach', 'retail.unique_buyers'),
    product_performance = ('product.performance_tier', 'retail.sku_performance'),
    is_premium_product = ('product.is_premium', 'retail.premium_sku'),
    is_best_seller = ('product.is_best_seller', 'retail.top_sku'),
    is_active_product = ('product.is_active', 'retail.sellable_sku')
  ),
  column_mask_expressions (
    supplier_name = '***redacted***',
    current_price = CAST(0 AS NUMERIC(10, 2)),
    total_revenue = CAST(0 AS NUMERIC(15, 2))
  ),
  column_classifications (
    supplier_name = internal,
    current_price = confidential,
    total_revenue = confidential
  ),
  assertions (
    unique_values(columns := (product_id)),
    not_null(columns := (product_id, product_name, category, supplier_id, supplier_name, current_price)),
    accepted_values(column := product_performance, is_in := ('Best Seller', 'Good Performer', 'Slow Mover', 'New'))
  )
);

WITH product_sales AS (
  SELECT
    p.product_id,
    p.name AS product_name,
    p.category,
    p.supplier_id,
    s.name AS supplier_name,
    p.price AS current_price,
    MIN(o.order_date) AS first_sale_date,
    MAX(o.order_date) AS last_sale_date,
    CAST(COUNT(DISTINCT oi.order_id) AS INTEGER) AS total_orders,
    CAST(COALESCE(SUM(oi.quantity), 0) AS INTEGER) AS total_quantity_sold,
    CAST(COALESCE(SUM(oi.quantity * oi.unit_price), 0) AS DECIMAL(15, 2)) AS total_revenue,
    CAST(COALESCE(AVG(oi.unit_price), 0) AS DECIMAL(15, 2)) AS avg_price_sold,
    CAST(COUNT(DISTINCT o.customer_id) AS INTEGER) AS unique_customers
  FROM bronzev1.products AS p
  INNER JOIN bronzev1.suppliers AS s ON p.supplier_id = s.supplier_id
  LEFT JOIN bronzev1.order_items AS oi ON p.product_id = oi.product_id
  LEFT JOIN bronzev1.orders AS o
    ON oi.order_id = o.order_id
    AND @revenue_order_filter(o.order_status)
  GROUP BY p.product_id, p.name, p.category, p.supplier_id, s.name, p.price
)
SELECT
  product_id,
  product_name,
  category,
  supplier_id,
  supplier_name,
  current_price,
  first_sale_date,
  last_sale_date,
  total_orders,
  total_quantity_sold,
  ROUND(total_revenue, 2) AS total_revenue,
  ROUND(CAST(total_quantity_sold AS DECIMAL(15, 2)) / NULLIF(total_orders, 0), 2) AS avg_quantity_per_order,
  ROUND(avg_price_sold, 2) AS avg_price_sold,
  unique_customers,
  CASE
    WHEN total_orders = 0 THEN 'New'
    WHEN total_revenue >= 1000 THEN 'Best Seller'
    WHEN total_revenue >= 500 THEN 'Good Performer'
    ELSE 'Slow Mover'
  END AS product_performance,
  CAST(CASE WHEN current_price >= 50.0 THEN 1 ELSE 0 END AS BIT) AS is_premium_product,
  CAST(CASE WHEN total_revenue >= 1000 THEN 1 ELSE 0 END AS BIT) AS is_best_seller,
  CAST(CASE WHEN last_sale_date IS NOT NULL THEN 1 ELSE 0 END AS BIT) AS is_active_product
FROM product_sales;
