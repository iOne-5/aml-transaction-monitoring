-- Account dimension: one row per unique account, with lifetime behaviour stats.
-- Built by unioning origin and destination roles, then aggregating.

CREATE OR REPLACE TABLE dim_account AS
WITH sent AS (
    SELECT
        account_orig                     AS account_id,
        orig_account_type                AS account_type,
        COUNT(*)                         AS n_sent,
        SUM(amount)                      AS total_amount_sent,
        AVG(amount)                      AS avg_amount_sent,
        MIN(step)                        AS first_step_sent,
        MAX(step)                        AS last_step_sent
    FROM stg_transactions
    GROUP BY account_orig, orig_account_type
),
received AS (
    SELECT
        account_dest                     AS account_id,
        dest_account_type                AS account_type,
        COUNT(*)                         AS n_received,
        SUM(amount)                      AS total_amount_received,
        MIN(step)                        AS first_step_received,
        MAX(step)                        AS last_step_received
    FROM stg_transactions
    GROUP BY account_dest, dest_account_type
)
SELECT
    COALESCE(s.account_id, r.account_id)         AS account_id,
    COALESCE(s.account_type, r.account_type)     AS account_type,
    COALESCE(s.n_sent, 0)                        AS n_sent,
    COALESCE(r.n_received, 0)                    AS n_received,
    COALESCE(s.n_sent, 0) + COALESCE(r.n_received, 0) AS n_total,
    COALESCE(s.total_amount_sent, 0)             AS total_amount_sent,
    COALESCE(r.total_amount_received, 0)         AS total_amount_received,
    s.avg_amount_sent,
    LEAST(
        COALESCE(s.first_step_sent, 999999),
        COALESCE(r.first_step_received, 999999)
    )                                            AS first_step,
    GREATEST(
        COALESCE(s.last_step_sent, 0),
        COALESCE(r.last_step_received, 0)
    )                                            AS last_step
FROM sent s
FULL OUTER JOIN received r ON s.account_id = r.account_id;