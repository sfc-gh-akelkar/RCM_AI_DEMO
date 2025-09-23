-- ========================================================================
-- RCM AI Demo - Data Generation Script (Part 1.5 of 4)
-- Populate RCM tables with realistic synthetic data
-- ========================================================================

USE ROLE SF_INTELLIGENCE_DEMO;
USE DATABASE RCM_AI_DEMO;
USE SCHEMA RCM_SCHEMA;

-- Continue inserting dimension data...

-- Insert Diagnosis Codes (ICD-10 Sample)
INSERT INTO diagnosis_dim VALUES
(1, 'I25.10', 'Atherosclerotic Heart Disease', 'Cardiovascular', 'Moderate'),
(2, 'E11.9', 'Type 2 Diabetes Mellitus', 'Endocrine', 'Moderate'),
(3, 'M79.3', 'Panniculitis, Unspecified', 'Musculoskeletal', 'Minor'),
(4, 'J44.1', 'Chronic Obstructive Pulmonary Disease', 'Respiratory', 'Moderate'),
(5, 'N18.6', 'End Stage Renal Disease', 'Genitourinary', 'Major'),
(6, 'F32.9', 'Major Depressive Disorder', 'Mental Health', 'Moderate'),
(7, 'G93.1', 'Anoxic Brain Damage', 'Neurological', 'Extreme'),
(8, 'C78.0', 'Secondary Malignant Neoplasm of Lung', 'Oncology', 'Major'),
(9, 'S72.001A', 'Fracture of Neck of Right Femur', 'Injury', 'Major'),
(10, 'K57.90', 'Diverticulosis of Intestine', 'Digestive', 'Minor'),
(11, 'H25.9', 'Unspecified Age-Related Cataract', 'Ophthalmologic', 'Minor'),
(12, 'M17.11', 'Unilateral Primary Osteoarthritis, Right Knee', 'Musculoskeletal', 'Moderate'),
(13, 'I50.9', 'Heart Failure, Unspecified', 'Cardiovascular', 'Major'),
(14, 'F03.90', 'Unspecified Dementia without Behavioral Disturbance', 'Neurological', 'Major'),
(15, 'Z51.11', 'Encounter for Antineoplastic Chemotherapy', 'Oncology', 'Major'),
(16, 'R06.02', 'Shortness of Breath', 'Respiratory', 'Minor'),
(17, 'M25.551', 'Pain in Right Hip', 'Musculoskeletal', 'Minor'),
(18, 'I10', 'Essential Hypertension', 'Cardiovascular', 'Minor'),
(19, 'N39.0', 'Urinary Tract Infection', 'Genitourinary', 'Minor'),
(20, 'K21.9', 'Gastroesophageal Reflux Disease', 'Digestive', 'Minor');

-- Insert Provider Specialties
INSERT INTO provider_specialties_dim VALUES
(1, 'Internal Medicine', 'Primary Care', 275000),
(2, 'Family Medicine', 'Primary Care', 265000),
(3, 'Pediatrics', 'Primary Care', 285000),
(4, 'Emergency Medicine', 'Specialty', 385000),
(5, 'Cardiology', 'Specialty', 520000),
(6, 'Orthopedic Surgery', 'Specialty', 680000),
(7, 'General Surgery', 'Specialty', 450000),
(8, 'Anesthesiology', 'Specialty', 425000),
(9, 'Radiology', 'Specialty', 485000),
(10, 'Gastroenterology', 'Specialty', 495000),
(11, 'Oncology', 'Specialty', 465000),
(12, 'Neurology', 'Specialty', 385000),
(13, 'Ophthalmology', 'Specialty', 425000),
(14, 'Dermatology', 'Specialty', 475000),
(15, 'Obstetrics & Gynecology', 'Specialty', 365000),
(16, 'Urology', 'Specialty', 485000),
(17, 'Psychiatry', 'Specialty', 285000),
(18, 'Pathology', 'Specialty', 385000),
(19, 'Physical Medicine & Rehabilitation', 'Specialty', 335000),
(20, 'Intensive Care Medicine', 'Sub-Specialty', 385000);

