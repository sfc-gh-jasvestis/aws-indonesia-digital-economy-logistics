-- ============================================================================
-- 07_SEMANTIC_VIEW.SQL — Semantic View for Last-Mile Logistics Optimization
-- ============================================================================
USE DATABASE LOGISTICS_OPTIMIZATION;
USE SCHEMA APP;

CREATE OR REPLACE SEMANTIC VIEW APP.LOGISTICS_ANALYTICS
  COMMENT = 'Last-mile delivery performance, fleet, hub capacity, and route analytics'
AS
  TABLES (
    CURATED.DELIVERY_PERFORMANCE AS delivery_performance,CURATED.HUB_CAPACITY AS hub_capacity,CURATED.ROUTE_EFFICIENCY AS route_efficiency,CURATED.DRIVER_PRODUCTIVITY AS driver_productivity
  );
