# Indonesia Parcel Logistics

**Indonesia - Last-Mile Parcel Delivery**
Use case: Hub delivery performance and disruption risk

> Delivery monitoring for a synthetic network of 30 parcel hubs across 6 Indonesian cities: dynamic tables, a holdout-evaluated disruption-risk classifier, a parcel-volume forecast and grounded AI answers.

## Why Snowflake

- **Dynamic tables** reconcile on-time delivery, failed attempts and sorter uptime from RAW hub data, with checks in `run_core.py`
- **Disruption-risk classification** gives a holdout-evaluated next-7-day disruption probability per hub
- **Parcel-volume forecast** projects 14 days of network-wide parcel volume with prediction intervals
- **Grounded AI**: the Cortex Agent (Analyst over a semantic view, plus Search over SOPs) shows its SQL and SOP citations
- **Live telemetry**: a native simulator (Snowflake only) or IoT Core, S3 and Snowpipe (AWS build), then an alert and email

## What is built

| | |
|---|---|
| Dimension table | `RAW.HUBS` (30 rows) |
| Fact table | `RAW.HUB_DAILY` (2,700 hub-days, 90 days) |
| Curated layer | `CURATED.KPI_SUMMARY`, `PERFORMANCE_SUMMARY`, `DISRUPTION_CAUSES`, `TREND_ANALYSIS` |
| ML | `ML.DISRUPTION_RISK_SCORES`, `ML.DISRUPTION_RISK_HOLDOUT_METRICS`, `ML.VOLUME_FORECAST`, `ML.DWELL_ANOMALIES` |

Cities: Jakarta, Surabaya, Bandung, Medan, Makassar, Balikpapan.
Hub types: Sortation Center, Last-Mile Depot, Port Hub, Air Cargo Hub, Cold Chain Hub.

## KPI cards (live from `CURATED.KPI_SUMMARY`; no fallback values)

| Card | Value from the seeded data |
|---|---|
| On-Time Delivery | 91.0% |
| Delivery Disruptions | 313 |
| Failed Attempts per 1k | 20.41 |
| Parcels Handled | 13,809,045 |
| Sorter Uptime | 98.3% |
| Hubs Monitored | 30 |
| Fleet Readiness | 89.6% |

Values are synthetic. A rebuild reproduces them because the data is HASH-seeded; dates are relative to the build day.

## Demo flow

1. Executive Cockpit: KPIs, daily on-time delivery, late parcels by disruption cause, hub table
2. Predictive: holdout metrics, risk bands, 14-day parcel-volume forecast, dwell-time anomalies
3. Hub Health: sorter uptime, fleet readiness, PM compliance against on-time delivery, then generate the action memo
4. Live IoT: run `CALL APP.SIMULATE_TELEMETRY(20)` (Snowflake only) or `python aws/publish_telemetry.py --count 20` (AWS build). Then run `EXECUTE ALERT APP.LIVE_ALARM_ALERT` and show the alert log and email.
5. Ask AI: the Cortex Agent answers metric questions through the semantic view and cites SOPs from Cortex Search. The SQL is shown.
6. QuickSight (AWS build): the same Snowflake tables through DIRECT_QUERY
7. Architecture: both builds side by side

## Talking points

- Per-hub on-time delivery ranges from 87.5% to 93.8%. Makassar is the lowest city, at 88.8%.
- Sorter jams make the most parcels late of the 14 disruption causes.
- The risk model is evaluated on a time-based holdout: precision 0.56 and recall 0.53 at 0.5, against a 0.41 base rate. Present it as triage, not a guarantee.
- The Jakarta flood road closure and the Makassar ferry suspension are excluded from disruption labels, because they are regional events, not hub-driven.

## Business impact

Use only the sourced references in `README.md` (Business Impact).
