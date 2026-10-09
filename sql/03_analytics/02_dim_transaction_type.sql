-- Transaction type dimension with human-readable descriptions.

CREATE OR REPLACE TABLE dim_transaction_type AS
SELECT * FROM (
    VALUES
        ('CASH_IN',  'Customer deposits cash via a merchant',        FALSE),
        ('CASH_OUT', 'Customer withdraws cash via a merchant',       TRUE),
        ('DEBIT',    'Funds sent from mobile money to a bank account', TRUE),
        ('PAYMENT',  'Customer pays a merchant for goods or services', TRUE),
        ('TRANSFER', 'Funds sent to another mobile money customer',  TRUE)
) AS t(transaction_type, description, is_outgoing);