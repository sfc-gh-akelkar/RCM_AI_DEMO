-- ========================================================================
-- Support Ticket Analytics Add-on for RCM AI Demo
-- This script adds customer support ticket tracking capabilities
-- Run this AFTER the main demo_setup.sql script
-- ========================================================================

USE ROLE SF_Intelligence_Demo;
USE DATABASE SF_AI_DEMO;
USE SCHEMA DEMO_SCHEMA;

-- ========================================================================
-- SUPPORT TICKET TABLES
-- ========================================================================

-- Support Tickets Fact Table
CREATE OR REPLACE TABLE support_tickets_fact (
    ticket_id VARCHAR(50) PRIMARY KEY,
    client_key INT NOT NULL,
    user_key INT,
    product_area VARCHAR(100) NOT NULL,        -- Claims, Denials, Reporting, Analytics, etc.
    feature_name VARCHAR(100),                 -- Specific feature if known
    severity_level VARCHAR(20),                -- Critical, High, Medium, Low
    category VARCHAR(50),                      -- Bug, Feature Request, How-to, Training
    subcategory VARCHAR(100),                  -- More specific categorization
    created_date DATE NOT NULL,
    resolved_date DATE,
    resolution_time_hours DECIMAL(8,2),
    status VARCHAR(30),                        -- Open, In Progress, Resolved, Closed
    customer_satisfaction_score INT,           -- 1-5 rating
    assigned_team VARCHAR(50),                 -- Support team that handled ticket
    escalated_flag BOOLEAN DEFAULT FALSE,     -- Whether ticket was escalated
    client_impact VARCHAR(20),                -- Low, Medium, High impact on client operations
    resolution_method VARCHAR(50),            -- Phone, Email, Remote Session, Documentation
    first_response_time_hours DECIMAL(8,2),   -- Time to first response
    created_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP(),
    updated_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP()
);

-- Support Categories Dimension
CREATE OR REPLACE TABLE support_categories_dim (
    category_key INT PRIMARY KEY,
    category_name VARCHAR(50) NOT NULL,
    category_description TEXT,
    typical_resolution_time_hours DECIMAL(8,2),
    requires_escalation BOOLEAN DEFAULT FALSE
);

-- Support Teams Dimension
CREATE OR REPLACE TABLE support_teams_dim (
    team_key INT PRIMARY KEY,
    team_name VARCHAR(50) NOT NULL,
    specialization VARCHAR(100),
    avg_resolution_time_hours DECIMAL(8,2),
    team_size INT,
    shift_coverage VARCHAR(20)              -- 24x7, Business Hours, Extended Hours
);

-- ========================================================================
-- LOAD REFERENCE DATA
-- ========================================================================

-- Insert Support Categories
INSERT INTO support_categories_dim VALUES
(1, 'Bug', 'Software defects requiring fixes', 24.0, FALSE),
(2, 'Feature Request', 'Requests for new functionality', 72.0, TRUE),
(3, 'How-to', 'Usage questions and guidance', 2.0, FALSE),
(4, 'Training', 'User training and education requests', 4.0, FALSE),
(5, 'Configuration', 'System setup and configuration help', 8.0, FALSE),
(6, 'Performance', 'System performance issues', 12.0, TRUE),
(7, 'Integration', 'Third-party integration issues', 48.0, TRUE),
(8, 'Data Issue', 'Data quality or data loading problems', 16.0, FALSE),
(9, 'Access Issue', 'Login and permission problems', 1.0, FALSE),
(10, 'Billing Question', 'Account and billing inquiries', 2.0, FALSE);

-- Insert Support Teams
INSERT INTO support_teams_dim VALUES
(1, 'Level 1 Support', 'General support and triage', 4.0, 12, 'Business Hours'),
(2, 'Level 2 Technical', 'Technical issues and bugs', 16.0, 8, 'Extended Hours'),
(3, 'Level 3 Engineering', 'Complex technical and development issues', 48.0, 4, 'Business Hours'),
(4, 'Customer Success', 'Training and best practices', 6.0, 6, 'Business Hours'),
(5, 'Implementation', 'Setup and configuration', 24.0, 5, 'Business Hours'),
(6, 'Data Team', 'Data issues and ETL problems', 12.0, 4, 'Business Hours');

