"""Build the AML warehouse from raw CSV through to analytics tables."""
import duckdb
from pathlib import Path

DB_PATH = "aml.duckdb"
SQL_DIR = Path("sql")

# Order matters: raw -> staging -> analytics -> detection
LAYERS = ["01_raw", "02_staging", "03_analytics"]


def run_sql_file(con, path: Path) -> None:
    sql = path.read_text(encoding="utf-8").strip()
    if not sql or all(line.strip().startswith("--") or not line.strip()
                      for line in sql.splitlines()):
        print(f"  ⚠ {path.name} is empty or comments only — skipped")
        return
    con.execute(sql)
    print(f"  ✓ {path.name}")

def main() -> None:
    con = duckdb.connect(DB_PATH)
    for layer in LAYERS:
        layer_dir = SQL_DIR / layer
        if not layer_dir.exists():
            continue
        print(f"\n[{layer}]")
        for sql_file in sorted(layer_dir.glob("*.sql")):
            run_sql_file(con, sql_file)
    con.close()
    print("\nWarehouse build complete.")


if __name__ == "__main__":
    main()