# SQL Conventions

## Dialect and style

- **Dialect:** Snowflake
- **CTE pattern:** `WITH` chain; lookup CTEs first, then source-specific base/classified, then enrichment, then final projection
- **Deduping:** `NULLIF(TRIM(col), '')` + `QUALIFY ROW_NUMBER() ... = 1`
- **Null-safe quantity checks:** `ZEROIFNULL(qty) > 0`
- **Case-insensitive joins:** `UPPER(a) = UPPER(b)` unless matching internal IDs already normalized
- **Avoid reserved-word aliases:** do not use `OUT`, `IN`, `ORDER` as table aliases — use `ob`, `ib`, `src`

## Normalization rules

| Rule | Implementation |
|------|----------------|
| GB → UK | `IFF(UPPER(country_code) = 'GB', 'UK', country_code)` |
| SKU join key | `LEFT(NULLIF(TRIM(lineitemsku), ''), 21)` matched to `NS_ITEMS_SKU` / `NS_ITEMS_ALIAS_SKU` |
| Argents location key | `CONCAT(SC_WAREHOUSE, '-US-', SC_SUBSIDIARY_SHORT)` → `NS_LOCATIONS.LOCATION_NAME` |
| YLC location key | `CONCAT('YLC-US-', SC_SUBSIDIARY_SHORT)` → `NS_LOCATIONS.LOCATION_NAME` |
| External ID cleanup | Strip prefix before first `-` via `REGEXP_REPLACE(EXTERNALID, '^[^-]*-', '')` |
| Shipment ID from external | FBA: first 12 chars; TO: `REGEXP_SUBSTR(..., '^[^._ -]+')` |

## XLSX vs golden query overrides

When requirements text conflicts with a golden reference query, **prefer the golden query**:

| XLSX says | Golden convention |
|-----------|-------------------|
| `unique_id` = UUID | Use source `pk` as `unique_id` |
| `external_id` = UUID | Use `CONCAT(pk, '-OUT')` / `CONCAT(pk, '-IN')` |
| Memo example uses cleaned external ID | Use `CONCAT(SC_SHIPMENT_ID, ' // ', RAW_ID)` for outbound |
| Geography from shipping country (inbound) | Hardcode `'US'` for inbound IA (Argents) |

## Knowledge merge rules

- Updates are **additive** — append columns, add `seen_in` references
- Never delete a rule without marking `deprecated: true`
- Conflicts → `<!-- CONFLICT -->` in the MD file + entry in `CHANGELOG.md`

## Output conventions (Inventory Adjustments)

- NetSuite API fields use **quoted lowercase/snake aliases**: `"unique_id"`, `"Department_id"`
- Header and line dimensions duplicated at line level (`line_*` fields)
- Outbound and inbound combined via `UNION ALL`
