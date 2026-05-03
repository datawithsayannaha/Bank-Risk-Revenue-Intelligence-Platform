/*        Home Credit Master Risk Base        */
/*
Application + Bureau + Installment combine

customer → full credit risk profile:

customer profile
loan application info
external risk score
credit bureau history
payment behavior
overall risk category
*/

IF OBJECT_ID('vw_customer_risk_base', 'V') IS NOT NULL
    DROP VIEW vw_customer_risk_base;
GO

CREATE VIEW vw_customer_risk_base AS

-- Step 1: Application Base
WITH application_base AS (
    SELECT
        *
    FROM vw_clean_application
),

-- Step 2: Add Bureau Summary
application_bureau_join AS (
    SELECT
        a.*,

        b.total_credit_accounts,
        b.active_credit_accounts,
        b.closed_credit_accounts,
        b.total_credit_amount,
        b.total_debt,
        b.total_overdue_amount,
        b.max_overdue_days,
        b.credit_type_count,
        b.debt_to_credit_ratio,
        b.overdue_flag

    FROM application_base a
    LEFT JOIN vw_bureau_customer_summary b
        ON a.SK_ID_CURR = b.SK_ID_CURR
),

-- Step 3: Add Installment Summary
application_payment_join AS (
    SELECT
        ab.*,

        i.total_installments,
        i.late_payment_count,
        i.on_time_payment_count,
        i.avg_delay_days,
        i.max_delay_days,
        i.total_installment_amount,
        i.total_payment_amount,
        i.payment_gap,
        i.payment_completion_rate,
        i.late_payment_rate,
        i.payment_behavior_segment

    FROM application_bureau_join ab
    LEFT JOIN vw_installment_customer_summary i
        ON ab.SK_ID_CURR = i.SK_ID_CURR
),

-- Step 4: Final Risk Logic
final_risk_base AS (
    SELECT
        *,

        CASE
            WHEN default_status = 'Default' THEN 'Actual Default'
            WHEN external_score_risk_band = 'High Risk'
                 OR overdue_flag = 'Overdue'
                 OR payment_behavior_segment = 'High Risk Payer'
                 OR late_payment_rate >= 0.40
                 OR debt_to_credit_ratio >= 0.70
            THEN 'High Risk'

            WHEN external_score_risk_band = 'Medium Risk'
                 OR payment_behavior_segment = 'Moderate Risk Payer'
                 OR late_payment_rate >= 0.20
                 OR debt_to_credit_ratio >= 0.40
            THEN 'Medium Risk'

            ELSE 'Low Risk'
        END AS overall_credit_risk_segment,

        CASE
            WHEN default_status = 'Default' THEN 1
            WHEN external_score_risk_band = 'High Risk'
                 OR overdue_flag = 'Overdue'
                 OR payment_behavior_segment = 'High Risk Payer'
                 OR late_payment_rate >= 0.40
                 OR debt_to_credit_ratio >= 0.70
            THEN 1
            ELSE 0
        END AS high_risk_flag

    FROM application_payment_join
)

-- Final Output
SELECT *
FROM final_risk_base;
GO

-- Check
-- SELECT  * FROM vw_customer_risk_base;

