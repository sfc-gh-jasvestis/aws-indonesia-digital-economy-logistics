-- ============================================================================
-- 06_INTELLIGENCE.SQL - search, anomaly detection, semantic view, agent,
-- live-telemetry alert and on-demand refresh DAG.
-- Run with snowflake/run_intelligence.py (substitutes checked __DEMO_DB__ /
-- __DEMO_WH__ / __ALERT_EMAIL__). Requires 00-05, plus 08 (Snowflake only) or
-- aws/setup_aws.py (AWS build) for RAW.LIVE_TELEMETRY.
-- Alerts and tasks are created SUSPENDED; run them with EXECUTE ALERT / EXECUTE TASK.
-- ============================================================================
USE DATABASE __DEMO_DB__;
CREATE SCHEMA IF NOT EXISTS SEARCH;
CREATE SCHEMA IF NOT EXISTS APP;

-- ---------- Synthetic hub-operations knowledge base (clearly synthetic SOPs) ----------
CREATE OR REPLACE TABLE SEARCH.HUB_SOP_DOCS AS
WITH causes AS (
  SELECT DISTINCT r.ROOT_CAUSE, h.CATEGORY
  FROM RAW.HUB_DAILY r JOIN RAW.HUBS h ON h.ID = r.ENTITY_ID
  WHERE r.ROOT_CAUSE IS NOT NULL AND r.DISRUPTION_COUNT > 0
)
SELECT
  'SOP-' || LPAD(ROW_NUMBER() OVER (ORDER BY CATEGORY, ROOT_CAUSE)::VARCHAR, 3, '0') AS DOC_ID,
  'SOP' AS DOC_TYPE,
  CATEGORY,
  ROOT_CAUSE,
  CATEGORY || ' - ' || ROOT_CAUSE || ' disruption response' AS TITLE,
  'Synthetic demo SOP. Hub type: ' || CATEGORY || '. Disruption cause: ' || ROOT_CAUSE || '. '
  || 'Step 1: notify the hub duty manager, flag affected parcels in the transport management system and warn downstream hubs. '
  || 'Step 2: ' || CASE
       WHEN ROOT_CAUSE ILIKE '%sorter%' OR ROOT_CAUSE ILIKE '%sorting%' THEN 'switch the affected lanes to manual sortation, clear the jam or backlog by oldest promise date first, and call the sorter maintenance contractor.'
       WHEN ROOT_CAUSE ILIKE '%staff%' OR ROOT_CAUSE ILIKE '%courier%' THEN 'call in the standby shift, rebalance couriers from the nearest under-loaded depot and cap new pickups until the backlog clears.'
       WHEN ROOT_CAUSE ILIKE '%vehicle%' OR ROOT_CAUSE ILIKE '%reefer truck%' THEN 'dispatch a replacement vehicle from the readiness pool, transfer parcels, and book the vehicle for inspection before reuse.'
       WHEN ROOT_CAUSE ILIKE '%address%' THEN 'contact the recipient through the app, confirm a landmark or pin location, and schedule a second attempt within 24 hours.'
       WHEN ROOT_CAUSE ILIKE '%port%' OR ROOT_CAUSE ILIKE '%vessel%' OR ROOT_CAUSE ILIKE '%ferry%' THEN 'rebook inter-island cargo on the next sailing, prioritise time-definite parcels and send a revised delivery date to customers.'
       WHEN ROOT_CAUSE ILIKE '%flight%' OR ROOT_CAUSE ILIKE '%customs%' THEN 'rebook offloaded cargo on the next flight, supply missing customs documents and escalate holds older than 24 hours.'
       WHEN ROOT_CAUSE ILIKE '%cold%' THEN 'move temperature-sensitive stock to the backup cold room, log temperatures every 30 minutes and quarantine anything out of range.'
       WHEN ROOT_CAUSE ILIKE '%flood%' THEN 'reroute couriers around closed roads, pause motorcycle deliveries in flooded zones and hold parcels safely at the hub.'
       ELSE 'record the issue, contain affected parcels and escalate to the regional operations lead.'
     END
  || ' Step 3: if parcel dwell time exceeds 8 hours or sorter load exceeds 92% after recovery, keep the hub on the watch list and divert new volume. '
  || 'Step 4: confirm recovery of on-time performance and record the root cause in the operations log.' AS CONTENT
FROM causes;

CREATE OR REPLACE CORTEX SEARCH SERVICE SEARCH.HUB_SOP_SEARCH
  ON CONTENT
  ATTRIBUTES CATEGORY, ROOT_CAUSE
  WAREHOUSE = __DEMO_WH__
  TARGET_LAG = '7 days'
