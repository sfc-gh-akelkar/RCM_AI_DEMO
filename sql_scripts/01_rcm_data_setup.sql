-- ========================================================================
-- RCM AI Demo - Data Setup Script (Part 1 of 4)
-- Healthcare Revenue Cycle Management Data Model
-- ========================================================================

-- Switch to accountadmin role to create warehouse and integrations
USE ROLE accountadmin;

-- Enable Snowflake Intelligence by creating the Config DB & Schema
--CREATE DATABASE IF NOT EXISTS snowflake_intelligence;
--CREATE SCHEMA IF NOT EXISTS snowflake_intelligence.agents;

-- Allow anyone to see the agents in this schema
GRANT USAGE ON DATABASE snowflake_intelligence TO ROLE PUBLIC;
GRANT USAGE ON SCHEMA snowflake_intelligence.agents TO ROLE PUBLIC;

-- Create role for RCM demo
--CREATE OR REPLACE ROLE SF_INTELLIGENCE_DEMO;

SET current_user_name = CURRENT_USER();

-- Grant the role to current user
GRANT ROLE SF_INTELLIGENCE_DEMO TO USER IDENTIFIER($current_user_name);
GRANT CREATE DATABASE ON ACCOUNT TO ROLE SF_INTELLIGENCE_DEMO;

-- Create a dedicated warehouse for the demo with auto-suspend/resume
CREATE OR REPLACE WAREHOUSE RCM_INTELLIGENCE_WH 
    WITH WAREHOUSE_SIZE = 'XSMALL'
    AUTO_SUSPEND = 300
    AUTO_RESUME = TRUE;

-- Grant usage on warehouse to demo role
GRANT USAGE ON WAREHOUSE RCM_INTELLIGENCE_WH TO ROLE SF_INTELLIGENCE_DEMO;

-- Set default role and warehouse for current user
ALTER USER IDENTIFIER($current_user_name) SET DEFAULT_ROLE = SF_INTELLIGENCE_DEMO;
ALTER USER IDENTIFIER($current_user_name) SET DEFAULT_WAREHOUSE = RCM_INTELLIGENCE_WH;

-- Note: No git integrations, repositories, or external dependencies created
-- Demo is completely self-contained

-- Switch to SF_INTELLIGENCE_DEMO role to create demo objects
USE ROLE SF_INTELLIGENCE_DEMO;

-- Create database and schema
CREATE OR REPLACE DATABASE RCM_AI_DEMO;
USE DATABASE RCM_AI_DEMO;

CREATE SCHEMA IF NOT EXISTS RCM_SCHEMA;
USE SCHEMA RCM_SCHEMA;

-- Create file format for CSV files
CREATE OR REPLACE FILE FORMAT CSV_FORMAT
    TYPE = 'CSV'
    FIELD_DELIMITER = ','
    RECORD_DELIMITER = '\n'
    SKIP_HEADER = 1
    FIELD_OPTIONALLY_ENCLOSED_BY = '"'
    TRIM_SPACE = TRUE
    ERROR_ON_COLUMN_COUNT_MISMATCH = FALSE
    ESCAPE = 'NONE'
    ESCAPE_UNENCLOSED_FIELD = '\134'
    DATE_FORMAT = 'YYYY-MM-DD'
    TIMESTAMP_FORMAT = 'YYYY-MM-DD HH24:MI:SS'
    NULL_IF = ('NULL', 'null', '', 'N/A', 'n/a');

-- Create internal stage for demo data and documents
CREATE OR REPLACE STAGE RCM_DATA_STAGE
    FILE_FORMAT = CSV_FORMAT
    COMMENT = 'Internal stage for RCM demo data and documents'
    DIRECTORY = ( ENABLE = TRUE)
    ENCRYPTION = (TYPE = 'SNOWFLAKE_SSE');

-- Note: No git repository or data pulling used for this demo
-- All data is generated synthetically and documents are embedded in the setup scripts

-- ========================================================================
-- DIMENSION TABLES - Healthcare Specific
-- ========================================================================

-- Healthcare Providers Dimension (Your RCM Clients)
CREATE OR REPLACE TABLE healthcare_providers_dim (
    provider_key INT PRIMARY KEY,
    provider_name VARCHAR(200) NOT NULL,
    provider_type VARCHAR(50), -- Hospital, Clinic, Practice, Surgery Center
    specialty VARCHAR(100), -- Primary specialty or Multi-Specialty
    beds_licensed INT, -- For hospitals
    annual_revenue DECIMAL(15,2),
    address VARCHAR(200),
    city VARCHAR(100),
    state VARCHAR(10),
    zip VARCHAR(20),
    created_date DATE
);

