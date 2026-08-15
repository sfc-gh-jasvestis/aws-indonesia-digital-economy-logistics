-- ============================================================================
-- 08_AGENT.SQL — Cortex Agent for Last-Mile Logistics Optimization
-- ============================================================================
USE DATABASE LOGISTICS_OPTIMIZATION;
USE SCHEMA APP;

CREATE OR REPLACE CORTEX AGENT APP.LOGISTICS_INTELLIGENCE_AGENT
  COMMENT = 'Last-Mile Logistics Optimization AI Assistant'
  MODEL = 'claude-opus-4-8'
  TOOLS = (
    SEMANTIC_VIEW_TOOL(SEMANTIC_VIEW => 'LOGISTICS_OPTIMIZATION.APP.LOGISTICS_ANALYTICS'),    CORTEX_SEARCH_TOOL(CORTEX_SEARCH_SERVICE => 'LOGISTICS_OPTIMIZATION.SEARCH.LOGISTICS_DOCS_SEARCH', TOOL_DESCRIPTION => 'Search documents for Digital Economy & E-Commerce information')
  )
  SYSTEM_PROMPT = 'You are the Logistics Intelligence Agent for Indonesia''s largest e-commerce logistics network, managing 500 hubs, 15,000 vehicles, and 30 million deliveries per month across 17,000 islands.';