AS (SELECT DOC_ID, TITLE, CATEGORY, ROOT_CAUSE, CONTENT FROM SEARCH.HUB_SOP_DOCS);

-- ---------- Parcel dwell-time anomaly detection (train first 75 days, detect last 15) ----------
CREATE OR REPLACE VIEW ML.DWELL_SERIES AS
SELECT ENTITY_ID, EVENT_DATE::TIMESTAMP_NTZ AS TS, DWELL_HOURS::FLOAT AS DWELL
FROM RAW.HUB_DAILY;
CREATE OR REPLACE VIEW ML.DWELL_TRAIN AS
SELECT * FROM ML.DWELL_SERIES WHERE TS < (SELECT DATEADD(day, -15, MAX(TS)) FROM ML.DWELL_SERIES);
CREATE OR REPLACE VIEW ML.DWELL_DETECT AS
SELECT * FROM ML.DWELL_SERIES WHERE TS >= (SELECT DATEADD(day, -15, MAX(TS)) FROM ML.DWELL_SERIES);

CREATE OR REPLACE SNOWFLAKE.ML.ANOMALY_DETECTION ML.DWELL_ANOMALY_MODEL(
  INPUT_DATA => SYSTEM$REFERENCE('VIEW', 'ML.DWELL_TRAIN'),
  SERIES_COLNAME => 'ENTITY_ID', TIMESTAMP_COLNAME => 'TS', TARGET_COLNAME => 'DWELL',
  LABEL_COLNAME => '');

CREATE OR REPLACE TABLE ML.DWELL_ANOMALIES AS
SELECT SERIES::VARCHAR AS ENTITY_ID, TS::DATE AS EVENT_DATE, Y AS DWELL, FORECAST AS EXPECTED,
       LOWER_BOUND, UPPER_BOUND, IS_ANOMALY, PERCENTILE
FROM TABLE(ML.DWELL_ANOMALY_MODEL!DETECT_ANOMALIES(
  INPUT_DATA => SYSTEM$REFERENCE('VIEW', 'ML.DWELL_DETECT'),
  SERIES_COLNAME => 'ENTITY_ID', TIMESTAMP_COLNAME => 'TS', TARGET_COLNAME => 'DWELL'));

-- ---------- Semantic view ----------
CREATE OR REPLACE SEMANTIC VIEW APP.LOGISTICS_ANALYTICS
  TABLES (
    hubs AS CURATED.PERFORMANCE_SUMMARY PRIMARY KEY (ENTITY_ID)
      WITH SYNONYMS = ('entities', 'hubs', 'depots', 'sites')
      COMMENT = 'One row per delivery hub (entity), 90-day totals',
    risk AS ML.DISRUPTION_RISK_SCORES PRIMARY KEY (ENTITY_ID)
      COMMENT = 'Latest next-7-day delivery disruption probability per hub',
    causes AS CURATED.DISRUPTION_CAUSES PRIMARY KEY (ROOT_CAUSE)
      COMMENT = 'Delivery disruptions by root cause, 90 days',
    daily AS CURATED.TREND_ANALYSIS PRIMARY KEY (METRIC_DATE)
      COMMENT = 'Network-wide totals per day'
  )
  RELATIONSHIPS (risk_hub AS risk (ENTITY_ID) REFERENCES hubs)
  FACTS (
    hubs.on_time_parcels_f AS ON_TIME_PARCELS,
    hubs.parcels_f AS PARCELS,
    hubs.routes_f AS COURIER_ROUTES,
    hubs.failed_f AS FAILED_ATTEMPTS,
    hubs.disruptions_f AS DISRUPTION_COUNT,
    hubs.downtime_hours_f AS DOWNTIME_HOURS,
    hubs.operating_hours_f AS OPERATING_HOURS,
    hubs.planned_hours_f AS PLANNED_HOURS,
    risk.disruption_prob_f AS DISRUPTION_PROB_7D,
    causes.cause_disruptions_f AS DISRUPTION_COUNT,
    causes.cause_late_parcels_f AS LATE_PARCELS,
    causes.cause_hours_f AS DOWNTIME_HOURS,
    daily.day_on_time_f AS ON_TIME_PARCELS,
    daily.day_parcels_f AS PARCELS,
    daily.day_disruptions_f AS DISRUPTION_COUNT
  )
  DIMENSIONS (
    hubs.hub_id AS ENTITY_ID WITH SYNONYMS = ('hub', 'entity', 'entity id', 'depot id'),
    hubs.hub_name AS ENTITY_NAME,
    hubs.city AS REGION WITH SYNONYMS = ('city', 'region', 'island') COMMENT = 'Indonesian city',
    hubs.hub_type AS CATEGORY WITH SYNONYMS = ('hub type', 'facility type', 'category'),
    risk.risk_band AS RISK_BAND COMMENT = 'High >= 0.5, Medium >= 0.25, else Low',
    risk.scored_as_of AS SCORED_AS_OF,
    causes.root_cause AS ROOT_CAUSE,
    daily.metric_date AS METRIC_DATE
  )
  METRICS (
    hubs.hub_count AS COUNT(hubs.hub_id) WITH SYNONYMS = ('number of entities', 'entity count', 'number of hubs'),
    hubs.on_time_delivery_pct AS 100 * SUM(hubs.on_time_parcels_f) / NULLIF(SUM(hubs.parcels_f), 0)
      WITH SYNONYMS = ('OTD', 'on-time rate') COMMENT = 'On-time parcels / parcels',
    hubs.total_disruptions AS SUM(hubs.disruptions_f) WITH SYNONYMS = ('disruptions', 'delivery disruptions'),
    hubs.failed_attempts_per_1k AS 1000 * SUM(hubs.failed_f) / NULLIF(SUM(hubs.parcels_f), 0),
    hubs.total_parcels AS SUM(hubs.parcels_f) WITH SYNONYMS = ('volume', 'parcel volume'),
    hubs.total_courier_routes AS SUM(hubs.routes_f),
    hubs.sorter_uptime_pct AS 100 * SUM(hubs.operating_hours_f) / NULLIF(SUM(hubs.planned_hours_f), 0),
    hubs.total_downtime_hours AS SUM(hubs.downtime_hours_f),
    risk.avg_disruption_prob AS AVG(risk.disruption_prob_f),
    causes.cause_disruptions AS SUM(causes.cause_disruptions_f),
    causes.cause_late_parcels AS SUM(causes.cause_late_parcels_f),
    causes.cause_downtime_hours AS SUM(causes.cause_hours_f),
    daily.daily_on_time_pct AS 100 * SUM(daily.day_on_time_f) / NULLIF(SUM(daily.day_parcels_f), 0),
    daily.daily_parcels AS SUM(daily.day_parcels_f),
    daily.daily_disruptions AS SUM(daily.day_disruptions_f)
  )
  COMMENT = 'Synthetic Indonesia parcel-network analytics (demo)';