-- Insert RCM Employees
INSERT INTO rcm_employees_dim VALUES
(1, 'Sarah Johnson', 'Claims Processing', 'Senior Claims Analyst', '2019-03-15', 68000, 'Chicago', 4.2),
(2, 'Michael Chen', 'Denials Management', 'Denial Specialist', '2020-07-22', 72000, 'Chicago', 4.5),
(3, 'Jennifer Rodriguez', 'Collections', 'Collections Manager', '2018-11-08', 85000, 'Chicago', 4.1),
(4, 'David Thompson', 'Prior Authorization', 'Authorization Specialist', '2021-02-14', 58000, 'Remote', 3.8),
(5, 'Lisa Wang', 'Claims Processing', 'Claims Analyst', '2020-09-30', 62000, 'Chicago', 4.3),
(6, 'Robert Martinez', 'Denials Management', 'Appeals Coordinator', '2019-12-05', 75000, 'Chicago', 4.4),
(7, 'Amanda Davis', 'Collections', 'Patient Financial Counselor', '2021-06-18', 55000, 'Remote', 4.0),
(8, 'James Wilson', 'Management', 'RCM Director', '2017-04-12', 125000, 'Chicago', 4.6),
(9, 'Michelle Taylor', 'Quality Assurance', 'QA Analyst', '2020-01-20', 65000, 'Chicago', 4.2),
(10, 'Christopher Brown', 'Claims Processing', 'Claims Supervisor', '2018-08-07', 78000, 'Chicago', 4.3),
(11, 'Jessica Garcia', 'Prior Authorization', 'Senior Auth Specialist', '2019-05-25', 68000, 'Remote', 4.1),
(12, 'Matthew Anderson', 'Denials Management', 'Denial Manager', '2017-10-11', 92000, 'Chicago', 4.5),
(13, 'Ashley Miller', 'Collections', 'Collections Specialist', '2021-03-08', 52000, 'Remote', 3.9),
(14, 'Ryan Thomas', 'IT Support', 'Systems Analyst', '2020-12-14', 75000, 'Chicago', 4.2),
(15, 'Nicole Jackson', 'Training', 'Training Coordinator', '2019-08-19', 58000, 'Chicago', 4.0),
(16, 'Daniel White', 'Claims Processing', 'Senior Claims Analyst', '2018-06-03', 71000, 'Chicago', 4.4),
(17, 'Stephanie Harris', 'Collections', 'Financial Counselor', '2020-11-28', 56000, 'Remote', 4.1),
(18, 'Kevin Lewis', 'Denials Management', 'Appeals Specialist', '2021-01-16', 69000, 'Chicago', 4.2),
(19, 'Rachel Clark', 'Quality Assurance', 'Compliance Analyst', '2019-07-09', 67000, 'Chicago', 4.3),
(20, 'Brandon Robinson', 'Management', 'Operations Manager', '2018-02-26', 95000, 'Chicago', 4.4);

-- Insert Patients (De-identified demographics)
INSERT INTO patients_dim 
SELECT 
    ROW_NUMBER() OVER (ORDER BY UNIFORM(1, 1000000, RANDOM())) as patient_key,
    CASE 
        WHEN UNIFORM(1, 100, RANDOM()) <= 15 THEN '0-17'
        WHEN UNIFORM(1, 100, RANDOM()) <= 35 THEN '18-34'
        WHEN UNIFORM(1, 100, RANDOM()) <= 55 THEN '35-54'
        WHEN UNIFORM(1, 100, RANDOM()) <= 75 THEN '55-64'
        ELSE '65+'
    END as age_group,
    CASE WHEN UNIFORM(1, 100, RANDOM()) <= 52 THEN 'Female' ELSE 'Male' END as gender,
    CASE 
        WHEN UNIFORM(1, 100, RANDOM()) <= 45 THEN 'Commercial'
        WHEN UNIFORM(1, 100, RANDOM()) <= 70 THEN 'Medicare'
        WHEN UNIFORM(1, 100, RANDOM()) <= 85 THEN 'Medicaid'
        ELSE 'Self-Pay'
    END as insurance_type,
    CASE 
        WHEN UNIFORM(1, 100, RANDOM()) <= 40 THEN 'Urban Chicago'
        WHEN UNIFORM(1, 100, RANDOM()) <= 65 THEN 'Suburban Chicago'
        WHEN UNIFORM(1, 100, RANDOM()) <= 85 THEN 'Northern Illinois'
        ELSE 'Other Illinois'
    END as geographic_region,
    CASE 
        WHEN UNIFORM(1, 100, RANDOM()) <= 35 THEN 'High'
        WHEN UNIFORM(1, 100, RANDOM()) <= 70 THEN 'Medium'
        ELSE 'Low'
    END as payment_propensity
FROM TABLE(GENERATOR(ROWCOUNT => 5000));

