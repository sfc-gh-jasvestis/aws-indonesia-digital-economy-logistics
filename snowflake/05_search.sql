-- ============================================================================
-- 05_SEARCH.SQL — Cortex Search for Last-Mile Logistics Optimization
-- ============================================================================
USE DATABASE LOGISTICS_OPTIMIZATION;
USE SCHEMA SEARCH;

CREATE OR REPLACE CORTEX SEARCH SERVICE SEARCH.LOGISTICS_DOCS_SEARCH
  ON CONTENT
  ATTRIBUTES DOC_TYPE, REGION, TRANSPORT_MODE
  WAREHOUSE = LOGISTICS_WH
  TARGET_LAG = '1 hour'
AS (
  SELECT * FROM RAW.LOGISTICS_DOCS
);
