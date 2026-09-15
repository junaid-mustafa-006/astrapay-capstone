-- =============================================================================
-- 04_post_load_validation.sql
-- Purpose : Prove the load is complete and faithful BEFORE any analysis.
--           A failure here is an upload bug, not a data-quality finding.
-- Engine  : Snowflake
-- =============================================================================

USE SCHEMA ASTRAPAY.RAW;

-- 1. Row counts vs the generator's expected output (seed 42) -----------------
WITH actual AS (
    SELECT 'CUSTOMER'               AS table_name, COUNT(*) AS n FROM CUSTOMER
    UNION ALL SELECT 'MERCHANT',               COUNT(*) FROM MERCHANT
    UNION ALL SELECT 'TRANSACTION',            COUNT(*) FROM TRANSACTION
    UNION ALL SELECT 'PAYMENT_EVENT',          COUNT(*) FROM PAYMENT_EVENT
    UNION ALL SELECT 'FRAUD_DECISION',         COUNT(*) FROM FRAUD_DECISION
    UNION ALL SELECT 'SETTLEMENT',             COUNT(*) FROM SETTLEMENT
    UNION ALL SELECT 'FX_RATE',                COUNT(*) FROM FX_RATE
    UNION ALL SELECT 'ROUTE_COST',             COUNT(*) FROM ROUTE_COST
    UNION ALL SELECT 'CHARGEBACK',             COUNT(*) FROM CHARGEBACK
    UNION ALL SELECT 'MERCHANT_RISK_SNAPSHOT', COUNT(*) FROM MERCHANT_RISK_SNAPSHOT
),
expected AS (
    SELECT 'CUSTOMER' AS table_name, 15000 AS n
    UNION ALL SELECT 'MERCHANT',                   600
    UNION ALL SELECT 'TRANSACTION',            260287
    UNION ALL SELECT 'PAYMENT_EVENT',         1000316
    UNION ALL SELECT 'FRAUD_DECISION',         466451
    UNION ALL SELECT 'SETTLEMENT',             224242
    UNION ALL SELECT 'FX_RATE',                  2920
    UNION ALL SELECT 'ROUTE_COST',               3285
    UNION ALL SELECT 'CHARGEBACK',                721
    UNION ALL SELECT 'MERCHANT_RISK_SNAPSHOT',   7200
)
SELECT  e.table_name,
        e.n                           AS expected_rows,
        a.n                           AS actual_rows,
        a.n - e.n                     AS diff,
        IFF(a.n = e.n, 'OK', 'FAIL')  AS load_status
FROM expected e
JOIN actual   a USING (table_name)
ORDER BY load_status DESC, e.table_name;


-- 2. The defects must have SURVIVED the load --------------------------------
-- If any of these returns zero, the loader silently cleaned your data.
SELECT 'transaction.merchant_id IS NULL'     AS check_name,
       COUNT(*) AS n,
       IFF(COUNT(*) > 0, 'PRESENT', 'LOST -- RELOAD') AS verdict
FROM TRANSACTION WHERE merchant_id IS NULL
UNION ALL
SELECT 'transaction.amount < 0',
       COUNT(*), IFF(COUNT(*) > 0, 'PRESENT', 'LOST -- RELOAD')
FROM TRANSACTION WHERE amount < 0
UNION ALL
SELECT 'fraud_decision.risk_score > 1',
       COUNT(*), IFF(COUNT(*) > 0, 'PRESENT', 'LOST -- RELOAD')
FROM FRAUD_DECISION WHERE risk_score > 1
UNION ALL
SELECT 'chargeback.resolved_at IS NULL',
       COUNT(*), IFF(COUNT(*) > 0, 'PRESENT', 'LOST -- RELOAD')
FROM CHARGEBACK WHERE resolved_at IS NULL;


-- 3. Date coverage: the period must be complete and contain no stragglers ----
SELECT 'TRANSACTION.created_at' AS column_name,
       MIN(created_at) AS min_value, MAX(created_at) AS max_value
FROM TRANSACTION
UNION ALL
SELECT 'PAYMENT_EVENT.event_time', MIN(event_time), MAX(event_time) FROM PAYMENT_EVENT
UNION ALL
SELECT 'SETTLEMENT.settlement_date', MIN(settlement_date), MAX(settlement_date) FROM SETTLEMENT
UNION ALL
SELECT 'FX_RATE.rate_date', MIN(rate_date), MAX(rate_date) FROM FX_RATE
UNION ALL
SELECT 'ROUTE_COST.rate_date', MIN(rate_date), MAX(rate_date) FROM ROUTE_COST;
-- NOTE: PAYMENT_EVENT.event_time extending past 2025-12-31 is EXPECTED
-- (settlement events for late-December transactions). It is not a load error.


-- 4. Declared primary keys really are unique --------------------------------
SELECT 'CUSTOMER.customer_id'  AS key_name, COUNT(*) - COUNT(DISTINCT customer_id)  AS dup_rows FROM CUSTOMER
UNION ALL SELECT 'MERCHANT.merchant_id',    COUNT(*) - COUNT(DISTINCT merchant_id)    FROM MERCHANT
UNION ALL SELECT 'TRANSACTION.transaction_id', COUNT(*) - COUNT(DISTINCT transaction_id) FROM TRANSACTION
UNION ALL SELECT 'CHARGEBACK.chargeback_id', COUNT(*) - COUNT(DISTINCT chargeback_id) FROM CHARGEBACK;
-- Expect 0 for all four. Anything else means a partial re-load: TRUNCATE and reload.
