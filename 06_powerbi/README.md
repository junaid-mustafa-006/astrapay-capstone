# 06 — Power BI Executive View

**Deliverables:** the `.pbix` in this folder, plus a one-page design/metric note.

## Constraints from the brief

- **No more than four primary visuals**, plus KPI cards.
- Must allow a decision-maker to move from overall profitability to the affected
  segment/route **without creating misleading aggregations**.
- Must include one **diagnostic** view and one **action-oriented** view.
- Must consume a **governed analytical model**, not a flat multi-table visual model.
- Must clearly distinguish **additive** metrics from rates and other
  non-additive measures.
- A 3-minute narrative using Pyramid Principle or SCQA.

## The trap

Contribution per successful transaction is a ratio. If a visual lets the user
slice it by a dimension whose weights are shifting, the number they read is a
blended average that hides the very thing the analysis found. Decide deliberately
whether each visual shows the ratio, the components, or the contribution to the
total change — and say which in the design note.
