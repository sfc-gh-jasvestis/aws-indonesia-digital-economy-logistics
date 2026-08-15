-- ============================================================================
-- 03_STAGING.SQL — Generate synthetic data for Last-Mile Logistics Optimization
-- Country: INDONESIA | Currency: IDR
-- ============================================================================
USE DATABASE LOGISTICS_OPTIMIZATION;
USE SCHEMA RAW;

-- Data generation scripts are demo-specific.
-- See the handcrafted SQL in the aws-malaysia-semiconductor-yield demo for
-- the full pattern: GENERATOR + UNIFORM + LATERAL for distribution,
-- Cortex Complete for text generation, engineered key demo numbers.

-- Target row counts:
-- DELIVERIES: 30,000,000 rows — 12 months of parcel delivery records with timestamps, routes, and outcomes
-- HUBS: 500 rows — Distribution hubs and sortation centers with capacity and throughput
-- FLEET: 15,000 rows — Delivery fleet (motorcycles, vans, trucks) with location and status
-- ROUTES: 50,000 rows — Delivery route definitions with distance, time, and cost per segment
-- DRIVER_PERFORMANCE: 200,000 rows — Driver productivity metrics: deliveries per shift, completion rate, ratings
-- LOGISTICS_DOCS: 80 rows — SOP documents, route planning guides, and inter-island logistics protocols
