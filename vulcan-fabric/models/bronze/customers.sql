MODEL (
  name bronzev1.customers,
  kind FULL,
  cron '0 */3 * * *',
  owner 'shreyasikarwartmdcio',
  grains [customer_id],
  tags ('generated-data', 'bronze', 'customer', 'pii'),
  description 'Generated customer master data with signup date and regional assignment.',
  columns (
    customer_id INTEGER,
    region_id INTEGER,
    name VARCHAR(255),
    email VARCHAR(255),
    signup_date DATE
  ),
  column_descriptions (
    customer_id = 'Unique customer identifier',
    region_id = 'Region the customer belongs to',
    name = 'Full name of the customer (PII)',
    email = 'Customer contact email address (PII)',
    signup_date = 'Date the customer registered'
  ),
  column_tags (
    customer_id = ('identifier', 'grain'),
    region_id = ('identifier', 'geography'),
    name = ('pii', 'customer'),
    email = ('pii', 'contact'),
    signup_date = ('temporal', 'acquisition')
  ),
  column_terms (
    customer_id = ('customer.id', 'identity.customer_id'),
    region_id = ('geography.region_id', 'customer.region'),
    name = ('customer.name', 'identity.full_name'),
    email = ('customer.email', 'contact.email_address'),
    signup_date = ('customer.signup_date', 'acquisition.registration_date')
  ),
  assertions (
    unique_values(columns := (customer_id)),
    not_null(columns := (customer_id, region_id, name, email, signup_date))
  )
);

SELECT
  customer_id,
  region_id,
  name,
  email,
  signup_date
FROM public_shreya.customers_ext;