-- Insert Denial Reasons
INSERT INTO denial_reasons_dim VALUES
(1, 'CO-16', 'Claim/service lacks information or has submission/billing error', 'Administrative', TRUE, 78.5),
(2, 'CO-11', 'The diagnosis is inconsistent with the procedure', 'Clinical', TRUE, 65.2),
(3, 'CO-50', 'These are non-covered services because this is not deemed a medical necessity', 'Coverage', TRUE, 42.8),
(4, 'CO-18', 'Duplicate claim/service', 'Administrative', FALSE, 95.1),
(5, 'CO-4', 'The procedure code is inconsistent with the modifier used or a required modifier is missing', 'Administrative', TRUE, 72.3),
(6, 'CO-97', 'The benefit for this service is included in the payment/allowance for another service/procedure', 'Coverage', TRUE, 38.9),
(7, 'CO-151', 'Payment adjusted because the payer deems the information submitted does not support this many/frequency of services', 'Clinical', TRUE, 55.7),
(8, 'CO-119', 'Benefit maximum for this time period or occurrence has been reached', 'Coverage', FALSE, 15.2),
(9, 'PR-1', 'Deductible amount', 'Patient Responsibility', FALSE, 0.0),
(10, 'PR-2', 'Coinsurance amount', 'Patient Responsibility', FALSE, 0.0),
(11, 'CO-167', 'This (these) diagnosis(es) is (are) not covered', 'Coverage', TRUE, 35.4),
(12, 'CO-22', 'This care may be covered by another payer per coordination of benefits', 'Administrative', TRUE, 68.9),
(13, 'CO-45', 'Charge exceeds fee schedule/maximum allowable or contracted/legislated fee arrangement', 'Coverage', FALSE, 12.1),
(14, 'CO-204', 'This service/equipment/drug is not covered under the patient''s current benefit plan', 'Coverage', TRUE, 28.7),
(15, 'CO-B15', 'This service/procedure requires that a qualifying service/procedure be received first', 'Coverage', TRUE, 51.2);

-- Insert Appeals Types
INSERT INTO appeals_dim VALUES
(1, 'First Level', 'Pending', 30),
(2, 'First Level', 'Approved', 30),
(3, 'First Level', 'Denied', 30),
(4, 'Second Level', 'Pending', 60),
(5, 'Second Level', 'Approved', 60),
(6, 'Second Level', 'Denied', 60),
(7, 'External Review', 'Pending', 120),
(8, 'External Review', 'Approved', 120),
(9, 'External Review', 'Denied', 120),
(10, 'Expedited', 'Approved', 3);

-- Insert Geographic Regions
INSERT INTO geographic_regions_dim VALUES
(1, 'Cook County', 'IL', 5150233, 68240, 8.2),
(2, 'DuPage County', 'IL', 932582, 89535, 4.1),
(3, 'Lake County', 'IL', 714342, 78962, 5.8),
(4, 'Will County', 'IL', 690743, 75234, 6.5),
(5, 'Kane County', 'IL', 516522, 72845, 7.2),
(6, 'McHenry County', 'IL', 307774, 79562, 5.9),
(7, 'Winnebago County', 'IL', 285350, 58932, 9.8),
(8, 'Madison County', 'IL', 265668, 62154, 8.1),
(9, 'St. Clair County', 'IL', 257400, 56789, 10.2),
(10, 'Sangamon County', 'IL', 196343, 61234, 7.8);

-- ========================================================================
-- GENERATE FACT TABLE DATA
-- ========================================================================

-- Generate Claims Fact Data (50,000 records)
INSERT INTO claims_fact
SELECT 
    'CLM' || LPAD(ROW_NUMBER() OVER (ORDER BY UNIFORM(1, 1000000, RANDOM()))::VARCHAR, 8, '0') as claim_id,
    UNIFORM(1, 15, RANDOM()) as provider_key,
    UNIFORM(1, 10, RANDOM()) as payer_key,
    UNIFORM(1, 5000, RANDOM()) as patient_key,
    UNIFORM(1, 20, RANDOM()) as procedure_key,
    UNIFORM(1, 20, RANDOM()) as diagnosis_key,
    UNIFORM(1, 20, RANDOM()) as specialty_key,
    UNIFORM(1, 10, RANDOM()) as region_key,
    UNIFORM(1, 20, RANDOM()) as employee_key,
    
    -- Dates
    DATEADD(day, -UNIFORM(1, 730, RANDOM()), CURRENT_DATE()) as submission_date,
    DATEADD(day, -UNIFORM(1, 760, RANDOM()), CURRENT_DATE()) as service_date,
    
    -- Financial metrics with realistic distributions
    UNIFORM(100, 25000, RANDOM()) as charge_amount,
    UNIFORM(80, 20000, RANDOM()) as allowed_amount,
    CASE 
        WHEN UNIFORM(1, 100, RANDOM()) <= 85 THEN UNIFORM(70, 18000, RANDOM())
        ELSE 0  -- 15% denied
    END as paid_amount,
    UNIFORM(10, 2000, RANDOM()) as patient_responsibility,
    
    -- Performance metrics
    CASE 
        WHEN UNIFORM(1, 100, RANDOM()) <= 85 THEN UNIFORM(5, 45, RANDOM())
        ELSE NULL  -- Unpaid claims
    END as days_to_payment,
    CASE WHEN UNIFORM(1, 100, RANDOM()) <= 78 THEN TRUE ELSE FALSE END as clean_claim_flag,
    CASE WHEN UNIFORM(1, 100, RANDOM()) <= 15 THEN TRUE ELSE FALSE END as denial_flag,
    CASE WHEN UNIFORM(1, 100, RANDOM()) <= 8 THEN TRUE ELSE FALSE END as appeal_flag,
    
    -- Status
    CASE 
        WHEN UNIFORM(1, 100, RANDOM()) <= 75 THEN 'Paid'
        WHEN UNIFORM(1, 100, RANDOM()) <= 85 THEN 'Denied'
        WHEN UNIFORM(1, 100, RANDOM()) <= 95 THEN 'Appealed'
        ELSE 'Pending'
    END as claim_status,
    CASE 
        WHEN UNIFORM(1, 100, RANDOM()) <= 70 THEN 'Full'
        WHEN UNIFORM(1, 100, RANDOM()) <= 85 THEN 'Partial'
        WHEN UNIFORM(1, 100, RANDOM()) <= 90 THEN 'Denied'
        ELSE 'Pending'
    END as payment_status
    