-- Payers Dimension (Insurance Companies)
CREATE OR REPLACE TABLE payers_dim (
    payer_key INT PRIMARY KEY,
    payer_name VARCHAR(200) NOT NULL,
    payer_type VARCHAR(50), -- Commercial, Government, Self-Pay
    market_share DECIMAL(5,2), -- Regional market share percentage
    avg_days_to_pay DECIMAL(5,1),
    address VARCHAR(200),
    city VARCHAR(100),
    state VARCHAR(10),
    zip VARCHAR(20),
    created_date DATE
);

-- Medical Procedures Dimension (CPT Codes)
CREATE OR REPLACE TABLE procedures_dim (
    procedure_key INT PRIMARY KEY,
    cpt_code VARCHAR(10) NOT NULL,
    procedure_name VARCHAR(300) NOT NULL,
    category VARCHAR(100), -- Surgery, Radiology, Medicine, etc.
    specialty VARCHAR(100), -- Cardiology, Orthopedics, etc.
    relative_value_units DECIMAL(6,2), -- RVU
    standard_charge DECIMAL(10,2)
);

-- Diagnosis Dimension (ICD-10 Codes)
CREATE OR REPLACE TABLE diagnosis_dim (
    diagnosis_key INT PRIMARY KEY,
    icd10_code VARCHAR(10) NOT NULL,
    diagnosis_name VARCHAR(500) NOT NULL,
    category VARCHAR(100),
    severity VARCHAR(20) -- Minor, Moderate, Major, Extreme
);

-- Provider Specialties Dimension
CREATE OR REPLACE TABLE provider_specialties_dim (
    specialty_key INT PRIMARY KEY,
    specialty_name VARCHAR(100) NOT NULL,
    specialty_type VARCHAR(50), -- Primary Care, Specialty, Sub-Specialty
    avg_reimbursement DECIMAL(10,2)
);

-- RCM Employees Dimension
CREATE OR REPLACE TABLE rcm_employees_dim (
    employee_key INT PRIMARY KEY,
    employee_name VARCHAR(200) NOT NULL,
    department VARCHAR(100), -- Claims Processing, Denials, Collections, etc.
    role VARCHAR(100),
    hire_date DATE,
    salary DECIMAL(10,2),
    location VARCHAR(100),
    performance_rating DECIMAL(3,2)
);

-- Patients Dimension (De-identified)
CREATE OR REPLACE TABLE patients_dim (
    patient_key INT PRIMARY KEY,
    age_group VARCHAR(20), -- 0-17, 18-34, 35-54, 55-64, 65+
    gender VARCHAR(10),
    insurance_type VARCHAR(50), -- Commercial, Medicare, Medicaid, Self-Pay
    geographic_region VARCHAR(50),
    payment_propensity VARCHAR(20) -- High, Medium, Low
);

-- Denial Reasons Dimension
CREATE OR REPLACE TABLE denial_reasons_dim (
    denial_reason_key INT PRIMARY KEY,
    denial_code VARCHAR(10) NOT NULL,
    denial_description VARCHAR(500) NOT NULL,
    category VARCHAR(100), -- Administrative, Clinical, Coverage
    appealable BOOLEAN,
    success_rate DECIMAL(5,2) -- Historical appeal success rate
);

-- Appeals Dimension
CREATE OR REPLACE TABLE appeals_dim (
    appeal_key INT PRIMARY KEY,
    appeal_type VARCHAR(50), -- First Level, Second Level, External
    appeal_status VARCHAR(50), -- Pending, Approved, Denied
    filing_deadline_days INT
);

-- Geographic Regions Dimension
CREATE OR REPLACE TABLE geographic_regions_dim (
    region_key INT PRIMARY KEY,
    region_name VARCHAR(100) NOT NULL,
    state VARCHAR(10),
    population BIGINT,
    median_income DECIMAL(10,2),
    uninsured_rate DECIMAL(5,2)
);

-- ========================================================================
-- FACT TABLES - RCM Core Data
-- ========================================================================

