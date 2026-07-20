# Lookup CTEs

Copy these blocks **verbatim** when generating queries. All use `NULLIF(TRIM(...), '')` and `QUALIFY ROW_NUMBER()` deduping.

## NS_SUBSIDIARIES

- **tags:** netsuite, lookup, dedupe
- **seen_in:** transfer-order-argents-ylc.sql, inventory-adjustments-argents.sql

```sql
NS_SUBSIDIARIES AS (
    SELECT NULLIF(TRIM(SUBSIDIARY_NAME), '')   AS SUBSIDIARY_NAME,
           NULLIF(TRIM(SUBSIDIARY_INT_ID), '') AS SUBSIDIARY_INT_ID,
           NULLIF(TRIM(SUBSIDIARY_SHORT), '')  AS SUBSIDIARY_SHORT
    FROM NETSUITE.NETSUITE.NETSUITE_SUBSIDIARIES
    WHERE SUBSIDIARY_NAME IS NOT NULL
      AND SUBSIDIARY_INT_ID IS NOT NULL
      AND SUBSIDIARY_SHORT IS NOT NULL
    QUALIFY
        ROW_NUMBER() OVER (
            PARTITION BY SUBSIDIARY_NAME
            ORDER BY SUBSIDIARY_INT_ID DESC NULLS LAST,
                     SUBSIDIARY_SHORT DESC NULLS LAST
        ) = 1
),
```

## NS_LOCATIONS

- **tags:** netsuite, lookup, dedupe
- **seen_in:** transfer-order-argents-ylc.sql, inventory-adjustments-argents.sql

```sql
NS_LOCATIONS AS (
    SELECT NULLIF(TRIM(LOCATION_SUBSIDIARY_NAME), '') AS LOCATION_SUBSIDIARY_NAME,
           NULLIF(TRIM(LOCATION_NAME), '')            AS LOCATION_NAME,
           NULLIF(TRIM(LOCATION_INT_ID), '')          AS LOCATION_INT_ID
    FROM NETSUITE.NETSUITE.NETSUITE_LOCATIONS
    WHERE LOCATION_SUBSIDIARY_NAME IS NOT NULL
      AND LOCATION_NAME IS NOT NULL
      AND LOCATION_INT_ID IS NOT NULL
    QUALIFY
        ROW_NUMBER() OVER (
            PARTITION BY LOCATION_SUBSIDIARY_NAME, LOCATION_NAME
            ORDER BY LOCATION_INT_ID DESC NULLS LAST
        ) = 1
),
```

## NS_GEOGRAPHIES

- **tags:** netsuite, lookup, dedupe
- **seen_in:** transfer-order-argents-ylc.sql, inventory-adjustments-argents.sql

```sql
NS_GEOGRAPHIES AS (
    SELECT NULLIF(TRIM(GEOGRAPHY_ISO_CODE), '') AS GEOGRAPHY_ISO_CODE,
           NULLIF(TRIM(GEOGRAPHY_INT_ID), '')   AS GEOGRAPHY_INT_ID
    FROM NETSUITE.NETSUITE.NETSUITE_GEOGRAPHIES
    WHERE GEOGRAPHY_ISO_CODE IS NOT NULL
      AND GEOGRAPHY_INT_ID IS NOT NULL
    QUALIFY
        ROW_NUMBER() OVER (
            PARTITION BY GEOGRAPHY_ISO_CODE
            ORDER BY GEOGRAPHY_INT_ID DESC NULLS LAST
        ) = 1
),
```

## NS_SALES_CHANNELS

- **tags:** netsuite, lookup, dedupe
- **seen_in:** transfer-order-argents-ylc.sql

```sql
NS_SALES_CHANNELS AS (
    SELECT NULLIF(TRIM(SALES_CHANNEL_CODE), '')   AS SALES_CHANNEL_CODE,
           NULLIF(TRIM(SALES_CHANNEL_INT_ID), '') AS SALES_CHANNEL_INT_ID
    FROM NETSUITE.NETSUITE.NETSUITE_SALES_CHANNELS
    WHERE SALES_CHANNEL_CODE IS NOT NULL
      AND SALES_CHANNEL_INT_ID IS NOT NULL
    QUALIFY
        ROW_NUMBER() OVER (
            PARTITION BY SALES_CHANNEL_CODE
            ORDER BY SALES_CHANNEL_INT_ID DESC NULLS LAST
        ) = 1
),
```

## NS_LANDED_COSTS

- **tags:** netsuite, lookup, dedupe
- **seen_in:** transfer-order-argents-ylc.sql

```sql
NS_LANDED_COSTS AS (
    SELECT NULLIF(TRIM(LC_PROFILE_NAME), '')   AS LC_PROFILE_NAME,
           NULLIF(TRIM(LC_PROFILE_INT_ID), '') AS LC_PROFILE_INT_ID
    FROM NETSUITE.NETSUITE.NETSUITE_LANDED_COSTS
    WHERE LC_PROFILE_NAME IS NOT NULL
      AND LC_PROFILE_INT_ID IS NOT NULL
    QUALIFY
        ROW_NUMBER() OVER (
            PARTITION BY LC_PROFILE_NAME
            ORDER BY LC_PROFILE_INT_ID DESC NULLS LAST
        ) = 1
),
```

## NS_ITEMS_SKU

- **tags:** netsuite, lookup, sku, dedupe
- **seen_in:** transfer-order-argents-ylc.sql, inventory-adjustments-argents.sql

```sql
NS_ITEMS_SKU AS (
    SELECT NULLIF(TRIM(SKU), '')     AS SKU,
           NULLIF(TRIM(ITEM_ID), '') AS ITEM_ID,
           NULLIF(TRIM(BRAND), '')   AS BRAND
    FROM NETSUITE.NETSUITE.NETSUITE_ITEMS
    WHERE NULLIF(TRIM(SKU), '') IS NOT NULL
      AND NULLIF(TRIM(ITEM_ID), '') IS NOT NULL
      AND NULLIF(TRIM(BRAND), '') IS NOT NULL
    QUALIFY
        ROW_NUMBER() OVER (
            PARTITION BY NULLIF(TRIM(SKU), '')
            ORDER BY NULLIF(TRIM(ITEM_ID), '') DESC NULLS LAST
        ) = 1
),
```

## NS_ITEMS_ALIAS_SKU

- **tags:** netsuite, lookup, sku, alias, dedupe
- **seen_in:** transfer-order-argents-ylc.sql, inventory-adjustments-argents.sql

```sql
NS_ITEMS_ALIAS_SKU AS (
    SELECT NULLIF(TRIM(ALIAS_SKU), '') AS ALIAS_SKU,
           NULLIF(TRIM(ITEM_ID), '')   AS ITEM_ID,
           NULLIF(TRIM(BRAND), '')     AS BRAND,
           NULLIF(TRIM(SKU), '')       AS SKU
    FROM NETSUITE.NETSUITE.NETSUITE_ITEMS
    WHERE NULLIF(TRIM(ALIAS_SKU), '') IS NOT NULL
      AND NULLIF(TRIM(ITEM_ID), '') IS NOT NULL
      AND NULLIF(TRIM(BRAND), '') IS NOT NULL
      AND NULLIF(TRIM(SKU), '') IS NOT NULL
    QUALIFY
        ROW_NUMBER() OVER (
            PARTITION BY NULLIF(TRIM(ALIAS_SKU), '')
            ORDER BY NULLIF(TRIM(ITEM_ID), '') DESC NULLS LAST
        ) = 1
),
```
