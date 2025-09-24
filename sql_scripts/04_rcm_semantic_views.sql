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
    CLAIMS_FACT as CLAIMS_FACT primary key (CLAIM_ID) 
        with synonyms=('claims','claim submissions','billing','medical claims') 
        comment='Core claims processing data for revenue cycle management',
    
    HEALTHCARE_PROVIDERS_DIM as HEALTHCARE_PROVIDERS_DIM primary key (PROVIDER_KEY) 
        with synonyms=('healthcare providers','hospitals','clinics','practices','clients') 
        comment='Healthcare provider clients served by RCM company',
    
    PAYERS_DIM as PAYERS_DIM primary key (PAYER_KEY) 
        with synonyms=('insurance companies','payers','insurers','health plans') 
        comment='Insurance companies and government payers',
    
    PROCEDURES_DIM as PROCEDURES_DIM primary key (PROCEDURE_KEY) 
        with synonyms=('medical procedures','CPT codes','services','treatments') 
        comment='Medical procedures and services billed',
    
    PROVIDER_SPECIALTIES_DIM as PROVIDER_SPECIALTIES_DIM primary key (SPECIALTY_KEY) 
        with synonyms=('medical specialties','departments','service lines') 
        comment='Medical specialties and service lines',
    
    GEOGRAPHIC_REGIONS_DIM as GEOGRAPHIC_REGIONS_DIM primary key (REGION_KEY) 
        with synonyms=('geographic regions','markets','service areas') 
        comment='Geographic regions and markets served',
    
    RCM_EMPLOYEES_DIM as RCM_EMPLOYEES_DIM primary key (EMPLOYEE_KEY) 
        with synonyms=('RCM staff','analysts','processors','employees') 
        comment='Revenue cycle management staff and analysts'
)
relationships (
    CLAIMS_TO_PROVIDERS: CLAIMS_FACT(PROVIDER_KEY) references HEALTHCARE_PROVIDERS_DIM(PROVIDER_KEY),
    CLAIMS_TO_PAYERS: CLAIMS_FACT(PAYER_KEY) references PAYERS_DIM(PAYER_KEY),
    CLAIMS_TO_PROCEDURES: CLAIMS_FACT(PROCEDURE_KEY) references PROCEDURES_DIM(PROCEDURE_KEY),
    CLAIMS_TO_SPECIALTIES: CLAIMS_FACT(SPECIALTY_KEY) references PROVIDER_SPECIALTIES_DIM(SPECIALTY_KEY),
    CLAIMS_TO_REGIONS: CLAIMS_FACT(REGION_KEY) references GEOGRAPHIC_REGIONS_DIM(REGION_KEY),
    CLAIMS_TO_EMPLOYEES: CLAIMS_FACT(EMPLOYEE_KEY) references RCM_EMPLOYEES_DIM(EMPLOYEE_KEY)
)
facts (
    CLAIMS_FACT.CHARGE_AMOUNT as charge_amount comment='Original charge amount billed',
    CLAIMS_FACT.ALLOWED_AMOUNT as allowed_amount comment='Insurance allowed amount',
    CLAIMS_FACT.PAID_AMOUNT as paid_amount comment='Amount actually paid by payer',
    CLAIMS_FACT.PATIENT_RESPONSIBILITY as patient_responsibility comment='Patient copay, deductible, and coinsurance',
    CLAIMS_FACT.DAYS_TO_PAYMENT as days_to_payment comment='Days from submission to payment'
)
dimensions (
    -- Claim attributes
    CLAIMS_FACT.SUBMISSION_DATE as submission_date with synonyms=('submission date','claim date','billing date') comment='Date claim was submitted to payer',
    CLAIMS_FACT.SERVICE_DATE as service_date with synonyms=('service date','date of service','DOS') comment='Date medical service was provided',
    CLAIMS_FACT.CLAIM_STATUS as claim_status with synonyms=('status','claim state') comment='Current status of claim (Submitted, Paid, Denied, Appealed)',
    CLAIMS_FACT.PAYMENT_STATUS as payment_status with synonyms=('payment status','payment state') comment='Payment status (Pending, Partial, Full, Denied)',
    CLAIMS_FACT.CLEAN_CLAIM_FLAG as clean_claim with synonyms=('clean claim','first pass') comment='Whether claim was processed cleanly on first submission',
    CLAIMS_FACT.DENIAL_FLAG as denied with synonyms=('denial','denied claim') comment='Whether claim was denied',
    CLAIMS_FACT.APPEAL_FLAG as appealed with synonyms=('appeal','appealed claim') comment='Whether claim was appealed',
    
    -- Time dimensions
    MONTH(CLAIMS_FACT.SUBMISSION_DATE) as submission_month comment='Month claim was submitted',
    YEAR(CLAIMS_FACT.SUBMISSION_DATE) as submission_year comment='Year claim was submitted',
    QUARTER(CLAIMS_FACT.SUBMISSION_DATE) as submission_quarter comment='Quarter claim was submitted',
    
    -- Provider information
    HEALTHCARE_PROVIDERS_DIM.PROVIDER_NAME as provider_name with synonyms=('provider','hospital','clinic','practice') comment='Name of healthcare provider',
    HEALTHCARE_PROVIDERS_DIM.PROVIDER_TYPE as provider_type with synonyms=('type','facility type') comment='Type of healthcare facility (Hospital, Clinic, Practice, Surgery Center)',
    HEALTHCARE_PROVIDERS_DIM.SPECIALTY as provider_specialty with synonyms=('specialty','primary specialty') comment='Primary specialty of provider',
    HEALTHCARE_PROVIDERS_DIM.ANNUAL_REVENUE as provider_revenue with synonyms=('revenue','annual revenue') comment='Annual revenue of healthcare provider',
    
    -- Payer information
    PAYERS_DIM.PAYER_NAME as payer_name with synonyms=('payer','insurance','insurer') comment='Name of insurance company or payer',
    PAYERS_DIM.PAYER_TYPE as payer_type with synonyms=('insurance type','payer category') comment='Type of payer (Commercial, Government, Self-Pay)',
    PAYERS_DIM.MARKET_SHARE as payer_market_share comment='Regional market share percentage of payer',
    PAYERS_DIM.AVG_DAYS_TO_PAY as payer_avg_days comment='Average days payer takes to pay claims',
    
    -- Procedure information
    PROCEDURES_DIM.CPT_CODE as cpt_code with synonyms=('CPT','procedure code') comment='CPT procedure code',
    PROCEDURES_DIM.PROCEDURE_NAME as procedure_name with synonyms=('procedure','service','treatment') comment='Name of medical procedure or service',
    PROCEDURES_DIM.CATEGORY as procedure_category with synonyms=('category','procedure type') comment='Category of procedure (Surgery, Radiology, Medicine, etc.)',
    PROCEDURES_DIM.RELATIVE_VALUE_UNITS as procedure_charge comment='Relative value units for procedure',
    
    -- Specialty information
    PROVIDER_SPECIALTIES_DIM.SPECIALTY_NAME as specialty_name with synonyms=('specialty','service line','department') comment='Medical specialty name',
    PROVIDER_SPECIALTIES_DIM.DESCRIPTION as specialty_description comment='Description of medical specialty',
    
    -- Geographic information
    GEOGRAPHIC_REGIONS_DIM.REGION_NAME as region_name with synonyms=('region','market','area') comment='Geographic region name',
    GEOGRAPHIC_REGIONS_DIM.STATE_LIST as state comment='States in region',
    
    -- Employee information
    RCM_EMPLOYEES_DIM.DEPARTMENT as employee_department with synonyms=('department','team') comment='RCM department (Claims Processing, Denials, Collections)',
    RCM_EMPLOYEES_DIM.ROLE as employee_role with synonyms=('role','position','title') comment='Employee job role'
)
metrics (
    -- Volume metrics
    total_claims: COUNT(*) comment='Total number of claims',
    clean_claims: COUNT(CASE WHEN CLAIMS_FACT.clean_claim_flag THEN 1 END) comment='Number of clean claims',
    denied_claims: COUNT(CASE WHEN CLAIMS_FACT.denial_flag THEN 1 END) comment='Number of denied claims',
    appealed_claims: COUNT(CASE WHEN CLAIMS_FACT.appeal_flag THEN 1 END) comment='Number of appealed claims',
    
    -- Financial metrics
    total_charges: SUM(CLAIMS_FACT.charge_amount) comment='Total charge amounts',
    total_allowed: SUM(CLAIMS_FACT.allowed_amount) comment='Total allowed amounts',
    total_paid: SUM(CLAIMS_FACT.paid_amount) comment='Total paid amounts',
    total_patient_responsibility: SUM(CLAIMS_FACT.patient_responsibility) comment='Total patient responsibility',
    
    -- Performance metrics
    clean_claim_rate: (COUNT(CASE WHEN CLAIMS_FACT.clean_claim_flag THEN 1 END) / COUNT(*) * 100) comment='Clean claim rate percentage',
    denial_rate: (COUNT(CASE WHEN CLAIMS_FACT.denial_flag THEN 1 END) / COUNT(*) * 100) comment='Denial rate percentage',
    net_collection_rate: (SUM(CLAIMS_FACT.paid_amount) / SUM(CLAIMS_FACT.charge_amount) * 100) comment='Net collection rate percentage',
    average_days_to_payment: AVG(CLAIMS_FACT.days_to_payment) comment='Average days from submission to payment',
    median_days_to_payment: MEDIAN(CLAIMS_FACT.days_to_payment) comment='Median days from submission to payment',
    
    -- Reimbursement metrics
    average_charge: AVG(CLAIMS_FACT.charge_amount) comment='Average charge amount per claim',
    average_allowed: AVG(CLAIMS_FACT.allowed_amount) comment='Average allowed amount per claim',
    average_paid: AVG(CLAIMS_FACT.paid_amount) comment='Average paid amount per claim',
    contractual_adjustment_rate: ((SUM(CLAIMS_FACT.charge_amount) - SUM(CLAIMS_FACT.allowed_amount)) / SUM(CLAIMS_FACT.charge_amount) * 100) comment='Contractual adjustment rate percentage'
)
comment='Comprehensive view for healthcare claims processing and revenue cycle analysis'
with extension (CA='{"tables":[{"name":"CLAIMS","dimensions":[{"name":"SUBMISSION_DATE","sample_values":["2024-01-15","2024-02-20","2024-03-10"]},{"name":"CLAIM_STATUS","sample_values":["Paid","Denied","Appealed","Pending"]},{"name":"PAYMENT_STATUS","sample_values":["Full","Partial","Denied","Pending"]},{"name":"CLEAN_CLAIM_FLAG","sample_values":["true","false"]}],"facts":[{"name":"CHARGE_AMOUNT"},{"name":"PAID_AMOUNT"},{"name":"DAYS_TO_PAYMENT"}],"metrics":[{"name":"TOTAL_CLAIMS"},{"name":"CLEAN_CLAIM_RATE"},{"name":"DENIAL_RATE"},{"name":"NET_COLLECTION_RATE"}]},{"name":"PROVIDERS","dimensions":[{"name":"PROVIDER_NAME","sample_values":["Ann & Robert H. Lurie Children''s Hospital","Northwestern Memorial Hospital","Rush University Medical Center"]},{"name":"PROVIDER_TYPE","sample_values":["Children''s Hospital","Academic Medical Center","Specialty Practice"]},{"name":"SPECIALTY","sample_values":["Pediatrics","Multi-Specialty","Orthopedics"]}]},{"name":"PAYERS","dimensions":[{"name":"PAYER_NAME","sample_values":["Blue Cross Blue Shield of Illinois","UnitedHealthcare","Medicare","Medicaid (Illinois)"]},{"name":"PAYER_TYPE","sample_values":["Commercial","Government","Self-Pay"]}]}],"relationships":[{"name":"CLAIMS_TO_PROVIDERS","relationship_type":"many_to_one"},{"name":"CLAIMS_TO_PAYERS","relationship_type":"many_to_one"}],"verified_queries":[{"name":"Clean claim rate by provider","question":"What is the clean claim rate for each healthcare provider?","sql":"SELECT\\n  p.provider_name,\\n  COUNT(c.claim_id) AS total_claims,\\n  COUNT(CASE WHEN c.clean_claim_flag THEN 1 END) AS clean_claims,\\n  (COUNT(CASE WHEN c.clean_claim_flag THEN 1 END) / COUNT(c.claim_id) * 100) AS clean_claim_rate\\nFROM\\n  claims AS c\\n  JOIN providers AS p ON c.provider_key = p.provider_key\\nGROUP BY\\n  p.provider_name\\nORDER BY\\n  clean_claim_rate DESC","use_as_onboarding_question":true,"verified_by":"System","verified_at":1704067200},{"name":"Denial rates by payer","question":"Which payers have the highest denial rates?","sql":"SELECT\\n  py.payer_name,\\n  COUNT(c.claim_id) AS total_claims,\\n  COUNT(CASE WHEN c.denial_flag THEN 1 END) AS denied_claims,\\n  (COUNT(CASE WHEN c.denial_flag THEN 1 END) / COUNT(c.claim_id) * 100) AS denial_rate\\nFROM\\n  claims AS c\\n  JOIN payers AS py ON c.payer_key = py.payer_key\\nGROUP BY\\n  py.payer_name\\nORDER BY\\n  denial_rate DESC","use_as_onboarding_question":false,"verified_by":"System","verified_at":1704067200}]}');