-- Claims Fact Table (Core revenue cycle data)
CREATE OR REPLACE TABLE claims_fact (
    claim_id VARCHAR(50) PRIMARY KEY,
    provider_key INT,
    payer_key INT,
    patient_key INT,
    procedure_key INT,
    diagnosis_key INT,
    specialty_key INT,
    region_key INT,
    employee_key INT, -- Processing analyst
    
    submission_date DATE,
    service_date DATE,
    
    -- Financial metrics
    charge_amount DECIMAL(12,2),
    allowed_amount DECIMAL(12,2),
    paid_amount DECIMAL(12,2),
    patient_responsibility DECIMAL(12,2),
    
    -- Performance metrics
    days_to_payment INT,
    clean_claim_flag BOOLEAN,
    denial_flag BOOLEAN,
    appeal_flag BOOLEAN,
    
    -- Status
    claim_status VARCHAR(50), -- Submitted, Paid, Denied, Appealed
    payment_status VARCHAR(50), -- Pending, Partial, Full, Denied
    
    FOREIGN KEY (provider_key) REFERENCES healthcare_providers_dim(provider_key),
    FOREIGN KEY (payer_key) REFERENCES payers_dim(payer_key),
    FOREIGN KEY (patient_key) REFERENCES patients_dim(patient_key),
    FOREIGN KEY (procedure_key) REFERENCES procedures_dim(procedure_key),
    FOREIGN KEY (diagnosis_key) REFERENCES diagnosis_dim(diagnosis_key),
    FOREIGN KEY (specialty_key) REFERENCES provider_specialties_dim(specialty_key),
    FOREIGN KEY (region_key) REFERENCES geographic_regions_dim(region_key),
    FOREIGN KEY (employee_key) REFERENCES rcm_employees_dim(employee_key)
);

-- Denials Fact Table
CREATE OR REPLACE TABLE denials_fact (
    denial_id VARCHAR(50) PRIMARY KEY,
    claim_id VARCHAR(50),
    provider_key INT,
    payer_key INT,
    denial_reason_key INT,
    appeal_key INT,
    employee_key INT, -- Denial analyst
    
    denial_date DATE,
    appeal_date DATE,
    resolution_date DATE,
    
    -- Financial impact
    denied_amount DECIMAL(12,2),
    recovered_amount DECIMAL(12,2),
    
    -- Performance metrics
    days_to_appeal INT,
    days_to_resolution INT,
    
    -- Status
    denial_status VARCHAR(50),
    appeal_outcome VARCHAR(50), -- Approved, Denied, Partial
    
    FOREIGN KEY (claim_id) REFERENCES claims_fact(claim_id),
    FOREIGN KEY (provider_key) REFERENCES healthcare_providers_dim(provider_key),
    FOREIGN KEY (payer_key) REFERENCES payers_dim(payer_key),
    FOREIGN KEY (denial_reason_key) REFERENCES denial_reasons_dim(denial_reason_key),
    FOREIGN KEY (appeal_key) REFERENCES appeals_dim(appeal_key),
    FOREIGN KEY (employee_key) REFERENCES rcm_employees_dim(employee_key)
);

-- Payments Fact Table
CREATE OR REPLACE TABLE payments_fact (
    payment_id VARCHAR(50) PRIMARY KEY,
    claim_id VARCHAR(50),
    provider_key INT,
    payer_key INT,
    patient_key INT,
    employee_key INT, -- Collections analyst
    
    payment_date DATE,
    posting_date DATE,
    
    -- Payment details
    payment_amount DECIMAL(12,2),
    payment_method VARCHAR(50), -- EFT, Check, Credit Card, Cash
    payment_type VARCHAR(50), -- Insurance, Patient, Adjustment
    
    -- Collections metrics
    aging_bucket VARCHAR(20), -- 0-30, 31-60, 61-90, 91-120, 120+
    collection_effort_count INT,
    
    FOREIGN KEY (claim_id) REFERENCES claims_fact(claim_id),
    FOREIGN KEY (provider_key) REFERENCES healthcare_providers_dim(provider_key),
    FOREIGN KEY (payer_key) REFERENCES payers_dim(payer_key),
    FOREIGN KEY (patient_key) REFERENCES patients_dim(patient_key),
    FOREIGN KEY (employee_key) REFERENCES rcm_employees_dim(employee_key)
);

