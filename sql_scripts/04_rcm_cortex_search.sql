-- ========================================================================
-- RCM AI Demo - Cortex Search Setup (Part 3 of 4)
-- Healthcare Document Intelligence with Vector Search
-- ========================================================================

USE ROLE SF_INTELLIGENCE_DEMO;
USE DATABASE RCM_AI_DEMO;
USE SCHEMA RCM_SCHEMA;

-- ========================================================================
-- DOCUMENT PARSING AND PREPARATION
-- ========================================================================

-- Parse documents from internal stage for healthcare content
CREATE OR REPLACE TABLE rcm_parsed_content AS 
SELECT 
    relative_path, 
    BUILD_STAGE_FILE_URL('@RCM_AI_DEMO.RCM_SCHEMA.RCM_DATA_STAGE', relative_path) as file_url,
    TO_FILE(BUILD_STAGE_FILE_URL('@RCM_AI_DEMO.RCM_SCHEMA.RCM_DATA_STAGE', relative_path)) file_object,
    SNOWFLAKE.CORTEX.PARSE_DOCUMENT(
        @RCM_AI_DEMO.RCM_SCHEMA.RCM_DATA_STAGE,
        relative_path,
        {'mode':'LAYOUT'}
    ):content::string as content
FROM directory(@RCM_AI_DEMO.RCM_SCHEMA.RCM_DATA_STAGE) 
WHERE relative_path ILIKE 'unstructured_docs/%.pdf';

-- ========================================================================
-- HEALTHCARE DOCUMENT SEARCH SERVICES
-- ========================================================================

-- Search service for RCM financial documents
-- Covers: Financial reports, expense policies, vendor contracts
CREATE OR REPLACE CORTEX SEARCH SERVICE rcm_finance_docs_search
    ON content
    ATTRIBUTES relative_path, file_url, title
    WAREHOUSE = RCM_INTELLIGENCE_WH
    TARGET_LAG = '30 day'
    EMBEDDING_MODEL = 'snowflake-arctic-embed-l-v2.0'
    AS (
        SELECT
            relative_path,
            file_url,
            REGEXP_SUBSTR(relative_path, '[^/]+$') as title,
            -- Enhance content with RCM-specific context
            CONCAT(
                'HEALTHCARE REVENUE CYCLE MANAGEMENT DOCUMENT: ',
                REGEXP_SUBSTR(relative_path, '[^/]+$'),
                ' CONTENT: ',
                content,
                ' KEYWORDS: revenue cycle, claims processing, denial management, payer contracts, reimbursement, financial performance, healthcare billing, medical coding, accounts receivable, cash flow'
            ) as content
        FROM rcm_parsed_content
        WHERE relative_path ILIKE '%/finance/%'
    );

-- Search service for RCM operations and HR documents  
-- Covers: Employee handbooks, performance guidelines, operational procedures
CREATE OR REPLACE CORTEX SEARCH SERVICE rcm_operations_docs_search
    ON content
    ATTRIBUTES relative_path, file_url, title
    WAREHOUSE = RCM_INTELLIGENCE_WH
    TARGET_LAG = '30 day'
    EMBEDDING_MODEL = 'snowflake-arctic-embed-l-v2.0'
    AS (
        SELECT
            relative_path,
            file_url,
            REGEXP_SUBSTR(relative_path, '[^/]+$') as title,
            -- Enhance content with healthcare operations context
            CONCAT(
                'HEALTHCARE OPERATIONS DOCUMENT: ',
                REGEXP_SUBSTR(relative_path, '[^/]+$'),
                ' CONTENT: ',
                content,
                ' KEYWORDS: healthcare operations, RCM staffing, claims analysts, denial specialists, appeals coordinators, workforce management, productivity metrics, performance standards, training procedures, compliance requirements'
            ) as content
        FROM rcm_parsed_content
        WHERE relative_path ILIKE '%/hr/%'
    );

-- Search service for RCM compliance and sales documents
-- Covers: Compliance policies, client success stories, sales materials
CREATE OR REPLACE CORTEX SEARCH SERVICE rcm_compliance_docs_search
    ON content
    ATTRIBUTES relative_path, file_url, title
    WAREHOUSE = RCM_INTELLIGENCE_WH
    TARGET_LAG = '30 day'
    EMBEDDING_MODEL = 'snowflake-arctic-embed-l-v2.0'
    AS (
        SELECT
            relative_path,
            file_url,
            REGEXP_SUBSTR(relative_path, '[^/]+$') as title,
            -- Enhance content with compliance and sales context
            CONCAT(
                'HEALTHCARE COMPLIANCE AND SALES DOCUMENT: ',
                REGEXP_SUBSTR(relative_path, '[^/]+$'),
                ' CONTENT: ',
                content,
                ' KEYWORDS: healthcare compliance, HIPAA, billing regulations, audit requirements, CMS guidelines, payer policies, client success, case studies, implementation, ROI, revenue optimization, cost reduction'
            ) as content
        FROM rcm_parsed_content
        WHERE relative_path ILIKE '%/sales/%'
    );

