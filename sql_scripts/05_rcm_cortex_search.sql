-- ========================================================================
-- RCM AI Demo - Cortex Search Setup (Part 5 of 6)
-- Healthcare Document Intelligence with Vector Search
-- ========================================================================

USE ROLE SF_INTELLIGENCE_DEMO;
USE DATABASE RCM_AI_DEMO;
USE SCHEMA RCM_SCHEMA;

-- ========================================================================
-- DOCUMENT CONTENT PREPARATION
-- ========================================================================

-- Use the documents created in script 02 for Cortex Search
-- Create a view that formats the content for search services
CREATE OR REPLACE VIEW rcm_parsed_content AS 
SELECT 
    document_path as relative_path,
    'internal://' || document_path as file_url,
    document_title as title,
    content
FROM rcm_document_content;

-- ========================================================================
-- HEALTHCARE DOCUMENT SEARCH SERVICES
-- ========================================================================

-- Search service for RCM financial documents
-- Covers: Financial reports, expense policies, vendor contracts
CREATE OR REPLACE CORTEX SEARCH SERVICE RCM_FINANCE_DOCS_SEARCH
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
        WHERE relative_path LIKE '/finance/%'
    );

-- Search service for RCM operations and HR documents  
-- Covers: Employee handbooks, performance guidelines, operational procedures
CREATE OR REPLACE CORTEX SEARCH SERVICE RCM_OPERATIONS_DOCS_SEARCH
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
        WHERE relative_path LIKE '/operations/%'
    );

-- Search service for RCM compliance and sales documents
-- Covers: Compliance policies, client success stories, sales materials
CREATE OR REPLACE CORTEX SEARCH SERVICE RCM_COMPLIANCE_DOCS_SEARCH
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
        WHERE relative_path LIKE '/compliance/%'
    );

-- Search service for RCM strategy and marketing documents
-- Covers: Strategic plans, market analysis, competitive intelligence
CREATE OR REPLACE CORTEX SEARCH SERVICE RCM_STRATEGY_DOCS_SEARCH
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
CREATE OR REPLACE CORTEX SEARCH SERVICE RCM_KNOWLEDGE_BASE_SEARCH
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
                WHEN relative_path LIKE '/finance/%' THEN 'Financial Policy'
                WHEN relative_path LIKE '/operations/%' THEN 'Operations Manual'
                WHEN relative_path LIKE '/compliance/%' THEN 'Compliance Guide'
                WHEN relative_path LIKE '/strategy/%' THEN 'Strategic Plan'
                ELSE 'General Document'
            END as document_type,
            -- Comprehensive healthcare RCM context
            CONCAT(
                'HEALTHCARE REVENUE CYCLE MANAGEMENT KNOWLEDGE BASE: ',
                CASE 
                    WHEN relative_path LIKE '/finance/%' THEN 'FINANCIAL POLICY AND PROCEDURES - '
                    WHEN relative_path LIKE '/operations/%' THEN 'OPERATIONS AND WORKFORCE MANAGEMENT - '
                    WHEN relative_path LIKE '/compliance/%' THEN 'COMPLIANCE AND AUDIT PROCEDURES - '
                    WHEN relative_path LIKE '/strategy/%' THEN 'STRATEGIC PLANNING AND MARKET ANALYSIS - '
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
    rcm_ai_demo.rcm_schema.RCM_FINANCE_DOCS_SEARCH(
        'denial management policies and procedures'
    )
) LIMIT 3;

SELECT 'Testing RCM Knowledge Base Search...' as test_step;
SELECT * FROM TABLE(
    rcm_ai_demo.rcm_schema.RCM_KNOWLEDGE_BASE_SEARCH(
        'revenue cycle optimization strategies'
    )
) LIMIT 3;

-- Verify document counts by type
SELECT 
    CASE 
        WHEN relative_path LIKE '/finance/%' THEN 'Financial Documents'
        WHEN relative_path LIKE '/operations/%' THEN 'Operations Documents'
        WHEN relative_path LIKE '/compliance/%' THEN 'Compliance Documents'
        WHEN relative_path LIKE '/strategy/%' THEN 'Strategic Documents'
        ELSE 'Other Documents'
    END as document_category,
    COUNT(*) as document_count,
    ROUND(AVG(LENGTH(content)), 0) as avg_content_length
FROM rcm_parsed_content
GROUP BY 1
ORDER BY document_count DESC;

SELECT 'RCM Cortex Search Setup Complete - Part 5 of 6' as status;
