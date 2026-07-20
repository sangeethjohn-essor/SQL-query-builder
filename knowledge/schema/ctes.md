# CTE Catalog

Reusable and domain-specific CTE layers. Copy lookup CTEs from [rules/lookups.md](../rules/lookups.md).

## Lookup layer (shared)

| CTE | Purpose | seen_in |
|-----|---------|---------|
| NS_SUBSIDIARIES | Subsidiary dedupe lookup | both |
| NS_LOCATIONS | Location dedupe lookup | both |
| NS_GEOGRAPHIES | Geography dedupe lookup | both |
| NS_SALES_CHANNELS | Sales channel lookup | transfer-order only |
| NS_LANDED_COSTS | Landed cost profile lookup | transfer-order only |
| NS_ITEMS_SKU | Primary SKU → item_id | both |
| NS_ITEMS_ALIAS_SKU | Alias SKU → item_id | both |

## Transfer order — enrichment layer

| CTE | Purpose | Depends on |
|-----|---------|------------|
| MANUAL_SUBSIDIARY_MAPPING | Brand+country → subsidiary | NS_SUBSIDIARIES, TO_BRAND_SUBSIDIARY_MAPPING |
| FROM_SUBSIDIARY_MAPPING | Brand+country → from subsidiary (YLC) | NS_SUBSIDIARIES |
| FBA_SHIPMENTS | FBA shipment metadata | FACT_AMAZON_INBOUND_SHIPMENTS |
| FBT_SHIPMENTS | TikTok FBT country | FACT_FBT_INBOUND |
| AMZ_SUBSIDIARIES | Seller+country → subsidiary | NS_SUBSIDIARIES, NRA mapping |
| PF_DATA | Placement fee flag | PLACEMENT_FEE_V3 |
| MANUAL_3PL_IO | YLC → FBA ref | FACT_3PL_IO |
| MANUAL_LOCATION_MAPPING | 3PL destination location prefix | TO_FINAL_LOCATION_MAPPING |

## Transfer order — source layer

| CTE | Purpose |
|-----|---------|
| SC_DATA_RAW_ARGENTS | Normalize Argents outbound rows |
| SC_DATA_RAW_YLC_BASE | Normalize YLC outbound rows |
| SC_DATA_RAW_YLC | Enrich YLC with country codes |
| SC_DATA_RAW | UNION Argents + YLC; 3PL_3PL → AMAZON channel default |
| SC_DATA | Filter ORDER_TYPE IN (3pl_3pl, walmart, tiktok, fba) |
| SC_DATA_WITH_FBA | Attach FBA seller/country |
| SC_DATA_WITH_FBA_AND_AMZ | Attach AMZ subsidiary + TO country |
| SC_DATA_WITH_PF | Attach placement fee flag |
| SC_DATA_WITH_LCT | Compute landed cost template key |
| SC_DATA_WITH_LOCATION_LOOKUP_KEY | Resolve from/to subsidiary, location keys, memo, posting date |
| FINAL_DATA | Resolve TO location |
| FINAL_WITH_TYPE | Classify TO vs ICTO vs UNIDENTIFIED |

## Inventory adjustments — source layer

| CTE | Purpose |
|-----|---------|
| OUTBOUND_BASE | Raw Argents outbound fields + vendor/warehouse/shipment derivation |
| OUTBOUND_CLASSIFIED | SKU join + ORDER_TYPE classifier |
| outbound_data | Project NetSuite IA header/line fields (outbound) |
| INBOUND_BASE | Raw Argents inbound fields |
| INBOUND_CLASSIFIED | SKU join + inbound ORDER_TYPE from ASN |
| inbound_data | Project NetSuite IA header/line fields (inbound) |
| combined_adjustments | UNION ALL outbound + inbound |

## CTE ordering convention

1. NetSuite lookup CTEs (NS_*)
2. Manual mapping CTEs (if needed)
3. Source BASE → CLASSIFIED → projection CTEs
4. UNION / final SELECT
