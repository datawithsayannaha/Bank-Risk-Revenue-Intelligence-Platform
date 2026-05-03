IF OBJECT_ID('vw_pos_cash_summary', 'V') IS NOT NULL
    DROP VIEW vw_pos_cash_summary;
GO

CREATE VIEW vw_pos_cash_summary AS

WITH pos_base AS (
    SELECT
        SK_ID_CURR,
        SK_ID_PREV,
        MONTHS_BALANCE,
        CNT_INSTALMENT,
        CNT_INSTALMENT_FUTURE,
        NAME_CONTRACT_STATUS,
        SK_DPD,
        SK_DPD_DEF
    FROM raw_pos_cash_balance
),

pos_summary AS (
    SELECT
        SK_ID_CURR,

        COUNT(*) AS total_pos_cash_records,
        COUNT(DISTINCT SK_ID_PREV) AS pos_cash_account_count,

        AVG(CNT_INSTALMENT) AS avg_total_pos_installments,
        AVG(CNT_INSTALMENT_FUTURE) AS avg_future_pos_installments,

        SUM(CASE WHEN NAME_CONTRACT_STATUS = 'Active' THEN 1 ELSE 0 END) AS active_pos_months,
        SUM(CASE WHEN NAME_CONTRACT_STATUS = 'Completed' THEN 1 ELSE 0 END) AS completed_pos_months,

        AVG(SK_DPD) AS avg_pos_dpd,
        MAX(SK_DPD) AS max_pos_dpd,

        AVG(SK_DPD_DEF) AS avg_pos_dpd_def,
        MAX(SK_DPD_DEF) AS max_pos_dpd_def,

        SUM(CASE WHEN SK_DPD > 0 THEN 1 ELSE 0 END) AS delayed_pos_months

    FROM pos_base
    GROUP BY SK_ID_CURR
),

pos_final AS (
    SELECT
        *,

        CASE
            WHEN total_pos_cash_records = 0 THEN NULL
            ELSE delayed_pos_months * 1.0 / total_pos_cash_records
        END AS pos_delay_month_rate,

        CASE
            WHEN max_pos_dpd > 30 THEN 'High POS Cash Risk'
            WHEN max_pos_dpd > 0 THEN 'Medium POS Cash Risk'
            ELSE 'Low POS Cash Risk'
        END AS pos_cash_risk_segment,

        CASE
            WHEN avg_future_pos_installments IS NULL THEN 'Unknown'
            WHEN avg_future_pos_installments = 0 THEN 'Fully Paid / Near Closed'
            WHEN avg_future_pos_installments <= 6 THEN 'Short Remaining Term'
            ELSE 'Long Remaining Term'
        END AS pos_remaining_term_segment

    FROM pos_summary
)

SELECT *
FROM pos_final;
GO

-- SELECT * FROM vw_pos_cash_summary;