# Hired by Data
### European Job Market Intelligence Pipeline

> 239 real LinkedIn job postings · 12 European countries · June 2026  
> Built to answer: *where are the opportunities, and where is competition lowest?*

---

## The Problem

Job searching is inefficient by default. Most candidates apply manually, without data on where opportunities concentrate, which roles dominate the market, or what the real level of competition per vacancy looks like.

This project replaces intuition with a data-driven approach.

---

## What This Is

An end-to-end data pipeline that:
1. Collects real job postings automatically from LinkedIn via Apify
2. Cleans and transforms raw data with Python
3. Models it in a SQL Server star schema
4. Delivers insights through an interactive Power BI dashboard with advanced Key Influencers analysis

---

## Architecture

```
LinkedIn (public search)
        ↓
Apify — curious_coder/linkedin-jobs-scraper
        ↓
JSON (raw) — linkedin_raw.json + linkedin_raw_east.json
        ↓
Python — clean.py
Normalisation · Field extraction · Calculated fields
        ↓
SQL Server Express — HiredByData
Star schema · 5 tables · Foreign keys validated
        ↓
Power BI Desktop
3 pages · DAX measures · Key Influencers · Conditional formatting
```

---

## Tech Stack

| Layer | Tool | Purpose |
|---|---|---|
| Collection | Apify | Automated LinkedIn scraping |
| Transformation | Python 3.14 — pandas, re, sqlalchemy | Cleaning, normalisation, calculated fields |
| Storage | SQL Server Express | Relational model — star schema |
| Validation | Power Query | Type adjustments post-import |
| Analytics | Power BI Desktop | Dashboard + DAX + Key Influencers |

---

## Data Model — Star Schema

```
                 dim_location
                ┌─────────────┐
                │ location_id │◄──┐
                │ city        │   │ fk_location
                │ country     │   │
                │ europe_region│  │
                └─────────────┘   │
                                  │
 dim_platform                     │          dim_jobtype
┌─────────────┐      fact_jobs    │         ┌─────────────────┐
│ platform_id │◄──┌──────────────────┐  ───►│ jobtype_id      │
│ platform_   │   │ job_id (PK)      │      │ contract_type   │
│ name        │   │ job_title        │      │ experience_level│
│ source_run  │   │ title_normalized │      │ sector          │
└─────────────┘   │ applicants_count │      └─────────────────┘
                  │ competition_     │
                  │ category         │      dim_company
                  │ salary_avg       │     ┌─────────────────┐
                  │ opportunity_score│ ───►│ company_id      │
                  │ fk_location      │     │ company_name    │
                  │ fk_platform      │     │ company_size    │
                  │ fk_jobtype       │     │ size_band       │
                  │ fk_company       │     └─────────────────┘
                  └──────────────────┘
```

---

## Key Technical Decisions

**Python over Power Query for transformation**  
80+ location mappings, regex extraction from unstructured text fields, and reproducibility requirements made Python the right tool. Power Query handles type validation post-import.

**Star schema over flat table**  
Separating dimensions eliminates redundancy, improves query performance, and makes the Power BI model extensible.

**Single direction relationships**  
Bidirectional cross-filtering caused a DAX evaluation bug — Total Jobs returned 93 instead of 239 with an active slicer. Single direction with `ALL()` in the base measure resolves this cleanly.

**MEDIAN alongside AVERAGE**  
The applicants distribution is right-skewed. Average = 96.57, Median = 73. The difference is itself an insight  cities like London (142 avg) distort the mean. Both metrics are exposed deliberately.

---

## DAX Measures

```dax
-- Base count — ALL() bypasses relationship filter context issue
Total Jobs =
    COUNTROWS(FILTER(ALL(fact_jobs), fact_jobs[job_id] <> ""))

-- Respects slicer context via CALCULATE
Low Competition Jobs =
    CALCULATE(
        COUNTROWS(fact_jobs),
        fact_jobs[competition_category] = "Low (<=25)"
    )

-- FORMAT ensures consistent % display across regional settings
% Low Competition =
    FORMAT(
        DIVIDE(
            CALCULATE(COUNTROWS(fact_jobs),
                fact_jobs[competition_category] = "Low (<=25)"),
            CALCULATE(COUNTROWS(fact_jobs), ALL(fact_jobs)),
            0
        ), "0.00%"
    )

-- Fixed-region measures for comparison cards
Avg Applicants Eastern =
    CALCULATE(
        AVERAGE(fact_jobs[applicants_count]),
        dim_location[europe_region] = "Eastern Europe"
    )
```

---

## Key Insights

| Insight | Data |
|---|---|
| Business Analyst dominates | 125 of 239 postings (52%) |
| Eastern Europe less competitive | Avg 75 applicants vs 105.7 Western |
| Eastern Europe low competition rate | 39.4% vs 16.1% Western |
| Best opportunity segment | Eastern Europe + Startup: 51.7% low competition |
| Key Influencer  Eastern Europe | 2.45x more likely to be low competition |
| Key Influencer  Data Analyst | 1.63x more likely to be high competition |
| Salary data available | 11% of records — UK and Ireland only |

---

## Dashboard

Three pages with conditional colour formatting (red = risk, yellow = caution, green = opportunity):

**Page 1 — Market Overview**  
KPI cards · Jobs by Role · Competition Level (donut) · West vs East Europe · Jobs by Country · Region slicer

**Page 2 — Competition Analysis**  
Average Competition by City · Total Jobs by Country · Low Competition Opportunities table (filtered, actionable)

**Page 3 — Key Influencers**  
What drives high/low competition? Automatic factor identification with multipliers and Top Segments.

---

## Limitations

- Salary absent in 89% of records  structural limitation of European LinkedIn, not of the system
- All low competition jobs show value 25  LinkedIn does not expose the exact number for recent postings
- Single snapshot  June 2026. Pipeline designed for periodic re-execution.
- UK over-represented (44% of sample)  reflects LinkedIn's European distribution

---

## Future Development

- Glassdoor integration for salary data and company ratings
- Weekly automated pipeline runs
- Keyword frequency analysis from job descriptions
- Expansion to DACH and Nordic markets

---

## Repository Structure

```
hired-by-data/
├── README.md
├── requirements.txt
├── pipeline/
│   ├── clean.py                  # Data cleaning and transformation
│   └── migrate_to_sqlserver.py   # SQL Server migration script
├── database/
│   └── schema.sql                # Star schema DDL
├── dashboard/
│   └── HiredByData.pbix          # Power BI dashboard
└── docs/
    └── HiredByData_Technical_Portfolio.docx
```

> **Note:** Raw data files (JSON, Excel) are not included in this repository due to LinkedIn terms of service. The pipeline scripts are fully functional with new data collected via Apify.

---

## Running the Pipeline

```bash
# Install dependencies
pip install -r requirements.txt

# 1. Collect data via Apify (curious_coder/linkedin-jobs-scraper)
# Export as JSON → save to pipeline/linkedin_raw.json

# 2. Clean and transform
cd pipeline
python clean.py

# 3. Migrate to SQL Server
python migrate_to_sqlserver.py
# Update server name in script before running

# 4. Open dashboard
# Power BI Desktop → Get Data → SQL Server → HiredByData
```

---

## Skills Demonstrated

`Python` `pandas` `regex` `SQL Server` `T-SQL` `Star Schema` `Power BI` `Power Query` `DAX` `Data Cleaning` `Data Modelling` `Business Intelligence` `Apify` `ETL Pipeline` `Conditional Formatting` `Key Influencers`

---

*Benilde Maela — Operations | Business Analysis | Data & BI*  
*github.com/Bmaela*

