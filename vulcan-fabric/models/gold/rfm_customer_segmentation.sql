MODEL (
  name goldv1.rfm_customer_segmentation,
  kind FULL,
  cron '0 */3 * * *',
  owner 'shreyasikarwartmdcio',
  grains [customer_id],
  description 'RFM customer segmentation model for retention, lifecycle, and campaign prioritization.',
  tags ('gold', 'customer', 'rfm', 'segmentation'),
  terms ('customer.rfm_analysis', 'retention.segmentation'),
  columns (
    customer_id INTEGER,
    customer_name VARCHAR(255),
    email VARCHAR(255),
    region_name VARCHAR(255),
    last_order_date TIMESTAMP,
    last_order_day DATE,
    recency_days INTEGER,
    frequency_orders INTEGER,
    monetary_value NUMERIC(15, 2),
    recency_score INTEGER,
    frequency_score INTEGER,
    monetary_score INTEGER,
    rfm_score VARCHAR(255),
    rfm_segment VARCHAR(255),
    is_at_risk_customer BIT,
    recommended_action VARCHAR(255)
  ),
  column_descriptions (
    customer_id = 'Unique customer identifier',
    customer_name = 'Full display name of the customer (PII)',
    email = 'Customer email address (PII)',
    region_name = 'Customer sales region name',
    last_order_date = 'Timestamp of the customer most recent order',
    last_order_day = 'Calendar date of the customer most recent order',
    recency_days = 'Days elapsed since the last order (lower = more recent)',
    frequency_orders = 'Total qualifying orders placed by the customer',
    monetary_value = 'Gross lifetime revenue attributed to this customer',
    recency_score = 'RFM recency component score (1-5; 5 = most recent)',
    frequency_score = 'RFM frequency component score (1-5; 5 = most frequent)',
    monetary_score = 'RFM monetary component score (1-5; 5 = highest revenue)',
    rfm_score = 'Composite RFM score as concatenation of R, F, M component scores',
    rfm_segment = 'RFM-derived customer lifecycle segment label',
    is_at_risk_customer = 'True for customers in At Risk, Hibernating, or Lost segments',
    recommended_action = 'Retention action recommended for this customer segment'
  ),
  column_tags (
    customer_id = ('identifier', 'grain'),
    customer_name = ('pii', 'customer'),
    email = ('pii', 'contact'),
    region_name = ('categorical', 'geography'),
    last_order_date = ('temporal', 'recency'),
    last_order_day = ('temporal', 'recency'),
    recency_days = ('numeric', 'rfm', 'recency'),
    frequency_orders = ('numeric', 'rfm', 'frequency'),
    monetary_value = ('numeric', 'rfm', 'revenue'),
    recency_score = ('numeric', 'rfm', 'score'),
    frequency_score = ('numeric', 'rfm', 'score'),
    monetary_score = ('numeric', 'rfm', 'score'),
    rfm_score = ('categorical', 'rfm', 'composite-score'),
    rfm_segment = ('categorical', 'segmentation', 'lifecycle'),
    is_at_risk_customer = ('boolean', 'churn', 'retention'),
    recommended_action = ('categorical', 'retention', 'action')
  ),
  column_terms (
    customer_id = ('customer.id', 'identity.customer_id'),
    customer_name = ('customer.display_name', 'identity.full_name'),
    email = ('customer.email', 'contact.email_address'),
    region_name = ('geography.region_name', 'sales.territory'),
    last_order_date = ('customer.last_order_date', 'rfm.recency_date'),
    last_order_day = ('customer.last_order_day', 'rfm.recency_day'),
    recency_days = ('rfm.recency_days', 'customer.days_since_last_order'),
    frequency_orders = ('rfm.frequency', 'customer.order_count'),
    monetary_value = ('rfm.monetary_value', 'customer.lifetime_revenue'),
    recency_score = ('rfm.recency_score', 'scoring.recency_component'),
    frequency_score = ('rfm.frequency_score', 'scoring.frequency_component'),
    monetary_score = ('rfm.monetary_score', 'scoring.monetary_component'),
    rfm_score = ('rfm.composite_score', 'scoring.rfm_composite'),
    rfm_segment = ('rfm.segment_label', 'retention.customer_segment'),
    is_at_risk_customer = ('rfm.is_at_risk', 'retention.churn_flag'),
    recommended_action = ('rfm.recommended_action', 'retention.campaign_action')
  ),
  column_mask_expressions (
    customer_name = '***redacted***',
    email = '****',
    recommended_action = '***redacted***',
    monetary_value = CAST(0 AS NUMERIC(15, 2))
  ),
  column_classifications (
    customer_name = restricted,
    email = restricted,
    recommended_action = confidential,
    monetary_value = confidential
  )
);

