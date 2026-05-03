IF OBJECT_ID('vw_customer_churn_base', 'V') IS NOT NULL
    DROP VIEW vw_customer_churn_base;
GO

CREATE VIEW vw_customer_churn_base AS
SELECT *
FROM raw_customer_churn_base;
GO

-- SELECT * FROM vw_customer_churn_base