# 05 — Trusted Profitability Model

**Deliverable:** logical/star model diagram, grain statements, metric
definitions and transformation logic. DDL lives in `../04_sql/03_model/`.

## Required measures

attempted volume · successful volume · success rate · gross payment value ·
processing cost · fraud/chargeback cost · FX impact ·
**contribution profit per successful transaction**

## Must be written down

- A **grain statement** for every analytical table.
- The **currency conversion logic**: which `rate_type`, which date, and why.
  `rate_to_usd` is a multiplier, so `amount_usd = amount * rate_to_usd`.
- How **settlement-level fees are attributed back to transactions** without
  double counting when settlement is not 1:1.
- Which metrics are **additive** and which are not. Success rate and
  contribution-per-transaction are ratios: they cannot be summed or averaged
  across segments without reweighting.