-- ---------- Cortex Agent ----------
CREATE OR REPLACE AGENT APP.LOGISTICS_AGENT
  COMMENT = 'Logistics assistant over a synthetic Indonesian parcel hub network'
  FROM SPECIFICATION
$$
models:
  orchestration: claude-sonnet-4-5
instructions:
  response: "Answer only from tool results. State that data is synthetic. Give hub IDs and numbers with units."
  orchestration: "Use logistics_analyst for on-time delivery, disruptions, failed attempts, parcel volume, hubs, cities, risk and root causes. Use sop_search for disruption response procedures."
tools:
  - tool_spec:
      type: cortex_analyst_text_to_sql
      name: logistics_analyst
      description: "On-time delivery, delivery disruptions, failed attempts per 1,000 parcels, parcel volume, sorter uptime, root causes and disruption-risk scores per hub"
  - tool_spec:
      type: cortex_search
      name: sop_search
      description: "Synthetic disruption-response SOPs by hub type and cause"
tool_resources:
  logistics_analyst:
    semantic_view: __DEMO_DB__.APP.LOGISTICS_ANALYTICS
    execution_environment:
      type: warehouse
      warehouse: __DEMO_WH__
  sop_search:
    name: __DEMO_DB__.SEARCH.HUB_SOP_SEARCH
    max_results: 3
    id_column: DOC_ID
    title_column: TITLE
$$;

-- ---------- Live-telemetry alert ----------
CREATE TABLE IF NOT EXISTS APP.ALERT_LOG (
  ALERTED_AT TIMESTAMP_LTZ DEFAULT CURRENT_TIMESTAMP(), HUB_ID VARCHAR,
  EVENT_TS TIMESTAMP_NTZ, DWELL_HOURS FLOAT, SORTER_LOAD_PCT FLOAT, SOP_HINT VARCHAR);

CREATE OR REPLACE NOTIFICATION INTEGRATION ID_LOGISTICS_EMAIL_INT
  TYPE = EMAIL ENABLED = TRUE ALLOWED_RECIPIENTS = ('__ALERT_EMAIL__');

CREATE OR REPLACE PROCEDURE APP.LOG_LIVE_ALARMS()
RETURNS NUMBER
LANGUAGE SQL
EXECUTE AS OWNER
AS
$$
DECLARE
  n NUMBER;
