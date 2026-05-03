IF OBJECT_ID('vw_bank_customer_mapping', 'V') IS NOT NULL
    DROP VIEW vw_bank_customer_mapping;
GO

CREATE VIEW vw_bank_customer_mapping AS

SELECT
    r.*,   -- full risk base
    c.credit_score,
    c.country,
    c.tenure,
    c.balance,
    c.products_number,
    c.credit_card,
    c.active_member,
    c.estimated_salary,
    c.churn,
    c.churn_label,
    c.activity_status,
    c.credit_card_status,
    c.credit_score_band,
    c.balance_segment,
    c.salary_segment,
    c.product_holding_segment,
    c.churn_risk_segment

FROM vw_customer_risk_base r
LEFT JOIN vw_customer_churn_base c
    ON r.SK_ID_CURR = c.churn_customer_id;

GO

-- Check
-- SELECT  * FROM vw_bank_customer_mapping;