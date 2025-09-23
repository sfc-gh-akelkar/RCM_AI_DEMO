-- ========================================================================
-- RCM AI Demo - Agent Setup (Part 4 of 4)  
-- Healthcare Revenue Cycle Management AI Agent Configuration
-- ========================================================================

USE ROLE accountadmin;

-- ========================================================================
-- EXTERNAL ACCESS AND INTEGRATIONS SETUP
-- ========================================================================

-- Grant privileges for agent creation
GRANT ALL PRIVILEGES ON DATABASE RCM_AI_DEMO TO ROLE ACCOUNTADMIN;
GRANT ALL PRIVILEGES ON SCHEMA RCM_AI_DEMO.RCM_SCHEMA TO ROLE ACCOUNTADMIN;

-- Network rule for external web access (for web scraping healthcare data)
CREATE OR REPLACE NETWORK RULE rcm_intelligence_web_access_rule
  MODE = EGRESS
  TYPE = HOST_PORT
  VALUE_LIST = ('0.0.0.0:80', '0.0.0.0:443');

GRANT USAGE ON NETWORK RULE rcm_intelligence_web_access_rule TO ROLE accountadmin;

USE SCHEMA RCM_AI_DEMO.RCM_SCHEMA;

-- External access integration for healthcare data sources
CREATE OR REPLACE EXTERNAL ACCESS INTEGRATION rcm_intelligence_external_access
ALLOWED_NETWORK_RULES = (rcm_intelligence_web_access_rule)
ENABLED = true;

-- Email notification integration for RCM alerts
CREATE OR REPLACE NOTIFICATION INTEGRATION rcm_email_notifications
  TYPE=EMAIL
  ENABLED=TRUE;

-- Grant usage on integrations to demo role
GRANT USAGE ON DATABASE snowflake_intelligence TO ROLE SF_INTELLIGENCE_DEMO;
GRANT USAGE ON SCHEMA snowflake_intelligence.agents TO ROLE SF_INTELLIGENCE_DEMO;
GRANT CREATE AGENT ON SCHEMA snowflake_intelligence.agents TO ROLE SF_INTELLIGENCE_DEMO;
GRANT USAGE ON INTEGRATION rcm_intelligence_external_access TO ROLE SF_INTELLIGENCE_DEMO;
GRANT USAGE ON INTEGRATION rcm_email_notifications TO ROLE SF_INTELLIGENCE_DEMO;

-- Switch to demo role for agent creation
USE ROLE SF_INTELLIGENCE_DEMO;

-- ========================================================================
-- HEALTHCARE UTILITY FUNCTIONS
-- ========================================================================

-- Create stored procedure to generate presigned URLs for RCM documents
CREATE OR REPLACE PROCEDURE Get_RCM_Document_URL(
    RELATIVE_FILE_PATH STRING, 
    EXPIRATION_MINS INTEGER DEFAULT 60
)
RETURNS STRING
LANGUAGE SQL
COMMENT = 'Generates a presigned URL for RCM documents in the internal stage. Input is the relative file path.'
EXECUTE AS CALLER
AS
$$
DECLARE
    presigned_url STRING;
    sql_stmt STRING;
    expiration_seconds INTEGER;
    stage_name STRING DEFAULT '@RCM_AI_DEMO.RCM_SCHEMA.RCM_DATA_STAGE';
BEGIN
    expiration_seconds := EXPIRATION_MINS * 60;

    sql_stmt := 'SELECT GET_PRESIGNED_URL(' || stage_name || ', ' || '''' || RELATIVE_FILE_PATH || '''' || ', ' || expiration_seconds || ') AS url';
    
    EXECUTE IMMEDIATE :sql_stmt;
    
    SELECT "URL"
    INTO :presigned_url
    FROM TABLE(RESULT_SCAN(LAST_QUERY_ID()));
    
    RETURN :presigned_url;
END;
$$;

-- Create procedure to send RCM alert emails
CREATE OR REPLACE PROCEDURE send_rcm_alert(recipient TEXT, subject TEXT, message TEXT)
RETURNS TEXT
LANGUAGE PYTHON
RUNTIME_VERSION = '3.11'
PACKAGES = ('snowflake-snowpark-python')
HANDLER = 'send_rcm_alert'
AS
$$
def send_rcm_alert(session, recipient, subject, message):
    session.call(
        'SYSTEM$SEND_EMAIL',
        'rcm_email_notifications',
        recipient,
        subject,
        message,
        'text/plain'
    )
    return f"RCM alert sent to {recipient} with subject: {subject}"
