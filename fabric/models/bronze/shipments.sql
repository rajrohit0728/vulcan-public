MODEL (
  name bronzev1.shipments,
  kind FULL,
  cron '0 */3 * * *',
  owner 'shreyasikarwartmdcio',
  grains [shipment_id],
  tags ('generated-data', 'bronze', 'shipments', 'fulfillment'),
  description 'Generated shipment data for fulfillment and carrier performance analysis.',
  columns (
    shipment_id INTEGER,
    order_id INTEGER,
    shipped_date DATE,
    carrier VARCHAR(255)
  ),
  column_descriptions (
    shipment_id = 'Unique shipment identifier',
    order_id = 'Order fulfilled by this shipment',
    shipped_date = 'Date the order was dispatched to the customer',
    carrier = 'Logistics carrier used for delivery (DHL, UPS, FedEx, USPS, BlueDart)'
  ),
  column_tags (
    shipment_id = ('identifier', 'grain'),
    order_id = ('identifier', 'fulfillment'),
    shipped_date = ('temporal', 'fulfillment'),
    carrier = ('categorical', 'logistics')
  ),
  column_terms (
    shipment_id = ('fulfillment.shipment_id', 'logistics.shipment_ref'),
    order_id = ('order.id', 'fulfillment.order_ref'),
    shipped_date = ('fulfillment.ship_date', 'logistics.dispatch_date'),
    carrier = ('logistics.carrier', 'fulfillment.shipping_carrier')
  ),
  assertions (
    unique_values(columns := (shipment_id)),
    not_null(columns := (shipment_id, order_id, shipped_date, carrier)),
    accepted_values(column := carrier, is_in := ('DHL', 'UPS', 'FedEx', 'USPS', 'BlueDart'))
  )
);

SELECT
  shipment_id,
  order_id,
  shipped_date,
  carrier
FROM public_shreya.shipments_ext;
