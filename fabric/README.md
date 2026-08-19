# Retail Intelligence Platform

`ri-fabric` is a Fabric-backed Vulcan data product for retail analytics. It converts order, customer, product, shipment, warehouse, supplier, region, and calendar data into governed business-ready models for sales performance, customer lifecycle, product merchandising, fulfillment conversion, and RFM-based retention planning.

## Storyline

A growing retail business is selling across multiple regions and product categories. Orders are captured in operational systems, shipments are tracked separately, product and supplier details live in reference tables, and customer information sits in another source. Every team needs the same answers, but each team currently stitches the data together differently.

The revenue team wants to know which regions and categories are driving growth. The retention team wants to find loyal, at-risk, and hibernating customers. The merchandising team wants to identify best sellers, slow movers, and premium products. The operations team wants to measure whether orders are moving through the funnel from registration to purchase to shipment.

This data product brings those views together into one governed retail intelligence layer so teams can ask business questions without rebuilding joins, filters, and metric logic every time.

## User Story

As a retail business analyst, I want a trusted Fabric data product that combines orders, customers, products, regions, and shipments into curated sales, customer, product, and fulfillment metrics, so that I can monitor revenue performance, understand customer value, prioritize retention campaigns, and identify operational drop-offs from a single semantic surface.

As a retention or growth manager, I want customers scored by recency, frequency, and monetary value, so that I can target champions with loyalty offers, nudge promising customers toward repeat purchases, and run win-back campaigns for at-risk customers.

As a data product consumer, I want the metrics to include metadata, tests, data quality checks, audits, and access policies, so that I can understand what each number means and trust it before using it in a dashboard or decision.

## Why We Need This

Retail reporting becomes unreliable when each dashboard defines revenue, active customers, product performance, and shipment conversion differently. A region-level revenue report may exclude cancelled orders while a customer lifetime value report may include them. One analyst may count shipped orders from the shipment table, while another may infer shipment status from order status.

This data product standardizes those decisions. It defines revenue-bearing orders once, computes customer and product profiles from the same curated inputs, exposes reusable business metrics, and validates the model with assertions, DQ checks, custom audits, and tests. The result is a shared source of truth for retail intelligence instead of scattered SQL logic.

## What This Data Product Provides

- Daily sales performance by order date, region, customer, product, and category.
- Weekly sales trends by week, region, and category, including revenue, order volume, active customers, and shipment flags.
- Customer profiles with lifetime revenue, order frequency, favorite category, shipment count, value segment, and activation flags.
- Product profiles with revenue, units sold, customer reach, supplier details, pricing tier, and performance flags.
- RFM customer segmentation with recency, frequency, monetary scores, segment labels, at-risk flags, and recommended retention actions.
- Sales funnel analysis from registered customers to orders, itemized orders, and shipped orders.
- Semantic models and metric definitions for revenue performance, customer lifetime value, RFM value, weekly trends, and fulfillment conversion.
- Data quality rules, model assertions, custom audits, unit-style tests, and project linting rules.
- Role-aware semantic access policies for full, analyst, and restricted consumer groups.

## How We Modeled It

The product follows a layered retail analytics design.

### Source Inputs

The input layer represents operational retail entities:

- `orders_ext`: order header, order date, customer, warehouse, and order status.
- `order_items_ext`: product-level line items with quantity and unit price.
- `customers_ext`: customer identity, signup date, and region.
- `products_ext`: product, category, supplier, and price.
- `suppliers_ext`: supplier-region mapping.
- `warehouses_ext`: warehouse-region mapping.
- `shipments_ext`: shipment event and carrier details.
- `regions_ext`: region reference data.
- `dim_dates_ext`: calendar reference data.

### Bronze Layer

The bronze layer keeps the source-aligned shape of the operational tables. These models provide the clean contract from raw source tables into the Vulcan project. They preserve business keys such as `order_id`, `customer_id`, `product_id`, `supplier_id`, `warehouse_id`, `region_id`, and `shipment_id`.

Bronze also includes supporting lookup models such as order status and fulfillment SLA references. The order status logic is reused through macros so analytics models consistently include only revenue-bearing orders.

### Silver Layer

The silver layer turns source records into reusable analytical facts and dimensions.

