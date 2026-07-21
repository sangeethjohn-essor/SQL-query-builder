# Tables

Physical and staging tables referenced in reference queries.

## NETSUITE.NETSUITE.NETSUITE_SUBSIDIARIES

- **seen_in:** transfer-order-argents-ylc.sql, inventory-adjustments-argents.sql
- **purpose:** NetSuite subsidiary dimension lookup
- **key_columns:** SUBSIDIARY_NAME, SUBSIDIARY_INT_ID, SUBSIDIARY_SHORT

## NETSUITE.NETSUITE.NETSUITE_LOCATIONS

- **seen_in:** transfer-order-argents-ylc.sql, inventory-adjustments-argents.sql
- **purpose:** NetSuite location dimension lookup
- **key_columns:** LOCATION_SUBSIDIARY_NAME, LOCATION_NAME, LOCATION_INT_ID

## NETSUITE.NETSUITE.NETSUITE_GEOGRAPHIES

- **seen_in:** transfer-order-argents-ylc.sql, inventory-adjustments-argents.sql
- **purpose:** Country/geography internal ID lookup
- **key_columns:** GEOGRAPHY_ISO_CODE, GEOGRAPHY_INT_ID

## NETSUITE.NETSUITE.NETSUITE_SALES_CHANNELS

- **seen_in:** transfer-order-argents-ylc.sql
- **purpose:** Sales channel internal ID lookup
- **key_columns:** SALES_CHANNEL_CODE, SALES_CHANNEL_INT_ID

## NETSUITE.NETSUITE.NETSUITE_LANDED_COSTS

- **seen_in:** transfer-order-argents-ylc.sql
- **purpose:** Landed cost template lookup
- **key_columns:** LC_PROFILE_NAME, LC_PROFILE_INT_ID

## NETSUITE.NETSUITE.NETSUITE_ITEMS

- **seen_in:** transfer-order-argents-ylc.sql, inventory-adjustments-argents.sql
- **purpose:** SKU / alias SKU → item_id, brand
- **key_columns:** SKU, ALIAS_SKU, ITEM_ID, BRAND, ALIAS_MARKET_COUNTRY

## DWH.PROD.FACT_FINANCE_ARGENTS_OUTBOUND_SHIPMENT

- **seen_in:** transfer-order-argents-ylc.sql, inventory-adjustments-argents.sql
- **purpose:** Argents outbound shipment line items
- **key_columns:** pk, id, ID, shippeddate, channelname, source, vendor, warehouse, externalid, lineitemsku, lineitemquantity, shippingaddresscountrytwolettercode, shippingaddressfirstname, shippingaddresslastname, shippingaddressname, billingaddressname, billingaddressfirstname, billingaddresslastname, billingaddresscountrytwolettercode, shippingstatus, created
- **filters_used:** SHIPPINGSTATUS IN ('PartiallyShipped', 'Shipped'); ZEROIFNULL(LINEITEMQUANTITY) > 0; TO query also filters `TO_DATE(CREATED) >= '2026-01-01'`

## DWH.PROD.FACT_FINANCE_ARGENTS_INBOUND_SHIPMENT

- **seen_in:** inventory-adjustments-argents.sql
- **purpose:** Argents inbound ASN line items
- **key_columns:** pk, id, receiveddate, asnnumber, vendorname, warehouseaddresscity, lineitemsku, lineitemactualshippedunits
- **filters_used:** ZEROIFNULL(lineitemactualshippedunits) > 0

## DWH.PROD.FACT_FINANCE_YLC_OUTBOUND_SHIPMENT

- **seen_in:** transfer-order-argents-ylc.sql
- **purpose:** YLC outbound shipment line items (semi-structured NODE_* fields)
- **key_columns:** NODE_ORDER_NUMBER, NODE_SHIPMENTS, NODE_SOURCE, NODE_SHOP_NAME, NODE_SHIPPING_ADDRESS_*, NODE_BILLING_ADDRESS_*, LINE_ITEM_SKU, LINE_ITEM_QUANTITY_SHIPPED, LINE_ITEM_WAREHOUSE, LINE_ITEM_FULFILLMENT_STATUS, NODE_ORDER_DATE, NODE_PACKING_NOTE

## DWH.PROD.TO_BRAND_SUBSIDIARY_MAPPING

- **seen_in:** transfer-order-argents-ylc.sql
- **purpose:** Manual brand + country → subsidiary mapping
- **key_columns:** CLASS (brand), COUNTRY_CODE, SUBSIDIARY, SUBSIDIARY_SHORT, SUBSIDIARY_INT_ID

## DWH.PROD.TO_FINAL_LOCATION_MAPPING

- **seen_in:** transfer-order-argents-ylc.sql
- **purpose:** Final location name → workflow type + NS prefix for TO location key
- **key_columns:** FINAL_LOCATION, WORKFLOW_MAPPING, NS_PREFIX

## DWH.PROD.FACT_3PL_IO

- **seen_in:** transfer-order-argents-ylc.sql
- **purpose:** YLC outbound → inbound ref lookup for FBA shipment IDs
- **key_columns:** OUTBOUND_REF, INBOUND_REF_3_PL_AMAZON_WALMART_SUPPLIER_ID_, SHIP_FROM
- **filters_used:** SHIP_FROM ILIKE 'ylc'

## DWH.PROD.FACT_AMAZON_INBOUND_SHIPMENTS

- **seen_in:** transfer-order-argents-ylc.sql
- **purpose:** FBA shipment → seller + country
- **key_columns:** SHIPMENT_ID, SELLER_ID, COUNTRY_CODE

## DWH.PROD.FACT_FBT_INBOUND

- **seen_in:** transfer-order-argents-ylc.sql
- **purpose:** TikTok FBT inbound; country from file name
- **key_columns:** ID, FILE_NAME

## DWH.RAW.NRA_AMAZON_SELLER_SUBSIDIARY_MAPPING

- **seen_in:** transfer-order-argents-ylc.sql
- **purpose:** Amazon seller + country → NetSuite subsidiary
- **key_columns:** SELLER_ID, COUNTRY_CODE, NETSUITE_SUBSIDIARY_INTERNAL_ID, SUBSIDIARY_SHORT

## DWH.STAGING.PLACEMENT_FEE_V3

- **seen_in:** transfer-order-argents-ylc.sql
- **purpose:** FBA placement fee flag per shipment
- **key_columns:** SHIPMENT_ID, SHIPMENT_TYPE, TOTAL_INBOUND_PLACEMENT_WITH_DEFECTS