WITH rfm_base AS (
  SELECT
    customer_id,
    customer_name,
    email,
    region_name,
    last_order_date,
    CAST(last_order_date AS DATE) AS last_order_day,
    days_since_last_order AS recency_days,
    total_orders AS frequency_orders,
    total_revenue AS monetary_value,
    CASE
      WHEN days_since_last_order <= 30 THEN 5
      WHEN days_since_last_order <= 60 THEN 4
      WHEN days_since_last_order <= 90 THEN 3
      WHEN days_since_last_order <= 180 THEN 2
      ELSE 1
    END AS recency_score,
    CASE
      WHEN total_orders >= 4 THEN 5
      WHEN total_orders >= 3 THEN 4
      WHEN total_orders >= 2 THEN 3
      WHEN total_orders >= 1 THEN 2
      ELSE 1
    END AS frequency_score,
    CASE
      WHEN total_revenue >= 1000 THEN 5
      WHEN total_revenue >= 750 THEN 4
      WHEN total_revenue >= 500 THEN 3
      WHEN total_revenue > 0 THEN 2
      ELSE 1
    END AS monetary_score
  FROM silverv1.dim_customer_profile
),
rfm_scored AS (
  SELECT
    customer_id,
    customer_name,
    email,
    region_name,
    last_order_date,
    last_order_day,
    recency_days,
    frequency_orders,
    monetary_value,
    recency_score,
    frequency_score,
    monetary_score,
    CONCAT(recency_score, frequency_score, monetary_score) AS rfm_score,
    CASE
      WHEN recency_score >= 4 AND frequency_score >= 4 AND monetary_score >= 4 THEN 'Champions'
      WHEN recency_score >= 3 AND frequency_score >= 4 THEN 'Loyal Customers'
      WHEN recency_score >= 4 AND frequency_score >= 2 THEN 'Potential Loyalists'
      WHEN recency_score >= 4 THEN 'Recent Customers'
      WHEN recency_score >= 3 AND monetary_score >= 2 THEN 'Promising'
      WHEN recency_score = 3 THEN 'Customers Needing Attention'
      WHEN recency_score <= 2 AND frequency_score >= 3 AND monetary_score >= 3 THEN 'At Risk'
      WHEN recency_score <= 2 AND frequency_score <= 2 THEN 'Hibernating'
      ELSE 'Lost'
    END AS rfm_segment,
    CASE
      WHEN recency_score >= 4 AND frequency_score >= 4 AND monetary_score >= 4 THEN 'Reward with VIP offers and early access'
      WHEN recency_score >= 3 AND frequency_score >= 4 THEN 'Upsell premium bundles and loyalty benefits'
      WHEN recency_score >= 4 AND frequency_score >= 2 THEN 'Nurture with cross-sell recommendations'
      WHEN recency_score >= 4 THEN 'Welcome and guide toward second purchase'
      WHEN recency_score >= 3 AND monetary_score >= 2 THEN 'Use personalized engagement campaigns'
      WHEN recency_score = 3 THEN 'Send re-engagement offers and surveys'
      WHEN recency_score <= 2 AND frequency_score >= 3 AND monetary_score >= 3 THEN 'Run high-priority win-back campaign'
      WHEN recency_score <= 2 AND frequency_score <= 2 THEN 'Use low-cost reactivation'
      ELSE 'Keep in low-touch nurture'
    END AS recommended_action
  FROM rfm_base
)
SELECT
  customer_id,
  customer_name,
  email,
  region_name,
  last_order_date,
  last_order_day,
  recency_days,
  frequency_orders,
  monetary_value,
  recency_score,
  frequency_score,
  monetary_score,
  rfm_score,
  rfm_segment,
  @boolean_flag(rfm_segment IN ('At Risk', 'Hibernating', 'Lost')) AS is_at_risk_customer,
  recommended_action
FROM rfm_scored;
