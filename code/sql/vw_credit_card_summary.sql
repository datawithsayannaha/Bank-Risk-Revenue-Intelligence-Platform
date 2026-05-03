IF OBJECT_ID('vw_credit_card_summary', 'V') IS NOT NULL
    DROP VIEW vw_credit_card_summary;
GO

CREATE VIEW vw_credit_card_summary AS

WITH card_base AS (
    SELECT
        SK_ID_CURR,
        SK_ID_PREV,
        MONTHS_BALANCE,
        AMT_BALANCE,
        AMT_CREDIT_LIMIT_ACTUAL,
        AMT_DRAWINGS_CURRENT,
        AMT_PAYMENT_TOTAL_CURRENT,
        AMT_TOTAL_RECEIVABLE,
        CNT_DRAWINGS_CURRENT,
        CNT_INSTALMENT_MATURE_CUM,
        NAME_CONTRACT_STATUS,
        SK_DPD,
        SK_DPD_DEF
    FROM raw_credit_card_balance
),

card_summary AS (
    SELECT
        SK_ID_CURR,

        COUNT(*) AS total_credit_card_records,
        COUNT(DISTINCT SK_ID_PREV) AS credit_card_account_count,

        AVG(AMT_BALANCE) AS avg_credit_card_balance,
        MAX(AMT_BALANCE) AS max_credit_card_balance,

        AVG(AMT_CREDIT_LIMIT_ACTUAL) AS avg_credit_limit,
        MAX(AMT_CREDIT_LIMIT_ACTUAL) AS max_credit_limit,

        SUM(AMT_DRAWINGS_CURRENT) AS total_card_drawings,
        AVG(AMT_DRAWINGS_CURRENT) AS avg_card_drawings,

        SUM(AMT_PAYMENT_TOTAL_CURRENT) AS total_card_payments,
        AVG(AMT_PAYMENT_TOTAL_CURRENT) AS avg_card_payment,

        AVG(AMT_TOTAL_RECEIVABLE) AS avg_total_receivable,
        MAX(AMT_TOTAL_RECEIVABLE) AS max_total_receivable,

        SUM(CNT_DRAWINGS_CURRENT) AS total_card_drawing_count,
        AVG(CNT_DRAWINGS_CURRENT) AS avg_card_drawing_count,

        AVG(CNT_INSTALMENT_MATURE_CUM) AS avg_mature_installments,

        AVG(SK_DPD) AS avg_card_dpd,
        MAX(SK_DPD) AS max_card_dpd,
        AVG(SK_DPD_DEF) AS avg_card_dpd_def,
        MAX(SK_DPD_DEF) AS max_card_dpd_def,

        SUM(CASE WHEN NAME_CONTRACT_STATUS = 'Active' THEN 1 ELSE 0 END) AS active_card_months,
        SUM(CASE WHEN SK_DPD > 0 THEN 1 ELSE 0 END) AS delayed_card_months

    FROM card_base
    GROUP BY SK_ID_CURR
),

card_final AS (
    SELECT
        *,

        CASE
            WHEN avg_credit_limit IS NULL OR avg_credit_limit = 0 THEN NULL
            ELSE avg_credit_card_balance / avg_credit_limit
        END AS credit_card_utilization_rate,

        CASE
            WHEN total_card_drawings IS NULL OR total_card_drawings = 0 THEN NULL
            ELSE total_card_payments / total_card_drawings
        END AS card_payment_to_drawing_ratio,

        CASE
            WHEN total_credit_card_records = 0 THEN NULL
            ELSE delayed_card_months * 1.0 / total_credit_card_records
        END AS card_delay_month_rate,

        CASE
            WHEN max_card_dpd > 30 OR 
                 (CASE WHEN avg_credit_limit IS NULL OR avg_credit_limit = 0 THEN NULL ELSE avg_credit_card_balance / avg_credit_limit END) >= 0.80
                THEN 'High Card Risk'
            WHEN max_card_dpd > 0 OR
                 (CASE WHEN avg_credit_limit IS NULL OR avg_credit_limit = 0 THEN NULL ELSE avg_credit_card_balance / avg_credit_limit END) >= 0.50
                THEN 'Medium Card Risk'
            ELSE 'Low Card Risk'
        END AS credit_card_risk_segment

    FROM card_summary
)

SELECT *
FROM card_final;
GO

-- SELECT * FROM vw_credit_card_summary;