-- ========================================================================
-- GENERATE SAMPLE SUPPORT TICKET DATA
-- ========================================================================

-- Generate sample support tickets across different product areas, clients, and time periods
WITH ticket_generator AS (
    SELECT 
        ROW_NUMBER() OVER (ORDER BY SEQ4()) as ticket_num,
        UNIFORM(1, 50, RANDOM()) as client_key,
        UNIFORM(1, 200, RANDOM()) as user_key,
        UNIFORM(0, 7, RANDOM()) as product_area_rand,
        UNIFORM(0, 9, RANDOM()) as feature_rand,
        UNIFORM(0, 3, RANDOM()) as severity_rand,
        UNIFORM(0, 4, RANDOM()) as category_rand,
        UNIFORM(0, 5, RANDOM()) as subcategory_rand,
        UNIFORM(1, 365, RANDOM()) as days_back,
        UNIFORM(1, 72, RANDOM()) as resolution_hours,
        UNIFORM(1, 5, RANDOM()) as satisfaction,
        UNIFORM(0, 5, RANDOM()) as team_rand,
        UNIFORM(0, 2, RANDOM()) as impact_rand,
        UNIFORM(0, 3, RANDOM()) as method_rand,
        ROUND(UNIFORM(1, 80, RANDOM()) / 10.0, 1) as first_response_hours,
        RANDOM() as status_rand,
        RANDOM() as resolved_rand,
        RANDOM() as escalated_rand
    FROM TABLE(GENERATOR(ROWCOUNT => 750))
)
INSERT INTO support_tickets_fact (
    ticket_id, client_key, user_key, product_area, feature_name, severity_level, 
    category, subcategory, created_date, resolved_date, resolution_time_hours, 
    status, customer_satisfaction_score, assigned_team, escalated_flag, 
    client_impact, resolution_method, first_response_time_hours
)
SELECT 
    'TKT' || LPAD(ticket_num::VARCHAR, 6, '0') as ticket_id,
    client_key,
    user_key,
    CASE product_area_rand
        WHEN 0 THEN 'Claims Processing'
        WHEN 1 THEN 'Denial Management'
        WHEN 2 THEN 'Reporting & Analytics'
        WHEN 3 THEN 'Patient Collections'
        WHEN 4 THEN 'User Management'
        WHEN 5 THEN 'System Integration'
        WHEN 6 THEN 'Mobile App'
        ELSE 'API Services'
    END as product_area,
    CASE feature_rand
        WHEN 0 THEN 'Batch Claims Upload'
        WHEN 1 THEN 'Appeal Generation'
        WHEN 2 THEN 'Custom Reports'
        WHEN 3 THEN 'Performance Dashboard'
        WHEN 4 THEN 'Payment Plans'
        WHEN 5 THEN 'User Roles'
        WHEN 6 THEN 'HL7 Interface'
        WHEN 7 THEN 'Mobile Claims Entry'
        WHEN 8 THEN 'REST API'
        ELSE 'Electronic Remittance'
    END as feature_name,
    CASE severity_rand
        WHEN 0 THEN 'Critical'
        WHEN 1 THEN 'High'
        WHEN 2 THEN 'Medium'
        ELSE 'Low'
    END as severity_level,
    CASE category_rand
        WHEN 0 THEN 'Bug'
        WHEN 1 THEN 'Feature Request'
        WHEN 2 THEN 'How-to'
        WHEN 3 THEN 'Training'
        ELSE 'Configuration'
    END as category,
    CASE subcategory_rand
        WHEN 0 THEN 'User Interface Issue'
        WHEN 1 THEN 'Data Processing Error'
        WHEN 2 THEN 'Performance Slow'
        WHEN 3 THEN 'Integration Failure'
        WHEN 4 THEN 'Permission Denied'
        ELSE 'Workflow Question'
    END as subcategory,
    DATEADD(day, -days_back, CURRENT_DATE()) as created_date,
    CASE 
        WHEN resolved_rand < 0.85 THEN DATEADD(hour, resolution_hours, DATEADD(day, -days_back, CURRENT_DATE()))
        ELSE NULL  -- 15% still open
    END as resolved_date,
    CASE 
        WHEN resolved_rand < 0.85 THEN resolution_hours::DECIMAL(8,2)
        ELSE NULL
    END as resolution_time_hours,
    CASE 
        WHEN status_rand < 0.85 THEN 'Resolved'
        WHEN status_rand < 0.95 THEN 'In Progress'
        ELSE 'Open'
    END as status,
    CASE 
        WHEN resolved_rand < 0.85 THEN satisfaction
        ELSE NULL
    END as customer_satisfaction_score,
    CASE team_rand
        WHEN 0 THEN 'Level 1 Support'
        WHEN 1 THEN 'Level 2 Technical'
        WHEN 2 THEN 'Level 3 Engineering'
        WHEN 3 THEN 'Customer Success'
        WHEN 4 THEN 'Implementation'
        ELSE 'Data Team'
    END as assigned_team,
    CASE WHEN escalated_rand < 0.2 THEN TRUE ELSE FALSE END as escalated_flag,
    CASE impact_rand
        WHEN 0 THEN 'Low'
        WHEN 1 THEN 'Medium'
        ELSE 'High'
    END as client_impact,
    CASE method_rand
        WHEN 0 THEN 'Phone'
        WHEN 1 THEN 'Email'
        WHEN 2 THEN 'Remote Session'
        ELSE 'Documentation'
    END as resolution_method,
    first_response_hours
