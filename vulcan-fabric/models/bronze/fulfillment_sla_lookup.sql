MODEL (
  name bronzev1.fulfillment_sla_lookup,
  kind EMBEDDED,
  owner 'shreyasikarwartmdcio',
  tags ('embedded-data', 'bronze', 'lookup', 'fulfillment'),
  description 'Embedded lookup demonstrating inline static reference data for fulfillment SLA guidance without materializing a table.',
  columns (
    status_group VARCHAR(255),
    sla_days INTEGER,
    escalation_priority VARCHAR(255)
  ),
  column_descriptions (
    status_group = 'Order status group from the order status lookup',
    sla_days = 'Target number of days to complete this fulfillment state',
    escalation_priority = 'Operational escalation priority for overdue orders'
  )
);

SELECT 'open' AS status_group, 2 AS sla_days, 'medium' AS escalation_priority
UNION ALL
SELECT 'fulfilled' AS status_group, 0 AS sla_days, 'none' AS escalation_priority
UNION ALL
SELECT 'cancelled' AS status_group, 0 AS sla_days, 'none' AS escalation_priority;
