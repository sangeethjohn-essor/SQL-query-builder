# Knowledge Changelog

## 2026-07-21 — Re-sync (inventory-adjustments update)

Synced from:
- `inventory-adjustments-argents.sql` (286 lines)
- `transfer-order-argents-ylc.sql` (671 lines, unchanged logic)

### Changes
- **projections.md:** Added `"order_type"` header field to IA outbound/inbound projections
- **classifiers.md:** IA inclusion filter now documents projecting `"order_type"` before final WHERE
- **conventions.md:** Updated IA filter guidance; noted inbound vs outbound order_type coverage
- **schema/ctes.md:** `outbound_data` / `inbound_data` include `"order_type"`

### Resolved
- Prior note about invalid final `ORDER_TYPE` filter — fixed in golden query by projecting `"order_type"` in union branches

## 2026-07-21 — Full sync from queries/reference/

Synced from:
- `transfer-order-argents-ylc.sql` (671 lines, reformatted)
- `inventory-adjustments-argents.sql` (284 lines, updated classifiers/filters)

### Schema
- Expanded `FACT_FINANCE_ARGENTS_OUTBOUND_SHIPMENT` columns (billing/shipping address fields, ID)
- Added join recipes: from_subsidiary, from_location (Argents/YLC), sales_channel, landed_cost, manual_location, placement_fee, fbt_shipment

### Rules
- **lookups.md:** Added TO enrichment CTEs (MANUAL_SUBSIDIARY_MAPPING, FROM_SUBSIDIARY_MAPPING, FBA/FBT/AMZ, PF_DATA, MANUAL_3PL_IO, MANUAL_LOCATION_MAPPING)
- **classifiers.md:** Updated inbound IA classifier (ASN ILIKE patterns); added YLC outbound classifier; added IA inclusion filter note; deprecated old inbound classifier
- **mappings.md:** `account_id` default changed to NULL (conflict with earlier ELSE 1693)
- **constants.md:** IA date filters unified to April 2026 for outbound and inbound
- **projections.md:** Aliases `ob`/`ib`; account_id NULL default; inclusion filter documented

<!-- Superseded: order_type projection added in re-sync same day -->

## 2026-07-20 — Initial seed

- Bootstrapped from `transfer-order-argents-ylc.sql` and `inventory-adjustments-argents.sql`
- Documented shared NetSuite lookups, Argents mappings, outbound/inbound classifiers
- Documented IA projection shape for Argents