BEGIN
  INSERT INTO APP.ALERT_LOG (HUB_ID, EVENT_TS, DWELL_HOURS, SORTER_LOAD_PCT, SOP_HINT)
    SELECT t.HUB_ID, t.EVENT_TS, t.DWELL_HOURS, t.SORTER_LOAD_PCT,
           'Check ' || h.CATEGORY || ' SOPs; current risk band ' || COALESCE(r.RISK_BAND, 'n/a')
    FROM RAW.LIVE_TELEMETRY t
    JOIN RAW.HUBS h ON h.ID = t.HUB_ID
    LEFT JOIN ML.DISRUPTION_RISK_SCORES r ON r.ENTITY_ID = t.HUB_ID
    WHERE t.STATUS = 'ALARM'
      AND NOT EXISTS (SELECT 1 FROM APP.ALERT_LOG l WHERE l.HUB_ID = t.HUB_ID AND l.EVENT_TS = t.EVENT_TS);
  n := SQLROWCOUNT;
  IF (n > 0) THEN
    CALL SYSTEM$SEND_EMAIL('ID_LOGISTICS_EMAIL_INT', '__ALERT_EMAIL__',
      '[Demo] Indonesia hub telemetry alarm',
      'New live-telemetry alarms logged in APP.ALERT_LOG: ' || :n || '. Data is synthetic.');
  END IF;
  RETURN n;
END;
$$;

CREATE OR REPLACE ALERT APP.LIVE_ALARM_ALERT
  WAREHOUSE = __DEMO_WH__
  SCHEDULE = '5 MINUTE'
  IF (EXISTS (
    SELECT 1 FROM RAW.LIVE_TELEMETRY t
    WHERE t.STATUS = 'ALARM'
      AND NOT EXISTS (SELECT 1 FROM APP.ALERT_LOG l WHERE l.HUB_ID = t.HUB_ID AND l.EVENT_TS = t.EVENT_TS)))
  THEN CALL APP.LOG_LIVE_ALARMS();

-- ---------- On-demand refresh DAG (suspended; run with EXECUTE TASK APP.TASK_REFRESH_CURATED) ----------
CREATE OR REPLACE PROCEDURE APP.REFRESH_CURATED()
RETURNS VARCHAR
LANGUAGE SQL
EXECUTE AS OWNER
AS
$$
BEGIN
  ALTER DYNAMIC TABLE CURATED.PERFORMANCE_SUMMARY REFRESH;
  ALTER DYNAMIC TABLE CURATED.TREND_ANALYSIS REFRESH;
  ALTER DYNAMIC TABLE CURATED.DISRUPTION_CAUSES REFRESH;
  ALTER DYNAMIC TABLE CURATED.KPI_SUMMARY REFRESH;
  RETURN 'refreshed';
END;
$$;

CREATE OR REPLACE TASK APP.TASK_REFRESH_CURATED
  WAREHOUSE = __DEMO_WH__
AS
  CALL APP.REFRESH_CURATED();

CREATE OR REPLACE TASK APP.TASK_RESCORE_RISK
  WAREHOUSE = __DEMO_WH__
  AFTER APP.TASK_REFRESH_CURATED
AS
  CREATE OR REPLACE TABLE ML.DISRUPTION_RISK_SCORES COPY GRANTS AS
  WITH latest AS (
    SELECT * FROM ML.DISRUPTION_FEATURES QUALIFY ROW_NUMBER() OVER (PARTITION BY ENTITY_ID ORDER BY EVENT_DATE DESC) = 1
  ), p AS (
    SELECT ENTITY_ID, EVENT_DATE,
           ML.DISRUPTION_RISK_MODEL!PREDICT(INPUT_DATA => OBJECT_CONSTRUCT(
             'CATEGORY', CATEGORY, 'AGE_YEARS', AGE_YEARS, 'DWELL_HOURS', DWELL_HOURS,
             'SORTER_LOAD_PCT', SORTER_LOAD_PCT, 'DWELL_7D', DWELL_7D, 'DISRUPTIONS_30D', DISRUPTIONS_30D)) AS PRED
    FROM latest
  )
  SELECT ENTITY_ID, EVENT_DATE AS SCORED_AS_OF, ROUND(PRED:probability:DISRUPTION::FLOAT, 4) AS DISRUPTION_PROB_7D,
         CASE WHEN PRED:probability:DISRUPTION::FLOAT >= 0.5 THEN 'High'
              WHEN PRED:probability:DISRUPTION::FLOAT >= 0.25 THEN 'Medium' ELSE 'Low' END AS RISK_BAND,
         CURRENT_TIMESTAMP() AS SCORED_AT
  FROM p;
