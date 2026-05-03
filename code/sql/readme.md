## 🧱 SQL Data Pipeline Structure

### 🔹 Raw Tables

- dbo.raw_application_train  
- dbo.raw_bureau  
- dbo.raw_credit_card_balance  
- dbo.raw_customer_churn_base  
- dbo.raw_installments_payments  
- dbo.raw_pos_cash_balance  
- dbo.raw_previous_application  

---

### 🔹 Intermediate Views

- dbo.vw_clean_application  
- dbo.vw_bureau_customer_summary  
- dbo.vw_credit_card_summary  
- dbo.vw_customer_behavior_summary  
- dbo.vw_customer_churn_base  
- dbo.vw_customer_risk_base  
- dbo.vw_installment_customer_summary  
- dbo.vw_pos_cash_summary  
- dbo.vw_previous_application_summary  

---

## 🔗 Final View Dependency Structure

### 🔹 vw_bank_customer_mapping

- dbo.vw_clean_application  
- dbo.vw_bureau_customer_summary  
- dbo.vw_previous_application_summary  
- dbo.vw_customer_churn_base  
- dbo.vw_customer_risk_base  
- dbo.vw_customer_behavior_summary

---

### 🔹 vw_customer_behavior_summary

- dbo.vw_clean_application  
- dbo.vw_credit_card_summary  
- dbo.vw_installment_customer_summary  
- dbo.vw_pos_cash_summary  



