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
    CLAIMS as CLAIMS_FACT primary key (CLAIM_ID) 
        with synonyms=('claims','claim submissions','billing','medical claims') 
        comment='Core claims processing data for revenue cycle management',
    
    PROVIDERS as HEALTHCARE_PROVIDERS_DIM primary key (PROVIDER_KEY) 
        with synonyms=('healthcare providers','hospitals','clinics','practices','clients') 
        comment='Healthcare provider clients served by RCM company',
    
    PAYERS as PAYERS_DIM primary key (PAYER_KEY) 
        with synonyms=('insurance companies','payers','insurers','health plans') 
        comment='Insurance companies and government payers',
    
    PROCEDURES as PROCEDURES_DIM primary key (PROCEDURE_KEY) 
        with synonyms=('medical procedures','CPT codes','services','treatments') 
        comment='Medical procedures and services billed',
    
    SPECIALTIES as PROVIDER_SPECIALTIES_DIM primary key (SPECIALTY_KEY) 
        with synonyms=('medical specialties','departments','service lines') 
        comment='Medical specialties and service lines',
    
    REGIONS as GEOGRAPHIC_REGIONS_DIM primary key (REGION_KEY) 
        with synonyms=('geographic regions','markets','service areas') 
        comment='Geographic regions and markets served',
    
    EMPLOYEES as RCM_EMPLOYEES_DIM primary key (EMPLOYEE_KEY) 
        with synonyms=('RCM staff','analysts','processors','employees') 
        comment='Revenue cycle management staff and analysts'
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
    CLAIMS.CHARGE_AMOUNT as charge_amount comment='Original charge amount billed',
    CLAIMS.ALLOWED_AMOUNT as allowed_amount comment='Insurance allowed amount',
    CLAIMS.PAID_AMOUNT as paid_amount comment='Amount actually paid by payer',
    CLAIMS.PATIENT_RESPONSIBILITY as patient_responsibility comment='Patient copay, deductible, and coinsurance',
    CLAIMS.DAYS_TO_PAYMENT as days_to_payment comment='Days from submission to payment',
    CLAIMS.CLAIM_RECORD as 1 comment='Count of claims for volume metrics'
)
dimensions (
    -- Claim attributes
    CLAIMS.SUBMISSION_DATE as submission_date with synonyms=('submission date','claim date','billing date') comment='Date claim was submitted to payer',
    CLAIMS.SERVICE_DATE as service_date with synonyms=('service date','date of service','DOS') comment='Date medical service was provided',
    CLAIMS.CLAIM_STATUS as claim_status with synonyms=('status','claim state') comment='Current status of claim (Submitted, Paid, Denied, Appealed)',
    CLAIMS.PAYMENT_STATUS as payment_status with synonyms=('payment status','payment state') comment='Payment status (Pending, Partial, Full, Denied)',
    CLAIMS.CLEAN_CLAIM_FLAG as clean_claim with synonyms=('clean claim','first pass') comment='Whether claim was processed cleanly on first submission',
    CLAIMS.DENIAL_FLAG as denied with synonyms=('denial','denied claim') comment='Whether claim was denied',
    CLAIMS.APPEAL_FLAG as appealed with synonyms=('appeal','appealed claim') comment='Whether claim was appealed',
    
    -- Time dimensions
    CLAIMS.SUBMISSION_MONTH as MONTH(CLAIMS.SUBMISSION_DATE) comment='Month claim was submitted',
    CLAIMS.SUBMISSION_YEAR as YEAR(CLAIMS.SUBMISSION_DATE) comment='Year claim was submitted',
    CLAIMS.SUBMISSION_QUARTER as QUARTER(CLAIMS.SUBMISSION_DATE) comment='Quarter claim was submitted',
    
    -- Provider information
    PROVIDERS.PROVIDER_NAME as provider_name with synonyms=('provider','hospital','clinic','practice') comment='Name of healthcare provider',
    PROVIDERS.PROVIDER_TYPE as provider_type with synonyms=('type','facility type') comment='Type of healthcare facility (Hospital, Clinic, Practice, Surgery Center)',
    PROVIDERS.SPECIALTY as provider_specialty with synonyms=('specialty','primary specialty') comment='Primary specialty of provider',
    PROVIDERS.ANNUAL_REVENUE as provider_revenue with synonyms=('revenue','annual revenue') comment='Annual revenue of healthcare provider',
    
    -- Payer information
    PAYERS.PAYER_NAME as payer_name with synonyms=('payer','insurance','insurer') comment='Name of insurance company or payer',
    PAYERS.PAYER_TYPE as payer_type with synonyms=('insurance type','payer category') comment='Type of payer (Commercial, Government, Self-Pay)',
    PAYERS.MARKET_SHARE as payer_market_share comment='Regional market share percentage of payer',
    PAYERS.AVG_DAYS_TO_PAY as payer_avg_days comment='Average days payer takes to pay claims',
    
    -- Procedure information
    PROCEDURES.CPT_CODE as cpt_code with synonyms=('CPT','procedure code') comment='CPT procedure code',
    PROCEDURES.PROCEDURE_NAME as procedure_name with synonyms=('procedure','service','treatment') comment='Name of medical procedure or service',
    PROCEDURES.CATEGORY as procedure_category with synonyms=('category','procedure type') comment='Category of procedure (Surgery, Radiology, Medicine, etc.)',
    PROCEDURES.STANDARD_CHARGE as procedure_charge comment='Standard charge for procedure',
    
    -- Specialty information
    SPECIALTIES.SPECIALTY_NAME as specialty_name with synonyms=('specialty','service line','department') comment='Medical specialty name',
    SPECIALTIES.SPECIALTY_TYPE as specialty_type comment='Type of specialty (Primary Care, Specialty, Sub-Specialty)',
    
    -- Geographic information
    REGIONS.REGION_NAME as region_name with synonyms=('region','market','area') comment='Geographic region name',
    REGIONS.STATE as state comment='State abbreviation',
    
    -- Employee information
    EMPLOYEES.DEPARTMENT as employee_department with synonyms=('department','team') comment='RCM department (Claims Processing, Denials, Collections)',
    EMPLOYEES.ROLE as employee_role with synonyms=('role','position','title') comment='Employee job role'
)
metrics (
    -- Volume metrics
    CLAIMS.TOTAL_CLAIMS as COUNT(claims.claim_record) comment='Total number of claims',
    CLAIMS.CLEAN_CLAIMS as COUNT(CASE WHEN claims.clean_claim_flag THEN claims.claim_record END) comment='Number of clean claims',
    CLAIMS.DENIED_CLAIMS as COUNT(CASE WHEN claims.denial_flag THEN claims.claim_record END) comment='Number of denied claims',
    CLAIMS.APPEALED_CLAIMS as COUNT(CASE WHEN claims.appeal_flag THEN claims.claim_record END) comment='Number of appealed claims',
    
    -- Financial metrics
    CLAIMS.TOTAL_CHARGES as SUM(claims.charge_amount) comment='Total charge amounts',
    CLAIMS.TOTAL_ALLOWED as SUM(claims.allowed_amount) comment='Total allowed amounts',
    CLAIMS.TOTAL_PAID as SUM(claims.paid_amount) comment='Total paid amounts',
    CLAIMS.TOTAL_PATIENT_RESPONSIBILITY as SUM(claims.patient_responsibility) comment='Total patient responsibility',
    
    -- Performance metrics
    CLAIMS.CLEAN_CLAIM_RATE as (COUNT(CASE WHEN claims.clean_claim_flag THEN claims.claim_record END) / COUNT(claims.claim_record) * 100) comment='Clean claim rate percentage',
    CLAIMS.DENIAL_RATE as (COUNT(CASE WHEN claims.denial_flag THEN claims.claim_record END) / COUNT(claims.claim_record) * 100) comment='Denial rate percentage',
    CLAIMS.NET_COLLECTION_RATE as (SUM(claims.paid_amount) / SUM(claims.charge_amount) * 100) comment='Net collection rate percentage',
    CLAIMS.AVERAGE_DAYS_TO_PAYMENT as AVG(claims.days_to_payment) comment='Average days from submission to payment',
    CLAIMS.MEDIAN_DAYS_TO_PAYMENT as MEDIAN(claims.days_to_payment) comment='Median days from submission to payment',
    
    -- Reimbursement metrics
    CLAIMS.AVERAGE_CHARGE as AVG(claims.charge_amount) comment='Average charge amount per claim',
    CLAIMS.AVERAGE_ALLOWED as AVG(claims.allowed_amount) comment='Average allowed amount per claim',
    CLAIMS.AVERAGE_PAID as AVG(claims.paid_amount) comment='Average paid amount per claim',
    CLAIMS.CONTRACTUAL_ADJUSTMENT_RATE as ((SUM(claims.charge_amount) - SUM(claims.allowed_amount)) / SUM(claims.charge_amount) * 100) comment='Contractual adjustment rate percentage'
)
comment='Comprehensive view for healthcare claims processing and revenue cycle analysis'
with extension (CA='{"tables":[{"name":"CLAIMS","dimensions":[{"name":"SUBMISSION_DATE","sample_values":["2024-01-15","2024-02-20","2024-03-10"]},{"name":"CLAIM_STATUS","sample_values":["Paid","Denied","Appealed","Pending"]},{"name":"PAYMENT_STATUS","sample_values":["Full","Partial","Denied","Pending"]},{"name":"CLEAN_CLAIM_FLAG","sample_values":["true","false"]}],"facts":[{"name":"CHARGE_AMOUNT"},{"name":"PAID_AMOUNT"},{"name":"DAYS_TO_PAYMENT"}],"metrics":[{"name":"TOTAL_CLAIMS"},{"name":"CLEAN_CLAIM_RATE"},{"name":"DENIAL_RATE"},{"name":"NET_COLLECTION_RATE"}]},{"name":"PROVIDERS","dimensions":[{"name":"PROVIDER_NAME","sample_values":["Ann & Robert H. Lurie Children''s Hospital","Northwestern Memorial Hospital","Rush University Medical Center"]},{"name":"PROVIDER_TYPE","sample_values":["Children''s Hospital","Academic Medical Center","Specialty Practice"]},{"name":"SPECIALTY","sample_values":["Pediatrics","Multi-Specialty","Orthopedics"]}]},{"name":"PAYERS","dimensions":[{"name":"PAYER_NAME","sample_values":["Blue Cross Blue Shield of Illinois","UnitedHealthcare","Medicare","Medicaid (Illinois)"]},{"name":"PAYER_TYPE","sample_values":["Commercial","Government","Self-Pay"]}]}],"relationships":[{"name":"CLAIMS_TO_PROVIDERS","relationship_type":"many_to_one"},{"name":"CLAIMS_TO_PAYERS","relationship_type":"many_to_one"}],"verified_queries":[{"name":"Clean claim rate by provider","question":"What is the clean claim rate for each healthcare provider?","sql":"SELECT\\n  p.provider_name,\\n  COUNT(c.claim_id) AS total_claims,\\n  COUNT(CASE WHEN c.clean_claim_flag THEN 1 END) AS clean_claims,\\n  (COUNT(CASE WHEN c.clean_claim_flag THEN 1 END) / COUNT(c.claim_id) * 100) AS clean_claim_rate\\nFROM\\n  claims AS c\\n  JOIN providers AS p ON c.provider_key = p.provider_key\\nGROUP BY\\n  p.provider_name\\nORDER BY\\n  clean_claim_rate DESC","use_as_onboarding_question":true,"verified_by":"System","verified_at":1704067200},{"name":"Denial rates by payer","question":"Which payers have the highest denial rates?","sql":"SELECT\\n  py.payer_name,\\n  COUNT(c.claim_id) AS total_claims,\\n  COUNT(CASE WHEN c.denial_flag THEN 1 END) AS denied_claims,\\n  (COUNT(CASE WHEN c.denial_flag THEN 1 END) / COUNT(c.claim_id) * 100) AS denial_rate\\nFROM\\n  claims AS c\\n  JOIN payers AS py ON c.payer_key = py.payer_key\\nGROUP BY\\n  py.payer_name\\nORDER BY\\n  denial_rate DESC","use_as_onboarding_question":false,"verified_by":"System","verified_at":1704067200}]}');

