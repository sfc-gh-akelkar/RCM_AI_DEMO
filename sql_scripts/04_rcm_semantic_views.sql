-- ========================================================================
-- RCM AI Demo - Semantic Views Setup (Part 2 of 4)
-- Healthcare Revenue Cycle Management Semantic Views for Cortex Analyst
-- ========================================================================

USE ROLE SF_INTELLIGENCE_DEMO;
USE DATABASE RCM_AI_DEMO;
USE SCHEMA RCM_SCHEMA;

-- ========================================================================
-- CLAIMS PROCESSING SEMANTIC VIEW
-- ========================================================================

CREATE OR REPLACE SEMANTIC VIEW RCM_AI_DEMO.RCM_SCHEMA.CLAIMS_PROCESSING_VIEW
tables (
    CLAIMS as CLAIMS_FACT primary key (CLAIM_ID),
    PROVIDERS as HEALTHCARE_PROVIDERS_DIM primary key (PROVIDER_KEY),
    PAYERS as PAYERS_DIM primary key (PAYER_KEY),
    PROCEDURES as PROCEDURES_DIM primary key (PROCEDURE_KEY),
    SPECIALTIES as PROVIDER_SPECIALTIES_DIM primary key (SPECIALTY_KEY),
    REGIONS as GEOGRAPHIC_REGIONS_DIM primary key (REGION_KEY),
    EMPLOYEES as RCM_EMPLOYEES_DIM primary key (EMPLOYEE_KEY)
)
relationships (
    CLAIMS_TO_PROVIDERS as CLAIMS(PROVIDER_KEY) references PROVIDERS(PROVIDER_KEY),
    CLAIMS_TO_PAYERS as CLAIMS(PAYER_KEY) references PAYERS(PAYER_KEY),
    CLAIMS_TO_PROCEDURES as CLAIMS(PROCEDURE_KEY) references PROCEDURES(PROCEDURE_KEY),
    CLAIMS_TO_SPECIALTIES as CLAIMS(SPECIALTY_KEY) references SPECIALTIES(SPECIALTY_KEY),
    CLAIMS_TO_REGIONS as CLAIMS(REGION_KEY) references REGIONS(REGION_KEY),
    CLAIMS_TO_EMPLOYEES as CLAIMS(EMPLOYEE_KEY) references EMPLOYEES(EMPLOYEE_KEY)
)
facts (
    CLAIMS.CHARGE_AMOUNT as charge_amount,
    CLAIMS.ALLOWED_AMOUNT as allowed_amount,
    CLAIMS.PAID_AMOUNT as paid_amount,
    CLAIMS.PATIENT_RESPONSIBILITY as patient_responsibility,
    CLAIMS.DAYS_TO_PAYMENT as days_to_payment
)
dimensions (
    CLAIMS.SUBMISSION_DATE as submission_date,
    CLAIMS.SERVICE_DATE as service_date,
    CLAIMS.CLAIM_STATUS as claim_status,
    CLAIMS.PAYMENT_STATUS as payment_status,
    CLAIMS.CLEAN_CLAIM_FLAG as clean_claim,
    CLAIMS.DENIAL_FLAG as denied,
    CLAIMS.APPEAL_FLAG as appealed,
    PROVIDERS.PROVIDER_NAME as provider_name,
    PROVIDERS.PROVIDER_TYPE as provider_type,
    PROVIDERS.SPECIALTY as provider_specialty,
    PROVIDERS.ANNUAL_REVENUE as provider_revenue,
    PAYERS.PAYER_NAME as payer_name,
    PAYERS.PAYER_TYPE as payer_type,
    PAYERS.MARKET_SHARE as payer_market_share,
    PAYERS.AVG_DAYS_TO_PAY as payer_avg_days,
    PROCEDURES.CPT_CODE as cpt_code,
    PROCEDURES.PROCEDURE_NAME as procedure_name,
    PROCEDURES.CATEGORY as procedure_category,
    PROCEDURES.RELATIVE_VALUE_UNITS as procedure_charge,
    SPECIALTIES.SPECIALTY_NAME as specialty_name,
    SPECIALTIES.DESCRIPTION as specialty_description,
    REGIONS.REGION_NAME as region_name,
    REGIONS.STATE_LIST as state,
    EMPLOYEES.DEPARTMENT as employee_department,
    EMPLOYEES.ROLE as employee_role
)
metrics (
    CLAIMS.TOTAL_CLAIMS as COUNT(*)
        WITH SYNONYMS = ('total claims', 'claim count', 'number of claims'),
    CLAIMS.CLEAN_CLAIMS as COUNT(CASE WHEN clean_claim_flag THEN 1 END)
        WITH SYNONYMS = ('clean claims', 'first pass claims'),
    CLAIMS.DENIED_CLAIMS as COUNT(CASE WHEN denial_flag THEN 1 END)
        WITH SYNONYMS = ('denied claims', 'claim denials'),
    CLAIMS.APPEALED_CLAIMS as COUNT(CASE WHEN appeal_flag THEN 1 END)
        WITH SYNONYMS = ('appealed claims', 'claims under appeal'),
    CLAIMS.TOTAL_CHARGES as SUM(charge_amount)
        WITH SYNONYMS = ('total charges', 'gross charges', 'billed amount'),
    CLAIMS.TOTAL_ALLOWED as SUM(allowed_amount)
        WITH SYNONYMS = ('total allowed', 'allowed amounts'),
    CLAIMS.TOTAL_PAID as SUM(paid_amount)
        WITH SYNONYMS = ('total paid', 'payments received', 'collections'),
    CLAIMS.TOTAL_PATIENT_RESPONSIBILITY as SUM(patient_responsibility)
        WITH SYNONYMS = ('patient responsibility', 'patient portion', 'copays and deductibles'),
    CLAIMS.CLEAN_CLAIM_RATE as (COUNT(CASE WHEN clean_claim_flag THEN 1 END) / COUNT(*) * 100)
        WITH SYNONYMS = ('clean claim rate', 'first pass rate', 'acceptance rate'),
    CLAIMS.DENIAL_RATE as (COUNT(CASE WHEN denial_flag THEN 1 END) / COUNT(*) * 100)
        WITH SYNONYMS = ('denial rate', 'rejection rate'),
    CLAIMS.NET_COLLECTION_RATE as (SUM(paid_amount) / SUM(charge_amount) * 100)
        WITH SYNONYMS = ('net collection rate', 'collection rate', 'reimbursement rate'),
    CLAIMS.AVERAGE_DAYS_TO_PAYMENT as AVG(days_to_payment)
        WITH SYNONYMS = ('average days to payment', 'payment cycle time', 'days in AR'),
    CLAIMS.AVERAGE_CHARGE as AVG(charge_amount)
        WITH SYNONYMS = ('average charge', 'average billed amount'),
    CLAIMS.AVERAGE_PAID as AVG(paid_amount)
        WITH SYNONYMS = ('average payment', 'average reimbursement')
);

