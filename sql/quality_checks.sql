-- ============================================================
-- Data quality checks. Each query returns rows ONLY on failure.
-- ============================================================

-- 1. Row counts must match between raw and staging
SELECT 'FAIL: row count mismatch' AS check_name,
       (SELECT COUNT(*) FROM raw_transactions) AS raw_rows,
       (SELECT COUNT(*) FROM stg_transactions) AS stg_rows
WHERE (SELECT COUNT(*) FROM raw_transactions)
   <> (SELECT COUNT(*) FROM stg_transactions);

-- 2. Transaction IDs must be unique
SELECT 'FAIL: duplicate transaction_id' AS check_name, transaction_id, COUNT(*) AS n
FROM fact_transactions
GROUP BY transaction_id
HAVING COUNT(*) > 1;

-- 3. No negative amounts
SELECT 'FAIL: negative amount' AS check_name, transaction_id, amount
FROM fact_transactions
WHERE amount < 0;

-- 4. Every fact row must join to a time dimension row
SELECT 'FAIL: orphan step' AS check_name, f.transaction_id, f.step
FROM fact_transactions f
LEFT JOIN dim_time t ON f.step = t.step
WHERE t.step IS NULL;

-- 5. Every fact row must join to an account dimension row
SELECT 'FAIL: orphan account_orig' AS check_name, f.transaction_id, f.account_orig
FROM fact_transactions f
LEFT JOIN dim_account a ON f.account_orig = a.account_id
WHERE a.account_id IS NULL;

-- 6. Fraud rate must be within a plausible range (0.05% – 0.5%)
SELECT 'FAIL: fraud rate out of range' AS check_name,
       ROUND(100.0 * AVG(is_fraud::INT), 4) AS fraud_pct
FROM fact_transactions
HAVING ROUND(100.0 * AVG(is_fraud::INT), 4) NOT BETWEEN 0.05 AND 0.5;

-- 7. Transaction types must match the dimension exactly
SELECT 'FAIL: unknown transaction type' AS check_name, f.transaction_type
FROM fact_transactions f
LEFT JOIN dim_transaction_type d ON f.transaction_type = d.transaction_type
WHERE d.transaction_type IS NULL
GROUP BY f.transaction_type;
