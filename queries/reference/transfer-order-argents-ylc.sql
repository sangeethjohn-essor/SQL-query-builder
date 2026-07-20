-- Golden reference: Transfer Order (Argents + YLC)
-- Use case: transfer_order | 3PL: argents, ylc

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

NS_SALES_CHANNEL AS (

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

MANUAL_SUBSIDIARY_MAPPING AS (

    SELECT NULLIF(TRIM(CLASS), '')             AS BRAND,

           NULLIF(TRIM(COUNTRY_CODE), '')      AS COUNTRY_CODE,

           NULLIF(TRIM(SUBSIDIARY), '')        AS SUBSIDIARY,

           NULLIF(TRIM(SUBSIDIARY_SHORT), '')  AS SUBSIDIARY_SHORT,

           NULLIF(TRIM(SUBSIDIARY_INT_ID), '') AS SUBSIDIARY_INT_ID

    FROM DWH.PROD.TO_BRAND_SUBSIDIARY_MAPPING

             LEFT JOIN NS_SUBSIDIARIES

                       ON UPPER(SUBSIDIARY) = UPPER(SUBSIDIARY_NAME)

    WHERE BRAND IS NOT NULL

      AND COUNTRY_CODE IS NOT NULL

      AND SUBSIDIARY IS NOT NULL

      AND SUBSIDIARY_INT_ID IS NOT NULL

      AND SUBSIDIARY_SHORT IS NOT NULL

    QUALIFY

        ROW_NUMBER() OVER (

            PARTITION BY BRAND, COUNTRY_CODE, SUBSIDIARY, SUBSIDIARY_SHORT

            ORDER BY SUBSIDIARY_INT_ID DESC NULLS LAST

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

FBA_SHIPMENTS AS (

    SELECT NULLIF(TRIM(SHIPMENT_ID), '')  AS FBA_SHIPMENT_ID,

           NULLIF(TRIM(SELLER_ID), '')    AS FBA_SELLER_ID,

           NULLIF(TRIM(COUNTRY_CODE), '') AS FBA_COUNTRY_CODE

    FROM DWH.PROD.FACT_AMAZON_INBOUND_SHIPMENTS

    WHERE FBA_SHIPMENT_ID IS NOT NULL

      AND FBA_SELLER_ID IS NOT NULL

      AND FBA_COUNTRY_CODE IS NOT NULL

    QUALIFY

        ROW_NUMBER() OVER (

            PARTITION BY FBA_SHIPMENT_ID

            ORDER BY FBA_SELLER_ID DESC NULLS LAST,

                     FBA_COUNTRY_CODE DESC NULLS LAST

        ) = 1

),

FBT_SHIPMENTS AS (

    SELECT DISTINCT

           ID,

           REGEXP_SUBSTR(FILE_NAME, 'TIKTOK_SHOP_([^/]+)', 1, 1, 'e', 1) AS FBT_COUNTRY_CODE

    FROM DWH.PROD.FACT_FBT_INBOUND

    GROUP BY ALL

),

AMZ_SUBSIDIARIES AS (

    SELECT NULLIF(TRIM(SELLER_ID), '')                       AS AMZ_SELLER_ID,

           NULLIF(TRIM(COUNTRY_CODE), '')                    AS AMZ_COUNTRY_CODE,

           NULLIF(TRIM(NETSUITE_SUBSIDIARY_INTERNAL_ID), '') AS AMZ_SUBSIDIARY_INTERNAL_ID,

           NULLIF(TRIM(SUBSIDIARY_SHORT), '')                AS AMZ_SUBSIDIARY_SHORT

    FROM DWH.RAW.NRA_AMAZON_SELLER_SUBSIDIARY_MAPPING

             LEFT JOIN NS_SUBSIDIARIES

                       ON UPPER(NULLIF(TRIM(NETSUITE_SUBSIDIARY_INTERNAL_ID), '')) =

                          UPPER(SUBSIDIARY_INT_ID)

    WHERE AMZ_SELLER_ID IS NOT NULL

      AND AMZ_COUNTRY_CODE IS NOT NULL

      AND AMZ_SUBSIDIARY_INTERNAL_ID IS NOT NULL

      AND AMZ_SUBSIDIARY_SHORT IS NOT NULL

    QUALIFY

        ROW_NUMBER() OVER (

            PARTITION BY AMZ_SELLER_ID, AMZ_COUNTRY_CODE

            ORDER BY AMZ_SUBSIDIARY_INTERNAL_ID DESC NULLS LAST,

                     AMZ_SUBSIDIARY_SHORT DESC NULLS LAST

        ) = 1

),

PF_DATA AS (

    SELECT SHIPMENT_ID,

           CASE

               WHEN SHIPMENT_TYPE ILIKE 'Minimal Splits'

                   OR COALESCE(TOTAL_INBOUND_PLACEMENT_WITH_DEFECTS, 0.0) > 0

                   THEN TRUE

               ELSE FALSE

           END AS PF_PLACEMENT_FEE_FLAG

    FROM DWH.STAGING.PLACEMENT_FEE_V3 AS PFV3

    QUALIFY

        ROW_NUMBER() OVER (

            PARTITION BY SHIPMENT_ID

            ORDER BY PF_PLACEMENT_FEE_FLAG DESC NULLS LAST

        ) = 1

),

-- YLC prerequisites: FROM_SUBSIDIARY_MAPPING (partitioned by BRAND, COUNTRY_CODE)

--                    MANUAL_3PL_IO (shipment ID lookup from FACT_3PL_IO)

FROM_SUBSIDIARY_MAPPING AS (

    SELECT NULLIF(TRIM(CLASS), '')             AS BRAND,

           NULLIF(TRIM(COUNTRY_CODE), '')      AS COUNTRY_CODE,

           NULLIF(TRIM(SUBSIDIARY), '')        AS SUBSIDIARY,

           NULLIF(TRIM(SUBSIDIARY_SHORT), '')  AS SUBSIDIARY_SHORT,

           NULLIF(TRIM(SUBSIDIARY_INT_ID), '') AS SUBSIDIARY_INT_ID

    FROM DWH.PROD.TO_BRAND_SUBSIDIARY_MAPPING

             LEFT JOIN NS_SUBSIDIARIES

                       ON UPPER(SUBSIDIARY) = UPPER(SUBSIDIARY_NAME)

    WHERE BRAND IS NOT NULL

      AND COUNTRY_CODE IS NOT NULL

      AND SUBSIDIARY IS NOT NULL

      AND SUBSIDIARY_INT_ID IS NOT NULL

      AND SUBSIDIARY_SHORT IS NOT NULL

    QUALIFY

        ROW_NUMBER() OVER (

            PARTITION BY BRAND, COUNTRY_CODE

            ORDER BY SUBSIDIARY_INT_ID DESC NULLS LAST

        ) = 1

),

MANUAL_3PL_IO AS (

    SELECT DISTINCT

           NULLIF(TRIM(OUTBOUND_REF), '')                                  AS OUTBOUND_REF,

           NULLIF(TRIM(INBOUND_REF_3_PL_AMAZON_WALMART_SUPPLIER_ID_), '')  AS INBOUND_REF_3_PL_AMAZON_WALMART_SUPPLIER_ID_

    FROM DWH.PROD.FACT_3PL_IO

    WHERE SHIP_FROM ILIKE 'ylc'

      AND OUTBOUND_REF IS NOT NULL

      AND INBOUND_REF_3_PL_AMAZON_WALMART_SUPPLIER_ID_ IS NOT NULL

    QUALIFY

        ROW_NUMBER() OVER (

            PARTITION BY NULLIF(TRIM(OUTBOUND_REF), '')

            ORDER BY NULLIF(TRIM(INBOUND_REF_3_PL_AMAZON_WALMART_SUPPLIER_ID_), '') DESC NULLS LAST

        ) = 1

),

-- Per-3PL source CTEs (see argents-cte.ts / ylc-cte.ts)

SC_DATA_RAW_ARGENTS AS (

    SELECT 'ARGENTS'                                                       AS NAME_3PL,

           ID                                                              AS SC_ID,

           SHIPPEDDATE                                                     AS SC_SHIPPEDDATE,

           CHANNELNAME                                                     AS SC_CHANNELNAME,

           SHIPPINGADDRESSNAME                                             AS SC_SHIPPINGADDRESSNAME,

           SHIPPINGADDRESSFIRSTNAME                                        AS SC_SHIPPINGADDRESSFIRSTNAME,

           SHIPPINGADDRESSLASTNAME                                         AS SC_SHIPPINGADDRESSLASTNAME,

           BILLINGADDRESSNAME                                              AS SC_BILLINGADDRESSNAME,

           BILLINGADDRESSFIRSTNAME                                         AS SC_BILLINGADDRESSFIRSTNAME,

           BILLINGADDRESSLASTNAME                                          AS SC_BILLINGADDRESSLASTNAME,

           IFF(UPPER(SHIPPINGADDRESSCOUNTRYTWOLETTERCODE) = 'GB', 'UK',

               SHIPPINGADDRESSCOUNTRYTWOLETTERCODE)                        AS SC_SHIPPINGADDRESSCOUNTRYTWOLETTERCODE,

           IFF(UPPER(BILLINGADDRESSCOUNTRYTWOLETTERCODE) = 'GB', 'UK',

               BILLINGADDRESSCOUNTRYTWOLETTERCODE)                         AS SC_BILLINGADDRESSCOUNTRYTWOLETTERCODE,

           CASE

               WHEN SC_CHANNELNAME IN (

                   '(uc3) FBA - Fulfilled by Amazon (ESR)',

                   'FBA - Fulfilled by Amazon (BOK)'

               ) THEN 'AMAZON'

               WHEN SC_CHANNELNAME IN (

                   '(uc3) FC - TikTokShop (ESR)',

                   'FC - TikTokShop (BOK)'

               ) THEN 'TIKTOK'

           END                                                             AS SC_SALES_CHANNEL,

           CASE

               WHEN VENDOR = 'Boka' THEN 'Boka LLC'

               WHEN VENDOR = 'Essor (uc3)' THEN 'Karaka LLC'

           END                                                             AS SC_SUBSIDIARY_NAME,

           CASE

               WHEN VENDOR = 'Boka' THEN 'BOK'

               WHEN VENDOR = 'Essor (uc3)' THEN 'KAR'

           END                                                             AS SC_SUBSIDIARY_SHORT,

           CASE

               WHEN WAREHOUSE IN ('Elgin IL', 'Elgin IL (uc3)', 'Elgin IL (oms)')

                   THEN 'Argents Elgin'

               WHEN WAREHOUSE IN ('Ladson SC', 'Ladson SC (uc3)')

                   THEN 'Argents Ladson'

           END                                                             AS SC_WAREHOUSE,

           EXTERNALID                                                      AS SC_EXTERNALID,

           IFF(

               CONTAINS(EXTERNALID, '-'),

               REGEXP_REPLACE(EXTERNALID, '^[^-]*-', ''),

               EXTERNALID

           )                                                               AS SC_CLEANED_EXTERNALID,

           CASE

               WHEN UPPER(SC_CLEANED_EXTERNALID) LIKE 'FBA%'

                   THEN SUBSTR(SC_CLEANED_EXTERNALID, 1, 12)

               WHEN UPPER(SC_CLEANED_EXTERNALID) LIKE 'TO%'

                   THEN REGEXP_SUBSTR(SC_CLEANED_EXTERNALID, '^[^._ -]+')

               ELSE SC_CLEANED_EXTERNALID

           END                                                             AS SC_SHIPMENT_ID,

           NULLIF(TRIM(LINEITEMSKU), '')                                   AS SC_LINEITEMSKU,

           LEFT(SC_LINEITEMSKU, 21)                                        AS SC_LINEITEMSKU_FOR_MAPPING,

           COALESCE(NS_ITEMS_SKU.SKU, NS_ITEMS_ALIAS_SKU.SKU)              AS ITEM_NUMBER,

           COALESCE(NS_ITEMS_SKU.ITEM_ID, NS_ITEMS_ALIAS_SKU.ITEM_ID)      AS ITEM_ID,

           LINEITEMQUANTITY                                                AS SC_LINEITEMQUANTITY,

           COALESCE(NS_ITEMS_SKU.BRAND, NS_ITEMS_ALIAS_SKU.BRAND)          AS BRAND,

           CASE

               WHEN CHANNELNAME ILIKE '%d2c%'

                   OR CHANNELNAME ILIKE '%d2s%'

                   OR SOURCE ILIKE '%shopify%'

                   OR CHANNELNAME ILIKE 'dc - tjx ( bok )'

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

                   OR SHIPPINGADDRESSFIRSTNAME ILIKE '%sample%'

                   OR SHIPPINGADDRESSLASTNAME ILIKE '%sample%'

                   THEN 'samples'

               WHEN SC_SHIPMENT_ID ILIKE 'fba%'

                   OR SC_ID ILIKE 'fba%'

                   THEN 'fba'

               WHEN SC_SHIPMENT_ID ILIKE 'ibr%'

                   OR SC_ID ILIKE 'ibr%'

                   THEN 'tiktok'

               WHEN SHIPPINGADDRESSFIRSTNAME ILIKE '%bray%'

                   OR SHIPPINGADDRESSFIRSTNAME ILIKE '%unis%'

                   OR SHIPPINGADDRESSFIRSTNAME ILIKE '%ylc%'

                   THEN '3pl_3pl'

               WHEN SHIPPINGADDRESSFIRSTNAME ILIKE '%relabel%'

                   OR SHIPPINGADDRESSLASTNAME ILIKE '%relabel%'

                   THEN 'relabel'

               WHEN ZEROIFNULL(LINEITEMQUANTITY) <= 5 THEN 'samples'

               ELSE 'unidentified'

           END                                                             AS ORDER_TYPE

    FROM DWH.PROD.FACT_FINANCE_ARGENTS_OUTBOUND_SHIPMENT

             LEFT JOIN NS_ITEMS_SKU

                       ON UPPER(LEFT(NULLIF(TRIM(LINEITEMSKU), ''), 21)) = UPPER(SKU)

             LEFT JOIN NS_ITEMS_ALIAS_SKU

                       ON UPPER(LEFT(NULLIF(TRIM(LINEITEMSKU), ''), 21)) = UPPER(ALIAS_SKU)

    WHERE SHIPPINGSTATUS IN ('PartiallyShipped', 'Shipped')

      AND ZEROIFNULL(LINEITEMQUANTITY) > 0

      AND TO_DATE(CREATED) >= '2026-01-01'

),

SC_DATA_RAW_YLC_BASE AS (

    SELECT 'YLC'                                                           AS NAME_3PL,

           NULLIF(TRIM(NODE_ORDER_NUMBER), '')                             AS SC_ID,

           TRY_TO_TIMESTAMP_NTZ(NODE_SHIPMENTS[0]:"created_date"::STRING)  AS SC_SHIPPEDDATE,

           CASE

               WHEN NULLIF(TRIM(NODE_SOURCE), '') ILIKE 'SHOPIFY'

                   AND NULLIF(TRIM(NODE_SHOP_NAME), '') ILIKE '%MYSHOPIFY%'

                   THEN 'SHOPIFY'

               WHEN NULLIF(TRIM(NODE_SOURCE), '') ILIKE 'AMAZON'

                   OR NULLIF(TRIM(NODE_SHIPPING_ADDRESS_FIRST_NAME), '') ILIKE '%AMAZON%'

                   THEN 'AMAZON'

               WHEN NULLIF(TRIM(NODE_SHIPPING_ADDRESS_FIRST_NAME), '') ILIKE '%TIKTOK%'

                   THEN 'TIKTOK'

               WHEN NULLIF(TRIM(NODE_SHIPPING_ADDRESS_FIRST_NAME), '') ILIKE '%WALMART%'

                   THEN 'WALMART'

               WHEN NODE_SHIPPING_ADDRESS_FIRST_NAME ILIKE '%UNIS%'

                   OR NODE_SHIPPING_ADDRESS_FIRST_NAME ILIKE '%DALLAS ONE SOLUTIONS%'

                   OR NODE_SHIPPING_ADDRESS_LAST_NAME ILIKE '%DALLAS ONE SOLUTIONS%'

                   THEN '3PL'

               ELSE NULLIF(TRIM(NODE_SOURCE), '')

           END                                                             AS SC_CHANNELNAME,

           NULLIF(TRIM(NODE_SHIPPING_ADDRESS_COMPANY), '')                 AS SC_SHIPPINGADDRESSNAME,

           NULLIF(TRIM(NODE_SHIPPING_ADDRESS_FIRST_NAME), '')              AS SC_SHIPPINGADDRESSFIRSTNAME,

           NULLIF(TRIM(NODE_SHIPPING_ADDRESS_LAST_NAME), '')               AS SC_SHIPPINGADDRESSLASTNAME,

           NULLIF(TRIM(NODE_BILLING_ADDRESS_COMPANY), '')                  AS SC_BILLINGADDRESSNAME,

           NULLIF(TRIM(NODE_BILLING_ADDRESS_FIRST_NAME), '')               AS SC_BILLINGADDRESSFIRSTNAME,

           NULLIF(TRIM(NODE_BILLING_ADDRESS_LAST_NAME), '')                AS SC_BILLINGADDRESSLASTNAME,

           IFF(UPPER(NULLIF(TRIM(NODE_SHIPPING_ADDRESS_COUNTRY_CODE), '')) = 'GB', 'UK',

               NULLIF(TRIM(NODE_SHIPPING_ADDRESS_COUNTRY), ''))            AS SC_SHIPPINGADDRESSCOUNTRYTWOLETTERCODE,

           IFF(UPPER(NULLIF(TRIM(NODE_BILLING_ADDRESS_COUNTRY_CODE), '')) = 'GB', 'UK',

               NULLIF(TRIM(NODE_BILLING_ADDRESS_COUNTRY), ''))             AS SC_BILLINGADDRESSCOUNTRYTWOLETTERCODE,

           CASE

               WHEN NULLIF(TRIM(NODE_SOURCE), '') ILIKE 'SHOPIFY'

                   AND NULLIF(TRIM(NODE_SHOP_NAME), '') ILIKE '%MYSHOPIFY%'

                   THEN 'SHOPIFY'

               WHEN NULLIF(TRIM(NODE_SOURCE), '') ILIKE 'AMAZON'

                   OR NULLIF(TRIM(NODE_SHIPPING_ADDRESS_FIRST_NAME), '') ILIKE '%AMAZON%'

                   THEN 'AMAZON'

               WHEN NULLIF(TRIM(NODE_SHIPPING_ADDRESS_FIRST_NAME), '') ILIKE '%TIKTOK%'

                   THEN 'TIKTOK'

               WHEN NULLIF(TRIM(NODE_SHIPPING_ADDRESS_FIRST_NAME), '') ILIKE '%WALMART%'

                   THEN 'WALMART'

               WHEN NODE_SHIPPING_ADDRESS_FIRST_NAME ILIKE '%UNIS%'

                   OR NODE_SHIPPING_ADDRESS_FIRST_NAME ILIKE '%DALLAS ONE SOLUTIONS%'

                   OR NODE_SHIPPING_ADDRESS_LAST_NAME ILIKE '%DALLAS ONE SOLUTIONS%'

                   THEN 'AMAZON'

               WHEN REGEXP_LIKE(NODE_SHIPPING_ADDRESS_FIRST_NAME, '^(LTL_)?[A-Z]{3}[0-9]$')

                   OR REGEXP_LIKE(NODE_SHIPPING_ADDRESS_LAST_NAME, '^(LTL_)?[A-Z]{3}[0-9]$')

                   THEN 'AMAZON'

               ELSE NULLIF(TRIM(NODE_SOURCE), '')

           END                                                             AS SC_SALES_CHANNEL,

           -- Subsidiary resolved via FROM_SUBSIDIARY_MAPPING join below

           FSM.SUBSIDIARY                                                  AS SC_SUBSIDIARY_NAME,

           FSM.SUBSIDIARY_SHORT                                            AS SC_SUBSIDIARY_SHORT,

           NULLIF(TRIM(LINE_ITEM_WAREHOUSE), '')                           AS SC_WAREHOUSE,

           NULLIF(TRIM(NODE_ORDER_NUMBER), '')                             AS SC_EXTERNALID,

           NULLIF(TRIM(NODE_ORDER_NUMBER), '')                             AS SC_CLEANED_EXTERNALID,

           COALESCE(

               REGEXP_SUBSTR(NODE_PACKING_NOTE, 'Shipment ID:\s*(FBA[A-Z0-9]+)', 1, 1, 'e', 1),

               REGEXP_SUBSTR(NODE_PACKING_NOTE, '\bFBA[A-Z0-9]{6,12}\b'),

               INBOUND_REF_3_PL_AMAZON_WALMART_SUPPLIER_ID_

           )                                                               AS SC_SHIPMENT_ID,

           NULLIF(TRIM(LINE_ITEM_SKU), '')                                 AS SC_LINEITEMSKU,

           LEFT(NULLIF(TRIM(LINE_ITEM_SKU), ''), 21)                       AS SC_LINEITEMSKU_FOR_MAPPING,

           COALESCE(NS_ITEMS_SKU.SKU, NS_ITEMS_ALIAS_SKU.SKU)              AS ITEM_NUMBER,

           COALESCE(NS_ITEMS_SKU.ITEM_ID, NS_ITEMS_ALIAS_SKU.ITEM_ID)      AS ITEM_ID,

           LINE_ITEM_QUANTITY_SHIPPED                                      AS SC_LINEITEMQUANTITY,

           COALESCE(NS_ITEMS_SKU.BRAND, NS_ITEMS_ALIAS_SKU.BRAND)          AS BRAND,

           CASE

               WHEN NODE_SOURCE ILIKE 'SHOPIFY'

                   OR NODE_ORDER_NUMBER ILIKE 'SO%'

                   THEN 'sales_order'

               WHEN NODE_SOURCE ILIKE 'AMAZON'

                   OR NODE_SHIPPING_ADDRESS_FIRST_NAME ILIKE '%AMAZON%'

                   THEN 'fba'

               WHEN NODE_ORDER_NUMBER ILIKE '%SAMPLE%'

                   OR NODE_ORDER_NUMBER ILIKE '%PERSONAL%'

                   THEN 'samples'

               WHEN NODE_SHIPPING_ADDRESS_FIRST_NAME ILIKE '%DISPOSAL%'

                   THEN 'disposal'

               WHEN NODE_SHIPPING_ADDRESS_FIRST_NAME ILIKE '%DONATION%'

                   AND NODE_SHIPPING_ADDRESS_LAST_NAME ILIKE '%DONATION%'

                   THEN 'donation'

               WHEN NODE_SHIPPING_ADDRESS_FIRST_NAME ILIKE '%TIKTOK%'

                   THEN 'tiktok'

               WHEN NODE_SHIPPING_ADDRESS_FIRST_NAME ILIKE '%UNIS%'

                   OR NODE_SHIPPING_ADDRESS_FIRST_NAME ILIKE '%DALLAS ONE SOLUTIONS%'

                   OR NODE_SHIPPING_ADDRESS_LAST_NAME ILIKE '%DALLAS ONE SOLUTIONS%'

                   THEN '3pl_3pl'

               WHEN NODE_SHIPPING_ADDRESS_FIRST_NAME ILIKE '%WALMART%'

                   THEN 'walmart'

               WHEN REGEXP_LIKE(NODE_SHIPPING_ADDRESS_FIRST_NAME, '^(LTL_)?[A-Z]{3}[0-9]$')

                   OR REGEXP_LIKE(NODE_SHIPPING_ADDRESS_LAST_NAME, '^(LTL_)?[A-Z]{3}[0-9]$')

                   THEN 'fba'

               WHEN NODE_SHIPPING_ADDRESS_FIRST_NAME ILIKE 'The Container Store'

                   OR NODE_SHIPPING_ADDRESS_FIRST_NAME ILIKE 'HomeGoods'

                   OR NODE_SHIPPING_ADDRESS_FIRST_NAME ILIKE 'World Market Management Services LLC'

                   OR NODE_SHIPPING_ADDRESS_FIRST_NAME ILIKE 'World Market Management Services, LLC'

                   OR NODE_SHIPPING_ADDRESS_FIRST_NAME ILIKE 'The Paper Store'

                   OR TRIM(NODE_SHIPPING_ADDRESS_FIRST_NAME) ILIKE 'Uncommon Goods LLC'

                   OR NODE_SHIPPING_ADDRESS_FIRST_NAME ILIKE 'Uncommon Goods'

                   OR NODE_ORDER_NUMBER ILIKE 'B2B%'

                   THEN 'sales_order'

               WHEN ZEROIFNULL(LINE_ITEM_QUANTITY_SHIPPED) <= 5 THEN 'samples'

               ELSE 'unidentified'

           END                                                             AS ORDER_TYPE

    FROM DWH.PROD.FACT_FINANCE_YLC_OUTBOUND_SHIPMENT

             LEFT JOIN NS_ITEMS_SKU

                       ON UPPER(LEFT(NULLIF(TRIM(LINE_ITEM_SKU), ''), 21)) = UPPER(SKU)

             LEFT JOIN NS_ITEMS_ALIAS_SKU

                       ON UPPER(LEFT(NULLIF(TRIM(LINE_ITEM_SKU), ''), 21)) = UPPER(ALIAS_SKU)

             LEFT JOIN MANUAL_3PL_IO

                       ON UPPER(NODE_ORDER_NUMBER) = UPPER(OUTBOUND_REF)

             LEFT JOIN FROM_SUBSIDIARY_MAPPING AS FSM

                       ON UPPER(COALESCE(NS_ITEMS_SKU.BRAND, NS_ITEMS_ALIAS_SKU.BRAND)) = UPPER(FSM.BRAND)

                       AND UPPER(FSM.COUNTRY_CODE) = 'US'

    WHERE LINE_ITEM_FULFILLMENT_STATUS IN ('fulfilled')

      AND ZEROIFNULL(LINE_ITEM_QUANTITY_SHIPPED) > 0

      AND TO_DATE(NODE_ORDER_DATE) >= '2026-01-01'

),

SC_DATA_RAW_YLC AS (

    SELECT NAME_3PL,

           SC_ID,

           SC_SHIPPEDDATE,

           SC_CHANNELNAME,

           SC_SHIPPINGADDRESSNAME,

           SC_SHIPPINGADDRESSFIRSTNAME,

           SC_SHIPPINGADDRESSLASTNAME,

           SC_BILLINGADDRESSNAME,

           SC_BILLINGADDRESSFIRSTNAME,

           SC_BILLINGADDRESSLASTNAME,

           CASE

               WHEN BASE.SC_SHIPPINGADDRESSCOUNTRYTWOLETTERCODE IS NOT NULL

                   THEN BASE.SC_SHIPPINGADDRESSCOUNTRYTWOLETTERCODE

               WHEN ORDER_TYPE ILIKE 'FBA' THEN FBA_COUNTRY_CODE

               WHEN ORDER_TYPE ILIKE 'WALMART' THEN 'US'

               WHEN ORDER_TYPE ILIKE 'TIKTOK' THEN FBT_COUNTRY_CODE

               WHEN ORDER_TYPE ILIKE '3PL_3PL'

                   AND (SC_SHIPPINGADDRESSFIRSTNAME ILIKE '%UNIS%'

                        OR SC_SHIPPINGADDRESSFIRSTNAME ILIKE '%DALLAS ONE SOLUTIONS%')

                   THEN 'US'

           END                                                         AS SC_SHIPPINGADDRESSCOUNTRYTWOLETTERCODE,

           SC_BILLINGADDRESSCOUNTRYTWOLETTERCODE,

           SC_SALES_CHANNEL,

           SC_SUBSIDIARY_NAME,

           SC_SUBSIDIARY_SHORT,

           SC_WAREHOUSE,

           SC_EXTERNALID,

           SC_CLEANED_EXTERNALID,

           SC_SHIPMENT_ID,

           SC_LINEITEMSKU,

           SC_LINEITEMSKU_FOR_MAPPING,

           ITEM_NUMBER,

           ITEM_ID,

           SC_LINEITEMQUANTITY,

           BRAND,

           ORDER_TYPE

    FROM SC_DATA_RAW_YLC_BASE AS BASE

             LEFT JOIN FBA_SHIPMENTS

                       ON UPPER(BASE.SC_SHIPMENT_ID) = UPPER(FBA_SHIPMENT_ID)

             LEFT JOIN FBT_SHIPMENTS

                       ON UPPER(BASE.SC_SHIPMENT_ID) = UPPER(FBT_SHIPMENTS.ID)

),

SC_DATA_RAW AS (

    -- Default Argents 3PL→3PL orders' sales channel to AMAZON so

    -- SALES_CHANNEL_ID resolves (they carry no Amazon/TikTok channel).

    -- YLC rows are left untouched — COALESCE keeps their original value.

    SELECT * EXCLUDE SC_SALES_CHANNEL,

           COALESCE(

               SC_SALES_CHANNEL,

               CASE

                   WHEN NAME_3PL = 'ARGENTS' AND ORDER_TYPE ILIKE '3PL_3PL'

                       THEN 'AMAZON'

               END

           ) AS SC_SALES_CHANNEL

    FROM (

        SELECT * FROM SC_DATA_RAW_ARGENTS

        UNION ALL

        SELECT * FROM SC_DATA_RAW_YLC

    )

),

SC_DATA AS (

    SELECT *

    FROM SC_DATA_RAW

    WHERE ORDER_TYPE IN ('3pl_3pl', 'walmart', 'tiktok', 'fba')

),

SC_DATA_WITH_FBA AS (

    SELECT SC_DATA.* EXCLUDE SC_CLEANED_EXTERNALID, FBA_SELLER_ID, FBA_COUNTRY_CODE

    FROM SC_DATA

             LEFT JOIN FBA_SHIPMENTS

                       ON UPPER(SC_SHIPMENT_ID) = UPPER(FBA_SHIPMENT_ID)

),

SC_DATA_WITH_FBA_AND_AMZ AS (

    SELECT SC_DATA_WITH_FBA.*

               EXCLUDE (FBA_SELLER_ID, FBA_COUNTRY_CODE),

           AMZ_SUBSIDIARIES.AMZ_SUBSIDIARY_INTERNAL_ID AS AMZ_SUBSIDIARY_INTERNAL_ID,

           AMZ_SUBSIDIARIES.AMZ_SUBSIDIARY_SHORT        AS AMZ_SUBSIDIARY_SHORT,

           COALESCE(

               SC_SHIPPINGADDRESSCOUNTRYTWOLETTERCODE,

               SC_BILLINGADDRESSCOUNTRYTWOLETTERCODE

           )                                            AS TO_COUNTRY_CODE

    FROM SC_DATA_WITH_FBA

             LEFT JOIN AMZ_SUBSIDIARIES

                       ON UPPER(FBA_SELLER_ID) = UPPER(AMZ_SELLER_ID)

                       AND UPPER(FBA_COUNTRY_CODE) = UPPER(AMZ_COUNTRY_CODE)

),

SC_DATA_WITH_PF AS (

    SELECT SC_DATA_WITH_FBA_AND_AMZ.*,

           PF_PLACEMENT_FEE_FLAG

    FROM SC_DATA_WITH_FBA_AND_AMZ

             LEFT JOIN PF_DATA AS PFV3

                       ON UPPER(SC_SHIPMENT_ID) = UPPER(PFV3.SHIPMENT_ID)

),

SC_DATA_WITH_LCT AS (

    SELECT SC_DATA_WITH_PF.*,

           CASE

               WHEN PF_PLACEMENT_FEE_FLAG = TRUE

                   THEN CONCAT('3PLFBA_', TO_COUNTRY_CODE, '_', ITEM_NUMBER)

               ELSE CONCAT('3PL_', TO_COUNTRY_CODE, '_', ITEM_NUMBER)

           END AS LCT

    FROM SC_DATA_WITH_PF

),

MANUAL_LOCATION_MAPPING AS (

    SELECT FINAL_LOCATION,

           CASE

               WHEN WORKFLOW_MAPPING ILIKE '3PL' THEN '3pl_3pl'

               WHEN WORKFLOW_MAPPING ILIKE 'AMAZON' THEN 'fba'

               WHEN WORKFLOW_MAPPING ILIKE 'TIKTOK' THEN 'tiktok'

               WHEN WORKFLOW_MAPPING ILIKE 'WALMART' THEN 'walmart'

           END        AS WORKFLOW_MAPPING,

           NS_PREFIX

    FROM DWH.PROD.TO_FINAL_LOCATION_MAPPING

    WHERE FINAL_LOCATION IS NOT NULL

      AND WORKFLOW_MAPPING IS NOT NULL

      AND NS_PREFIX IS NOT NULL

    QUALIFY

        ROW_NUMBER() OVER (

            PARTITION BY UPPER(FINAL_LOCATION), UPPER(WORKFLOW_MAPPING)

            ORDER BY NS_PREFIX DESC NULLS LAST

        ) = 1

),

SC_DATA_WITH_LOCATION_LOOKUP_KEY AS (

    SELECT SC_DATA_WITH_LCT.*,

           -- FROM

           FROM_SUBSIDIARY.SUBSIDIARY_INT_ID                                  AS SUBSIDIARY_INT_ID,

           FROM_LOCATIONS.LOCATION_INT_ID                                     AS FROM_LOCATION_INT_ID,

           -- TO — Walmart always posts to the fixed MRKT subsidiary (id 87);

           -- other order types resolve via AMZ/manual subsidiary mapping.

           CASE

               WHEN ORDER_TYPE ILIKE 'WALMART' THEN 87

               ELSE COALESCE(

                   AMZ_SUBSIDIARY_INTERNAL_ID,

                   MANUAL_SUBSIDIARY_MAPPING.SUBSIDIARY_INT_ID

               )

           END                                                                AS TO_SUBSIDIARY_INT_ID,

           CASE

               WHEN ORDER_TYPE ILIKE 'WALMART' THEN 'MRKT'

               ELSE COALESCE(

                   AMZ_SUBSIDIARY_SHORT,

                   MANUAL_SUBSIDIARY_MAPPING.SUBSIDIARY_SHORT

               )

           END                                                                AS TO_SUBSIDIARY_SHORT,

           -- TO LOCATION LOOKUP KEY — resolves for all order types, not just FBA

           CASE

               WHEN ORDER_TYPE ILIKE 'FBA'

                   THEN CONCAT('FBAInbounding-', TO_COUNTRY_CODE, '-', TO_SUBSIDIARY_SHORT)

               WHEN ORDER_TYPE ILIKE 'WALMART'

                   THEN CONCAT('Walmart-', TO_COUNTRY_CODE, '-', TO_SUBSIDIARY_SHORT)

               WHEN ORDER_TYPE ILIKE 'TIKTOK'

                   THEN CONCAT('Tiktok-', TO_COUNTRY_CODE, '-', TO_SUBSIDIARY_SHORT)

               WHEN ORDER_TYPE ILIKE '3PL_3PL'

                   THEN CONCAT(NS_PREFIX, TO_SUBSIDIARY_SHORT)

           END                                                                AS TO_LOCATION_LOOKUP_KEY,

           -- MEMO

           CONCAT(SC_SHIPMENT_ID, ' // ', SC_ID)                              AS MEMO,

           SC_SHIPPEDDATE                                                      AS POSTING_DATE,

           -- SALES CHANNEL

           SALES_CHANNEL_INT_ID                                               AS SALES_CHANNEL_ID,

           -- GEOGRAPHY

           GEOGRAPHY_INT_ID                                                   AS GEOGRAPHY_ID,

           CASE

               WHEN SC_SALES_CHANNEL = 'AMAZON'

                   AND ORDER_TYPE ILIKE 'FBA'

                   AND UPPER(SC_SHIPMENT_ID) REGEXP '^FBA[A-Z0-9]{9}$'

                   THEN SC_SHIPMENT_ID

           END                                                                AS FBA_ID,

           -- SKU

           ITEM_ID                                                            AS SKU_INTERNAL_ID,

           -- QUANTITY

           SC_LINEITEMQUANTITY                                                AS QUANTITY,

           -- SALES CHANNEL AT LINE-ITEM

           SALES_CHANNEL_INT_ID                                               AS LINE_SALES_CHANNEL_ID,

           -- GEOGRAPHY AT LINE-ITEM

           GEOGRAPHY_INT_ID                                                   AS LINE_GEOGRAPHY_ID,

           -- LCT AT LINE-ITEM

           LC_PROFILE_INT_ID                                                  AS LANDED_COST_TEMPLATE_PER_ITEM_ID

    FROM SC_DATA_WITH_LCT

             LEFT JOIN NS_SUBSIDIARIES AS FROM_SUBSIDIARY

                       ON UPPER(SC_SUBSIDIARY_NAME) = UPPER(SUBSIDIARY_NAME)

             LEFT JOIN NS_LOCATIONS AS FROM_LOCATIONS

                       ON UPPER(

                           CASE

                               WHEN NAME_3PL = 'ARGENTS'

                                   THEN CONCAT(SC_WAREHOUSE, '-US-', SC_SUBSIDIARY_SHORT)

                               WHEN NAME_3PL = 'YLC'

                                   THEN CONCAT('YLC-US-', SC_SUBSIDIARY_SHORT)

                           END

                       ) = UPPER(FROM_LOCATIONS.LOCATION_NAME)

             LEFT JOIN MANUAL_LOCATION_MAPPING

                       ON UPPER(SC_SHIPPINGADDRESSFIRSTNAME) = UPPER(FINAL_LOCATION)

                       AND UPPER(ORDER_TYPE) = UPPER(WORKFLOW_MAPPING)

             LEFT JOIN MANUAL_SUBSIDIARY_MAPPING

                       ON UPPER(SC_DATA_WITH_LCT.BRAND) =

                          UPPER(MANUAL_SUBSIDIARY_MAPPING.BRAND)

                       AND UPPER(SC_SHIPPINGADDRESSCOUNTRYTWOLETTERCODE) =

                           UPPER(COUNTRY_CODE)

             LEFT JOIN NS_SALES_CHANNEL

                       ON UPPER(SC_SALES_CHANNEL) = UPPER(SALES_CHANNEL_CODE)

             LEFT JOIN NS_GEOGRAPHIES

                       ON UPPER(SC_SHIPPINGADDRESSCOUNTRYTWOLETTERCODE) =

                          UPPER(GEOGRAPHY_ISO_CODE)

             LEFT JOIN NS_LANDED_COSTS

                       ON UPPER(LCT) = UPPER(LC_PROFILE_NAME)

),

FINAL_DATA AS (

    SELECT SC_DATA_WITH_LOCATION_LOOKUP_KEY.*,

           TO_LOCATIONS.LOCATION_INT_ID AS TO_LOCATION_INT_ID,

           TO_LOCATIONS.LOCATION_NAME   AS TO_LOCATION_NAME

    FROM SC_DATA_WITH_LOCATION_LOOKUP_KEY

             LEFT JOIN NS_LOCATIONS AS TO_LOCATIONS

                       ON UPPER(TO_LOCATION_LOOKUP_KEY) =

                          UPPER(TO_LOCATIONS.LOCATION_NAME)

),

FINAL_WITH_TYPE AS (

    SELECT FINAL_DATA.*,

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

    FROM FINAL_DATA

)

SELECT *

FROM FINAL_WITH_TYPE

WHERE 1=1

    

    

    

    AND POSTING_DATE BETWEEN '2026-01-01' AND '2026-07-17'

ORDER BY

    POSTING_DATE DESC,

    SC_ID,

    SC_LINEITEMSKU
