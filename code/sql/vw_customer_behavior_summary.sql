IF OBJECT_ID('vw_customer_behavior_summary', 'V') IS NOT NULL
    DROP VIEW vw_customer_behavior_summary;
GO

CREATE VIEW vw_customer_behavior_summary AS

SELECT
    m.SK_ID_CURR,

    -- Previous
    p.total_previous_applications,
    p.total_application_amount,
    p.avg_application_amount,
    p.total_credit_amount,
    p.avg_credit_amount,
    p.credit_to_application_ratio,
    p.borrower_segment,

    -- Credit Card
    c.total_credit_card_records,
    c.avg_credit_card_balance,
    c.max_credit_card_balance,
    c.avg_credit_limit,
    c.total_card_drawings,
    c.total_card_payments,
    c.credit_card_utilization_rate,
    c.card_payment_to_drawing_ratio,
    c.credit_card_risk_segment,

    -- POS
    pos.total_pos_cash_records,
    pos.avg_total_pos_installments,
    pos.avg_future_pos_installments,
    pos.avg_pos_dpd,
    pos.max_pos_dpd,
    pos.pos_cash_risk_segment,

    -- Combined
    CASE
        WHEN c.credit_card_risk_segment = 'High Card Risk'
          OR pos.pos_cash_risk_segment = 'High POS Cash Risk'
        THEN 'High Behavior Risk'

        WHEN c.credit_card_risk_segment = 'Medium Card Risk'
          OR pos.pos_cash_risk_segment = 'Medium POS Cash Risk'
        THEN 'Medium Behavior Risk'

        ELSE 'Low Behavior Risk'
    END AS overall_behavior_risk_segment

FROM vw_bank_customer_mapping m 

LEFT JOIN vw_previous_application_summary p
    ON m.SK_ID_CURR = p.SK_ID_CURR

LEFT JOIN vw_credit_card_summary c
    ON m.SK_ID_CURR = c.SK_ID_CURR

LEFT JOIN vw_pos_cash_summary pos
    ON m.SK_ID_CURR = pos.SK_ID_CURR;

GO

-- SELECT * FROM vw_customer_behavior_summary;