-- ========================================================================
-- DENIALS MANAGEMENT SEMANTIC VIEW
-- ========================================================================

CREATE OR REPLACE SEMANTIC VIEW RCM_AI_DEMO.RCM_SCHEMA.DENIALS_MANAGEMENT_VIEW
tables (
    DENIALS as DENIALS_FACT primary key (DENIAL_ID),
    CLAIMS as CLAIMS_FACT primary key (CLAIM_ID),
    PROVIDERS as HEALTHCARE_PROVIDERS_DIM primary key (PROVIDER_KEY),
    PAYERS as PAYERS_DIM primary key (PAYER_KEY),
    DENIAL_REASONS as DENIAL_REASONS_DIM primary key (DENIAL_REASON_KEY),
    APPEALS as APPEALS_DIM primary key (APPEAL_KEY),
    EMPLOYEES as RCM_EMPLOYEES_DIM primary key (EMPLOYEE_KEY)
)
relationships (
    DENIALS_TO_CLAIMS as DENIALS(CLAIM_ID) references CLAIMS(CLAIM_ID),
    DENIALS_TO_PROVIDERS as DENIALS(PROVIDER_KEY) references PROVIDERS(PROVIDER_KEY),
    DENIALS_TO_PAYERS as DENIALS(PAYER_KEY) references PAYERS(PAYER_KEY),
    DENIALS_TO_REASONS as DENIALS(DENIAL_REASON_KEY) references DENIAL_REASONS(DENIAL_REASON_KEY),
    DENIALS_TO_APPEALS as DENIALS(APPEAL_KEY) references APPEALS(APPEAL_KEY),
    DENIALS_TO_EMPLOYEES as DENIALS(EMPLOYEE_KEY) references EMPLOYEES(EMPLOYEE_KEY)
)
facts (
    DENIALS.DENIED_AMOUNT as denied_amount,
    DENIALS.RECOVERED_AMOUNT as recovered_amount,
    DENIALS.DAYS_TO_APPEAL as days_to_appeal,
    DENIALS.DAYS_TO_RESOLUTION as days_to_resolution
)
dimensions (
    DENIALS.DENIAL_DATE as denial_date,
    DENIALS.DENIAL_STATUS as denial_status,
    DENIALS.APPEAL_OUTCOME as appeal_outcome,
    PROVIDERS.PROVIDER_NAME as provider_name,
    PROVIDERS.PROVIDER_TYPE as provider_type,
    PROVIDERS.SPECIALTY as provider_specialty,
    PAYERS.PAYER_NAME as payer_name,
    PAYERS.PAYER_TYPE as payer_type,
    DENIAL_REASONS.DENIAL_CODE as denial_code,
    DENIAL_REASONS.DENIAL_DESCRIPTION as denial_description,
    DENIAL_REASONS.CATEGORY as denial_category,
    DENIAL_REASONS.APPEALABLE as appealable,
    DENIAL_REASONS.SUCCESS_RATE as historical_success_rate,
    APPEALS.APPEAL_TYPE as appeal_type,
    APPEALS.AVG_RESOLUTION_DAYS as appeal_avg_days,
    EMPLOYEES.DEPARTMENT as employee_department,
    EMPLOYEES.ROLE as employee_role
)
metrics (
    DENIALS.TOTAL_DENIALS as COUNT(*)
        WITH SYNONYMS = ('total denials', 'denial count', 'number of denials'),
    DENIALS.APPEALED_DENIALS as COUNT(CASE WHEN days_to_appeal IS NOT NULL THEN 1 END)
        WITH SYNONYMS = ('appealed denials', 'denials under appeal'),
    DENIALS.RESOLVED_DENIALS as COUNT(CASE WHEN days_to_resolution IS NOT NULL THEN 1 END)
        WITH SYNONYMS = ('resolved denials', 'closed denials'),
    DENIALS.TOTAL_DENIED_AMOUNT as SUM(denied_amount)
        WITH SYNONYMS = ('total denied amount', 'denied dollars', 'lost revenue'),
    DENIALS.TOTAL_RECOVERED_AMOUNT as SUM(recovered_amount)
        WITH SYNONYMS = ('total recovered', 'appeal recoveries', 'recovered revenue'),
    DENIALS.AVERAGE_DENIED_AMOUNT as AVG(denied_amount)
        WITH SYNONYMS = ('average denial amount', 'mean denial value'),
    DENIALS.APPEAL_RATE as (COUNT(CASE WHEN days_to_appeal IS NOT NULL THEN 1 END) / COUNT(*) * 100)
        WITH SYNONYMS = ('appeal rate', 'percentage appealed'),
    DENIALS.RECOVERY_RATE as (SUM(recovered_amount) / SUM(denied_amount) * 100)
        WITH SYNONYMS = ('recovery rate', 'appeal success percentage'),
    DENIALS.AVERAGE_DAYS_TO_APPEAL as AVG(days_to_appeal)
        WITH SYNONYMS = ('average days to appeal', 'appeal timing'),
    DENIALS.AVERAGE_DAYS_TO_RESOLUTION as AVG(days_to_resolution)
        WITH SYNONYMS = ('average resolution time', 'time to resolve'),
    DENIALS.SUCCESSFUL_APPEALS as COUNT(CASE WHEN appeal_outcome IN ('Approved', 'Partial') THEN 1 END)
        WITH SYNONYMS = ('successful appeals', 'won appeals'),
    DENIALS.APPEAL_SUCCESS_RATE as (COUNT(CASE WHEN appeal_outcome IN ('Approved', 'Partial') THEN 1 END) / COUNT(CASE WHEN days_to_appeal IS NOT NULL THEN 1 END) * 100)
        WITH SYNONYMS = ('appeal success rate', 'win rate for appeals')
);

-- Show semantic views creation completion
SHOW SEMANTIC VIEWS;

SELECT 'RCM Semantic Views Setup Complete - Part 2 of 4' as status;
