# Knowledge Index

Route the Agent to the right files for each task.

| Task | Read these files |
|------|------------------|
| **Sync new reference query** | All `schema/*`, all `rules/*`, `conventions.md`; update `CHANGELOG.md` |
| **Generate IA Argents** | `rules/lookups.md`, `rules/mappings.md`, `rules/classifiers.md`, `rules/constants.md`, `rules/projections.md`, `schema/tables.md`, `schema/joins.md`, `conventions.md`, `queries/reference/inventory-adjustments-argents.sql` |
| **Generate Transfer Order (Argents/YLC)** | All rules + schema files, `queries/reference/transfer-order-argents-ylc.sql` |
| **Resolve XLSX field mapping** | Requirements MD/XLSX + `rules/projections.md` + `conventions.md` |

## File purposes

| File | Contents |
|------|----------|
| [conventions.md](conventions.md) | SQL style, Snowflake patterns, XLSX vs golden overrides |
| [schema/tables.md](schema/tables.md) | Physical tables, columns, filters |
| [schema/joins.md](schema/joins.md) | Join recipes and keys |
| [schema/ctes.md](schema/ctes.md) | CTE catalog and dependencies |
| [rules/lookups.md](rules/lookups.md) | Reusable NetSuite lookup CTEs (copy verbatim) |
| [rules/mappings.md](rules/mappings.md) | Vendor, warehouse, account, location mappings |
| [rules/classifiers.md](rules/classifiers.md) | ORDER_TYPE and related CASE blocks |
| [rules/constants.md](rules/constants.md) | Fixed NetSuite internal IDs |
| [rules/projections.md](rules/projections.md) | Use-case output column shapes |
| [CHANGELOG.md](CHANGELOG.md) | Knowledge update log and conflicts |