FROM ticket_generator;

-- ========================================================================
-- CREATE INDEXES FOR PERFORMANCE
-- ========================================================================

-- Add indexes for common query patterns
-- Note: Snowflake automatically manages clustering, but these help with query optimization
ALTER TABLE support_tickets_fact ADD SEARCH OPTIMIZATION;

-- ========================================================================
-- VERIFICATION QUERIES
-- ========================================================================

-- Verify data was loaded correctly
SELECT 'Support Tickets by Product Area' as metric_name, '' as value
UNION ALL
SELECT product_area, COUNT(*)::VARCHAR 
FROM support_tickets_fact 
GROUP BY product_area 
ORDER BY COUNT(*) DESC;

SELECT '' as separator, ''
UNION ALL
SELECT 'Support Tickets by Status' as metric_name, '' as value
UNION ALL
SELECT status, COUNT(*)::VARCHAR 
FROM support_tickets_fact 
GROUP BY status;

SELECT '' as separator, ''
UNION ALL
SELECT 'Average Resolution Time by Product Area' as metric_name, '' as value
UNION ALL
SELECT product_area, ROUND(AVG(resolution_time_hours), 1)::VARCHAR || ' hours'
FROM support_tickets_fact 
WHERE resolution_time_hours IS NOT NULL
GROUP BY product_area 
ORDER BY AVG(resolution_time_hours) DESC;

-- Show total counts
SELECT 'SUPPORT TICKET TABLES' as category, '' as table_name, NULL as row_count
UNION ALL
SELECT '', 'support_tickets_fact', COUNT(*) FROM support_tickets_fact
UNION ALL
SELECT '', 'support_categories_dim', COUNT(*) FROM support_categories_dim
UNION ALL
SELECT '', 'support_teams_dim', COUNT(*) FROM support_teams_dim;

-- ========================================================================
-- COMPLETION MESSAGE
-- ========================================================================

SELECT 'Support Ticket Analytics Setup Complete!' as status,
       'Tables created: support_tickets_fact, support_categories_dim, support_teams_dim' as details,
       'Next: Run support_semantic_view.sql to create the semantic view' as next_step;
