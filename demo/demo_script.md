# Demo Script: Last-Mile Logistics Optimization
## ~4-Minute Recorded Walkthrough
**Format**: Screen recording with voiceover
**Target**: Customer meeting / booth loop / social share
**Narrative**: "Snowflake optimizes last-mile delivery across 17,000 islands — Dynamic Tables maintain real-time fleet visibility, ML.FORECAST projects volume by hub, and Cortex AI generates route optimization recommendations for Indonesia's unique archipelago geography"
**Demo Mode**: Open app with `?demo=true` for presenter notes

---

## Two Personas

| Persona | Role | Tool | What they care about |
|---|---|---|---|
| **Rudi Hartanto** | VP Logistics Operations | React App (SPCS) | On-time delivery rate, cost per parcel, fleet utilization, inter-island logistics costs |
| **Devi Anggraeni** | Network Planning Analyst | Amazon QuickSight | Hub capacity planning, route efficiency, driver productivity, seasonal surge preparation |

---

## What's Built

| Layer | Component | Detail |
|---|---|---|
| **RAW** | 6 tables | DELIVERIES (30000000), HUBS (500), FLEET (15000), ROUTES (50000), DRIVER_PERFORMANCE (200000), LOGISTICS_DOCS (80) |
| **CURATED** | 4 Dynamic Tables | DELIVERY_PERFORMANCE, HUB_CAPACITY, ROUTE_EFFICIENCY, DRIVER_PRODUCTIVITY |
| **ML** | ML.FORECAST | Forecasting + anomaly detection |
| **AI** | COMPLETE, AI_CLASSIFY, SUMMARIZE | Classification + extraction |
| **Search** | Cortex Search | 80 documents indexed |
| **Agent** | LOGISTICS_INTELLIGENCE_AGENT | Semantic View + Search tools |


---

## The Story

Indonesia's 17,000-island archipelago creates the world's most complex last-mile logistics challenge. With 30 million monthly deliveries, on-time rates below target, and Harbolnas (12.12) projected to spike volumes 60%, the VP Logistics needs real-time fleet visibility and ML-powered demand planning — not reactive spreadsheet management after SLA breaches.

---

## Script

### [0:00–0:45] OPERATIONS OVERVIEW

**Show**: Operations Overview tab

> "30 million deliveries per month across 500 hubs and 17,000 islands."

**Action**: Point at 30M deliveries and 91.3% OTD rate

### [0:45–1:30] ROUTE ANALYTICS

**Show**: Route Analytics tab

> "50,000 routes analyzed — inter-island routes 3.2x more expensive per parcel."

**Action**: Show cost per parcel by region map

### [1:30–2:15] DEMAND PLANNING

**Show**: Demand Planning tab

> "ML.FORECAST projects 48M deliveries during Harbolnas week — 60% above baseline."

**Action**: Show volume forecast chart with Harbolnas spike

### [2:15–3:00] ASK AI

**Show**: Ask AI tab

> "Rudi asks: 'What's our on-time delivery rate this week?'"

**Action**: Type delivery rate question

### [3:00–3:45] ARCHITECTURE & DATA

**Show**: Architecture & Data tab

> "Six Snowflake capabilities, six AWS services."

**Action**: Walk through architecture diagram


---

## Key Demo Differentiators

1. **ML.FORECAST for hub volume prediction** — Only demo using ML.FORECAST for last-mile delivery volume forecasting at archipelago scale
2. **AI route optimization recommendations** — Cortex AI generates consolidation and rebalancing plans across 50,000 routes
3. **Inter-island logistics cost analysis** — Unique to Indonesian archipelago — 3.2x cost premium for inter-island delivery
4. **Indonesian e-logistics context** — 17,000 islands, 500 hubs, Harbolnas surge planning, motorcycle last-mile


---

## Demo Prep Checklist

### Data Verification
- [ ] `SELECT COUNT(*) FROM LOGISTICS_OPTIMIZATION.RAW.DELIVERIES` → 30000000
- [ ] `SELECT COUNT(*) FROM LOGISTICS_OPTIMIZATION.RAW.HUBS` → 500
- [ ] `SELECT COUNT(*) FROM LOGISTICS_OPTIMIZATION.RAW.FLEET` → 15000

### ML Model Verification
- [ ] `SELECT COUNT(*) FROM LOGISTICS_OPTIMIZATION.ML.VOLUME_FORECAST_RESULTS` → >0

### AI/Agent Verification
- [ ] `SELECT COUNT(*) FROM LOGISTICS_OPTIMIZATION.AI.DELIVERY_FAILURE_CLASSIFICATION` → >0

