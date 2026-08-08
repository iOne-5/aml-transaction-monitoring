-- Raw layer: exact copy of the source CSV, no transformation.
-- This is the immutable source of truth. Never edit rows here.

CREATE OR REPLACE TABLE raw_transactions AS
SELECT *
FROM read_csv_auto('data/raw/PS_20174392719_1491204439457_log.csv');