# Projections

Output column shapes per use case.

## inventory_adjustments_argents

- **seen_in:** inventory-adjustments-argents.sql
- **golden_reference:** queries/reference/inventory-adjustments-argents.sql
- **source_tables:** FACT_FINANCE_ARGENTS_OUTBOUND_SHIPMENT, FACT_FINANCE_ARGENTS_INBOUND_SHIPMENT
- **combine:** UNION ALL outbound_data + inbound_data

### Header fields

| Target column | Level | SQL expression (outbound) | SQL expression (inbound) |
|---------------|-------|---------------------------|--------------------------|
| unique_id | Header | `out.SC_ID` | `ib.SC_ID` |
| external_id | Header | `CONCAT(out.SC_ID, '-OUT')` | `CONCAT(ib.SC_ID, '-IN')` |
| memo | Header | `CONCAT(out.SC_SHIPMENT_ID, ' // ', out.RAW_ID)` | `CONCAT(ib.SC_ASNNUMBER, ' // ', ib.RAW_ID)` |
| date | Header | `TO_DATE(out.SC_SHIPPEDDATE)` | `TO_DATE(ib.SC_RECEIVEDDATE)` |
| subsidiary_internal_id | Header | `sub.SUBSIDIARY_INT_ID` | `sub.SUBSIDIARY_INT_ID` |
| account_id | Header | CASE on ORDER_TYPE (see mappings.md) | CASE on ORDER_TYPE |
| location_internal_id | Header | `loc.LOCATION_INT_ID` | `loc.LOCATION_INT_ID` |
| Department_id | Header | `12` | `12` |
| Class_id | Header | `LEFT(out.ITEM_NUMBER, 3)` | `LEFT(ib.ITEM_NUMBER, 3)` |
| sales_channel_id | Header | `1` | `1` |
| geography_id | Header | `geo.GEOGRAPHY_INT_ID` (from shipping country) | `geo.GEOGRAPHY_INT_ID` (US fixed) |

### Line fields

| Target column | Level | SQL expression |
|---------------|-------|----------------|
| sku_internal_id | Line | `ITEM_ID` |
| quantity | Line | `SC_LINEITEMQUANTITY` |
| line_location_internal_id | Line | `loc.LOCATION_INT_ID` |
| line_department_id | Line | `12` |
| line_class_id | Line | `LEFT(ITEM_NUMBER, 3)` |
| line_sales_channel_id | Line | `1` |
| line_geography_id | Line | same as geography_id |

### Required output columns (from XLSX)

All of the above are required (`Required?=Yes` in requirements sheet).

## transfer_order_argents_ylc

- **seen_in:** transfer-order-argents-ylc.sql
- **golden_reference:** queries/reference/transfer-order-argents-ylc.sql
- **final_cte:** FINAL_WITH_TYPE
- **key_output_columns:** SUBSIDIARY_INT_ID, FROM_LOCATION_INT_ID, TO_SUBSIDIARY_INT_ID, TO_LOCATION_INT_ID, TRANSACTION_TYPE, POSTING_DATE, QUANTITY, SKU_INTERNAL_ID, MEMO, LCT, SALES_CHANNEL_ID, GEOGRAPHY_ID
- **filter:** ORDER_TYPE IN (3pl_3pl, walmart, tiktok, fba); POSTING_DATE range
