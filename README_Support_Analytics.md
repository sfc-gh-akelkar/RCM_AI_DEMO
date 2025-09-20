# Support Analytics Add-on for RCM AI Demo

This add-on extends the RCM AI demo with customer support ticket analytics capabilities, enabling analysis of which product areas generate the most support tickets and related metrics.

## 📋 **Installation Instructions**

### **Step 1: Run the Support Ticket Setup**
```sql
-- Execute this script in Snowflake after running the main demo_setup.sql
/sql_scripts/support_ticket_setup.sql
```

### **Step 2: Create the Semantic View**
```sql
-- Execute this script to create the semantic view for support analytics
/sql_scripts/support_semantic_view.sql
```

### **Step 3: Add to Snowflake Intelligence Agent**
1. Open your Snowflake Intelligence Agent configuration
2. Add the tool configuration from `agent_configuration_support.json`
3. Update agent instructions to include support analytics capabilities

## 🎯 **What This Add-on Enables**

### **Key Questions You Can Now Answer:**
1. **"Which product areas generate the most customer support tickets?"**
2. **"What's the average resolution time by product area?"**
3. **"Which client types submit the most support tickets?"**
4. **"Are support tickets increasing or decreasing over time?"**
5. **"What's our customer satisfaction score by support team?"**
6. **"Which features have the most bugs reported?"**
7. **"How many critical tickets are still open?"**
8. **"What's the escalation rate by product area?"**

## 📊 **Data Structure Created**

### **Tables Added:**
- **`support_tickets_fact`**: 750 sample support tickets across 12 months
- **`support_categories_dim`**: 10 support ticket categories
- **`support_teams_dim`**: 6 support team configurations

### **Product Areas Tracked:**
- Claims Processing
- Denial Management  
- Reporting & Analytics
- Patient Collections
- User Management
- System Integration
- Mobile App
- API Services

### **Metrics Available:**
- **Volume**: Total tickets, open tickets, resolved tickets
- **Performance**: Average resolution time, first response time
- **Quality**: Customer satisfaction scores, escalation rates
- **Trends**: Monthly patterns, seasonal variations

## 🔧 **Sample Data Generated**

### **Ticket Distribution:**
- **Claims Processing**: ~35% of tickets (highest volume)
- **Denial Management**: ~22% of tickets
- **Reporting & Analytics**: ~18% of tickets
- **Other Areas**: ~25% of tickets

### **Severity Levels:**
- **Critical**: ~10% (avg 4-8 hour resolution)
- **High**: ~25% (avg 12-24 hour resolution)
- **Medium**: ~45% (avg 24-48 hour resolution)
- **Low**: ~20% (avg 2-72 hour resolution)

### **Client Type Patterns:**
- **Hospitals**: Higher volume, more complex issues
- **Physician Groups**: Moderate volume, training-focused
- **DMEs**: Lower volume, configuration-heavy
- **Labs**: Specialized integration issues
- **Medical Billing**: Workflow and reporting questions

## 🎭 **Demo Scenarios**

### **Product Quality Analysis:**
*"Our Claims Processing module has the highest ticket volume at 35%, but also the fastest average resolution time at 8.2 hours. This suggests high usage rather than quality issues."*

### **Client Segmentation Insights:**
*"Hospitals generate 40% of our support tickets but have a 4.2/5 satisfaction score, indicating complex needs but good support quality."*

### **Operational Optimization:**
*"Level 1 Support resolves 65% of tickets without escalation, but training requests could be reduced through better documentation."*

### **Feature Development Priorities:**
*"Custom Reports feature generates 23% of all feature requests, indicating strong demand for enhanced reporting capabilities."*

## 🔄 **Integration with Existing Demo**

### **Enhances These Demo Sections:**
- **Section 4: Product Analysis & Feature Performance** - Now includes support ticket correlation
- **Section 5: Client Health & Retention Analytics** - Adds support satisfaction as health indicator
- **Section 6: Operational Excellence** - Includes support team productivity metrics

### **Cross-Analysis Opportunities:**
- **Feature Usage vs Support Tickets**: Correlate low usage with high support volume
- **Client Performance vs Support Needs**: Identify if struggling clients need more support
- **Product Roadmap Planning**: Prioritize features based on support ticket trends

## ⚡ **Quick Verification**

After installation, test with these queries:

```sql
-- Verify ticket data
SELECT product_area, COUNT(*) as ticket_count
FROM support_tickets_fact 
GROUP BY product_area 
ORDER BY ticket_count DESC;

-- Test semantic view
SELECT 'Support Analytics Ready!' as status;
SHOW SEMANTIC VIEWS LIKE 'SUPPORT_ANALYTICS_VIEW';
```

## 🚀 **Removal Instructions**

If you want to remove this add-on:

```sql
-- Remove the tables
DROP TABLE IF EXISTS support_tickets_fact;
DROP TABLE IF EXISTS support_categories_dim;
DROP TABLE IF EXISTS support_teams_dim;

-- Remove the semantic view
DROP SEMANTIC VIEW IF EXISTS support_analytics_view;
```

## 📈 **Expected Demo Impact**

This add-on transforms the RCM demo from purely operational analytics to include **customer experience and product quality insights**, making it more compelling for:

- **Product teams** interested in feature performance and quality
- **Customer success teams** focused on client satisfaction and support efficiency
- **Executive audiences** wanting comprehensive business intelligence including customer health

The support analytics seamlessly integrate with existing RCM metrics to provide a complete picture of both operational performance and customer experience.