FROM TABLE(GENERATOR(ROWCOUNT => 50000));

-- Generate Denials Fact Data (Based on 15% of claims being denied)
INSERT INTO denials_fact
SELECT 
    'DEN' || LPAD(ROW_NUMBER() OVER (ORDER BY UNIFORM(1, 1000000, RANDOM()))::VARCHAR, 8, '0') as denial_id,
    c.claim_id,
    c.provider_key,
    c.payer_key,
    UNIFORM(1, 15, RANDOM()) as denial_reason_key,
    UNIFORM(1, 10, RANDOM()) as appeal_key,
    UNIFORM(1, 20, RANDOM()) as employee_key,
    
    -- Dates
    DATEADD(day, UNIFORM(1, 15, RANDOM()), c.submission_date) as denial_date,
    CASE 
        WHEN UNIFORM(1, 100, RANDOM()) <= 60 THEN DATEADD(day, UNIFORM(5, 30, RANDOM()), c.submission_date)
        ELSE NULL  -- 40% not appealed
    END as appeal_date,
    CASE 
        WHEN UNIFORM(1, 100, RANDOM()) <= 45 THEN DATEADD(day, UNIFORM(15, 90, RANDOM()), c.submission_date)
        ELSE NULL  -- 55% still pending
    END as resolution_date,
    
    -- Financial impact
    c.charge_amount as denied_amount,
    CASE 
        WHEN UNIFORM(1, 100, RANDOM()) <= 45 THEN UNIFORM(0.3, 0.9, RANDOM()) * c.charge_amount
        ELSE 0  -- Some appeals successful
    END as recovered_amount,
    
    -- Performance metrics
    CASE 
        WHEN UNIFORM(1, 100, RANDOM()) <= 60 THEN UNIFORM(1, 25, RANDOM())
        ELSE NULL
    END as days_to_appeal,
    CASE 
        WHEN UNIFORM(1, 100, RANDOM()) <= 45 THEN UNIFORM(15, 85, RANDOM())
        ELSE NULL
    END as days_to_resolution,
    
    -- Status
    CASE 
        WHEN UNIFORM(1, 100, RANDOM()) <= 45 THEN 'Resolved'
        WHEN UNIFORM(1, 100, RANDOM()) <= 65 THEN 'Under Review'
        ELSE 'Open'
    END as denial_status,
    CASE 
        WHEN UNIFORM(1, 100, RANDOM()) <= 25 THEN 'Approved'
        WHEN UNIFORM(1, 100, RANDOM()) <= 35 THEN 'Partial'
        WHEN UNIFORM(1, 100, RANDOM()) <= 50 THEN 'Denied'
        ELSE NULL  -- Not yet resolved
    END as appeal_outcome
    
FROM claims_fact c
WHERE c.denial_flag = TRUE
LIMIT 7500;  -- Approximately 15% of 50,000 claims

-- Show data generation completion
SELECT 
    'Claims' as table_name, COUNT(*) as record_count 
FROM claims_fact
UNION ALL
SELECT 
    'Denials' as table_name, COUNT(*) as record_count 
FROM denials_fact
UNION ALL
SELECT 
    'Healthcare Providers' as table_name, COUNT(*) as record_count 
FROM healthcare_providers_dim
UNION ALL
SELECT 
    'Payers' as table_name, COUNT(*) as record_count 
FROM payers_dim
UNION ALL
SELECT 
    'Procedures' as table_name, COUNT(*) as record_count 
FROM procedures_dim;

SELECT 'RCM Data Generation Complete - Part 1.5 of 4' as status;