$$;

-- Create healthcare web scraping function for market intelligence
CREATE OR REPLACE FUNCTION scrape_healthcare_data(weburl TEXT)
RETURNS TEXT
LANGUAGE PYTHON
RUNTIME_VERSION = '3.11'
PACKAGES = ('requests', 'beautifulsoup4', 'snowflake-snowpark-python')
IMPORTS = ()
HANDLER = 'scrape_healthcare_data'
EXTERNAL_ACCESS_INTEGRATIONS = (rcm_intelligence_external_access)
AS
$$
import requests
from bs4 import BeautifulSoup

def scrape_healthcare_data(weburl):
    """
    Scrapes healthcare-related web content for market intelligence.
    Useful for gathering payer policy updates, CMS announcements, industry trends.
    """
    try:
        url = f"{weburl}"
        response = requests.get(url, timeout=30)
        response.raise_for_status()
        
        soup = BeautifulSoup(response.text, 'html.parser')
        
        # Remove script and style elements
        for script in soup(["script", "style"]):
            script.extract()
        
        # Get text content
        text = soup.get_text()
        
        # Clean up text
        lines = (line.strip() for line in text.splitlines())
        chunks = (phrase.strip() for line in lines for phrase in line.split("  "))
        text = ' '.join(chunk for chunk in chunks if chunk)
        
        return text[:10000]  # Limit to first 10k characters
        
    except Exception as e:
        return f"Error scraping healthcare data: {str(e)}"
$$;

-- ========================================================================
-- RCM SNOWFLAKE INTELLIGENCE AGENT
-- ========================================================================

