# Loading the CSVs into Snowflake via Snowsight

All 10 files are under Snowsight's 250 MB per-file browser upload limit
(largest is `payment_event.csv` at ~80 MB).

## Before you start

Run, in a Snowsight worksheet, in this order:

1. `01_create_schema.sql` — creates `ASTRAPAY`, the `RAW` / `STAGING` / `MART`
   schemas, and the `FF_CSV` file format.
2. `02_create_tables.sql` — creates the 10 empty tables with explicit types.

Do **not** let Snowsight infer the schema. The tables must exist first, or the
loader will guess types and may reject the negative amounts and the
out-of-range risk scores — destroying two defects you are meant to find.

## Loading each file

For each of the 10 tables:

1. Snowsight → **Data** → **Databases** → `ASTRAPAY` → `RAW` → **Tables**
2. Click the table name (e.g. `TRANSACTION`)
3. **Load Data** button (top right)
4. Select the matching CSV from `data/`
5. File format: choose **Existing file format** → `ASTRAPAY.RAW.FF_CSV`
6. **Load**

| CSV | Target table |
|---|---|
| `customer.csv` | `RAW.CUSTOMER` |
| `merchant.csv` | `RAW.MERCHANT` |
| `transaction.csv` | `RAW.TRANSACTION` |
| `payment_event.csv` | `RAW.PAYMENT_EVENT` |
| `fraud_decision.csv` | `RAW.FRAUD_DECISION` |
| `settlement.csv` | `RAW.SETTLEMENT` |
| `fx_rate.csv` | `RAW.FX_RATE` |
| `route_cost.csv` | `RAW.ROUTE_COST` |
| `chargeback.csv` | `RAW.CHARGEBACK` |
| `merchant_risk_snapshot.csv` | `RAW.MERCHANT_RISK_SNAPSHOT` |

Load the small files first (`merchant`, `fx_rate`, `route_cost`,
`merchant_risk_snapshot`, `chargeback`, `customer`) to confirm the format works
before spending upload time on `payment_event.csv`.

## After loading

Run `04_post_load_validation.sql` and confirm **every** row count matches.
A mismatch here means a broken load, not a data-quality finding — fix it before
Task 3, or you will spend hours auditing your own upload.

## If a load fails

- *"Number of columns in file does not match"* — you picked the wrong target table.
- *"Timestamp could not be parsed"* — the file format was not applied; redo step 5.
- *Rows rejected on `AMOUNT` or `RISK_SCORE`* — the table was auto-created by the
  loader instead of by `02_create_tables.sql`. Drop it and re-run the DDL.
