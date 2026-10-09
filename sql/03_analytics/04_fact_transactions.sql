-- Fact table: one row per transaction, with foreign keys to the dimensions.

CREATE OR REPLACE TABLE fact_transactions AS
SELECT
    transaction_id,

    -- Foreign keys
    step,
    account_orig,
    account_dest,
    transaction_type,

    -- Measures
    amount,
    old_balance_orig,
    new_balance_orig,
    old_balance_dest,
    new_balance_dest,
    amount_to_balance_ratio,

    -- Flags
    is_fraud,
    is_flagged_fraud,
    balance_inconsistent_orig,
    orig_balance_missing,
    dest_balance_missing,
    orig_emptied

FROM stg_transactions;