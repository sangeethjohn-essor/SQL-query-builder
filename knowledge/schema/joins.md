# Join Recipes

Normalized join patterns extracted from reference queries.

## subsidiary_by_name

- **seen_in:** transfer-order-argents-ylc.sql, inventory-adjustments-argents.sql
- **purpose:** Resolve NetSuite subsidiary internal ID from derived subsidiary name
- **join:**

```sql
LEFT JOIN NS_SUBSIDIARIES sub
    ON UPPER(source.SC_SUBSIDIARY_NAME) = UPPER(sub.SUBSIDIARY_NAME)
```

## argents_location_by_warehouse

- **seen_in:** inventory-adjustments-argents.sql, transfer-order-argents-ylc.sql (Argents branch)
- **purpose:** Resolve location internal ID for Argents warehouses
- **join:**

```sql
LEFT JOIN NS_LOCATIONS loc
    ON UPPER(CONCAT(source.SC_WAREHOUSE, '-US-', source.SC_SUBSIDIARY_SHORT)) = UPPER(loc.LOCATION_NAME)
```

## ylc_location_by_subsidiary_short

- **seen_in:** transfer-order-argents-ylc.sql
- **purpose:** Resolve YLC from-location
- **join:**

```sql
LEFT JOIN NS_LOCATIONS FROM_LOCATIONS
    ON UPPER(CONCAT('YLC-US-', SC_SUBSIDIARY_SHORT)) = UPPER(FROM_LOCATIONS.LOCATION_NAME)
```

## geography_by_country_code

- **seen_in:** inventory-adjustments-argents.sql (outbound), transfer-order-argents-ylc.sql
- **purpose:** Resolve geography internal ID from ISO country code
- **join:**

```sql
LEFT JOIN NS_GEOGRAPHIES geo
    ON UPPER(source.SC_SHIPPINGADDRESSCOUNTRYTWOLETTERCODE) = UPPER(geo.GEOGRAPHY_ISO_CODE)
```

## geography_inbound_us_fixed

- **seen_in:** inventory-adjustments-argents.sql
- **purpose:** Inbound IA always uses US geography
- **join:**

```sql
LEFT JOIN NS_GEOGRAPHIES geo
    ON geo.GEOGRAPHY_ISO_CODE = 'US'
```

## sku_by_lineitemsku_21

- **seen_in:** transfer-order-argents-ylc.sql, inventory-adjustments-argents.sql
- **purpose:** Map line item SKU to NetSuite item (SKU + alias)
- **join:**

```sql
LEFT JOIN NS_ITEMS_SKU
    ON UPPER(LEFT(NULLIF(TRIM(source.SC_LINEITEMSKU), ''), 21)) = UPPER(NS_ITEMS_SKU.SKU)
LEFT JOIN NS_ITEMS_ALIAS_SKU
    ON UPPER(LEFT(NULLIF(TRIM(source.SC_LINEITEMSKU), ''), 21)) = UPPER(NS_ITEMS_ALIAS_SKU.ALIAS_SKU)
```

## brand_subsidiary_mapping

- **seen_in:** transfer-order-argents-ylc.sql
- **purpose:** Brand + country → manual subsidiary for TO destination
- **join:**

```sql
LEFT JOIN MANUAL_SUBSIDIARY_MAPPING
    ON UPPER(BRAND) = UPPER(MANUAL_SUBSIDIARY_MAPPING.BRAND)
    AND UPPER(SC_SHIPPINGADDRESSCOUNTRYTWOLETTERCODE) = UPPER(COUNTRY_CODE)
```

## fba_shipment_lookup

- **seen_in:** transfer-order-argents-ylc.sql
- **purpose:** Shipment ID → Amazon seller + country
- **join:**

```sql
LEFT JOIN FBA_SHIPMENTS
    ON UPPER(SC_SHIPMENT_ID) = UPPER(FBA_SHIPMENT_ID)
```

## amz_subsidiary_by_seller_country

- **seen_in:** transfer-order-argents-ylc.sql
- **purpose:** Amazon seller + country → subsidiary internal ID
- **join:**

```sql
LEFT JOIN AMZ_SUBSIDIARIES
    ON UPPER(FBA_SELLER_ID) = UPPER(AMZ_SELLER_ID)
    AND UPPER(FBA_COUNTRY_CODE) = UPPER(AMZ_COUNTRY_CODE)
```

## to_location_by_lookup_key

- **seen_in:** transfer-order-argents-ylc.sql
- **purpose:** Resolve TO location from computed lookup key
- **join:**

```sql
LEFT JOIN NS_LOCATIONS AS TO_LOCATIONS
    ON UPPER(TO_LOCATION_LOOKUP_KEY) = UPPER(TO_LOCATIONS.LOCATION_NAME)
```

## ylc_3pl_io_shipment

- **seen_in:** transfer-order-argents-ylc.sql
- **purpose:** YLC order number → FBA inbound ref from 3PL IO
- **join:**

```sql
LEFT JOIN MANUAL_3PL_IO
    ON UPPER(NODE_ORDER_NUMBER) = UPPER(OUTBOUND_REF)
```

## from_subsidiary_mapping_ylc

- **seen_in:** transfer-order-argents-ylc.sql
- **purpose:** YLC brand → from subsidiary (US)
- **join:**

```sql
LEFT JOIN FROM_SUBSIDIARY_MAPPING AS FSM
    ON UPPER(COALESCE(NS_ITEMS_SKU.BRAND, NS_ITEMS_ALIAS_SKU.BRAND)) = UPPER(FSM.BRAND)
    AND UPPER(FSM.COUNTRY_CODE) = 'US'
```
