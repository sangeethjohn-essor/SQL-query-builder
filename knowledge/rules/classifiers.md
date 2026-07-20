# Classifiers

## argents_outbound_order_type

- **seen_in:** transfer-order-argents-ylc.sql (SC_DATA_RAW_ARGENTS), inventory-adjustments-argents.sql (OUTBOUND_CLASSIFIED)
- **source:** FACT_FINANCE_ARGENTS_OUTBOUND_SHIPMENT

```sql
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
```

## argents_inbound_order_type

- **seen_in:** inventory-adjustments-argents.sql (INBOUND_CLASSIFIED)
- **source:** FACT_FINANCE_ARGENTS_INBOUND_SHIPMENT
- **classifier_input:** SC_ASNNUMBER (asnnumber)

```sql
CASE
    WHEN LOWER(SC_ASNNUMBER) LIKE '%work order%' THEN 'work_order'
    WHEN LOWER(SC_ASNNUMBER) LIKE '%sample%' THEN 'samples'
    WHEN LOWER(SC_ASNNUMBER) LIKE '%disposal%' THEN 'disposal'
    ELSE 'unidentified'
END AS ORDER_TYPE
```

## transfer_order_filter

- **seen_in:** transfer-order-argents-ylc.sql
- **purpose:** Rows included in TO pipeline

```sql
WHERE ORDER_TYPE IN ('3pl_3pl', 'walmart', 'tiktok', 'fba')
```

## argents_sales_channel_from_channelname

- **seen_in:** transfer-order-argents-ylc.sql (SC_DATA_RAW_ARGENTS)

```sql
CASE
    WHEN SC_CHANNELNAME IN (
        '(uc3) FBA - Fulfilled by Amazon (ESR)',
        'FBA - Fulfilled by Amazon (BOK)'
    ) THEN 'AMAZON'
    WHEN SC_CHANNELNAME IN (
        '(uc3) FC - TikTokShop (ESR)',
        'FC - TikTokShop (BOK)'
    ) THEN 'TIKTOK'
END AS SC_SALES_CHANNEL
```

## argents_3pl_3pl_amazon_default

- **seen_in:** transfer-order-argents-ylc.sql (SC_DATA_RAW)
- **purpose:** Default NULL sales channel to AMAZON for Argents 3PL_3PL orders

```sql
COALESCE(
    SC_SALES_CHANNEL,
    CASE
        WHEN NAME_3PL = 'ARGENTS' AND ORDER_TYPE ILIKE '3PL_3PL'
            THEN 'AMAZON'
    END
) AS SC_SALES_CHANNEL
```

## lct_key_by_placement_fee

- **seen_in:** transfer-order-argents-ylc.sql

```sql
CASE
    WHEN PF_PLACEMENT_FEE_FLAG = TRUE
        THEN CONCAT('3PLFBA_', TO_COUNTRY_CODE, '_', ITEM_NUMBER)
    ELSE CONCAT('3PL_', TO_COUNTRY_CODE, '_', ITEM_NUMBER)
END AS LCT
```

## workflow_mapping_from_final_location

- **seen_in:** transfer-order-argents-ylc.sql (MANUAL_LOCATION_MAPPING)

| WORKFLOW_MAPPING (source) | ORDER_TYPE |
|---------------------------|------------|
| ILIKE '3PL' | 3pl_3pl |
| ILIKE 'AMAZON' | fba |
| ILIKE 'TIKTOK' | tiktok |
| ILIKE 'WALMART' | walmart |
