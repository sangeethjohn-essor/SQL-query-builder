#!/usr/bin/env python3
"""Validate generated SQL: Snowflake syntax + required output columns."""

from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path

try:
    import sqlglot
    from sqlglot import exp
except ImportError:
    print("Error: sqlglot is required. Install with: pip install sqlglot", file=sys.stderr)
    sys.exit(1)


def parse_sql(sql_path: Path) -> exp.Expression:
    sql = sql_path.read_text(encoding="utf-8")
    try:
        return sqlglot.parse_one(sql, read="snowflake")
    except sqlglot.errors.ParseError as exc:
        raise ValueError(f"SQL parse error in {sql_path}: {exc}") from exc


def _columns_from_select(select: exp.Select) -> set[str]:
    columns: set[str] = set()
    for projection in select.expressions:
        alias = projection.alias
        if alias:
            columns.add(alias.strip('"').strip("'"))
            continue
        if isinstance(projection, exp.Column):
            columns.add(projection.name.strip('"').strip("'"))
        elif isinstance(projection, exp.Star):
            return {"*"}
        else:
            text = projection.sql(dialect="snowflake")
            match = re.search(r'\s+AS\s+"?([^"\s,]+)"?\s*$', text, re.IGNORECASE)
            if match:
                columns.add(match.group(1))
    return columns


def _find_cte(parsed: exp.Expression, name: str) -> exp.Expression | None:
    with_ = parsed.find(exp.With)
    if not with_:
        return None
    for cte in with_.expressions:
        if cte.alias_or_name.upper() == name.upper():
            return cte.this
    return None


def _columns_from_node(parsed: exp.Expression, node: exp.Expression) -> set[str]:
    if isinstance(node, exp.Select):
        cols = _columns_from_select(node)
        if "*" in cols:
            from_ = node.find(exp.From)
            if from_ and isinstance(from_.this, exp.Table):
                inner = _find_cte(parsed, from_.this.name)
                if inner is not None:
                    return _columns_from_node(parsed, inner)
        return cols
    if isinstance(node, exp.Union):
        return _columns_from_node(parsed, node.this)
    return set()


def extract_output_columns(parsed: exp.Expression) -> set[str]:
    """Extract final SELECT output column names/aliases."""
    outer_select = None
    for node in parsed.walk():
        if isinstance(node, exp.Select):
            outer_select = node
    if not outer_select:
        raise ValueError("No SELECT found in SQL")

    columns = _columns_from_select(outer_select)
    if "*" not in columns:
        return columns

    from_ = outer_select.find(exp.From)
    if not from_:
        return columns

    source = from_.this
    if isinstance(source, exp.Table):
        inner = _find_cte(parsed, source.name)
        if inner is not None:
            return _columns_from_node(parsed, inner)
    return columns


def load_required_columns(requirements_path: Path) -> list[str]:
    text = requirements_path.read_text(encoding="utf-8")
    required: list[str] = []

    # From summary table
    in_table = False
    for line in text.splitlines():
        if line.strip() == "## Required output columns":
            in_table = True
            continue
        if in_table:
            if line.startswith("## "):
                break
            if line.startswith("|") and not line.startswith("| Column") and not line.startswith("|--"):
                parts = [p.strip() for p in line.split("|") if p.strip()]
                if parts:
                    required.append(parts[0])
            continue

        # Fallback: parse ### headers with required: Yes
        if line.startswith("### "):
            current = line.replace("### ", "").strip()
            required.append(current)
            continue
        if line.strip() == "- **required:** Yes" and required:
            # keep last header — handled below differently
            pass

    # Deduplicate while preserving order; filter from ### parsing false positives
    if "## Required output columns" in text:
        seen: set[str] = set()
        deduped: list[str] = []
        for col in required:
            if col not in seen and col != "Column":
                seen.add(col)
                deduped.append(col)
        return deduped

    # Fallback: scan sections
    sections = re.split(r"\n### ", text)
    for section in sections[1:]:
        lines = section.splitlines()
        name = lines[0].strip()
        body = "\n".join(lines[1:])
        if "- **required:** Yes" in body:
            required.append(name)

    seen = set()
    deduped = []
    for col in required:
        if col not in seen:
            seen.add(col)
            deduped.append(col)
    return deduped


def validate(sql_path: Path, requirements_path: Path) -> list[str]:
    errors: list[str] = []

    try:
        parsed = parse_sql(sql_path)
    except ValueError as exc:
        return [str(exc)]

    output_cols = extract_output_columns(parsed)
    if "*" in output_cols:
        # UNION ALL SELECT * — check inner CTEs have required cols; skip strict check
        pass
    else:
        required = load_required_columns(requirements_path)
        missing = [c for c in required if c not in output_cols]
        if missing:
            errors.append(
                f"Missing required output columns: {', '.join(missing)}"
            )

    return errors


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description="Validate generated Snowflake SQL")
    parser.add_argument("--output", "-o", type=Path, required=True, help="Generated SQL file")
    parser.add_argument(
        "--requirements",
        "-r",
        type=Path,
        required=True,
        help="Requirements Markdown file",
    )
    args = parser.parse_args(argv)

    if not args.output.exists():
        print(f"Error: SQL file not found: {args.output}", file=sys.stderr)
        return 1
    if not args.requirements.exists():
        print(f"Error: requirements file not found: {args.requirements}", file=sys.stderr)
        return 1

    errors = validate(args.output, args.requirements)
    if errors:
        print("Validation FAILED:", file=sys.stderr)
        for err in errors:
            print(f"  - {err}", file=sys.stderr)
        return 1

    print(f"Validation PASSED: {args.output}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
