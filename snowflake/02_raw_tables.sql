-- Synthetic hub-day observations for an Indonesian parcel network. Nothing is
-- seeded as a prediction. Randomness is HASH-seeded, so every rebuild is
-- reproducible: per-hub capacity, fleet age and disruption propensity, load from
-- weekly seasonality and a flash-sale peak, wear between preventive-maintenance
-- (PM) visits, category-weighted disruption causes, and two regional events.
USE DATABASE IDENTIFIER($DEMO_DB);
USE SCHEMA RAW;
USE WAREHOUSE IDENTIFIER($DEMO_WH);

CREATE TABLE RAW.HUBS AS
WITH hubs AS (
  SELECT ROW_NUMBER() OVER (ORDER BY SEQ4()) - 1 AS HUB_INDEX
  FROM TABLE(GENERATOR(ROWCOUNT => 30))
), draws AS (
  SELECT HUB_INDEX,
         MOD(ABS(HASH(HUB_INDEX, 'age')), 1000000) / 1e6 AS U_AGE,
         MOD(ABS(HASH(HUB_INDEX, 'rate')), 1000000) / 1e6 AS U_RATE,
         MOD(ABS(HASH(HUB_INDEX, 'pm')), 1000000) / 1e6 AS U_PM,
         MOD(ABS(HASH(HUB_INDEX, 'discipline')), 1000000) / 1e6 AS U_DISCIPLINE,
         MOD(ABS(HASH(HUB_INDEX, 'capacity')), 1000000) / 1e6 AS U_CAPACITY
  FROM hubs
)
SELECT 'HB-' || LPAD(HUB_INDEX::VARCHAR, 4, '0') AS ID,
       'Synthetic hub ' || LPAD(HUB_INDEX::VARCHAR, 4, '0') AS NAME,
       -- Deterministic spread (7 and 5 are coprime): every city and hub type is
       -- present, with Jakarta the largest region.
       CASE MOD(HUB_INDEX, 7) WHEN 0 THEN 'Jakarta' WHEN 1 THEN 'Jakarta' WHEN 2 THEN 'Surabaya'
            WHEN 3 THEN 'Bandung' WHEN 4 THEN 'Medan' WHEN 5 THEN 'Makassar'
            ELSE 'Balikpapan' END AS REGION,
       CASE MOD(HUB_INDEX, 5) WHEN 0 THEN 'Sortation Center' WHEN 1 THEN 'Last-Mile Depot'
            WHEN 2 THEN 'Port Hub' WHEN 3 THEN 'Air Cargo Hub' ELSE 'Cold Chain Hub' END AS CATEGORY,
       HUB_INDEX,
       ROUND(1 + U_AGE * 9, 1) AS AGE_YEARS,
       -- Base daily disruption probability 0.5%-3.5%; ~15% of hubs are chronic (x3).
       (0.005 + U_RATE * 0.03) * IFF(U_RATE > 0.85, 3, 1) AS BASE_DISRUPTION_RATE,
       7 * (1 + FLOOR(U_PM * 3)) AS PM_INTERVAL_DAYS,
       0.55 + U_DISCIPLINE * 0.45 AS PM_COMPLETION_PROB,
       ROUND(CASE MOD(HUB_INDEX, 5) WHEN 0 THEN 16000 WHEN 1 THEN 6000 WHEN 2 THEN 4000
                  WHEN 3 THEN 3000 ELSE 1500 END * (0.8 + U_CAPACITY * 0.4)) AS DAILY_CAPACITY,
       'Active' AS STATUS
FROM draws;

