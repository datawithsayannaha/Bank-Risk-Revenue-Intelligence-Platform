/*         Bureau Summary Cleaning        */
/* customer → ALL credit history summarize:

total credit account
active vs closed credit account
total credit amount
total debt
overdue behavior
credit diversity
debt_to_credit_ratio 
overdue_flag

*/

IF OBJECT_ID('vw_bureau_customer_summary', 'V') IS NOT NULL
    DROP VIEW vw_bureau_customer_summary;
GO

CREATE VIEW vw_bureau_customer_summary AS

-- Step 1: Base bureau
WITH bureau_base AS (
    SELECT
        SK_ID_CURR,
        SK_ID_BUREAU,
        CREDIT_ACTIVE,
        AMT_CREDIT_SUM,
        AMT_CREDIT_SUM_DEBT,
        AMT_CREDIT_SUM_OVERDUE,
        CREDIT_DAY_OVERDUE,
        CREDIT_TYPE
    FROM raw_bureau
),

-- Step 2: Aggregation per customer
bureau_summary AS (
    SELECT
        SK_ID_CURR,

        COUNT(SK_ID_BUREAU) AS total_credit_accounts,
        SUM(CASE WHEN CREDIT_ACTIVE = 'Active' THEN 1 ELSE 0 END) AS active_credit_accounts,
        SUM(CASE WHEN CREDIT_ACTIVE = 'Closed' THEN 1 ELSE 0 END) AS closed_credit_accounts,
        SUM(AMT_CREDIT_SUM) AS total_credit_amount,

        SUM(AMT_CREDIT_SUM_DEBT) AS total_debt,

        SUM(AMT_CREDIT_SUM_OVERDUE) AS total_overdue_amount,

        MAX(CREDIT_DAY_OVERDUE) AS max_overdue_days,

        COUNT(DISTINCT CREDIT_TYPE) AS credit_type_count

    FROM bureau_base
    GROUP BY SK_ID_CURR
),
-- Step 3: Derived ratios
bureau_final AS (
    SELECT
        *,

        CASE 
            WHEN total_credit_amount IS NULL OR total_credit_amount = 0 THEN NULL
            ELSE total_debt / total_credit_amount
        END AS debt_to_credit_ratio,

        CASE 
            WHEN total_overdue_amount > 0 OR max_overdue_days > 0 THEN 'Overdue'
            ELSE 'No Overdue'
        END AS overdue_flag

    FROM bureau_summary
)

-- Final output
SELECT * FROM bureau_final;
GO

-- Check
--SELECT * FROM vw_bureau_customer_summary;