-- Patient Encounters Fact Table
CREATE OR REPLACE TABLE patient_encounters_fact (
    encounter_id VARCHAR(50) PRIMARY KEY,
    provider_key INT,
    patient_key INT,
    specialty_key INT,
    region_key INT,
    
    encounter_date DATE,
    encounter_type VARCHAR(50), -- Inpatient, Outpatient, Emergency, Surgery
    
    -- Clinical metrics
    length_of_stay INT, -- For inpatient
    procedures_count INT,
    
    -- Financial metrics
    total_charges DECIMAL(12,2),
    expected_reimbursement DECIMAL(12,2),
    
    -- Quality metrics
    readmission_flag BOOLEAN,
    patient_satisfaction_score DECIMAL(3,2),
    
    FOREIGN KEY (provider_key) REFERENCES healthcare_providers_dim(provider_key),
    FOREIGN KEY (patient_key) REFERENCES patients_dim(patient_key),
    FOREIGN KEY (specialty_key) REFERENCES provider_specialties_dim(specialty_key),
    FOREIGN KEY (region_key) REFERENCES geographic_regions_dim(region_key)
);

-- ========================================================================
-- SYNTHETIC DATA GENERATION
-- ========================================================================

-- Insert Healthcare Providers (RCM Clients)
INSERT INTO healthcare_providers_dim VALUES
(1, 'Ann & Robert H. Lurie Children''s Hospital', 'Children''s Hospital', 'Pediatrics', 288, 1200000000, '225 E Chicago Ave', 'Chicago', 'IL', '60611', '2020-01-15'),
(2, 'Northwestern Memorial Hospital', 'Academic Medical Center', 'Multi-Specialty', 894, 2800000000, '251 E Huron St', 'Chicago', 'IL', '60611', '2019-03-20'),
(3, 'Rush University Medical Center', 'Academic Medical Center', 'Multi-Specialty', 664, 2100000000, '1611 W Harrison St', 'Chicago', 'IL', '60612', '2018-07-10'),
(4, 'Advocate Aurora Health', 'Health System', 'Multi-Specialty', 1200, 3500000000, '3075 Highland Pkwy', 'Downers Grove', 'IL', '60515', '2017-11-05'),
(5, 'DuPage Medical Group', 'Large Practice', 'Multi-Specialty', 0, 450000000, '28W751 Warrenville Rd', 'Warrenville', 'IL', '60555', '2019-08-22'),
(6, 'Midwest Orthopedic Center', 'Specialty Practice', 'Orthopedics', 0, 85000000, '1801 S Meyers Rd', 'Oakbrook Terrace', 'IL', '60181', '2020-05-12'),
(7, 'Chicago Eye Institute', 'Specialty Practice', 'Ophthalmology', 0, 32000000, '4500 N Broadway', 'Chicago', 'IL', '60640', '2021-02-08'),
(8, 'Heartland Surgery Center', 'Surgery Center', 'Surgery', 8, 28000000, '2500 W Higgins Rd', 'Hoffman Estates', 'IL', '60169', '2020-09-15'),
(9, 'Prairie Cardiovascular Associates', 'Specialty Practice', 'Cardiology', 0, 67000000, '1000 Central St', 'Evanston', 'IL', '60201', '2019-12-03'),
(10, 'Suburban Gastroenterology', 'Specialty Practice', 'Gastroenterology', 0, 41000000, '1555 Barrington Rd', 'Hoffman Estates', 'IL', '60169', '2021-06-17'),
(11, 'Lake Forest Dermatology', 'Specialty Practice', 'Dermatology', 0, 22000000, '1000 N Westmoreland Rd', 'Lake Forest', 'IL', '60045', '2020-11-30'),
(12, 'North Shore Radiology', 'Specialty Practice', 'Radiology', 0, 95000000, '2650 Ridge Ave', 'Evanston', 'IL', '60201', '2018-04-25'),
(13, 'University of Chicago Medicine', 'Academic Medical Center', 'Multi-Specialty', 811, 2400000000, '5841 S Maryland Ave', 'Chicago', 'IL', '60637', '2017-09-12'),
(14, 'NorthShore University HealthSystem', 'Health System', 'Multi-Specialty', 956, 1800000000, '1001 University Pl', 'Evanston', 'IL', '60201', '2018-12-01'),
(15, 'AMITA Health', 'Health System', 'Multi-Specialty', 1100, 2200000000, '1700 S Wells St', 'Chicago', 'IL', '60616', '2019-05-14');

