-- =============================================================================
-- 01_create_schema.sql
-- Purpose : Create the database, schema and CSV file format for the AstraPay
--           payment profitability diagnostic.
-- Engine  : Snowflake
-- Run as  : a role with CREATE DATABASE privilege (e.g. SYSADMIN)
-- =============================================================================

CREATE DATABASE IF NOT EXISTS ASTRAPAY;
USE DATABASE ASTRAPAY;

-- RAW holds the source files exactly as delivered. Nothing is cleaned here:
-- every planted defect must survive into RAW so the DQ audit can measure it.
CREATE SCHEMA IF NOT EXISTS RAW;

-- STAGING holds conformed, grain-corrected, one-row-per-entity tables.
CREATE SCHEMA IF NOT EXISTS STAGING;

-- MART holds the governed analytical model that Power BI consumes.
CREATE SCHEMA IF NOT EXISTS MART;

USE SCHEMA ASTRAPAY.RAW;

-- CSV format matching the generator's output:
--   header row present, comma delimited, double-quoted strings,
--   empty field -> NULL (this is what makes the missing merchant_id defect land
--   as a true NULL rather than an empty string).
CREATE OR REPLACE FILE FORMAT ASTRAPAY.RAW.FF_CSV
    TYPE                         = CSV
    FIELD_DELIMITER              = ','
    SKIP_HEADER                  = 1
    FIELD_OPTIONALLY_ENCLOSED_BY = '"'
    EMPTY_FIELD_AS_NULL          = TRUE
    NULL_IF                      = ('', 'NULL', 'null', '\\N')
    TRIM_SPACE                   = FALSE
    ERROR_ON_COLUMN_COUNT_MISMATCH = TRUE
    COMPRESSION                  = AUTO;

SHOW FILE FORMATS IN SCHEMA ASTRAPAY.RAW;
