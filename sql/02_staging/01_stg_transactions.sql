-- Staging layer: cleaned and standardised, still one row per transaction.
-- Changes from raw: snake_case names, explicit types, derived quality flags.

CREATE OR REPLACE TABLE stg_transactions AS
SELECT
    ROW_NUMBER() OVER (ORDER BY step, nameOrig, nameDest) AS transaction_id,

    -- Core fields, renamed to snake_case
    CAST(step AS INTEGER)                AS step,
    CAST(type AS VARCHAR)                AS transaction_type,
    CAST(amount AS DOUBLE)               AS amount,

    CAST(nameOrig AS VARCHAR)            AS account_orig,
    CAST(oldbalanceOrg AS DOUBLE)        AS old_balance_orig,
    CAST(newbalanceOrig AS DOUBLE)       AS new_balance_orig,

    CAST(nameDest AS VARCHAR)            AS account_dest,
    CAST(oldbalanceDest AS DOUBLE)       AS old_balance_dest,
    CAST(newbalanceDest AS DOUBLE)       AS new_balance_dest,

    CAST(isFraud AS BOOLEAN)             AS is_fraud,
    CAST(isFlaggedFraud AS BOOLEAN)      AS is_flagged_fraud,

    -- Derived: account classification
    CASE WHEN nameOrig LIKE 'M%' THEN 'merchant' ELSE 'customer' END AS orig_account_type,
    CASE WHEN nameDest LIKE 'M%' THEN 'merchant' ELSE 'customer' END AS dest_account_type,

    -- Balance consistency check for outgoing transactions.
    -- Excluded: CASH_IN (adds funds, opposite formula) and rows where
    -- balance data is missing (PaySim encodes missing as 0).
    CASE
        WHEN type = 'CASH_IN' THEN FALSE
        WHEN oldbalanceOrg = 0 AND newbalanceOrig = 0 THEN FALSE
        WHEN ABS((oldbalanceOrg - amount) - newbalanceOrig) > 0.01 THEN TRUE
        ELSE FALSE
    END AS balance_inconsistent_orig,
    
    -- Zero balances in PaySim are often missing data rather than a true zero
    CASE WHEN oldbalanceOrg = 0 AND newbalanceOrig = 0 THEN TRUE ELSE FALSE END AS orig_balance_missing,
    CASE WHEN oldbalanceDest = 0 AND newbalanceDest = 0 THEN TRUE ELSE FALSE END AS dest_balance_missing,

    -- Derived: behavioural signal — did this transaction empty the account?
    CASE
        WHEN oldbalanceOrg > 0 AND newbalanceOrig = 0 THEN TRUE
        ELSE FALSE
    END AS orig_emptied,

    -- Derived: what share of the balance moved
    CASE
        WHEN oldbalanceOrg > 0 THEN ROUND(amount / oldbalanceOrg, 4)
        ELSE NULL
    END AS amount_to_balance_ratio

FROM raw_transactions;