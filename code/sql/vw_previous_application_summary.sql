IF OBJECT_ID('vw_previous_application_summary', 'V') IS NOT NULL
    DROP VIEW vw_previous_application_summary;
GO

CREATE VIEW vw_previous_application_summary AS

-- Step 1: Base
WITH previous_base AS (
    SELECT
        SK_ID_CURR,
        SK_ID_PREV,
        AMT_APPLICATION,
        AMT_CREDIT,
        AMT_ANNUITY,
        AMT_DOWN_PAYMENT,
        AMT_GOODS_PRICE,
        DAYS_DECISION,
        NAME_PAYMENT_TYPE,
        NAME_PRODUCT_TYPE,
        CHANNEL_TYPE,
        SELLERPLACE_AREA
    FROM raw_previous_application
),

-- Step 2: Aggregation
previous_summary AS (
    SELECT
        SK_ID_CURR,

        COUNT(SK_ID_PREV) AS total_previous_applications,

        SUM(AMT_APPLICATION) AS total_application_amount,
        AVG(AMT_APPLICATION) AS avg_application_amount,

        SUM(AMT_CREDIT) AS total_credit_amount,
        AVG(AMT_CREDIT) AS avg_credit_amount,

        AVG(AMT_ANNUITY) AS avg_annuity,
        AVG(AMT_DOWN_PAYMENT) AS avg_down_payment,
        AVG(AMT_GOODS_PRICE) AS avg_goods_price,

        MIN(DAYS_DECISION) AS oldest_decision_days,
        MAX(DAYS_DECISION) AS latest_decision_days,

        COUNT(DISTINCT NAME_PAYMENT_TYPE) AS payment_type_count,
        COUNT(DISTINCT NAME_PRODUCT_TYPE) AS product_type_count,
        COUNT(DISTINCT CHANNEL_TYPE) AS channel_type_count,

        AVG(SELLERPLACE_AREA) AS avg_seller_area

    FROM previous_base
    GROUP BY SK_ID_CURR
),

-- Step 3: Derived features
previous_final AS (
    SELECT
        *,

        CASE
            WHEN total_application_amount IS NULL OR total_application_amount = 0 THEN NULL
            ELSE total_credit_amount * 1.0 / total_application_amount
        END AS credit_to_application_ratio,

        CASE
            WHEN total_previous_applications >= 5 THEN 'Frequent Borrower'
            WHEN total_previous_applications >= 2 THEN 'Moderate Borrower'
            ELSE 'New Borrower'
        END AS borrower_segment

    FROM previous_summary
)

-- Final
SELECT *
FROM previous_final;
GO

-- SELECT * FROM vw_previous_application_summary;