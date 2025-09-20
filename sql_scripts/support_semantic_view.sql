-- ========================================================================
-- Support Analytics Semantic View
-- This creates the semantic view for support ticket analytics
-- Run this AFTER support_ticket_setup.sql
-- Add this semantic view to your Snowflake Intelligence Agent configuration
-- ========================================================================

USE ROLE SF_Intelligence_Demo;
USE DATABASE SF_AI_DEMO;
USE SCHEMA DEMO_SCHEMA;

-- ========================================================================
-- SUPPORT ANALYTICS SEMANTIC VIEW
-- ========================================================================

CREATE OR REPLACE SEMANTIC VIEW SF_AI_DEMO.DEMO_SCHEMA.SUPPORT_ANALYTICS_VIEW
tables (
    TICKETS as SUPPORT_TICKETS_FACT primary key (TICKET_ID) 
        with synonyms=('support tickets','customer tickets','help desk','customer support') 
        comment='Customer support ticket data across all product areas',
    
    CLIENTS as CLIENT_DIM primary key (CLIENT_KEY) 
        with synonyms=('clients','customers','organizations') 
        comment='Client information with type segmentation',
    
    CATEGORIES as SUPPORT_CATEGORIES_DIM primary key (CATEGORY_KEY) 
        with synonyms=('ticket categories','support categories') 
        comment='Support ticket categories and types',
    
    TEAMS as SUPPORT_TEAMS_DIM primary key (TEAM_KEY) 
        with synonyms=('support teams','help desk teams') 
        comment='Support team information and specializations'
)
relationships (
    TICKETS_TO_CLIENTS as TICKETS(CLIENT_KEY) references CLIENTS(CLIENT_KEY),
    TICKETS_TO_CATEGORIES as TICKETS(CATEGORY) references CATEGORIES(CATEGORY_NAME),
    TICKETS_TO_TEAMS as TICKETS(ASSIGNED_TEAM) references TEAMS(TEAM_NAME)
)
facts (
    TICKETS.TICKET_RECORD as 1 comment='Count of support tickets',
    TICKETS.RESOLUTION_TIME as resolution_time_hours comment='Time to resolve ticket in hours',
    TICKETS.FIRST_RESPONSE_TIME as first_response_time_hours comment='Time to first response in hours',
    TICKETS.CUSTOMER_SATISFACTION as customer_satisfaction_score comment='Customer satisfaction rating 1-5'
)
dimensions (
    -- Ticket Classification
    TICKETS.PRODUCT_AREA as product_area with synonyms=('product area','module','feature area','system area') comment='Product area generating the ticket (Claims, Denials, Reporting, etc.)',
    TICKETS.FEATURE_NAME as feature_name with synonyms=('feature','capability','function') comment='Specific feature name within product area',
    TICKETS.CATEGORY as ticket_category with synonyms=('category','type','ticket type') comment='Type of support request (Bug, Feature Request, How-to, Training)',
    TICKETS.SUBCATEGORY as ticket_subcategory with synonyms=('subcategory','issue type') comment='More specific categorization of the ticket',
    
    -- Severity and Impact
    TICKETS.SEVERITY_LEVEL as severity with synonyms=('severity','priority','urgency') comment='Ticket severity level (Critical, High, Medium, Low)',
    TICKETS.CLIENT_IMPACT as client_impact with synonyms=('impact','business impact') comment='Impact on client operations (Low, Medium, High)',
    TICKETS.ESCALATED_FLAG as escalated with synonyms=('escalated','escalation') comment='Whether ticket was escalated to higher level support',
    
    -- Status and Resolution
    TICKETS.STATUS as ticket_status with synonyms=('status','state') comment='Current status of the ticket (Open, In Progress, Resolved, Closed)',
    TICKETS.RESOLUTION_METHOD as resolution_method with synonyms=('resolution type','how resolved') comment='Method used to resolve ticket (Phone, Email, Remote Session, Documentation)',
    
    -- Timing
    TICKETS.CREATED_DATE as ticket_date with synonyms=('date','created date','submission date') comment='Date ticket was created',
    TICKETS.TICKET_MONTH as MONTH(ticket_date) comment='Month the ticket was created',
    TICKETS.TICKET_YEAR as YEAR(ticket_date) comment='Year the ticket was created',
    TICKETS.RESOLVED_DATE as resolved_date with synonyms=('resolution date','closed date') comment='Date ticket was resolved',
    
    -- Client Information
    CLIENTS.CLIENT_TYPE as client_type with synonyms=('client segment','organization type','provider type') comment='Type of healthcare organization (DME, Hospital, Lab, Medical Billing, Physician Group)',
    CLIENTS.CLIENT_NAME as client_name with synonyms=('client','customer','organization') comment='Name of the client organization',
    CLIENTS.CLIENT_SIZE as client_size with synonyms=('size','scale') comment='Size category of client',
    
    -- Support Team Information
    TICKETS.ASSIGNED_TEAM as support_team with synonyms=('team','assigned team','handling team') comment='Support team that handled the ticket',
    TEAMS.SPECIALIZATION as team_specialization comment='Team specialization area',
    TEAMS.SHIFT_COVERAGE as team_coverage comment='Team shift coverage (24x7, Business Hours, Extended Hours)'
)
metrics (
    -- Volume Metrics
    TICKETS.TOTAL_TICKETS as COUNT(tickets.ticket_record) comment='Total number of support tickets',
    TICKETS.OPEN_TICKETS as COUNT(CASE WHEN tickets.ticket_status IN ('Open', 'In Progress') THEN tickets.ticket_record END) comment='Number of open/in-progress tickets',
    TICKETS.RESOLVED_TICKETS as COUNT(CASE WHEN tickets.ticket_status = 'Resolved' THEN tickets.ticket_record END) comment='Number of resolved tickets',
    
    -- Performance Metrics
    TICKETS.AVERAGE_RESOLUTION_TIME as AVG(tickets.resolution_time_hours) comment='Average time to resolve tickets in hours',
    TICKETS.AVERAGE_FIRST_RESPONSE_TIME as AVG(tickets.first_response_time_hours) comment='Average time to first response in hours',
    TICKETS.MEDIAN_RESOLUTION_TIME as MEDIAN(tickets.resolution_time_hours) comment='Median time to resolve tickets in hours',
    
    -- Quality Metrics
    TICKETS.AVERAGE_SATISFACTION as AVG(tickets.customer_satisfaction_score) comment='Average customer satisfaction score',
    TICKETS.ESCALATION_RATE as (COUNT(CASE WHEN tickets.escalated THEN tickets.ticket_record END) / COUNT(tickets.ticket_record) * 100) comment='Percentage of tickets that were escalated',
    TICKETS.RESOLUTION_RATE as (COUNT(CASE WHEN tickets.ticket_status = 'Resolved' THEN tickets.ticket_record END) / COUNT(tickets.ticket_record) * 100) comment='Percentage of tickets resolved',
    
    -- Trend Metrics
    TICKETS.TICKETS_BY_PRODUCT_AREA as COUNT(tickets.ticket_record) comment='Number of tickets by product area for ranking',
    TICKETS.HIGH_SEVERITY_TICKETS as COUNT(CASE WHEN tickets.severity IN ('Critical', 'High') THEN tickets.ticket_record END) comment='Number of high severity tickets',
    TICKETS.CRITICAL_TICKETS as COUNT(CASE WHEN tickets.severity = 'Critical' THEN tickets.ticket_record END) comment='Number of critical tickets'
)
comment='Comprehensive view for analyzing customer support ticket patterns, resolution performance, and product area issues'
with extension (CA='{"tables":[{"name":"TICKETS","dimensions":[{"name":"PRODUCT_AREA","sample_values":["Claims Processing","Denial Management","Reporting & Analytics","Patient Collections","User Management","System Integration","Mobile App","API Services"]},{"name":"FEATURE_NAME","sample_values":["Batch Claims Upload","Appeal Generation","Custom Reports","Performance Dashboard","Payment Plans","User Roles"]},{"name":"CATEGORY","sample_values":["Bug","Feature Request","How-to","Training","Configuration"]},{"name":"SEVERITY_LEVEL","sample_values":["Critical","High","Medium","Low"]},{"name":"STATUS","sample_values":["Open","In Progress","Resolved","Closed"]},{"name":"CLIENT_IMPACT","sample_values":["Low","Medium","High"]},{"name":"TICKET_DATE","sample_values":["2024-01-15","2024-02-20","2024-03-10"]}],"facts":[{"name":"TICKET_RECORD"},{"name":"RESOLUTION_TIME"},{"name":"FIRST_RESPONSE_TIME"},{"name":"CUSTOMER_SATISFACTION"}],"metrics":[{"name":"TOTAL_TICKETS"},{"name":"AVERAGE_RESOLUTION_TIME"},{"name":"AVERAGE_SATISFACTION"},{"name":"ESCALATION_RATE"}]},{"name":"CLIENTS","dimensions":[{"name":"CLIENT_TYPE","sample_values":["DME","Hospital","Lab","Medical Billing","Physician Group"]},{"name":"CLIENT_NAME","sample_values":["Regional Medical Center","Metro Physician Group","Advanced DME Solutions"]},{"name":"CLIENT_SIZE","sample_values":["Small","Medium","Large","Enterprise"]}]},{"name":"TEAMS","dimensions":[{"name":"TEAM_NAME","sample_values":["Level 1 Support","Level 2 Technical","Level 3 Engineering","Customer Success"]},{"name":"SPECIALIZATION","sample_values":["General support and triage","Technical issues and bugs","Complex technical issues","Training and best practices"]},{"name":"SHIFT_COVERAGE","sample_values":["Business Hours","Extended Hours","24x7"]}]}],"relationships":[{"name":"TICKETS_TO_CLIENTS","relationship_type":"many_to_one"},{"name":"TICKETS_TO_CATEGORIES","relationship_type":"many_to_one"},{"name":"TICKETS_TO_TEAMS","relationship_type":"many_to_one"}],"verified_queries":[{"name":"Product areas with most tickets","question":"Which product areas generate the most customer support tickets?","sql":"SELECT\\n  t.product_area,\\n  COUNT(t.ticket_record) AS total_tickets,\\n  AVG(t.resolution_time_hours) AS avg_resolution_time\\nFROM\\n  tickets AS t\\nWHERE\\n  t.ticket_date >= ''2024-01-01''\\nGROUP BY\\n  t.product_area\\nORDER BY\\n  total_tickets DESC","use_as_onboarding_question":true,"verified_by":"System","verified_at":1704067200},{"name":"Support tickets by client type","question":"How do support ticket volumes vary by client type?","sql":"SELECT\\n  c.client_type,\\n  COUNT(t.ticket_record) AS ticket_count,\\n  AVG(t.customer_satisfaction_score) AS avg_satisfaction\\nFROM\\n  tickets AS t\\n  JOIN clients AS c ON t.client_key = c.client_key\\nGROUP BY\\n  c.client_type\\nORDER BY\\n  ticket_count DESC","use_as_onboarding_question":false,"verified_by":"System","verified_at":1704067200}]}');

-- ========================================================================
-- VERIFICATION
-- ========================================================================

-- Show the semantic view was created successfully
SHOW SEMANTIC VIEWS LIKE 'SUPPORT_ANALYTICS_VIEW';

-- Show dimensions for the support analytics view
SHOW SEMANTIC DIMENSIONS IN SEMANTIC VIEW SUPPORT_ANALYTICS_VIEW;

-- Show metrics for the support analytics view
SHOW SEMANTIC METRICS IN SEMANTIC VIEW SUPPORT_ANALYTICS_VIEW;

-- ========================================================================
-- COMPLETION MESSAGE
-- ========================================================================

SELECT 'Support Analytics Semantic View Created Successfully!' as status,
       'View Name: SUPPORT_ANALYTICS_VIEW' as view_name,
       'Ready to add to Snowflake Intelligence Agent configuration' as next_step;