CREATE OR REPLACE AGENT SNOWFLAKE_INTELLIGENCE.AGENTS.RCM_Healthcare_Agent
WITH PROFILE='{ "display_name": "Healthcare Revenue Cycle Management AI Agent" }'
COMMENT=$$ 
Healthcare Revenue Cycle Management AI Agent for analyzing claims, denials, payer performance, 
provider metrics, and operational efficiency. Specializes in RCM KPIs, financial analysis, 
and healthcare industry intelligence.
$$
FROM SPECIFICATION $$
{
  "models": {
    "orchestration": "mixtral-8x7b"
  },
  "instructions": {
    "response": "You are a healthcare revenue cycle management (RCM) analyst with deep expertise in claims processing, denial management, payer relations, and healthcare financial operations. You have access to comprehensive healthcare provider data, payer performance metrics, claims and denials data, and healthcare industry documents. When answering questions, focus on RCM-specific KPIs like clean claim rates, denial rates, net collection rates, days in A/R, appeal success rates, and payer performance metrics. Provide visualizations when possible and always relate insights back to revenue cycle optimization and healthcare financial performance. Use healthcare terminology throughout your responses.",
    "orchestration": "Use Cortex Search to find relevant healthcare documents and policies, then use Cortex Analyst to analyze claims, denials, and financial data. For questions about providers, payers, or operational metrics, prioritize the Claims Processing and Denials Management datamarts. Always consider healthcare industry context and RCM best practices. When discussing financial performance, focus on revenue cycle metrics like clean claim rates, net collection rates, and payer performance. For document searches, look for policies, procedures, compliance requirements, and strategic planning documents.",
    "sample_questions": [
      {
        "question": "How many healthcare provider clients are growing YOY vs. shrinking in revenue?"
      },
      {
        "question": "Which payers have the highest denial rates and longest payment times?"
      },
      {
        "question": "What is our clean claim rate by provider specialty and which areas need improvement?"
      },
      {
        "question": "Show me the most common denial reason codes and their appeal success rates"
      },
      {
        "question": "Search our denial management policies for appeal procedures and timelines"
      }
    ]
  },
  "tools": [
    {
      "tool_spec": {
        "type": "cortex_analyst_text_to_sql",
        "name": "Analyze Claims Processing Data",
        "description": "Query and analyze healthcare claims processing data including provider performance, payer behavior, procedure analysis, clean claim rates, denial rates, and financial metrics. Use this for questions about claims volume, processing times, reimbursement patterns, and operational efficiency."
      },
      "semantic_model": "RCM_AI_DEMO.RCM_SCHEMA.CLAIMS_PROCESSING_VIEW"
    },
    {
      "tool_spec": {
        "type": "cortex_analyst_text_to_sql", 
        "name": "Analyze Denials and Appeals Data",
        "description": "Query and analyze denials management data including denial reasons, appeal outcomes, recovery rates, payer-specific denial patterns, and appeal success metrics. Use this for questions about denial trends, appeal effectiveness, and denial management optimization."
      },
      "semantic_model": "RCM_AI_DEMO.RCM_SCHEMA.DENIALS_MANAGEMENT_VIEW"
    },
    {
      "tool_spec": {
        "type": "cortex_search",
        "name": "Search RCM Financial Documents",
        "description": "Search financial policies, vendor contracts, expense procedures, and financial reports related to revenue cycle management. Use for questions about financial policies, contract terms, billing procedures, and financial compliance."
      },
      "cortex_search_service": "RCM_AI_DEMO.RCM_SCHEMA.RCM_FINANCE_DOCS_SEARCH"
    },
    {
      "tool_spec": {
        "type": "cortex_search",
        "name": "Search RCM Operations Documents", 
        "description": "Search operational procedures, employee handbooks, performance guidelines, and training materials for RCM operations. Use for questions about operational policies, staffing procedures, performance standards, and training requirements."
      },
      "cortex_search_service": "RCM_AI_DEMO.RCM_SCHEMA.RCM_OPERATIONS_DOCS_SEARCH"
    },
    {
      "tool_spec": {
        "type": "cortex_search",
        "name": "Search RCM Compliance Documents",
        "description": "Search compliance policies, audit procedures, regulatory requirements, and client success documentation. Use for questions about compliance requirements, audit preparation, regulatory updates, and client implementation best practices."
      },
      "cortex_search_service": "RCM_AI_DEMO.RCM_SCHEMA.RCM_COMPLIANCE_DOCS_SEARCH"
    },
    {
      "tool_spec": {
        "type": "cortex_search",
        "name": "Search RCM Strategy Documents",
        "description": "Search strategic plans, market analysis, competitive intelligence, and growth strategies for healthcare revenue cycle management. Use for questions about strategic planning, market opportunities, competitive analysis, and business development."
      },
      "cortex_search_service": "RCM_AI_DEMO.RCM_SCHEMA.RCM_STRATEGY_DOCS_SEARCH"
    },
    {
      "tool_spec": {
        "type": "cortex_search",
        "name": "Search Healthcare Knowledge Base",
        "description": "Search the comprehensive healthcare RCM knowledge base covering all document types. Use for broad questions that might span multiple areas or when you need to find information across all healthcare documentation."
      },
      "cortex_search_service": "RCM_AI_DEMO.RCM_SCHEMA.RCM_KNOWLEDGE_BASE_SEARCH"
    },
    {
      "tool_spec": {
        "type": "generic",
        "name": "Scrape Healthcare Market Data",
        "description": "Scrape healthcare industry websites for current market intelligence, payer policy updates, CMS announcements, and industry trends. Use when users need current healthcare market information or regulatory updates.",
        "input_schema": {
          "type": "object",
          "properties": {
            "weburl": {
              "description": "Healthcare website URL (must include http:// or https://) for scraping market intelligence, policy updates, or industry news.",
              "type": "string"
            }
          },
          "required": [
            "weburl"
          ]
        }
      },
      "function": "RCM_AI_DEMO.RCM_SCHEMA.SCRAPE_HEALTHCARE_DATA"
    },
    {
      "tool_spec": {
        "type": "generic",
        "name": "Generate Document Download Link",
        "description": "Generate secure download links for RCM documents and reports. Use when users need to access or download specific healthcare policy documents, reports, or procedures found through document searches.",
        "input_schema": {
          "type": "object",
          "properties": {
            "relative_file_path": {
              "description": "The relative file path from document search results. This should be the 'relative_path' value returned from Cortex Search tools.",
              "type": "string"
            },
            "expiration_minutes": {
              "description": "Number of minutes until the download link expires. Default is 60 minutes.",
              "type": "integer"
            }
          },
          "required": [
            "relative_file_path"
          ]
        }
      },
      "function": "RCM_AI_DEMO.RCM_SCHEMA.GET_RCM_DOCUMENT_URL"
    },
    {
      "tool_spec": {
        "type": "generic",
        "name": "Send RCM Alert",
        "description": "Send email alerts for critical RCM issues like high denial rates, payment delays, or compliance concerns. Use when analysis reveals issues that require immediate attention.",
        "input_schema": {
          "type": "object",
          "properties": {
            "recipient": {
              "description": "Email address of the recipient (must be verified in Snowflake)",
              "type": "string"
            },
            "subject": {
              "description": "Email subject line describing the RCM alert",
              "type": "string"
            },
            "message": {
              "description": "Detailed message about the RCM issue or finding",
              "type": "string"
            }
          },
          "required": [
            "recipient",
            "subject", 
            "message"
          ]
        }
      },
      "function": "RCM_AI_DEMO.RCM_SCHEMA.SEND_RCM_ALERT"
    }
  ],
  "cortex_search_services": [
    {
      "name": "RCM_AI_DEMO.RCM_SCHEMA.RCM_FINANCE_DOCS_SEARCH"
    },
    {
      "name": "RCM_AI_DEMO.RCM_SCHEMA.RCM_OPERATIONS_DOCS_SEARCH"
    },
    {
      "name": "RCM_AI_DEMO.RCM_SCHEMA.RCM_COMPLIANCE_DOCS_SEARCH"
    },
    {
      "name": "RCM_AI_DEMO.RCM_SCHEMA.RCM_STRATEGY_DOCS_SEARCH"
    },
    {
      "name": "RCM_AI_DEMO.RCM_SCHEMA.RCM_KNOWLEDGE_BASE_SEARCH"
    }
  ]
}
$$;