-- ========================================================================
-- DENIALS MANAGEMENT SEMANTIC VIEW
-- ========================================================================

CREATE OR REPLACE SEMANTIC VIEW RCM_AI_DEMO.RCM_SCHEMA.DENIALS_MANAGEMENT_VIEW
tables (
    DENIALS as DENIALS_FACT primary key (DENIAL_ID) 
        with synonyms=('denials','denied claims','claim denials','appeals') 
        comment='Denied claims and appeals management data',
    
    CLAIMS as CLAIMS_FACT primary key (CLAIM_ID) 
        with synonyms=('original claims','base claims') 
        comment='Original claims that were denied',
    
    PROVIDERS as HEALTHCARE_PROVIDERS_DIM primary key (PROVIDER_KEY) 
        with synonyms=('healthcare providers','hospitals','clinics','practices') 
        comment='Healthcare providers with denied claims',
    
    PAYERS as PAYERS_DIM primary key (PAYER_KEY) 
        with synonyms=('insurance companies','payers','insurers') 
        comment='Payers who denied claims',
    
    DENIAL_REASONS as DENIAL_REASONS_DIM primary key (DENIAL_REASON_KEY) 
        with synonyms=('denial codes','denial reasons','reason codes') 
        comment='Standard denial reason codes and descriptions',
    
    APPEALS as APPEALS_DIM primary key (APPEAL_KEY) 
        with synonyms=('appeal types','appeal levels') 
        comment='Types and levels of appeals processes',
    
    EMPLOYEES as RCM_EMPLOYEES_DIM primary key (EMPLOYEE_KEY) 
        with synonyms=('denial analysts','appeals specialists','RCM staff') 
        comment='RCM staff handling denials and appeals'
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
    DENIALS.DENIED_AMOUNT as denied_amount comment='Amount denied by payer',
    DENIALS.RECOVERED_AMOUNT as recovered_amount comment='Amount recovered through appeals',
    DENIALS.DAYS_TO_APPEAL as days_to_appeal comment='Days from denial to appeal submission',
    DENIALS.DAYS_TO_RESOLUTION as days_to_resolution comment='Days from denial to final resolution',
    DENIALS.DENIAL_RECORD as 1 comment='Count of denials for volume metrics'
)
dimensions (
    -- Denial timing
    DENIALS.DENIAL_DATE as denial_date with synonyms=('denial date','date denied') comment='Date claim was denied',
    DENIALS.APPEAL_DATE as appeal_date with synonyms=('appeal date','date appealed') comment='Date appeal was submitted',
    DENIALS.RESOLUTION_DATE as resolution_date with synonyms=('resolution date','final date') comment='Date denial was finally resolved',
    
    -- Time dimensions
    DENIALS.DENIAL_MONTH as MONTH(DENIALS.DENIAL_DATE) comment='Month claim was denied',
    DENIALS.DENIAL_YEAR as YEAR(DENIALS.DENIAL_DATE) comment='Year claim was denied',
    DENIALS.DENIAL_QUARTER as QUARTER(DENIALS.DENIAL_DATE) comment='Quarter claim was denied',
    
    -- Status and outcomes
    DENIALS.DENIAL_STATUS as denial_status with synonyms=('status','denial state') comment='Current status of denial (Open, Under Review, Resolved)',
    DENIALS.APPEAL_OUTCOME as appeal_outcome with synonyms=('outcome','appeal result','result') comment='Final outcome of appeal (Approved, Denied, Partial)',
    
    -- Provider information
    PROVIDERS.PROVIDER_NAME as provider_name with synonyms=('provider','hospital','clinic') comment='Name of healthcare provider',
    PROVIDERS.PROVIDER_TYPE as provider_type comment='Type of healthcare facility',
    PROVIDERS.SPECIALTY as provider_specialty comment='Primary specialty of provider',
    
    -- Payer information
    PAYERS.PAYER_NAME as payer_name with synonyms=('payer','insurance','insurer') comment='Name of payer who denied claim',
    PAYERS.PAYER_TYPE as payer_type comment='Type of payer (Commercial, Government, Self-Pay)',
    
    -- Denial reason details
    DENIAL_REASONS.DENIAL_CODE as denial_code with synonyms=('code','reason code') comment='Standard denial reason code',
    DENIAL_REASONS.DENIAL_DESCRIPTION as denial_description with synonyms=('description','reason','denial reason') comment='Description of denial reason',
    DENIAL_REASONS.CATEGORY as denial_category with synonyms=('category','type') comment='Category of denial (Administrative, Clinical, Coverage)',
    DENIAL_REASONS.APPEALABLE as appealable with synonyms=('can appeal','appealable') comment='Whether denial reason is appealable',
    DENIAL_REASONS.SUCCESS_RATE as historical_success_rate comment='Historical appeal success rate for this denial reason',
    
    -- Appeal information
    APPEALS.APPEAL_TYPE as appeal_type with synonyms=('appeal level','level') comment='Type/level of appeal (First Level, Second Level, External)',
    APPEALS.APPEAL_STATUS as appeal_status comment='Status of appeal process',
    
    -- Employee information
    EMPLOYEES.DEPARTMENT as employee_department comment='RCM department handling denial',
    EMPLOYEES.ROLE as employee_role comment='Role of employee handling denial'
)
metrics (
    -- Volume metrics
    DENIALS.TOTAL_DENIALS as COUNT(denials.denial_record) comment='Total number of denials',
    DENIALS.APPEALED_DENIALS as COUNT(CASE WHEN denials.appeal_date IS NOT NULL THEN denials.denial_record END) comment='Number of denials that were appealed',
    DENIALS.RESOLVED_DENIALS as COUNT(CASE WHEN denials.resolution_date IS NOT NULL THEN denials.denial_record END) comment='Number of resolved denials',
    
    -- Financial metrics
    DENIALS.TOTAL_DENIED_AMOUNT as SUM(denials.denied_amount) comment='Total amount denied',
    DENIALS.TOTAL_RECOVERED_AMOUNT as SUM(denials.recovered_amount) comment='Total amount recovered through appeals',
    DENIALS.AVERAGE_DENIED_AMOUNT as AVG(denials.denied_amount) comment='Average amount per denial',
    
    -- Performance metrics
    DENIALS.APPEAL_RATE as (COUNT(CASE WHEN denials.appeal_date IS NOT NULL THEN denials.denial_record END) / COUNT(denials.denial_record) * 100) comment='Percentage of denials that are appealed',
    DENIALS.RECOVERY_RATE as (SUM(denials.recovered_amount) / SUM(denials.denied_amount) * 100) comment='Percentage of denied amount recovered',
    DENIALS.AVERAGE_DAYS_TO_APPEAL as AVG(denials.days_to_appeal) comment='Average days from denial to appeal',
    DENIALS.AVERAGE_DAYS_TO_RESOLUTION as AVG(denials.days_to_resolution) comment='Average days from denial to resolution',
    
    -- Success metrics
    DENIALS.SUCCESSFUL_APPEALS as COUNT(CASE WHEN denials.appeal_outcome IN ('Approved', 'Partial') THEN denials.denial_record END) comment='Number of successful appeals',
    DENIALS.APPEAL_SUCCESS_RATE as (COUNT(CASE WHEN denials.appeal_outcome IN ('Approved', 'Partial') THEN denials.denial_record END) / COUNT(CASE WHEN denials.appeal_date IS NOT NULL THEN denials.denial_record END) * 100) comment='Percentage of appeals that are successful'
)
comment='Comprehensive view for denials management and appeals analysis'
with extension (CA='{"tables":[{"name":"DENIALS","dimensions":[{"name":"DENIAL_DATE","sample_values":["2024-01-15","2024-02-20","2024-03-10"]},{"name":"DENIAL_STATUS","sample_values":["Open","Under Review","Resolved"]},{"name":"APPEAL_OUTCOME","sample_values":["Approved","Denied","Partial"]}],"facts":[{"name":"DENIED_AMOUNT"},{"name":"RECOVERED_AMOUNT"},{"name":"DAYS_TO_APPEAL"}],"metrics":[{"name":"TOTAL_DENIALS"},{"name":"APPEAL_RATE"},{"name":"RECOVERY_RATE"}]},{"name":"DENIAL_REASONS","dimensions":[{"name":"DENIAL_CODE","sample_values":["CO-16","CO-11","CO-50","CO-18"]},{"name":"DENIAL_DESCRIPTION","sample_values":["Claim lacks information","Diagnosis inconsistent","Not medically necessary","Duplicate claim"]},{"name":"CATEGORY","sample_values":["Administrative","Clinical","Coverage"]}]}],"verified_queries":[{"name":"Top denial reasons","question":"What are the most common denial reasons and their financial impact?","sql":"SELECT\\n  dr.denial_code,\\n  dr.denial_description,\\n  COUNT(d.denial_id) AS denial_count,\\n  SUM(d.denied_amount) AS total_denied_amount\\nFROM\\n  denials AS d\\n  JOIN denial_reasons AS dr ON d.denial_reason_key = dr.denial_reason_key\\nGROUP BY\\n  dr.denial_code, dr.denial_description\\nORDER BY\\n  denial_count DESC","use_as_onboarding_question":true,"verified_by":"System","verified_at":1704067200}]}');

-- Show semantic views creation completion
SHOW SEMANTIC VIEWS;

SELECT 'RCM Semantic Views Setup Complete - Part 2 of 4' as status;
