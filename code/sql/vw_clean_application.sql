/*       Clean Application View           */

IF OBJECT_ID('vw_clean_application', 'V') IS NOT NULL
    DROP VIEW vw_clean_application;
GO

CREATE VIEW vw_clean_application AS

-- Step 1: Clean Application Base
WITH application_base AS (
    SELECT
        SK_ID_CURR,
        TARGET,
        NAME_CONTRACT_TYPE,
        CODE_GENDER,
        FLAG_OWN_CAR,
        FLAG_OWN_REALTY,
        CNT_CHILDREN,
        AMT_INCOME_TOTAL,
        AMT_CREDIT,
        AMT_ANNUITY,
        AMT_GOODS_PRICE,
        NAME_TYPE_SUITE,
        NAME_INCOME_TYPE,
        NAME_EDUCATION_TYPE,
        NAME_FAMILY_STATUS,
        NAME_HOUSING_TYPE,
        REGION_POPULATION_RELATIVE,
        DAYS_BIRTH,
        DAYS_EMPLOYED,
        OCCUPATION_TYPE,
        CNT_FAM_MEMBERS,
        REGION_RATING_CLIENT,
        ORGANIZATION_TYPE,
        EXT_SOURCE_1,
        EXT_SOURCE_2,
        EXT_SOURCE_3,
        AMT_REQ_CREDIT_BUREAU_MON,
        AMT_REQ_CREDIT_BUREAU_QRT,
        AMT_REQ_CREDIT_BUREAU_YEAR
    FROM raw_application_train
),

-- Step 2: Convert Days + Basic Cleaning
application_cleaned AS (
    SELECT
        *,
        CAST(ROUND(ABS(DAYS_BIRTH) / 365.0, 0) AS INT) AS age_years,

        CAST(
            ROUND(
                CASE 
                    WHEN DAYS_EMPLOYED = 365243 THEN NULL
                    WHEN DAYS_EMPLOYED > 0 THEN NULL
                    ELSE ABS(DAYS_EMPLOYED) / 365.0
                END
            , 0)
        AS INT) AS employment_years,

        CASE 
            WHEN CODE_GENDER = 'M' THEN 'Male'
            WHEN CODE_GENDER = 'F' THEN 'Female'
            ELSE 'Unknown'
        END AS gender_clean,

        CASE 
            WHEN TARGET = 1 THEN 'Default'
            ELSE 'Non-Default'
        END AS default_status
    FROM application_base
),

-- Step 3: Business Segmentation
application_segments AS (
    SELECT
        *,
        CASE
            WHEN age_years < 30 THEN 'Young'
            WHEN age_years < 45 THEN 'Adult'
            WHEN age_years < 60 THEN 'Middle Age'
            ELSE 'Senior'
        END AS age_segment,

        CASE
            WHEN AMT_INCOME_TOTAL < 100000 THEN 'Low Income'
            WHEN AMT_INCOME_TOTAL < 250000 THEN 'Medium Income'
            WHEN AMT_INCOME_TOTAL < 500000 THEN 'High Income'
            ELSE 'Very High Income'
        END AS income_segment,

        CASE
            WHEN AMT_CREDIT < 300000 THEN 'Small Loan'
            WHEN AMT_CREDIT < 800000 THEN 'Medium Loan'
            WHEN AMT_CREDIT < 1500000 THEN 'Large Loan'
            ELSE 'Very Large Loan'
        END AS loan_amount_segment,

        CASE
            WHEN REGION_RATING_CLIENT = 1 THEN 'Low Risk Region'
            WHEN REGION_RATING_CLIENT = 2 THEN 'Medium Risk Region'
            WHEN REGION_RATING_CLIENT = 3 THEN 'High Risk Region'
            ELSE 'Unknown Region Risk'
        END AS region_risk_segment
    FROM application_cleaned
),

-- Step 4: Financial Ratios
application_ratios AS (
    SELECT
        *,
        CASE 
            WHEN AMT_INCOME_TOTAL = 0 OR AMT_INCOME_TOTAL IS NULL THEN NULL
            ELSE AMT_CREDIT / AMT_INCOME_TOTAL
        END AS loan_to_income_ratio,

        CASE 
            WHEN AMT_INCOME_TOTAL = 0 OR AMT_INCOME_TOTAL IS NULL THEN NULL
            ELSE AMT_ANNUITY / AMT_INCOME_TOTAL
        END AS annuity_to_income_ratio,

        CASE 
            WHEN AMT_CREDIT = 0 OR AMT_CREDIT IS NULL THEN NULL
            ELSE AMT_GOODS_PRICE / AMT_CREDIT
        END AS goods_to_credit_ratio
    FROM application_segments
),

-- Step 5: External Risk Score
application_risk_score AS (
    SELECT
        *,
        (
            COALESCE(EXT_SOURCE_1, 0) +
            COALESCE(EXT_SOURCE_2, 0) +
            COALESCE(EXT_SOURCE_3, 0)
        ) /
        NULLIF(
            CASE WHEN EXT_SOURCE_1 IS NOT NULL THEN 1 ELSE 0 END +
            CASE WHEN EXT_SOURCE_2 IS NOT NULL THEN 1 ELSE 0 END +
            CASE WHEN EXT_SOURCE_3 IS NOT NULL THEN 1 ELSE 0 END,
            0
        ) AS avg_external_score
    FROM application_ratios
),

-- Step 6: Application Risk Band
final_application AS (
    SELECT
        *,
        CASE
            WHEN avg_external_score IS NULL THEN 'Unknown Risk'
            WHEN avg_external_score < 0.30 THEN 'High Risk'
            WHEN avg_external_score < 0.60 THEN 'Medium Risk'
            ELSE 'Low Risk'
        END AS external_score_risk_band,

        CASE
            WHEN loan_to_income_ratio >= 5 THEN 'Very High Loan Burden'
            WHEN loan_to_income_ratio >= 3 THEN 'High Loan Burden'
            WHEN loan_to_income_ratio >= 1.5 THEN 'Medium Loan Burden'
            ELSE 'Low Loan Burden'
        END AS loan_burden_segment
    FROM application_risk_score
)

-- Final Output
SELECT
    *
FROM final_application;
GO

-- Check
-- SELECT  * FROM vw_clean_application;
/*
SELECT TOP 50
    SK_ID_CURR,
    DAYS_BIRTH,
    age_years,
    DAYS_EMPLOYED,
    employment_years
FROM vw_clean_application;
*/