-- ========================================================================
-- DENIALS MANAGEMENT SEMANTIC VIEW
-- ========================================================================

CREATE OR REPLACE SEMANTIC VIEW RCM_AI_DEMO.RCM_SCHEMA.DENIALS_MANAGEMENT_VIEW
tables (
    DENIALS_FACT as DENIALS_FACT primary key (DENIAL_ID) 
        with synonyms=('denials','denied claims','claim denials','appeals') 
        comment='Denied claims and appeals management data',
    
    CLAIMS_FACT as CLAIMS_FACT primary key (CLAIM_ID) 
        with synonyms=('original claims','base claims') 
        comment='Original claims that were denied',
    
    HEALTHCARE_PROVIDERS_DIM as HEALTHCARE_PROVIDERS_DIM primary key (PROVIDER_KEY) 
        with synonyms=('healthcare providers','hospitals','clinics','practices') 
        comment='Healthcare providers with denied claims',
    
    PAYERS_DIM as PAYERS_DIM primary key (PAYER_KEY) 
        with synonyms=('insurance companies','payers','insurers') 
        comment='Payers who denied claims',
    
    DENIAL_REASONS_DIM as DENIAL_REASONS_DIM primary key (DENIAL_REASON_KEY) 
        with synonyms=('denial codes','denial reasons','reason codes') 
        comment='Standard denial reason codes and descriptions',
    
    APPEALS_DIM as APPEALS_DIM primary key (APPEAL_KEY) 
        with synonyms=('appeal types','appeal levels') 
        comment='Types and levels of appeals processes',
    
    RCM_EMPLOYEES_DIM as RCM_EMPLOYEES_DIM primary key (EMPLOYEE_KEY) 
        with synonyms=('denial analysts','appeals specialists','RCM staff') 
        comment='RCM staff handling denials and appeals'
)
relationships (
    DENIALS_TO_CLAIMS: DENIALS_FACT(CLAIM_ID) references CLAIMS_FACT(CLAIM_ID),
    DENIALS_TO_PROVIDERS: DENIALS_FACT(PROVIDER_KEY) references HEALTHCARE_PROVIDERS_DIM(PROVIDER_KEY),
    DENIALS_TO_PAYERS: DENIALS_FACT(PAYER_KEY) references PAYERS_DIM(PAYER_KEY),
    DENIALS_TO_REASONS: DENIALS_FACT(DENIAL_REASON_KEY) references DENIAL_REASONS_DIM(DENIAL_REASON_KEY),
    DENIALS_TO_APPEALS: DENIALS_FACT(APPEAL_KEY) references APPEALS_DIM(APPEAL_KEY),
    DENIALS_TO_EMPLOYEES: DENIALS_FACT(EMPLOYEE_KEY) references RCM_EMPLOYEES_DIM(EMPLOYEE_KEY)
)
facts (
    DENIALS_FACT.DENIED_AMOUNT as denied_amount comment='Amount denied by payer',
    DENIALS_FACT.RECOVERED_AMOUNT as recovered_amount comment='Amount recovered through appeals',
    DENIALS_FACT.DAYS_TO_APPEAL as days_to_appeal comment='Days from denial to appeal submission',
    DENIALS_FACT.DAYS_TO_RESOLUTION as days_to_resolution comment='Days from denial to final resolution'
)
dimensions (
    -- Denial timing
    DENIALS_FACT.DENIAL_DATE as denial_date with synonyms=('denial date','date denied') comment='Date claim was denied',
    DENIALS_FACT.DAYS_TO_APPEAL as appeal_timing comment='Days from denial to appeal submission',
    DENIALS_FACT.DAYS_TO_RESOLUTION as resolution_timing comment='Days from denial to final resolution',
    
    -- Time dimensions
    MONTH(DENIALS_FACT.DENIAL_DATE) as denial_month comment='Month claim was denied',
    YEAR(DENIALS_FACT.DENIAL_DATE) as denial_year comment='Year claim was denied',
    QUARTER(DENIALS_FACT.DENIAL_DATE) as denial_quarter comment='Quarter claim was denied',
    
    -- Status and outcomes
    DENIALS_FACT.DENIAL_STATUS as denial_status with synonyms=('status','denial state') comment='Current status of denial (Open, Under Review, Resolved)',
    DENIALS_FACT.APPEAL_OUTCOME as appeal_outcome with synonyms=('outcome','appeal result','result') comment='Final outcome of appeal (Approved, Denied, Partial)',
    
    -- Provider information
    HEALTHCARE_PROVIDERS_DIM.PROVIDER_NAME as provider_name with synonyms=('provider','hospital','clinic') comment='Name of healthcare provider',
    HEALTHCARE_PROVIDERS_DIM.PROVIDER_TYPE as provider_type comment='Type of healthcare facility',
    HEALTHCARE_PROVIDERS_DIM.SPECIALTY as provider_specialty comment='Primary specialty of provider',
    
    -- Payer information
    PAYERS_DIM.PAYER_NAME as payer_name with synonyms=('payer','insurance','insurer') comment='Name of payer who denied claim',
    PAYERS_DIM.PAYER_TYPE as payer_type comment='Type of payer (Commercial, Government, Self-Pay)',
    
    -- Denial reason details
    DENIAL_REASONS_DIM.DENIAL_CODE as denial_code with synonyms=('code','reason code') comment='Standard denial reason code',
    DENIAL_REASONS_DIM.DENIAL_DESCRIPTION as denial_description with synonyms=('description','reason','denial reason') comment='Description of denial reason',
    DENIAL_REASONS_DIM.CATEGORY as denial_category with synonyms=('category','type') comment='Category of denial (Administrative, Clinical, Coverage)',
    DENIAL_REASONS_DIM.APPEALABLE as appealable with synonyms=('can appeal','appealable') comment='Whether denial reason is appealable',
    DENIAL_REASONS_DIM.SUCCESS_RATE as historical_success_rate comment='Historical appeal success rate for this denial reason',
    
    -- Appeal information
    APPEALS_DIM.APPEAL_TYPE as appeal_type with synonyms=('appeal level','level') comment='Type/level of appeal (First Level, Second Level, External)',
    APPEALS_DIM.AVG_RESOLUTION_DAYS as appeal_avg_days comment='Average resolution days for this appeal type',
    
    -- Employee information
    RCM_EMPLOYEES_DIM.DEPARTMENT as employee_department comment='RCM department handling denial',
    RCM_EMPLOYEES_DIM.ROLE as employee_role comment='Role of employee handling denial'
)
metrics (
    -- Volume metrics
    total_denials: COUNT(*) comment='Total number of denials',
    appealed_denials: COUNT(CASE WHEN DENIALS_FACT.days_to_appeal IS NOT NULL THEN 1 END) comment='Number of denials that were appealed',
    resolved_denials: COUNT(CASE WHEN DENIALS_FACT.days_to_resolution IS NOT NULL THEN 1 END) comment='Number of resolved denials',
    
    -- Financial metrics
    total_denied_amount: SUM(DENIALS_FACT.denied_amount) comment='Total amount denied',
    total_recovered_amount: SUM(DENIALS_FACT.recovered_amount) comment='Total amount recovered through appeals',
    average_denied_amount: AVG(DENIALS_FACT.denied_amount) comment='Average amount per denial',
    
    -- Performance metrics
    appeal_rate: (COUNT(CASE WHEN DENIALS_FACT.days_to_appeal IS NOT NULL THEN 1 END) / COUNT(*) * 100) comment='Percentage of denials that are appealed',
    recovery_rate: (SUM(DENIALS_FACT.recovered_amount) / SUM(DENIALS_FACT.denied_amount) * 100) comment='Percentage of denied amount recovered',
    average_days_to_appeal: AVG(DENIALS_FACT.days_to_appeal) comment='Average days from denial to appeal',
    average_days_to_resolution: AVG(DENIALS_FACT.days_to_resolution) comment='Average days from denial to resolution',
    
    -- Success metrics
    successful_appeals: COUNT(CASE WHEN DENIALS_FACT.appeal_outcome IN ('Approved', 'Partial') THEN 1 END) comment='Number of successful appeals',
    appeal_success_rate: (COUNT(CASE WHEN DENIALS_FACT.appeal_outcome IN ('Approved', 'Partial') THEN 1 END) / COUNT(CASE WHEN DENIALS_FACT.days_to_appeal IS NOT NULL THEN 1 END) * 100) comment='Percentage of appeals that are successful'
)
comment='Comprehensive view for denials management and appeals analysis'
with extension (CA='{"tables":[{"name":"DENIALS","dimensions":[{"name":"DENIAL_DATE","sample_values":["2024-01-15","2024-02-20","2024-03-10"]},{"name":"DENIAL_STATUS","sample_values":["Open","Under Review","Resolved"]},{"name":"APPEAL_OUTCOME","sample_values":["Approved","Denied","Partial"]}],"facts":[{"name":"DENIED_AMOUNT"},{"name":"RECOVERED_AMOUNT"},{"name":"DAYS_TO_APPEAL"}],"metrics":[{"name":"TOTAL_DENIALS"},{"name":"APPEAL_RATE"},{"name":"RECOVERY_RATE"}]},{"name":"DENIAL_REASONS","dimensions":[{"name":"DENIAL_CODE","sample_values":["CO-16","CO-11","CO-50","CO-18"]},{"name":"DENIAL_DESCRIPTION","sample_values":["Claim lacks information","Diagnosis inconsistent","Not medically necessary","Duplicate claim"]},{"name":"CATEGORY","sample_values":["Administrative","Clinical","Coverage"]}]}],"verified_queries":[{"name":"Top denial reasons","question":"What are the most common denial reasons and their financial impact?","sql":"SELECT\\n  dr.denial_code,\\n  dr.denial_description,\\n  COUNT(d.denial_id) AS denial_count,\\n  SUM(d.denied_amount) AS total_denied_amount\\nFROM\\n  denials AS d\\n  JOIN denial_reasons AS dr ON d.denial_reason_key = dr.denial_reason_key\\nGROUP BY\\n  dr.denial_code, dr.denial_description\\nORDER BY\\n  denial_count DESC","use_as_onboarding_question":true,"verified_by":"System","verified_at":1704067200}]}');

-- Show semantic views creation completion
SHOW SEMANTIC VIEWS;

SELECT 'RCM Semantic Views Setup Complete - Part 2 of 4' as status;
