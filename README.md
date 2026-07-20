# SQL Query Builder

Generate high-quality Snowflake SQL from XLSX requirement sheets using Markdown knowledge extracted from reference queries. Designed for Cursor Agent workflows.

## Quick start

```bash
# Install helpers (XLSX conversion + SQL validation)
python3 -m pip install sqlglot openpyxl

# Convert requirements XLSX to Markdown
python3 scripts/xlsx_to_md.py requirements/ia-argents-mapping.xlsx

# Validate generated SQL
python3 scripts/validate.py \
  --requirements requirements/ia-argents-mapping.md \
  --output output/inventory-adjustments-argents.sql
```

## Project structure

```
queries/reference/     # Golden reference SQL — add new queries here
requirements/          # XLSX mapping sheets (+ .md from xlsx_to_md.py)
knowledge/             # Schema & rules (Markdown knowledge base)
  schema/              # Tables, joins, CTE catalog
  rules/               # Lookups, mappings, classifiers, constants, projections
output/                # Generated SQL (gitignored)
prompts/               # Agent workflow prompts
.cursor/skills/        # Cursor Skill for sync + generate
scripts/               # xlsx_to_md.py, validate.py
```

## Day-to-day workflow

### 1. Add a reference query

Drop a `.sql` file into `queries/reference/`.

### 2. Sync knowledge (Cursor Agent)

In Cursor chat:

> Sync knowledge from queries/reference/my-new-query.sql

The Agent reads the SQL and updates `knowledge/schema/` and `knowledge/rules/` (see [prompts/sync-knowledge.md](prompts/sync-knowledge.md)).

### 3. Add requirements

Place your XLSX mapping sheet in `requirements/`. Optionally convert to MD:

```bash
python3 scripts/xlsx_to_md.py requirements/my-mapping.xlsx
```

### 4. Generate SQL (Cursor Agent)

In Cursor chat:

> Generate SQL for requirements/ia-argents-mapping.xlsx

The Agent reads knowledge + requirements, writes SQL to `output/`, and runs validation (see [prompts/generate-query.md](prompts/generate-query.md)).

### 5. Validate

```bash
python3 scripts/validate.py \
  --requirements requirements/ia-argents-mapping.md \
  --output output/inventory-adjustments-argents.sql
```

Validation checks:
- Snowflake SQL syntax (sqlglot)
- All required columns from requirements are present in output

## Knowledge files

| File | Purpose |
|------|---------|
| [knowledge/INDEX.md](knowledge/INDEX.md) | Routing — which files to read per task |
| [knowledge/conventions.md](knowledge/conventions.md) | SQL style, XLSX vs golden overrides |
| [knowledge/schema/tables.md](knowledge/schema/tables.md) | Tables and columns |
| [knowledge/rules/lookups.md](knowledge/rules/lookups.md) | Reusable NetSuite lookup CTEs |
| [knowledge/rules/mappings.md](knowledge/rules/mappings.md) | Vendor, warehouse, account mappings |
| [knowledge/rules/classifiers.md](knowledge/rules/classifiers.md) | ORDER_TYPE CASE blocks |
| [knowledge/rules/projections.md](knowledge/rules/projections.md) | Output column shapes per use case |

## Seeded examples

| Reference query | Use case |
|-----------------|----------|
| `transfer-order-argents-ylc.sql` | Transfer orders (Argents + YLC) |
| `inventory-adjustments-argents.sql` | Inventory adjustments (Argents inbound + outbound) |

Requirements: `requirements/ia-argents-mapping.xlsx`

## Quality guidelines

- Agent copies lookup CTEs **verbatim** from `knowledge/rules/lookups.md`
- Use closest golden reference query as structural template
- When XLSX text conflicts with golden SQL, follow [knowledge/conventions.md](knowledge/conventions.md)
- Avoid reserved-word aliases (`OUT`, `IN`) in generated SQL
- Always run `validate.py` before using generated SQL in production

## Cursor Skill

The project includes `.cursor/skills/sql-query-builder/SKILL.md`. Cursor will use it when you ask to sync knowledge or generate SQL.

## Extending

To support a new use case (e.g. YLC inventory adjustments):

1. Add a golden reference query to `queries/reference/`
2. Sync knowledge → updates MD files
3. Add requirements XLSX
4. Generate + validate

Add projection shape to `knowledge/rules/projections.md` when the output column set is new.