CREATE TABLE RAW.HUB_DAILY AS
WITH days AS (
  SELECT ROW_NUMBER() OVER (ORDER BY SEQ4()) - 1 AS DAY_INDEX
  FROM TABLE(GENERATOR(ROWCOUNT => 90))
), regional_events AS (
  -- Two region-wide events in the window.
  SELECT * FROM VALUES (27, 'Jakarta', 'Flood road closure', 6.0),
                       (64, 'Makassar', 'Ferry suspension (weather)', 9.0)
    AS o(DAY_INDEX, REGION, EVENT_CAUSE, HOURS)
), base AS (
  SELECT h.ID AS ENTITY_ID, h.HUB_INDEX, h.CATEGORY, h.REGION, h.AGE_YEARS,
         h.BASE_DISRUPTION_RATE, h.PM_INTERVAL_DAYS, h.PM_COMPLETION_PROB, h.DAILY_CAPACITY,
         d.DAY_INDEX,
         DATEADD('day', d.DAY_INDEX - 89, CURRENT_DATE()) AS EVENT_DATE,
         24.0 AS PLANNED_HOURS,
         MOD(d.DAY_INDEX + h.HUB_INDEX * 5, h.PM_INTERVAL_DAYS) AS DAYS_SINCE_PM,
         MOD(ABS(HASH(h.ID, d.DAY_INDEX, 'dis')), 1000000) / 1e6 AS U_DIS,
         MOD(ABS(HASH(h.ID, d.DAY_INDEX, 'down')), 1000000) / 1e6 + 1e-6 AS U_DOWN,
         MOD(ABS(HASH(h.ID, d.DAY_INDEX, 'cause')), 1000000) / 1e6 AS U_CAUSE,
         MOD(ABS(HASH(h.ID, d.DAY_INDEX, 'pmdone')), 1000000) / 1e6 AS U_PMDONE,
         MOD(ABS(HASH(h.ID, d.DAY_INDEX, 'volume')), 1000000) / 1e6 AS U_VOLUME,
         MOD(ABS(HASH(h.ID, d.DAY_INDEX, 'noise')), 1000000) / 1e6 AS U_NOISE,
         MOD(ABS(HASH(h.ID, d.DAY_INDEX, 'hit')), 1000000) / 1e6 AS U_HIT,
         e.EVENT_CAUSE, e.HOURS AS EVENT_HOURS
  FROM RAW.HUBS h CROSS JOIN days d
  LEFT JOIN regional_events e ON e.DAY_INDEX = d.DAY_INDEX AND e.REGION = h.REGION
), loaded AS (
  SELECT *,
         IFF(DAYS_SINCE_PM = 0, 1, 0) AS PM_DUE,
         IFF(DAYS_SINCE_PM = 0 AND U_PMDONE < PM_COMPLETION_PROB, 1, 0) AS PM_COMPLETED,
         -- Sorter and fleet wear rise between PM visits; weak PM discipline carries wear over.
         DAYS_SINCE_PM / PM_INTERVAL_DAYS + (1 - PM_COMPLETION_PROB) AS WEAR,
         -- Backlog stress episode: 9 of every 28 days per hub (staggered), e.g. a staffing gap.
         IFF(MOD(DAY_INDEX + HUB_INDEX * 11, 28) < 9, 1, 0) AS STRESS,
         -- Volume: weekly low day and a flash-sale peak on day 45 (+60%) easing over 3 days.
         ROUND(DAILY_CAPACITY * (0.70 + 0.25 * U_VOLUME)
               * IFF(MOD(DAY_INDEX, 7) = 6, 0.75, 1.0)
               * CASE DAY_INDEX - 45 WHEN 0 THEN 1.6 WHEN 1 THEN 1.4 WHEN 2 THEN 1.2 ELSE 1.0 END) AS PARCELS
  FROM base
), disruptions AS (
  SELECT *, PARCELS / DAILY_CAPACITY AS LOAD_RATIO,
         LEAST(0.5, BASE_DISRUPTION_RATE * (0.4 + 1.6 * WEAR) * (0.3 + PARCELS / DAILY_CAPACITY)
                    * (1 + AGE_YEARS / 20) * (1 + 2.5 * STRESS)) AS P_DIS
  FROM loaded
), counted AS (
  SELECT *,
         CASE WHEN EVENT_HOURS IS NOT NULL THEN 1
              WHEN U_DIS < P_DIS / 4 THEN 2
              WHEN U_DIS < P_DIS THEN 1
              ELSE 0 END AS DISRUPTION_COUNT
  FROM disruptions
), timed AS (
  SELECT *,
         -- Sorter or dispatch downtime: exponential, mean depends on hub type.
         CASE WHEN DISRUPTION_COUNT = 0 THEN 0.0
              WHEN EVENT_HOURS IS NOT NULL THEN EVENT_HOURS
              ELSE LEAST(20.0, ROUND(DISRUPTION_COUNT * (0.5 - LN(U_DOWN) *
                   CASE CATEGORY WHEN 'Sortation Center' THEN 3.0 WHEN 'Last-Mile Depot' THEN 2.0
                                 WHEN 'Port Hub' THEN 4.0 WHEN 'Air Cargo Hub' THEN 2.5 ELSE 3.5 END), 1))
         END AS DOWNTIME_HOURS,
         -- On-time rate: base by hub type, minus wear and overload, minus the disruption hit.
         LEAST(0.995, GREATEST(0.50,
           CASE CATEGORY WHEN 'Sortation Center' THEN 0.955 WHEN 'Last-Mile Depot' THEN 0.940
                         WHEN 'Port Hub' THEN 0.925 WHEN 'Air Cargo Hub' THEN 0.960 ELSE 0.950 END
           - 0.025 * WEAR - 0.04 * GREATEST(0, LOAD_RATIO - 0.9) - 0.006 * U_NOISE
           - DISRUPTION_COUNT * (0.08 + 0.12 * U_HIT))) AS ON_TIME_RATE
  FROM counted
)
SELECT ENTITY_ID || '-' || TO_CHAR(EVENT_DATE, 'YYYYMMDD') AS EVENT_ID,
       ENTITY_ID, EVENT_DATE, PLANNED_HOURS, DOWNTIME_HOURS,
       PLANNED_HOURS - DOWNTIME_HOURS AS OPERATING_HOURS,
       DISRUPTION_COUNT,
       CASE WHEN DISRUPTION_COUNT = 0 THEN 'None'
            WHEN EVENT_CAUSE IS NOT NULL THEN EVENT_CAUSE
            WHEN CATEGORY = 'Sortation Center' THEN IFF(U_CAUSE < 0.5, 'Sorter jam', IFF(U_CAUSE < 0.8, 'Sorting backlog', 'Staff shortage'))
            WHEN CATEGORY = 'Last-Mile Depot' THEN IFF(U_CAUSE < 0.45, 'Courier shortage', IFF(U_CAUSE < 0.75, 'Vehicle breakdown', 'Address not found'))
            WHEN CATEGORY = 'Port Hub' THEN IFF(U_CAUSE < 0.6, 'Port congestion', 'Vessel delay')
            WHEN CATEGORY = 'Air Cargo Hub' THEN IFF(U_CAUSE < 0.55, 'Flight offload', 'Customs hold')
            ELSE IFF(U_CAUSE < 0.6, 'Cold-room fault', 'Reefer truck breakdown') END AS ROOT_CAUSE,
       PM_DUE, PM_COMPLETED,
       PARCELS,
       FLOOR(PARCELS * ON_TIME_RATE) AS ON_TIME_PARCELS,
       ROUND(PARCELS / (90 + U_VOLUME * 30)) AS COURIER_ROUTES,
       ROUND(PARCELS * (0.010 + 0.008 * WEAR + 0.025 * DISRUPTION_COUNT + 0.004 * U_NOISE)) AS FAILED_ATTEMPTS,
       ROUND(3.0 + 2.5 * WEAR + 3.0 * GREATEST(0, LOAD_RATIO - 0.8) + 1.8 * STRESS + 3.5 * DISRUPTION_COUNT + U_NOISE * 0.8, 2) AS DWELL_HOURS,
       ROUND(LEAST(100, 100 * LOAD_RATIO * (0.85 + 0.1 * U_NOISE) + 7 * STRESS + 4 * DISRUPTION_COUNT), 1) AS SORTER_LOAD_PCT,
       CURRENT_TIMESTAMP() AS LOADED_AT
FROM timed;

-- Delivery fleet readiness per hub (snapshot): vehicles required versus available.
CREATE TABLE RAW.FLEET_READINESS AS
SELECT ID AS ENTITY_ID,
       CASE CATEGORY WHEN 'Sortation Center' THEN 'Line-haul truck' WHEN 'Last-Mile Depot' THEN 'Motorcycle'
                     WHEN 'Port Hub' THEN 'Container truck' WHEN 'Air Cargo Hub' THEN 'Cargo van'
                     ELSE 'Reefer truck' END AS VEHICLE_TYPE,
       10 + MOD(ABS(HASH(ID, 'req')), 31) AS REQUIRED_QTY,
       FLOOR((10 + MOD(ABS(HASH(ID, 'req')), 31)) * (0.70 + MOD(ABS(HASH(ID, 'avail')), 1000) / 1000 * 0.35)) AS ON_HAND_QTY,
       MOD(ABS(HASH(ID, 'order')), 4) AS ON_ORDER_QTY,
       CURRENT_DATE() AS SNAPSHOT_DATE
FROM RAW.HUBS;
