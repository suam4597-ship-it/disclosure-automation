# GlobalPulse SEC Positive Signal Scoring

Date: 2026-05-14

## Purpose

GlobalPulse now supports configurable SEC positive-signal scoring for investment-idea discovery.

The first version is intentionally conservative: the score is not hard-coded in the parser. It is read from each SEC source registry config so the thresholds and weights can be tuned later without changing application code.

## Runtime Behavior

When a canonical feed item is created, the ingestion pipeline checks the source config field:

```yaml
positive_signal_score:
  version: sec_positive_signal_v1
  label: sec_8k_positive_catalyst
  base: 80
  max: 98
  category_scores:
    Form 4 insider purchase cluster: 96
  keyword_scores:
    item 3.02: 10
    partnership: 5
```

If the config exists, GlobalPulse computes:

```text
score = max(base, matched_category_score) + matched_keyword_scores
score is capped by max
```

The computed value is stored in bounded metadata and also mapped to `relevance_score` so the digest can sort stronger positive signals above weaker ones for the same edition/date.

## Stored Metadata

Each scored item receives the following metadata keys:

```text
positive_signal_score
positive_signal_label
positive_signal_category
positive_signal_reasons
positive_signal_version
```

These are bounded rule outputs. They do not expose raw filings, private auth material, cookies, tokens, or parser internals.

## Initial SEC Source Weights

The initial values are deliberately adjustable starting points:

```text
Form 4 clustered insider buys: very high baseline
Schedule TO tender offers: very high baseline
Schedule 13D activist ownership: high baseline
S-4 / F-4 merger registrations: high baseline
8-K positive catalyst items: high baseline with keyword boosts
13F institutional accumulation: medium-high baseline
S-1 / F-1 IPO registrations: medium-high baseline
10-Q / 10-K financial reports: medium baseline with revenue/EPS/guidance boosts
13G increased ownership: medium-high baseline
```

## Tuning Guide

Use the source registry config to tune the model:

```text
base
```

Raises or lowers the default importance for every item from that source.

```text
max
```

Caps the score so noisy keyword matches cannot overtake stronger source classes.

```text
category_scores
```

Gives a category-specific floor when parser summaries identify a known filing category.

```text
keyword_scores
```

Adds small boosts for positive catalyst language such as merger, tender offer, insider buy, strategic investment, partnership, backlog, customer contract, IPO use of proceeds, or guidance raise.

Recommended operating pattern:

```text
1. Start broad with conservative weights.
2. Watch public digest ordering and false positives.
3. Lower noisy keyword weights first.
4. Raise source base scores only when the filing class is consistently useful.
5. Keep max caps below stronger event classes when signal quality is lower.
```

## Guardrails

- No backend digest JSON response shape change.
- No public poll UI.
- No public Source Health UI.
- No frontend framework change.
- No scheduled production polling expansion.
- Scores are heuristic ranking aids, not final investment recommendations.

