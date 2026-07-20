# SQL Query Builder — Agent Instructions

This repo generates Snowflake SQL from XLSX requirement sheets using Markdown knowledge extracted from reference queries.

## Start here

1. Read [knowledge/INDEX.md](knowledge/INDEX.md) to find relevant knowledge files
2. Use the **sql-query-builder** skill (`.cursor/skills/sql-query-builder/SKILL.md`) for sync and generate workflows

## Key paths

| Path | When to use |
|------|-------------|
| `queries/reference/` | Golden SQL examples — learn patterns, use as templates |
| `requirements/` | XLSX/MD mapping sheets for new queries to generate |
| `knowledge/` | Schema and rules — always read before generating |
| `output/` | Write generated SQL here |
| `scripts/validate.py` | Run after every generation |

## Commands

```bash
python3 scripts/xlsx_to_md.py requirements/<file>.xlsx
python3 scripts/validate.py --requirements requirements/<file>.md --output output/<file>.sql
```

## Rules for this repo

- **Sync** updates Markdown knowledge only — never generate SQL during sync
- **Generate** must reuse lookup CTEs verbatim from `knowledge/rules/lookups.md`
- **Validate** must pass before finishing a generate task
- Prefer golden reference query conventions over literal XLSX wording (see `knowledge/conventions.md`)
