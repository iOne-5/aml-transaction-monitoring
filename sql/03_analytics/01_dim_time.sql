-- Time dimension. In PaySim, 1 step = 1 hour, starting at hour 0 of day 1.

CREATE OR REPLACE TABLE dim_time AS
SELECT DISTINCT
    step,
    ((step - 1) / 24) + 1               AS day_number,
    (step - 1) % 24                     AS hour_of_day,
    (((step - 1) / 24) % 7) + 1         AS day_of_week,
    CASE
        WHEN (step - 1) % 24 BETWEEN 0 AND 5 THEN TRUE
        WHEN (step - 1) % 24 >= 22        THEN TRUE
        ELSE FALSE
    END                                 AS is_night
FROM stg_transactions
ORDER BY step;