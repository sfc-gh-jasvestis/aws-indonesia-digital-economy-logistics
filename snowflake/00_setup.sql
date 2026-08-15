-- ============================================================================
-- Last-Mile Logistics Optimization
-- Route optimization and delivery intelligence for Indonesia's archipelago logistics challenge — ML.FORECAST predicts delivery volumes, Dynamic Tables build real-time fleet dashboards, and Cortex AI generates route recommendations.
-- ============================================================================
USE ROLE ACCOUNTADMIN;
CREATE DATABASE IF NOT EXISTS LOGISTICS_OPTIMIZATION;
CREATE WAREHOUSE IF NOT EXISTS LOGISTICS_WH WAREHOUSE_SIZE = 'MEDIUM' AUTO_SUSPEND = 120 AUTO_RESUME = TRUE;
USE DATABASE LOGISTICS_OPTIMIZATION;
CREATE SCHEMA IF NOT EXISTS RAW;
CREATE SCHEMA IF NOT EXISTS CURATED;
CREATE SCHEMA IF NOT EXISTS ML;
CREATE SCHEMA IF NOT EXISTS AI;
CREATE SCHEMA IF NOT EXISTS SEARCH;
CREATE SCHEMA IF NOT EXISTS APP;

USE WAREHOUSE LOGISTICS_WH;
