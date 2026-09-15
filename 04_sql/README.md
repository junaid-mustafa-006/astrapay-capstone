# 04 — SQL

| Folder | Contents |
|---|---|
| `00_setup/` | Schema, DDL, Snowsight load checklist, post-load validation |
| `01_profiling/` | Profiling queries backing the Task 3 DQ scorecard |
| `02_staging/` | Conformed, grain-corrected views — one row per entity |
| `03_model/` | The transaction-grain fact table and its dimensions |
| `04_analysis/` | Root-cause, segmentation and decomposition queries |
| `99_validation/` | Reconciliation and the fan-out inflation proofs |

## Conventions

- Every script opens with a header comment: purpose, engine, inputs, outputs, **grain**.
- Explicit joins only. No comma joins, no implicit crosses.
- Anything one-to-many is aggregated to transaction grain in its own CTE
  **before** it is joined to the fact.
- `99_validation/` must contain, at minimum:
  - one reconciliation comparing transaction-side and settlement-side totals
  - one test proving a one-to-many join does **not** inflate payment amount
    (run the naive join, show the inflated number, then show the correct one)
