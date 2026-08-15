-- ============================================================================
-- 04_DYNAMIC_TABLES.SQL — Curated layer for Last-Mile Logistics Optimization
-- ============================================================================
USE DATABASE LOGISTICS_OPTIMIZATION;
USE SCHEMA CURATED;

-- DELIVERY_PERFORMANCE: Real-time on-time delivery rate, cost per parcel, and SLA compliance by hub
-- Source: DELIVERIES, HUBS
CREATE OR REPLACE DYNAMIC TABLE CURATED.DELIVERY_PERFORMANCE
  TARGET_LAG = '5 minutes'
  WAREHOUSE = LOGISTICS_WH
AS
SELECT * FROM RAW.DELIVERIES;
-- TODO: Replace with actual join/aggregation logic per demo

-- HUB_CAPACITY: Hub throughput vs capacity with overflow risk flags
-- Source: HUBS, DELIVERIES
CREATE OR REPLACE DYNAMIC TABLE CURATED.HUB_CAPACITY
  TARGET_LAG = '5 minutes'
  WAREHOUSE = LOGISTICS_WH
AS
SELECT * FROM RAW.HUBS;
-- TODO: Replace with actual join/aggregation logic per demo

-- ROUTE_EFFICIENCY: Route-level cost, time, and delivery density analysis
-- Source: ROUTES, DELIVERIES, FLEET
CREATE OR REPLACE DYNAMIC TABLE CURATED.ROUTE_EFFICIENCY
  TARGET_LAG = '5 minutes'
  WAREHOUSE = LOGISTICS_WH
AS
SELECT * FROM RAW.ROUTES;
-- TODO: Replace with actual join/aggregation logic per demo

-- DRIVER_PRODUCTIVITY: Driver performance scoring and shift optimization metrics
-- Source: DRIVER_PERFORMANCE, DELIVERIES
CREATE OR REPLACE DYNAMIC TABLE CURATED.DRIVER_PRODUCTIVITY
  TARGET_LAG = '5 minutes'
  WAREHOUSE = LOGISTICS_WH
AS
SELECT * FROM RAW.DRIVER_PERFORMANCE;
-- TODO: Replace with actual join/aggregation logic per demo

