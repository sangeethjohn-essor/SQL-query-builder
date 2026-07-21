# Mappings

## argents_vendor_to_subsidiary

- **seen_in:** transfer-order-argents-ylc.sql, inventory-adjustments-argents.sql
- **source_column:** VENDOR (outbound) / vendorname (inbound)
- **join:** `UPPER(SC_SUBSIDIARY_NAME) = UPPER(NS_SUBSIDIARIES.SUBSIDIARY_NAME)`

| Source (VENDOR / vendorname) | Subsidiary Name (SC_SUBSIDIARY_NAME) | Short (SC_SUBSIDIARY_SHORT) |
|------------------------------|-------------------------------------|-----------------------------|
| Boka | Boka LLC | BOK |
| Essor (uc3) | Karaka LLC | KAR |

```sql
CASE
    WHEN VENDOR = 'Boka' THEN 'Boka LLC'
    WHEN VENDOR = 'Essor (uc3)' THEN 'Karaka LLC'
END AS SC_SUBSIDIARY_NAME,
CASE
    WHEN VENDOR = 'Boka' THEN 'BOK'
    WHEN VENDOR = 'Essor (uc3)' THEN 'KAR'
END AS SC_SUBSIDIARY_SHORT
```

## argents_warehouse_outbound

- **seen_in:** transfer-order-argents-ylc.sql, inventory-adjustments-argents.sql
- **source_column:** WAREHOUSE

| WAREHOUSE values | SC_WAREHOUSE |
|------------------|--------------|
| Elgin IL, Elgin IL (uc3), Elgin IL (oms) | Argents Elgin |
| Ladson SC, Ladson SC (uc3) | Argents Ladson |

## argents_warehouse_inbound

- **seen_in:** inventory-adjustments-argents.sql
- **source_column:** warehouseaddresscity

| Pattern | SC_WAREHOUSE |
|---------|--------------|
| ILIKE '%Elgin%' | Argents Elgin |
| ILIKE '%Ladson%' | Argents Ladson |
| else | warehouseaddresscity |

## account_id_by_order_type

- **seen_in:** inventory-adjustments-argents.sql
- **purpose:** NetSuite account internal ID for IA transactions

| ORDER_TYPE | account_id | Account name (from XLSX) |
|------------|------------|--------------------------|
| work_order | 1693 | 134000 Manual Adjustments |
| samples | 3323 | 524500 Essor Samples |
| disposal | 2872 | 518110 Other Disposals |
| default | NULL | unmatched ORDER_TYPE |

```sql
CASE
    WHEN ORDER_TYPE = 'work_order' THEN 1693
    WHEN ORDER_TYPE = 'samples' THEN 3323
    WHEN ORDER_TYPE = 'disposal' THEN 2872
    ELSE NULL
END AS account_id
```

<!-- CONFLICT: earlier seed used ELSE 1693 as fallback; current golden uses ELSE NULL (2026-07-21) -->

## argents_external_id_cleanup

- **seen_in:** transfer-order-argents-ylc.sql, inventory-adjustments-argents.sql

```sql
IFF(
    CONTAINS(EXTERNALID, '-'),
    REGEXP_REPLACE(EXTERNALID, '^[^-]*-', ''),
    EXTERNALID
) AS SC_CLEANED_EXTERNALID,
CASE
    WHEN UPPER(SC_CLEANED_EXTERNALID) LIKE 'FBA%' THEN SUBSTR(SC_CLEANED_EXTERNALID, 1, 12)
    WHEN UPPER(SC_CLEANED_EXTERNALID) LIKE 'TO%' THEN REGEXP_SUBSTR(SC_CLEANED_EXTERNALID, '^[^._ -]+')
    ELSE SC_CLEANED_EXTERNALID
END AS SC_SHIPMENT_ID
```

## to_location_lookup_key

- **seen_in:** transfer-order-argents-ylc.sql

| ORDER_TYPE | TO_LOCATION_LOOKUP_KEY pattern |
|------------|-------------------------------|
| FBA | `CONCAT('FBAInbounding-', TO_COUNTRY_CODE, '-', TO_SUBSIDIARY_SHORT)` |
| WALMART | `CONCAT('Walmart-', TO_COUNTRY_CODE, '-', TO_SUBSIDIARY_SHORT)` |
| TIKTOK | `CONCAT('Tiktok-', TO_COUNTRY_CODE, '-', TO_SUBSIDIARY_SHORT)` |
| 3PL_3PL | `CONCAT(NS_PREFIX, TO_SUBSIDIARY_SHORT)` |

## walmart_subsidiary_fixed

- **seen_in:** transfer-order-argents-ylc.sql
- **TO_SUBSIDIARY_INT_ID:** 87
- **TO_SUBSIDIARY_SHORT:** MRKT

## transaction_type_to_icto

- **seen_in:** transfer-order-argents-ylc.sql

```sql
CASE
    WHEN SUBSIDIARY_INT_ID IS NOT NULL
        AND TO_SUBSIDIARY_INT_ID IS NOT NULL
        AND SUBSIDIARY_INT_ID = TO_SUBSIDIARY_INT_ID
        THEN 'TO'
    WHEN SUBSIDIARY_INT_ID IS NOT NULL
        AND TO_SUBSIDIARY_INT_ID IS NOT NULL
        AND SUBSIDIARY_INT_ID != TO_SUBSIDIARY_INT_ID
        THEN 'ICTO'
    ELSE 'UNIDENTIFIED'
END AS TRANSACTION_TYPE
```
