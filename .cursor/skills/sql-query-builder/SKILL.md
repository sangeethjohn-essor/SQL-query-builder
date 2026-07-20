---
name: sql-query-builder
description: Sync schema/rules knowledge from reference SQL queries and generate Snowflake SQL from XLSX requirements. Use when adding queries to queries/reference/, syncing knowledge, generating SQL from requirements, or validating generated SQL.
---

# SQL Query Builder

Generate high-quality Snowflake SQL from XLSX requirement sheets using Markdown knowledge extracted from reference queries.

## When to use

- User adds a query to `queries/reference/`
- User says **"sync knowledge"**, **"update schema and rules"**, or **"sync from reference query"**
- User says **"generate SQL"** for a requirements XLSX/MD file
- User asks to validate generated SQL

## Project layout

| Path | Purpose |
|------|---------|
| `queries/reference/` | Golden reference SQL queries |
| `requirements/` | XLSX mapping sheets (+ generated `.md`) |
| `knowledge/` | Schema and rules (Markdown knowledge base) |
| `knowledge/INDEX.md` | Routing table — read first |
| `output/` | Generated SQL |
| `scripts/xlsx_to_md.py` | Convert XLSX → requirements MD |
| `scripts/validate.py` | Syntax + required column validation |
| `prompts/sync-knowledge.md` | Full sync workflow |
| `prompts/generate-query.md` | Full generate workflow |

## Workflow 1: Sync knowledge

**Trigger:** New or updated file in `queries/reference/`

Follow [prompts/sync-knowledge.md](../prompts/sync-knowledge.md):

1. Read reference query + existing `knowledge/**/*.md`
2. Extract tables, joins, CTEs, mappings, classifiers, constants, projections
3. Merge additively into knowledge files; update `CHANGELOG.md`
4. Do **not** generate SQL

## Workflow 2: Generate query

**Trigger:** User provides requirements XLSX or MD path

Follow [prompts/generate-query.md](../prompts/generate-query.md):

1. Read requirements (convert XLSX with `python scripts/xlsx_to_md.py` if needed)
2. Read `knowledge/INDEX.md` → load relevant knowledge files
3. Use closest `queries/reference/*.sql` as structural template
4. Write SQL to `output/` — reuse lookup CTEs and classifiers **verbatim** from knowledge
5. Run `python scripts/validate.py --requirements ... --output ...` — fix until pass

## Quality rules

- Copy lookup CTEs from `knowledge/rules/lookups.md` verbatim — do not rewrite from memory
- Only use documented tables, columns, and join recipes
- When XLSX conflicts with golden query, follow `knowledge/conventions.md`
- Always run validation before finishing

## Quick commands

```bash
# Install dependencies
pip install -e .

# Convert XLSX to MD
python scripts/xlsx_to_md.py requirements/ia-argents-mapping.xlsx

# Validate generated SQL
python scripts/validate.py \
  --requirements requirements/ia-argents-mapping.md \
  --output output/inventory-adjustments-argents.sql
```
