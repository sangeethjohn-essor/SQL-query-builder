# Generate SQL from Requirements

Use this workflow when the user asks to generate SQL from an XLSX or requirements MD file.

## Steps

1. **Read requirements**
   - Read the XLSX in `requirements/` OR the corresponding `.md` from `python scripts/xlsx_to_md.py requirements/<file>.xlsx`
   - Identify: use case, 3PL, source tables, header/line field mappings, required fields

2. **Load knowledge context**
   - Read `knowledge/INDEX.md` → load all relevant files for the use case
   - Minimum for IA Argents: `lookups.md`, `mappings.md`, `classifiers.md`, `constants.md`, `projections.md`, `schema/tables.md`, `schema/joins.md`, `conventions.md`

3. **Select golden reference query**
   - Find closest match in `queries/reference/` (same use case + 3PL)
   - Use as structural template — match CTE layering and naming

4. **Generate SQL**
   - Write to `output/<use-case>-<3pl>.sql`
   - Add header comment: use case, source tables, date filters, reference query used
   - **Copy lookup CTEs verbatim** from `knowledge/rules/lookups.md`
   - **Copy classifiers verbatim** from `knowledge/rules/classifiers.md` when applicable
   - Apply mappings from `knowledge/rules/mappings.md`
   - Map every required XLSX field using `projections.md` + requirements
   - Follow overrides in `knowledge/conventions.md` when XLSX text conflicts with golden query

5. **Validate (mandatory)**
   ```bash
   pip install -e .
   python scripts/validate.py --requirements requirements/<file>.md --output output/<generated>.sql
   ```
   - If validation fails, fix SQL and re-run until exit code 0
   - Report validation result to the user

## Guardrails

- Only use tables/columns documented in `knowledge/schema/` or the reference query
- Do not invent join keys — reuse recipes from `knowledge/schema/joins.md`
- Output must be valid Snowflake SQL (passes sqlglot parse)
- All `Required?=Yes` columns from requirements must appear in final SELECT
- Prefer golden query conventions over literal XLSX wording (see `conventions.md`)

## Date filters

- Use CLI-specified dates if user provides them
- Otherwise use defaults from `knowledge/rules/constants.md` for the use case
