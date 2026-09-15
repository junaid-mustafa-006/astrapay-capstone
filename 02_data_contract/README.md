# 02 — Data Contract & Grain Audit

**Deliverable:** `02_data_contract.xlsx` in this folder.

One sheet per concern, or one row per dataset with the columns below.

## Required per dataset

grain · business owner · primary key · join keys · expected cardinality ·
critical fields · two validation rules

## Also required

- **At least four joins** that could create duplication or temporal leakage,
  named explicitly with the direction of the fan-out.
- **Which date drives each major KPI, and why.** `created_at`, `event_time`,
  `ingestion_time`, `settlement_date` and `snapshot_month` are all candidates and
  they disagree with each other.

## Gotchas this dataset plants

- `ROUTE_COST` is dated. Joining on `route_id` alone silently applies one day's
  fee to the whole year.
- `MERCHANT_RISK_SNAPSHOT` has 12 rows per merchant. A plain join multiplies
  payment amount by ~12.
- `FRAUD_DECISION` has 1–4 rows per transaction.
- `SETTLEMENT` is not 1:1 with `TRANSACTION` in either direction.
- `FX_RATE` has two `rate_type` values for every currency and date.
