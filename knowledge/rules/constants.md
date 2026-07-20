# Constants

Fixed NetSuite internal IDs used across use cases.

## department_id

- **seen_in:** inventory-adjustments-argents.sql
- **value:** 12
- **label:** Supply Chain 21100
- **fields:** `"Department_id"`, `"line_department_id"`

## sales_channel_id

- **seen_in:** inventory-adjustments-argents.sql
- **value:** 1
- **label:** Amazon Seller Central
- **fields:** `"sales_channel_id"`, `"line_sales_channel_id"`

## class_id_derivation

- **seen_in:** inventory-adjustments-argents.sql
- **rule:** First 3 characters of resolved SKU (ITEM_NUMBER), not ITEM_ID
- **expression:** `LEFT(ITEM_NUMBER, 3)`
- **fields:** `"Class_id"`, `"line_class_id"`

## ia_outbound_date_filter_default

- **seen_in:** inventory-adjustments-argents.sql
- **from:** 2026-05-01
- **to:** 2026-05-31
- **column:** SC_SHIPPEDDATE

## ia_inbound_date_filter_default

- **seen_in:** inventory-adjustments-argents.sql
- **from:** 2026-04-01
- **to:** 2026-07-20
- **column:** SC_RECEIVEDDATE

## to_date_filter_default

- **seen_in:** transfer-order-argents-ylc.sql
- **from:** 2026-01-01
- **to:** 2026-07-17
- **column:** POSTING_DATE

## argents_outbound_created_filter

- **seen_in:** transfer-order-argents-ylc.sql
- **filter:** `TO_DATE(CREATED) >= '2026-01-01'`

## ylc_fulfilled_filter

- **seen_in:** transfer-order-argents-ylc.sql
- **filter:** `LINE_ITEM_FULFILLMENT_STATUS IN ('fulfilled')`

## quantity_positive_filters

- **outbound:** `ZEROIFNULL(LINEITEMQUANTITY) > 0`
- **inbound:** `ZEROIFNULL(lineitemactualshippedunits) > 0`

## shipping_status_outbound

- **seen_in:** transfer-order-argents-ylc.sql, inventory-adjustments-argents.sql
- **filter:** `SHIPPINGSTATUS IN ('PartiallyShipped', 'Shipped')`
