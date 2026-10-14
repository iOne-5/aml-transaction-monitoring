"""Run data quality checks. Exits non-zero if any check fails."""
import sys
import duckdb

con = duckdb.connect("aml.duckdb")
sql = open("sql/quality_checks.sql", encoding="utf-8").read()

failures = 0
for chunk in sql.split(";"):
    # Drop comment lines: every chunk starts with a "-- N. ..." header
    statement = "\n".join(
        line for line in chunk.splitlines() if not line.strip().startswith("--")
    ).strip()
    if not statement:
        continue
    result = con.execute(statement).fetchall()
    if result:
        failures += 1
        print(f"Fail: {result[0][0]}")
        for row in result[:5]:
            print(f"   {row}")

if failures == 0:
    print("Success: All data quality checks passed.")
else:
    print(f"\n{failures} check(s) failed.")
    sys.exit(1)
