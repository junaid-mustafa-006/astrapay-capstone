-- =============================================================================
-- 02_create_tables.sql
-- Purpose : Explicit DDL for the 10 source tables.
-- Engine  : Snowflake
--
-- Tables are created BEFORE loading so that column types are a deliberate
-- decision rather than whatever Snowsight infers. Two types matter:
--
--   * TRANSACTION.AMOUNT must accept NEGATIVE values (reversals and the
--     orphaned-negative defect). Do not constrain it.
--   * FRAUD_DECISION.RISK_SCORE must accept values OUTSIDE 0-1. One model
--     version emits a different scale; constraining the column here would
--     destroy the defect before it can be measured.
--
-- Each table carries its GRAIN STATEMENT as a comment. Task 2 requires one
-- for every dataset; putting it in the DDL means it cannot drift.
-- =============================================================================

USE SCHEMA ASTRAPAY.RAW;

-- GRAIN: 1 row per customer. PK: customer_id.
CREATE OR REPLACE TABLE CUSTOMER (
    customer_id      VARCHAR(16)   NOT NULL,
    segment          VARCHAR(16),
    country          VARCHAR(2),
    onboarding_date  DATE,
    kyc_status       VARCHAR(16)
) COMMENT = 'GRAIN: 1 row per customer. PK customer_id.';

-- GRAIN: 1 row per merchant. PK: merchant_id.
CREATE OR REPLACE TABLE MERCHANT (
    merchant_id      VARCHAR(16)   NOT NULL,
    category         VARCHAR(32),
    country          VARCHAR(2),
    pricing_plan     VARCHAR(32),
    risk_tier        VARCHAR(16)
) COMMENT = 'GRAIN: 1 row per merchant. PK merchant_id.';

-- GRAIN: 1 row per payment ATTEMPT (not per successful payment). PK: transaction_id.
CREATE OR REPLACE TABLE TRANSACTION (
    transaction_id   VARCHAR(20)   NOT NULL,
    customer_id      VARCHAR(16),
    merchant_id      VARCHAR(16),          -- nullable: a small share is missing
    amount           NUMBER(18,2),         -- may be negative (reversals + defects)
    currency         VARCHAR(3),
    channel          VARCHAR(20),
    status           VARCHAR(16),
    created_at       TIMESTAMP_NTZ,
    route_id         VARCHAR(16)
) COMMENT = 'GRAIN: 1 row per payment attempt. PK transaction_id. amount may be negative.';

-- GRAIN: 1 row per lifecycle EVENT. NOT unique on transaction_id.
CREATE OR REPLACE TABLE PAYMENT_EVENT (
    transaction_id   VARCHAR(20)   NOT NULL,
    event_type       VARCHAR(20),
    event_time       TIMESTAMP_NTZ,
    processing_ms    NUMBER(12,0),
    ingestion_time   TIMESTAMP_NTZ
) COMMENT = 'GRAIN: 1 row per lifecycle event (2-4 per transaction). FAN-OUT RISK.';

-- GRAIN: 1 row per fraud RULE DECISION. NOT unique on transaction_id.
CREATE OR REPLACE TABLE FRAUD_DECISION (
    transaction_id   VARCHAR(20)   NOT NULL,
    rule_id          VARCHAR(32),
    decision         VARCHAR(16),
    risk_score       NUMBER(12,4),         -- NOT constrained to 0-1 on purpose
    model_version    VARCHAR(16)
) COMMENT = 'GRAIN: 1 row per fraud rule decision (1-4 per transaction). FAN-OUT RISK.';

-- GRAIN: 1 row per settlement RECORD. NOT guaranteed 1:1 with transaction.
CREATE OR REPLACE TABLE SETTLEMENT (
    transaction_id      VARCHAR(20),
    settlement_amount   NUMBER(18,2),
    settlement_currency VARCHAR(3),
    fee_amount          NUMBER(18,4),
    settlement_status   VARCHAR(20),
    settlement_date     DATE
) COMMENT = 'GRAIN: 1 row per settlement record. May be missing, duplicated or orphaned vs TRANSACTION.';

-- GRAIN: 1 row per (rate_date, currency, rate_type). Composite PK.
CREATE OR REPLACE TABLE FX_RATE (
    rate_date        DATE          NOT NULL,
    currency         VARCHAR(3)    NOT NULL,
    rate_to_usd      NUMBER(20,8),         -- MULTIPLIER: amount_usd = amount * rate_to_usd
    rate_type        VARCHAR(20)   NOT NULL
) COMMENT = 'GRAIN: 1 row per rate_date + currency + rate_type. rate_to_usd is a MULTIPLIER.';

-- GRAIN: 1 row per (route_id, rate_date). Fees are DATED, not constant.
CREATE OR REPLACE TABLE ROUTE_COST (
    route_id         VARCHAR(16)   NOT NULL,
    provider         VARCHAR(32),
    region           VARCHAR(2),
    rate_date        DATE          NOT NULL,
    fixed_fee        NUMBER(12,4),
    variable_fee_pct NUMBER(12,6)
) COMMENT = 'GRAIN: 1 row per route_id + rate_date. Fees change over time - always join on date.';

-- GRAIN: 1 row per chargeback. PK: chargeback_id.
CREATE OR REPLACE TABLE CHARGEBACK (
    chargeback_id    VARCHAR(20)   NOT NULL,
    transaction_id   VARCHAR(20),
    reason           VARCHAR(48),
    amount           NUMBER(18,2),
    opened_at        TIMESTAMP_NTZ,
    resolved_at      TIMESTAMP_NTZ         -- nullable: still open
) COMMENT = 'GRAIN: 1 row per chargeback. PK chargeback_id. A transaction may have 0 or 1.';

-- GRAIN: 1 row per (merchant_id, snapshot_month). 12 rows per merchant.
CREATE OR REPLACE TABLE MERCHANT_RISK_SNAPSHOT (
    merchant_id      VARCHAR(16)   NOT NULL,
    snapshot_month   VARCHAR(7)    NOT NULL,   -- 'YYYY-MM'
    risk_score       NUMBER(12,4),
    risk_band        VARCHAR(16)
) COMMENT = 'GRAIN: 1 row per merchant per month (12 per merchant). SEVERE FAN-OUT RISK - use an as-of join.';

SHOW TABLES IN SCHEMA ASTRAPAY.RAW;