-- Insert Payers
INSERT INTO payers_dim VALUES
(1, 'Blue Cross Blue Shield of Illinois', 'Commercial', 28.5, 18.2, '300 E Randolph St', 'Chicago', 'IL', '60601', '2015-01-01'),
(2, 'UnitedHealthcare', 'Commercial', 22.1, 16.8, '233 S Wacker Dr', 'Chicago', 'IL', '60606', '2015-01-01'),
(3, 'Cigna Healthcare', 'Commercial', 12.3, 19.5, '500 W Madison St', 'Chicago', 'IL', '60661', '2015-01-01'),
(4, 'Medicare', 'Government', 35.2, 14.2, 'Federal Program', 'Baltimore', 'MD', '21244', '2015-01-01'),
(5, 'Medicaid (Illinois)', 'Government', 18.9, 45.3, '201 S Grand Ave E', 'Springfield', 'IL', '62763', '2015-01-01'),
(6, 'Aetna', 'Commercial', 8.7, 17.9, '151 Farmington Ave', 'Hartford', 'CT', '06156', '2015-01-01'),
(7, 'Humana', 'Commercial', 6.2, 20.1, '500 W Main St', 'Louisville', 'KY', '40202', '2015-01-01'),
(8, 'TRICARE', 'Government', 2.1, 25.8, 'Military Health System', 'Falls Church', 'VA', '22042', '2015-01-01'),
(9, 'Self-Pay', 'Self-Pay', 4.8, 120.5, 'Patient Responsibility', 'Various', 'IL', '00000', '2015-01-01'),
(10, 'Workers Compensation', 'Other', 1.2, 35.7, 'State Program', 'Springfield', 'IL', '62701', '2015-01-01');

-- Insert Medical Procedures (Sample CPT Codes)
INSERT INTO procedures_dim VALUES
-- Evaluation & Management
(1, '99213', 'Office Visit - Established Patient Level 3', 'Evaluation & Management', 'Primary Care', 1.3, 150.00),
(2, '99214', 'Office Visit - Established Patient Level 4', 'Evaluation & Management', 'Primary Care', 2.0, 220.00),
(3, '99223', 'Initial Hospital Care Level 3', 'Evaluation & Management', 'Internal Medicine', 3.5, 350.00),
(4, '99233', 'Subsequent Hospital Care Level 3', 'Evaluation & Management', 'Internal Medicine', 2.8, 280.00),
-- Surgery
(5, '47562', 'Laparoscopic Cholecystectomy', 'Surgery', 'General Surgery', 15.6, 4500.00),
(6, '27447', 'Total Knee Arthroplasty', 'Surgery', 'Orthopedics', 32.5, 12500.00),
(7, '66984', 'Cataract Surgery with IOL', 'Surgery', 'Ophthalmology', 8.9, 2800.00),
(8, '43239', 'Upper Endoscopy with Biopsy', 'Surgery', 'Gastroenterology', 4.2, 1200.00),
-- Radiology
(9, '73721', 'MRI Knee without Contrast', 'Radiology', 'Radiology', 3.5, 1800.00),
(10, '74177', 'CT Abdomen and Pelvis with Contrast', 'Radiology', 'Radiology', 4.8, 2200.00),
(11, '76805', 'Obstetric Ultrasound', 'Radiology', 'Obstetrics', 2.1, 450.00),
(12, '71020', 'Chest X-Ray 2 Views', 'Radiology', 'Radiology', 0.8, 120.00),
-- Cardiology
(13, '93307', 'Echocardiogram Complete', 'Medicine', 'Cardiology', 3.2, 850.00),
(14, '93000', 'Electrocardiogram', 'Medicine', 'Cardiology', 0.6, 85.00),
(15, '92928', 'Percutaneous Coronary Intervention', 'Surgery', 'Cardiology', 22.8, 8500.00),
-- Emergency Medicine
(16, '99284', 'Emergency Department Visit Level 4', 'Evaluation & Management', 'Emergency Medicine', 4.8, 480.00),
(17, '99285', 'Emergency Department Visit Level 5', 'Evaluation & Management', 'Emergency Medicine', 7.2, 720.00),
-- Pediatrics
(18, '99392', 'Preventive Visit Age 1-4', 'Preventive Care', 'Pediatrics', 1.8, 280.00),
(19, '99214', 'Office Visit Pediatric Level 4', 'Evaluation & Management', 'Pediatrics', 2.0, 200.00),
(20, '49505', 'Inguinal Hernia Repair - Pediatric', 'Surgery', 'Pediatric Surgery', 8.5, 3200.00);

-- Continue with remaining dimension data...
-- (This script continues with the remaining data generation)

-- Show completion message
SELECT 'RCM Data Setup Complete - Part 1 of 4' as status;
