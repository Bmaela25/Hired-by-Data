-- Hired by Data — Star Schema DDL
-- SQL Server Express (T-SQL)
-- Generated from: migrate_to_sqlserver.py

-- ─────────────────────────────────────────
-- DIMENSION TABLES
-- ─────────────────────────────────────────

IF OBJECT_ID('dim_location', 'U') IS NOT NULL DROP TABLE dim_location;
CREATE TABLE dim_location (
    location_id     INT IDENTITY(1,1) PRIMARY KEY,
    city            NVARCHAR(100),
    country         NVARCHAR(100),
    europe_region   NVARCHAR(50)        -- 'Western Europe' | 'Eastern Europe'
);

IF OBJECT_ID('dim_platform', 'U') IS NOT NULL DROP TABLE dim_platform;
CREATE TABLE dim_platform (
    platform_id     INT IDENTITY(1,1) PRIMARY KEY,
    platform_name   NVARCHAR(50),       -- e.g. 'LinkedIn'
    source_run      NVARCHAR(100)       -- e.g. 'LinkedIn - Western Europe'
);

IF OBJECT_ID('dim_jobtype', 'U') IS NOT NULL DROP TABLE dim_jobtype;
CREATE TABLE dim_jobtype (
    jobtype_id       INT IDENTITY(1,1) PRIMARY KEY,
    contract_type    NVARCHAR(100),     -- 'Full-time', 'Contract', etc.
    experience_level NVARCHAR(100),     -- 'Mid-Senior level', 'Entry level', etc.
    sector           NVARCHAR(200)      -- Normalised first industry value
);

IF OBJECT_ID('dim_company', 'U') IS NOT NULL DROP TABLE dim_company;
CREATE TABLE dim_company (
    company_id      INT IDENTITY(1,1) PRIMARY KEY,
    company_name    NVARCHAR(200),
    company_size    INT,                -- Raw employee count (nullable)
    size_band       NVARCHAR(50)        -- 'Startup (<=50)' | 'SME' | 'Mid-size' | 'Enterprise'
);

-- ─────────────────────────────────────────
-- FACT TABLE
-- ─────────────────────────────────────────

IF OBJECT_ID('fact_jobs', 'U') IS NOT NULL DROP TABLE fact_jobs;
CREATE TABLE fact_jobs (
    job_id               NVARCHAR(50) PRIMARY KEY,
    job_title            NVARCHAR(200),
    title_normalized     NVARCHAR(100),  -- 'Business Analyst' | 'Data Analyst' | etc.
    date_posted          DATE,
    scraped_date         DATE,
    applicants_count     INT,            -- Extracted from text: 'Be among first 25' -> 25
    competition_category NVARCHAR(50),   -- 'Low (<=25)' | 'Medium' | 'High' | 'Very High'
    salary_min           FLOAT,          -- NULL when not disclosed (89% of records)
    salary_max           FLOAT,
    salary_avg           FLOAT,          -- (salary_min + salary_max) / 2
    salary_currency      NVARCHAR(10),   -- 'GBP' | 'EUR' | 'USD'
    opportunity_score    FLOAT,          -- salary_avg / (applicants_count + 1)
    apply_url            NVARCHAR(500),
    job_url              NVARCHAR(500),
    source               NVARCHAR(50),   -- 'LinkedIn'
    source_run           NVARCHAR(100),  -- Run identifier for traceability
    -- Foreign keys
    fk_location          INT REFERENCES dim_location(location_id),
    fk_platform          INT REFERENCES dim_platform(platform_id),
    fk_jobtype           INT REFERENCES dim_jobtype(jobtype_id),
    fk_company           INT REFERENCES dim_company(company_id)
);

-- ─────────────────────────────────────────
-- ANALYSIS QUERIES
-- ─────────────────────────────────────────

-- Q1: Opportunity Score by City
SELECT
    l.city,
    l.country,
    l.europe_region,
    COUNT(*) AS total_jobs,
    ROUND(AVG(CAST(f.applicants_count AS FLOAT)), 1) AS avg_applicants,
    ROUND(AVG(f.salary_avg), 0) AS avg_salary,
    f.salary_currency
FROM fact_jobs f
JOIN dim_location l ON f.fk_location = l.location_id
GROUP BY l.city, l.country, l.europe_region, f.salary_currency
ORDER BY total_jobs DESC;

-- Q2: Top 20 Low Competition Opportunities
SELECT TOP 20
    f.job_title,
    c.company_name,
    l.city,
    l.europe_region,
    f.applicants_count,
    f.competition_category
FROM fact_jobs f
JOIN dim_location l ON f.fk_location = l.location_id
JOIN dim_company c ON f.fk_company = c.company_id
WHERE f.competition_category = 'Low (<=25)'
ORDER BY f.applicants_count ASC;

-- Q3: West vs East Europe Comparison
SELECT
    l.europe_region,
    COUNT(*) AS total_jobs,
    ROUND(AVG(CAST(f.applicants_count AS FLOAT)), 1) AS avg_competition,
    SUM(CASE WHEN f.competition_category = 'Low (<=25)'
        THEN 1 ELSE 0 END) AS low_competition_jobs,
    ROUND(CAST(SUM(CASE WHEN f.competition_category = 'Low (<=25)'
        THEN 1 ELSE 0 END) AS FLOAT) / COUNT(*) * 100, 1) AS pct_low_competition
FROM fact_jobs f
JOIN dim_location l ON f.fk_location = l.location_id
GROUP BY l.europe_region;

-- Q4: Distribution by Title and Region
SELECT
    f.title_normalized,
    l.europe_region,
    COUNT(*) AS total_jobs,
    ROUND(AVG(CAST(f.applicants_count AS FLOAT)), 1) AS avg_applicants
FROM fact_jobs f
JOIN dim_location l ON f.fk_location = l.location_id
GROUP BY f.title_normalized, l.europe_region
ORDER BY total_jobs DESC;
