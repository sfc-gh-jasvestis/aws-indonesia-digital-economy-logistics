-- ============================================================================
-- 11_TASK_PIPELINE.SQL — Task DAG for Last-Mile Logistics Optimization
-- ============================================================================
USE DATABASE LOGISTICS_OPTIMIZATION;
USE SCHEMA APP;

CREATE OR REPLACE TASK APP.TASK_REFRESH_DELIVERIES
  WAREHOUSE = LOGISTICS_WH
  SCHEDULE = 'USING CRON 0 */1 * * * UTC'
  COMMENT = 'Refresh delivery performance and SLA metrics'
AS
  SELECT 1; -- Replace with actual refresh logic

CREATE OR REPLACE TASK APP.TASK_FORECAST_VOLUME
  WAREHOUSE = LOGISTICS_WH
  AFTER APP.TASK_REFRESH_DELIVERIES
  COMMENT = 'Run volume forecast by hub for next 7 days'
AS
  SELECT 1; -- Replace with actual refresh logic

CREATE OR REPLACE TASK APP.TASK_OPTIMIZE_ROUTES
  WAREHOUSE = LOGISTICS_WH
  AFTER APP.TASK_FORECAST_VOLUME
  COMMENT = 'Generate route optimization recommendations'
AS
  SELECT 1; -- Replace with actual refresh logic

ALTER TASK APP.TASK_OPTIMIZE_ROUTES RESUME;
ALTER TASK APP.TASK_FORECAST_VOLUME RESUME;
ALTER TASK APP.TASK_REFRESH_DELIVERIES RESUME;
