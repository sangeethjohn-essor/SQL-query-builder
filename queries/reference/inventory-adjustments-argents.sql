-- Golden reference: Inventory Adjustments (Argents)
-- Use case: inventory_adjustments | 3PL: argents
-- Sources: FACT_FINANCE_ARGENTS_OUTBOUND_SHIPMENT, FACT_FINANCE_ARGENTS_INBOUND_SHIPMENT

WITH NS_SUBSIDIARIES AS (
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
OUTBOUND_BASE AS (
    SELECT
        pk AS SC_ID,
        id AS RAW_ID,
        shippeddate AS SC_SHIPPEDDATE,
        channelname AS SC_CHANNELNAME,
        source AS SC_SOURCE,
        shippingaddressfirstname AS SC_SHIPPINGADDRESSFIRSTNAME,
        shippingaddresslastname AS SC_SHIPPINGADDRESSLASTNAME,
        externalid AS SC_EXTERNALID,
        lineitemsku AS SC_LINEITEMSKU,
        lineitemquantity AS SC_LINEITEMQUANTITY,
        IFF(UPPER(shippingaddresscountrytwolettercode) = 'GB', 'UK',
            shippingaddresscountrytwolettercode) AS SC_SHIPPINGADDRESSCOUNTRYTWOLETTERCODE,
        CASE
            WHEN VENDOR = 'Boka' THEN 'Boka LLC'
            WHEN VENDOR = 'Essor (uc3)' THEN 'Karaka LLC'
        END AS SC_SUBSIDIARY_NAME,
        CASE
            WHEN VENDOR = 'Boka' THEN 'BOK'
            WHEN VENDOR = 'Essor (uc3)' THEN 'KAR'
        END AS SC_SUBSIDIARY_SHORT,
        CASE
            WHEN WAREHOUSE IN ('Elgin IL', 'Elgin IL (uc3)', 'Elgin IL (oms)') THEN 'Argents Elgin'
            WHEN WAREHOUSE IN ('Ladson SC', 'Ladson SC (uc3)') THEN 'Argents Ladson'
        END AS SC_WAREHOUSE,
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
    FROM dwh.prod.FACT_FINANCE_ARGENTS_OUTBOUND_SHIPMENT
    WHERE SHIPPINGSTATUS IN ('PartiallyShipped', 'Shipped')
      AND ZEROIFNULL(LINEITEMQUANTITY) > 0
),
OUTBOUND_CLASSIFIED AS (
    SELECT
        base.*,
        COALESCE(NS_ITEMS_SKU.SKU, NS_ITEMS_ALIAS_SKU.SKU) AS ITEM_NUMBER,
        COALESCE(NS_ITEMS_SKU.ITEM_ID, NS_ITEMS_ALIAS_SKU.ITEM_ID) AS ITEM_ID,
        CASE
            WHEN SC_CHANNELNAME ILIKE '%d2c%'
                OR SC_CHANNELNAME ILIKE '%d2s%'
                OR SC_SOURCE ILIKE '%shopify%'
                OR SC_CHANNELNAME ILIKE 'dc - tjx ( bok )'
                OR SC_SHIPMENT_ID ILIKE 'SO%'
                OR SC_SHIPMENT_ID ILIKE 'ESSOR-GIFTS%'
                THEN 'sales_order'
            WHEN SC_LINEITEMSKU ILIKE '%vir%' THEN 'virtual_bundle'
            WHEN SC_SHIPMENT_ID ILIKE '%disposa%' THEN 'disposal'
            WHEN SC_SHIPMENT_ID ILIKE '%workorder%'
                OR SC_SHIPMENT_ID ILIKE '%bundle%'
                OR SC_SHIPMENT_ID ILIKE 'CON-ZSKKILAP20CT'
                THEN 'work_order'
            WHEN SC_SHIPMENT_ID ILIKE 'COH%' THEN 'donation'
            WHEN SC_SHIPMENT_ID ILIKE '%SAMPLE%'
                OR SC_SHIPMENT_ID ILIKE 'LORNAMEAD0129'
                OR SC_SHIPPINGADDRESSFIRSTNAME ILIKE '%sample%'
                OR SC_SHIPPINGADDRESSLASTNAME ILIKE '%sample%'
                THEN 'samples'
            WHEN SC_SHIPMENT_ID ILIKE 'fba%'
                OR SC_ID ILIKE 'fba%'
                THEN 'fba'
            WHEN SC_SHIPMENT_ID ILIKE 'ibr%'
                OR SC_ID ILIKE 'ibr%'
                THEN 'tiktok'
            WHEN SC_SHIPPINGADDRESSFIRSTNAME ILIKE '%bray%'
                OR SC_SHIPPINGADDRESSFIRSTNAME ILIKE '%unis%'
                OR SC_SHIPPINGADDRESSFIRSTNAME ILIKE '%ylc%'
                THEN '3pl_3pl'
            WHEN SC_SHIPPINGADDRESSFIRSTNAME ILIKE '%relabel%'
                OR SC_SHIPPINGADDRESSLASTNAME ILIKE '%relabel%'
                THEN 'relabel'
            WHEN ZEROIFNULL(SC_LINEITEMQUANTITY) <= 5 THEN 'samples'
            ELSE 'unidentified'
        END AS ORDER_TYPE
    FROM OUTBOUND_BASE base
    LEFT JOIN NS_ITEMS_SKU
        ON UPPER(LEFT(NULLIF(TRIM(base.SC_LINEITEMSKU), ''), 21)) = UPPER(NS_ITEMS_SKU.SKU)
    LEFT JOIN NS_ITEMS_ALIAS_SKU
        ON UPPER(LEFT(NULLIF(TRIM(base.SC_LINEITEMSKU), ''), 21)) = UPPER(NS_ITEMS_ALIAS_SKU.ALIAS_SKU)
),
outbound_data AS (
    SELECT
        ob.SC_ID AS "unique_id",
        CONCAT(ob.SC_ID, '-OUT') AS "external_id",
        CONCAT(ob.SC_SHIPMENT_ID, ' // ', ob.RAW_ID) AS "memo",
        TO_DATE(ob.SC_SHIPPEDDATE) AS "date",
        sub.SUBSIDIARY_INT_ID AS "subsidiary_internal_id",
        ob.ORDER_TYPE AS "order_type",
        CASE
            WHEN ob.ORDER_TYPE = 'work_order' THEN 1693
            WHEN ob.ORDER_TYPE = 'samples' THEN 3323
            WHEN ob.ORDER_TYPE = 'disposal' THEN 2872
            ELSE NULL
        END AS "account_id",
        loc.LOCATION_INT_ID AS "location_internal_id",
        12 AS "Department_id",
        LEFT(ob.ITEM_NUMBER, 3) AS "Class_id",
        1 AS "sales_channel_id",
        geo.GEOGRAPHY_INT_ID AS "geography_id",
        ob.ITEM_ID AS "sku_internal_id",
        ob.SC_LINEITEMQUANTITY AS "quantity",
        loc.LOCATION_INT_ID AS "line_location_internal_id",
        12 AS "line_department_id",
        LEFT(ob.ITEM_NUMBER, 3) AS "line_class_id",
        1 AS "line_sales_channel_id",
        geo.GEOGRAPHY_INT_ID AS "line_geography_id"
    FROM OUTBOUND_CLASSIFIED ob
    LEFT JOIN NS_SUBSIDIARIES sub
        ON UPPER(ob.SC_SUBSIDIARY_NAME) = UPPER(sub.SUBSIDIARY_NAME)
    LEFT JOIN NS_LOCATIONS loc
        ON UPPER(CONCAT(ob.SC_WAREHOUSE, '-US-', ob.SC_SUBSIDIARY_SHORT)) = UPPER(loc.LOCATION_NAME)
    LEFT JOIN NS_GEOGRAPHIES geo
        ON UPPER(ob.SC_SHIPPINGADDRESSCOUNTRYTWOLETTERCODE) = UPPER(geo.GEOGRAPHY_ISO_CODE)
    WHERE TO_DATE(ob.SC_SHIPPEDDATE) >= TO_DATE('2026-04-01')
      AND TO_DATE(ob.SC_SHIPPEDDATE) <= TO_DATE('2026-04-30')
),
INBOUND_BASE AS (
    SELECT
        pk AS SC_ID,
        id AS RAW_ID,
        receiveddate AS SC_RECEIVEDDATE,
        asnnumber AS SC_ASNNUMBER,
        vendorname AS SC_VENDORNAME,
        warehouseaddresscity AS SC_WAREHOUSE_CITY,
        lineitemsku AS SC_LINEITEMSKU,
        lineitemactualshippedunits AS SC_LINEITEMQUANTITY,
        CASE
            WHEN vendorname = 'Boka' THEN 'Boka LLC'
            WHEN vendorname = 'Essor (uc3)' THEN 'Karaka LLC'
        END AS SC_SUBSIDIARY_NAME,
        CASE
            WHEN vendorname = 'Boka' THEN 'BOK'
            WHEN vendorname = 'Essor (uc3)' THEN 'KAR'
        END AS SC_SUBSIDIARY_SHORT,
        CASE
            WHEN warehouseaddresscity ILIKE '%Elgin%' THEN 'Argents Elgin'
            WHEN warehouseaddresscity ILIKE '%Ladson%' THEN 'Argents Ladson'
            ELSE warehouseaddresscity
        END AS SC_WAREHOUSE
    FROM dwh.prod.FACT_FINANCE_ARGENTS_INBOUND_SHIPMENT
    WHERE ZEROIFNULL(lineitemactualshippedunits) > 0
),
INBOUND_CLASSIFIED AS (
    SELECT
        ib.*,
        COALESCE(NS_ITEMS_SKU.SKU, NS_ITEMS_ALIAS_SKU.SKU) AS ITEM_NUMBER,
        COALESCE(NS_ITEMS_SKU.ITEM_ID, NS_ITEMS_ALIAS_SKU.ITEM_ID) AS ITEM_ID,
        CASE
               WHEN SC_ASNNUMBER ILIKE '%RMA%' THEN 'return'
               WHEN SC_ASNNUMBER ILIKE 'CANCELLED%' THEN 'cancelled'
               WHEN SC_ASNNUMBER ILIKE '%MAILER%' THEN 'components'
               WHEN SC_ASNNUMBER ILIKE '%WORKORDER%'
                 OR SC_ASNNUMBER ILIKE '%BUNDLE%'
                 OR SC_ASNNUMBER ILIKE 'CON%' THEN 'work_order'
               ELSE NULL
        END AS ORDER_TYPE
    FROM INBOUND_BASE ib
    LEFT JOIN NS_ITEMS_SKU
        ON UPPER(LEFT(NULLIF(TRIM(ib.SC_LINEITEMSKU), ''), 21)) = UPPER(NS_ITEMS_SKU.SKU)
    LEFT JOIN NS_ITEMS_ALIAS_SKU
        ON UPPER(LEFT(NULLIF(TRIM(ib.SC_LINEITEMSKU), ''), 21)) = UPPER(NS_ITEMS_ALIAS_SKU.ALIAS_SKU)
),
inbound_data AS (
    SELECT
        ib.SC_ID AS "unique_id",
        CONCAT(ib.SC_ID, '-IN') AS "external_id",
        CONCAT(ib.SC_ASNNUMBER, ' // ', ib.RAW_ID) AS "memo",
        TO_DATE(ib.SC_RECEIVEDDATE) AS "date",
        sub.SUBSIDIARY_INT_ID AS "subsidiary_internal_id",
        ib.ORDER_TYPE AS "order_type",
        CASE
            WHEN ib.ORDER_TYPE = 'work_order' THEN 1693
            WHEN ib.ORDER_TYPE = 'samples' THEN 3323
            WHEN ib.ORDER_TYPE = 'disposal' THEN 2872
            ELSE NULL
        END AS "account_id",
        loc.LOCATION_INT_ID AS "location_internal_id",
        12 AS "Department_id",
        LEFT(ib.ITEM_NUMBER, 3) AS "Class_id",
        1 AS "sales_channel_id",
        geo.GEOGRAPHY_INT_ID AS "geography_id",
        ib.ITEM_ID AS "sku_internal_id",
        ib.SC_LINEITEMQUANTITY AS "quantity",
        loc.LOCATION_INT_ID AS "line_location_internal_id",
        12 AS "line_department_id",
        LEFT(ib.ITEM_NUMBER, 3) AS "line_class_id",
        1 AS "line_sales_channel_id",
        geo.GEOGRAPHY_INT_ID AS "line_geography_id"
    FROM INBOUND_CLASSIFIED ib
    LEFT JOIN NS_SUBSIDIARIES sub
        ON UPPER(ib.SC_SUBSIDIARY_NAME) = UPPER(sub.SUBSIDIARY_NAME)
    LEFT JOIN NS_LOCATIONS loc
        ON UPPER(CONCAT(ib.SC_WAREHOUSE, '-US-', ib.SC_SUBSIDIARY_SHORT)) = UPPER(loc.LOCATION_NAME)
    LEFT JOIN NS_GEOGRAPHIES geo
        ON geo.GEOGRAPHY_ISO_CODE = 'US'
    WHERE TO_DATE(ib.SC_RECEIVEDDATE) >= TO_DATE('2026-04-01')
      AND TO_DATE(ib.SC_RECEIVEDDATE) <= TO_DATE('2026-04-30')
),
combined_adjustments AS (
    SELECT * FROM outbound_data
    UNION ALL
    SELECT * FROM inbound_data
)
SELECT * FROM combined_adjustments WHERE ORDER_TYPE IN ('work_order', 'samples', 'disposal');
