# Last-Mile Logistics Optimization

**Indonesia - Digital Economy & E-Commerce**
Use case: Last-Mile Logistics

> Route optimization and delivery intelligence for Indonesia's archipelago logistics challenge — ML.FORECAST predicts delivery volumes, Dynamic Tables build real-time fleet dashboards, and Cortex AI generates route recommendations.

## Why Snowflake

Snowflake optimizes last-mile delivery across 17,000 islands — Dynamic Tables maintain real-time fleet visibility, ML.FORECAST projects volume by hub, and Cortex AI generates route optimization recommendations for Indonesia's unique archipelago geography

- **ML.FORECAST for hub volume prediction** - Only demo using ML.FORECAST for last-mile delivery volume forecasting at archipelago scale
- **AI route optimization recommendations** - Cortex AI generates consolidation and rebalancing plans across 50,000 routes
- **Inter-island logistics cost analysis** - Unique to Indonesian archipelago — 3.2x cost premium for inter-island delivery
- **Indonesian e-logistics context** - 17,000 islands, 500 hubs, Harbolnas surge planning, motorcycle last-mile

## What is deployed

| | |
|---|---|
| Database | `ID_DIGITAL_ECONOMY_LOGISTICS` |
| Service | `ID_DIGITAL_ECONOMY_LOGISTICS_APP` |
| Compute pool | `SEA_DEMOS_INDONESIA_POOL` |
| Dimension table | `RAW.LOGISTICS_DOCS` (20 rows) |
| Fact table | `RAW.DELIVERIES` (250,000 rows, 90 days) |
| Curated layer | `CURATED.PERFORMANCE_SUMMARY`, `CURATED.TREND_ANALYSIS`, `CURATED.KPI_SUMMARY` |
| Currency | IDR (Rp) |

Regions in play: Jakarta, North Sumatra, Riau, East Kalimantan, Sulawesi
Segments: Instant, Same Day, Next Day, Regular Cargo

Dynamic tables are created suspended and refreshed on demand:

```bash
./refresh_demo_data.sh ID_DIGITAL_ECONOMY_LOGISTICS
```

## KPI cards

Every card below is served live from `CURATED.KPI_SUMMARY`. The app keeps the
original literal as a fallback, so it still renders if Snowflake is unreachable.

| Card | Value | Backed by |
|---|---|---|
| Deliveries (MTD) | `14.2M` | total across Logistics Docs |
| On-Time Rate | `93.4%` | average per event |
| Avg Delivery Time | `2.1 days` | average per event |
| Active Riders | `184K` | total across Logistics Docs |
| Fuel Cost Saved | `Rp 2.4B` | total across Logistics Docs |
| Route Efficiency | `+12%` | average per event |
| Failed Deliveries | `3.2%` | total across Logistics Docs |


## Demo flow

1. Operations Overview
2. Route Analytics
3. Demand Planning
4. Ask AI
5. Architecture & Data

## Talking points

- **30M deliveries/month** - across 500 hubs and 17,000 islands
- **91.3% OTD** - on-time delivery rate (target: 95%)
- **Rp 8,200** - average cost per parcel
- **15,000 vehicles** - motorcycles, vans, and trucks in fleet
- **50,000 routes** - analyzed for optimization opportunities

## Business impact

- Indonesia logistics costs represent 23% of GDP — highest in ASEAN (World Bank Logistics)
- Indonesian e-commerce logistics market valued at US$8.5B in 2023 with 25% CAGR (Ken Research)
- AI-optimized routing reduces last-mile delivery costs by 15-25% (McKinsey Last-Mile)
- On-time delivery improvement from 91% to 95% reduces customer churn by 20% (Bain & Company)

---
Generated from `generator/demo_specs/aws-indonesia-digital-economy-logistics.json`. Do not hand-edit: run
`python3 generator/gen_repo_docs.py aws-indonesia-digital-economy-logistics` instead.