-- Search service for RCM strategy and marketing documents
-- Covers: Strategic plans, market analysis, competitive intelligence
CREATE OR REPLACE CORTEX SEARCH SERVICE rcm_strategy_docs_search
    ON content
    ATTRIBUTES relative_path, file_url, title
    WAREHOUSE = RCM_INTELLIGENCE_WH
    TARGET_LAG = '30 day'
    EMBEDDING_MODEL = 'snowflake-arctic-embed-l-v2.0'
    AS (
        SELECT
            relative_path,
            file_url,
            REGEXP_SUBSTR(relative_path, '[^/]+$') as title,
            -- Enhance content with strategic and market context
            CONCAT(
                'HEALTHCARE STRATEGY DOCUMENT: ',
                REGEXP_SUBSTR(relative_path, '[^/]+$'),
                ' CONTENT: ',
                content,
                ' KEYWORDS: healthcare strategy, market analysis, competitive landscape, revenue cycle trends, industry benchmarks, payer mix analysis, specialty markets, growth opportunities, digital transformation, AI automation'
            ) as content
        FROM rcm_parsed_content
        WHERE relative_path ILIKE '%/marketing/%'
    );

-- ========================================================================
-- HEALTHCARE POLICY AND PROCEDURE SEARCH
-- ========================================================================

-- Create comprehensive healthcare knowledge base search
-- Combines all documents for cross-functional healthcare intelligence
CREATE OR REPLACE CORTEX SEARCH SERVICE rcm_knowledge_base_search
    ON content
    ATTRIBUTES relative_path, file_url, title, document_type
    WAREHOUSE = RCM_INTELLIGENCE_WH
    TARGET_LAG = '30 day'
    EMBEDDING_MODEL = 'snowflake-arctic-embed-l-v2.0'
    AS (
        SELECT
            relative_path,
            file_url,
            REGEXP_SUBSTR(relative_path, '[^/]+$') as title,
            CASE 
                WHEN relative_path ILIKE '%/finance/%' THEN 'Financial Policy'
                WHEN relative_path ILIKE '%/hr/%' THEN 'Operations Manual'
                WHEN relative_path ILIKE '%/sales/%' THEN 'Client Success Guide'
                WHEN relative_path ILIKE '%/marketing/%' THEN 'Strategic Plan'
                ELSE 'General Document'
            END as document_type,
            -- Comprehensive healthcare RCM context
            CONCAT(
                'HEALTHCARE REVENUE CYCLE MANAGEMENT KNOWLEDGE BASE: ',
                CASE 
                    WHEN relative_path ILIKE '%/finance/%' THEN 'FINANCIAL POLICY AND PROCEDURES - '
                    WHEN relative_path ILIKE '%/hr/%' THEN 'OPERATIONS AND HUMAN RESOURCES - '
                    WHEN relative_path ILIKE '%/sales/%' THEN 'CLIENT SUCCESS AND IMPLEMENTATION - '
                    WHEN relative_path ILIKE '%/marketing/%' THEN 'STRATEGIC PLANNING AND MARKET ANALYSIS - '
                    ELSE 'GENERAL HEALTHCARE DOCUMENT - '
                END,
                REGEXP_SUBSTR(relative_path, '[^/]+$'),
                ' DOCUMENT CONTENT: ',
                content,
                ' HEALTHCARE CONTEXT: This document relates to revenue cycle management, healthcare billing, claims processing, denial management, payer relations, compliance requirements, operational efficiency, financial performance, and client services in the healthcare industry.'
            ) as content
        FROM rcm_parsed_content
    );

-- ========================================================================
-- SEARCH SERVICE VERIFICATION
-- ========================================================================

-- Show all created search services
SHOW CORTEX SEARCH SERVICES;

-- Test search functionality with healthcare-specific queries
SELECT 'Testing RCM Finance Search...' as test_step;
SELECT * FROM TABLE(
    rcm_ai_demo.rcm_schema.rcm_finance_docs_search(
        'denial management policies and procedures'
    )
) LIMIT 3;

SELECT 'Testing RCM Knowledge Base Search...' as test_step;
SELECT * FROM TABLE(
    rcm_ai_demo.rcm_schema.rcm_knowledge_base_search(
        'revenue cycle optimization strategies'
    )
) LIMIT 3;

-- Verify document counts by type
SELECT 
    CASE 
        WHEN relative_path ILIKE '%/finance/%' THEN 'Financial Documents'
        WHEN relative_path ILIKE '%/hr/%' THEN 'Operations Documents'
        WHEN relative_path ILIKE '%/sales/%' THEN 'Client Success Documents'
        WHEN relative_path ILIKE '%/marketing/%' THEN 'Strategic Documents'
        ELSE 'Other Documents'
    END as document_category,
    COUNT(*) as document_count,
    ROUND(AVG(LENGTH(content)), 0) as avg_content_length
FROM rcm_parsed_content
GROUP BY 1
ORDER BY document_count DESC;

SELECT 'RCM Cortex Search Setup Complete - Part 3 of 4' as status;