- `silver.fct_daily_sales` models daily revenue at `order_date`, `region_id`, `customer_id`, and `product_id` grain. It computes order count, items sold, revenue, average order value, shipment count, shipment rate, and `has_shipment`.
- `silver.fct_weekly_sales` rolls daily sales into `week_start_date`, `region_id`, and `category` grain. It adds weekly revenue, order volume, active customers, shipment days, and weekly shipment flags.
- `silver.dim_customer_profile` creates one row per customer with signup, region, first and last order dates, lifetime revenue, favorite category, shipment count, value segment, and boolean lifecycle flags.
- `silver.dim_product_profile` creates one row per product with supplier details, price, first and last sale dates, revenue, quantity sold, customer reach, performance tier, and boolean product flags.

### Gold Layer

The gold layer turns curated facts and dimensions into business decision models.

- `gold.rfm_customer_segmentation` scores each customer across recency, frequency, and monetary value. It creates an RFM score, assigns a segment such as `Champions`, `Loyal Customers`, `At Risk`, or `Hibernating`, marks at-risk customers, and recommends the next retention action.
- `gold.sales_funnel_analysis` measures regional funnel conversion from registration to order placement, itemized order, and shipment. It also calculates drop-offs, average items per order, and average time to ship.

### Semantic and Metric Layer

The semantic layer exposes business-friendly dimensions, measures, joins, segments, access policies, and `ai_context` so consumers can query the data product without knowing the underlying SQL model structure.

The metric layer defines reusable business metrics for:

- `daily_sales_performance`
- `weekly_revenue_trends`
- `customer_lifetime_value`
- `rfm_value_by_segment`
- `fulfillment_conversion`

Together, these layers let consumers ask governed questions such as:

- What is total daily revenue by region and category?
- Which customers are active, high value, or at risk?
- Which RFM segments contribute the most monetary value?
- Which products are best sellers or slow movers?
- What is the order-to-shipment conversion rate by region?

## Trust and Governance

This product is modeled with trust controls built into the project:

- Model-level assertions validate uniqueness, not-null requirements, accepted values, and metric consistency.
- DQ files define quality checks for facts, dimensions, RFM segmentation, product profiles, and referential integrity.
- SQL audits check daily sales metric consistency, order status lookup consistency, and RFM score consistency.
- Tests cover daily sales aggregation and RFM customer segmentation behavior.
- Linter rules enforce model ownership, grain definitions, DQ coverage, audit coverage, and source generation conventions.
- Semantic policies support role-based access, including masking sensitive customer fields for restricted users.

Semantic policy roles are derived from Heimdall/DataOS role tags by `plugins.auth_ext:resolve_user_groups`. A tag such as `roles:id:retail-north-analyst` becomes the policy group `retail_north_analyst`.

Policy roles:

- `retail_admin`: Full access across all semantic models.
- `retail_north_analyst`: North-only access on region-aware models. Customer PII, RFM recommendations, and product supplier names are masked.
- `retail_south_analyst`: South-only access on region-aware models. Customer PII, RFM recommendations, and product supplier names are masked.
- `retail_east_analyst`: East-only access on region-aware models. Customer PII, RFM recommendations, and product supplier names are masked.
- `retail_west_analyst`: West-only access on region-aware models. Customer PII, RFM recommendations, and product supplier names are masked.
- `retail_central_analyst`: Central-only access on region-aware models. Customer PII, RFM recommendations, and product supplier names are masked.

## Deployment Shape

The DataOS resource `ri-fabric` runs this Vulcan data product on the Postgres engine. The workflow plans and runs the project on a scheduled cadence, while the API exposes the governed semantic surface for consumers.

Postgres connection values are injected from DataOS depot configuration or local environment variables into:

- `POSTGRES_HOST`
- `POSTGRES_PORT`
- `POSTGRES_DATABASE`
- `POSTGRES_USERNAME`
- `POSTGRES_PASSWORD`

## Local Workflow

Load local environment variables before running Vulcan:

```sh
set -a; source .env; set +a
```

Validate and run the project:

```sh
vulcan info
vulcan plan
vulcan run
vulcan test
```

## Caveats

This is a demo-grade retail intelligence data product built on generated sample data. It is suitable for validating Postgres connectivity, Vulcan modeling patterns, semantic metrics, DQ checks, audits, tests, access policies, and deployment flow. It should not be used for financial close, operational shipment execution, inventory planning, or production customer decisioning until the demo sources are replaced with production systems and business owners approve the metric definitions.
