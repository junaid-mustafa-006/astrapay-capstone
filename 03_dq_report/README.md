# 03 — Data Quality Investigation

**Deliverable:** `03_dq_report.xlsx` in this folder.
Profiling SQL belongs in `../04_sql/01_profiling/`.

## Scorecard dimensions

completeness · validity · uniqueness · consistency · timeliness · reconciliation

## Required per defect

- A **quantified** count and rate (not "some records")
- Severity: **blocking / warning / informational**
- For every blocking issue, the remediation decision:
  **exclude / repair / quarantine / retain with a flag** — and the reason

## Judgement, not mechanics

The marks are in the classification, not the counting. Two traps:

- Not every negative amount is a defect. Some are legitimate reversals and the
  business definition does not exclude them. Separate the two populations before
  you classify either.
- Defect rates that are **not uniform** across a dimension are findings in
  themselves. Always profile a defect rate *by* channel, provider and month
  before calling it noise.
