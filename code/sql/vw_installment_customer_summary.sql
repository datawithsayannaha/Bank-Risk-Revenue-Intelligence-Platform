/*        Installment Payment Behavior Summary        */
/*
customer → installment/payment behavior summarize:

total installments
late payment count
on-time payment count
avg delay days
max delay days
total installment amount
total payment amount
payment gap
payment completion rate
payment behavior segment

*/

IF OBJECT_ID('vw_installment_customer_summary', 'V') IS NOT NULL
    DROP VIEW vw_installment_customer_summary;
GO

CREATE VIEW vw_installment_customer_summary AS

-- Step 1: Base Installment
WITH installment_base AS (
    SELECT
        SK_ID_CURR,
        SK_ID_PREV,
        NUM_INSTALMENT_NUMBER,
        DAYS_INSTALMENT,
        DAYS_ENTRY_PAYMENT,
        AMT_INSTALMENT,
        AMT_PAYMENT,

        CASE
            WHEN DAYS_ENTRY_PAYMENT IS NULL THEN NULL
            ELSE DAYS_ENTRY_PAYMENT - DAYS_INSTALMENT
        END AS delay_days,

        CASE 
            WHEN DAYS_ENTRY_PAYMENT IS NULL THEN 1
            WHEN DAYS_ENTRY_PAYMENT - DAYS_INSTALMENT > 0 THEN 1
            ELSE 0
        END AS late_payment_flag
    FROM raw_installments_payments
),

-- Customer Aggregation
installment_summary AS (
    SELECT
        SK_ID_CURR,

        COUNT(*) AS total_installments,

        SUM(late_payment_flag) AS late_payment_count,

        SUM(CASE WHEN late_payment_flag = 0 THEN 1 ELSE 0 END) AS on_time_payment_count,

        AVG(CASE WHEN delay_days > 0 THEN delay_days * 1.0 ELSE 0 END) AS avg_delay_days,

        MAX(CASE WHEN delay_days > 0 THEN delay_days ELSE 0 END) AS max_delay_days,

        SUM(AMT_INSTALMENT) AS total_installment_amount,

        SUM(AMT_PAYMENT) AS total_payment_amount

    FROM installment_base
    GROUP BY SK_ID_CURR
),

-- Step 3: Derived Payment Ratios
installment_final AS (
    SELECT
        *,

        total_installment_amount - total_payment_amount AS payment_gap,

        CASE 
            WHEN total_installment_amount IS NULL OR total_installment_amount = 0 THEN NULL
            ELSE total_payment_amount / total_installment_amount
        END AS payment_completion_rate,

        CASE
            WHEN total_installments = 0 THEN NULL
            ELSE late_payment_count * 1.0 / total_installments
        END AS late_payment_rate,

        CASE
            WHEN late_payment_count = 0 THEN 'Excellent Payer'
            WHEN late_payment_count <= 2 THEN 'Good Payer'
            WHEN late_payment_count <= 5 THEN 'Moderate Risk Payer'
            ELSE 'High Risk Payer'
        END AS payment_behavior_segment

    FROM installment_summary
)

-- Final Output
SELECT *
FROM installment_final;
GO

-- Check
-- SELECT  * FROM vw_installment_customer_summary;
