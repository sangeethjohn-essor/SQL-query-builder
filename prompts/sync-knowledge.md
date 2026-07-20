# Sync Knowledge from Reference Queries

Use this workflow when the user adds or updates a file in `queries/reference/`.

## Steps

1. **Identify changed queries**
   - List all files in `queries/reference/*.sql`
   - Focus on files the user mentioned or recently modified

2. **Read existing knowledge**
   - Read `knowledge/INDEX.md` for routing
   - Read all files under `knowledge/schema/` and `knowledge/rules/`
   - Read `knowledge/conventions.md` and `knowledge/CHANGELOG.md`

3. **Extract from each reference query**
   - **Tables:** every `FROM` / `JOIN` target → `knowledge/schema/tables.md`
   - **Columns:** columns used in SELECT, WHERE, JOIN, GROUP BY
   - **Joins:** ON clauses → `knowledge/schema/joins.md` as named recipes
   - **CTEs:** name, purpose, dependencies → `knowledge/schema/ctes.md`
   - **Lookup CTEs:** full SQL blocks → `knowledge/rules/lookups.md`
   - **Mappings:** vendor/warehouse/account CASE blocks → `knowledge/rules/mappings.md`
   - **Classifiers:** ORDER_TYPE and filter CASE blocks → `knowledge/rules/classifiers.md`
   - **Constants:** literal internal IDs → `knowledge/rules/constants.md`
   - **Projections:** final SELECT shapes → `knowledge/rules/projections.md`

4. **Merge rules (additive only)**
   - Append new columns to existing table sections
   - Add `seen_in: [filename.sql]` to every touched section
   - If logic matches an existing rule, merge `seen_in` — do not duplicate
   - If logic **conflicts**, keep both versions and mark with `<!-- CONFLICT: reason -->`
   - Log changes in `knowledge/CHANGELOG.md` with date and filename

5. **Do not generate SQL** in this workflow — only update knowledge files

## Output checklist

- [ ] `schema/tables.md` updated
- [ ] `schema/joins.md` updated (new join recipes named clearly)
- [ ] `schema/ctes.md` updated
- [ ] Relevant `rules/*.md` updated
- [ ] `CHANGELOG.md` entry added
- [ ] No undocumented conflicts
