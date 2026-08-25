-- ============================================================================
-- 10_ALERTS_NOTIFICATIONS.SQL — Alerts for Last-Mile Logistics Optimization
-- ============================================================================
USE DATABASE LOGISTICS_OPTIMIZATION;
USE SCHEMA APP;

-- Notification integration (email)
CREATE OR REPLACE NOTIFICATION INTEGRATION aws_indonesia_digital_economy_logistics_EMAIL_INT
  TYPE = EMAIL
  ENABLED = TRUE
  ALLOWED_RECIPIENTS = ('<YOUR_EMAIL>');

-- Alert: SLA_BREACH_ALERT
CREATE OR REPLACE ALERT APP.SLA_BREACH_ALERT
  WAREHOUSE = LOGISTICS_WH
  SCHEDULE = '5 MINUTE'
  COMMENT = 'Delivery SLA breach at hub — investigate capacity and routing'
IF (EXISTS (
  SELECT 1 FROM CURATED.DELIVERY_PERFORMANCE
  WHERE 1=1 -- Condition: On-time delivery drops below 90% for any hub
))
THEN
  CALL SYSTEM$SEND_EMAIL(
    'aws_indonesia_digital_economy_logistics_EMAIL_INT',
    '<YOUR_EMAIL>',
    '[ALERT] Last-Mile Logistics Optimization: Delivery SLA breach at hub — investigate capacity and routing',
    'Delivery SLA breach at hub — investigate capacity and routing'
  );

ALTER ALERT APP.SLA_BREACH_ALERT RESUME;

-- Alert: HUB_OVERFLOW_ALERT
CREATE OR REPLACE ALERT APP.HUB_OVERFLOW_ALERT
  WAREHOUSE = LOGISTICS_WH
  SCHEDULE = '5 MINUTE'
  COMMENT = 'Hub approaching overflow — volume rerouting needed'
IF (EXISTS (
  SELECT 1 FROM CURATED.DELIVERY_PERFORMANCE
  WHERE 1=1 -- Condition: Hub throughput exceeds 95% capacity for 3 consecutive days
))
THEN
  CALL SYSTEM$SEND_EMAIL(
    'aws_indonesia_digital_economy_logistics_EMAIL_INT',
    '<YOUR_EMAIL>',
    '[ALERT] Last-Mile Logistics Optimization: Hub approaching overflow — volume rerouting needed',
    'Hub approaching overflow — volume rerouting needed'
  );

ALTER ALERT APP.HUB_OVERFLOW_ALERT RESUME;