-- ========================================================================
-- AGENT VERIFICATION AND COMPLETION
-- ========================================================================

-- Show created agent
SHOW AGENTS IN SCHEMA snowflake_intelligence.agents;

-- Verify all components are in place
SELECT 'Verifying RCM Demo Components...' as verification_step;

-- Check semantic views
SELECT 'Semantic Views:' as component, COUNT(*) as count 
FROM INFORMATION_SCHEMA.SEMANTIC_VIEWS 
WHERE SEMANTIC_VIEW_SCHEMA = 'RCM_SCHEMA'
UNION ALL
-- Check search services  
SELECT 'Search Services:' as component, COUNT(*) as count
FROM INFORMATION_SCHEMA.CORTEX_SEARCH_SERVICES
WHERE SEARCH_SERVICE_SCHEMA = 'RCM_SCHEMA'
UNION ALL
-- Check tables
SELECT 'Tables:' as component, COUNT(*) as count
FROM INFORMATION_SCHEMA.TABLES 
WHERE TABLE_SCHEMA = 'RCM_SCHEMA' AND TABLE_TYPE = 'BASE TABLE'
UNION ALL
-- Check functions
SELECT 'Functions:' as component, COUNT(*) as count
FROM INFORMATION_SCHEMA.FUNCTIONS 
WHERE FUNCTION_SCHEMA = 'RCM_SCHEMA';

-- Display sample data counts for verification
SELECT 
    'Healthcare Providers' as entity, COUNT(*) as count FROM healthcare_providers_dim
UNION ALL
SELECT 
    'Payers' as entity, COUNT(*) as count FROM payers_dim  
UNION ALL
SELECT 
    'Claims' as entity, COUNT(*) as count FROM claims_fact
UNION ALL
SELECT 
    'Denials' as entity, COUNT(*) as count FROM denials_fact
UNION ALL
SELECT 
    'Documents' as entity, COUNT(*) as count FROM rcm_parsed_content;

-- Success message
SELECT 
    '🏥 RCM Healthcare AI Agent Setup Complete! 🏥' as status,
    'Agent: RCM_Healthcare_Agent' as agent_name,
    'Database: RCM_AI_DEMO' as database_name,
    'Schema: RCM_SCHEMA' as schema_name,
    'Ready for Healthcare Revenue Cycle Management Analysis!' as message;

SELECT 'RCM Agent Setup Complete - Part 4 of 4' as final_status;
