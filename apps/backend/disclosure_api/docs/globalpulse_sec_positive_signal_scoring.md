# GlobalPulse SEC Signal Scoring Retired

Date: 2026-05-14

## Status

SEC positive-signal scoring is retired for now.

The first configurable scoring version was useful as a wiring test, but the current signal quality is not strong enough to justify showing numeric scores or using them for digest ordering. GlobalPulse now keeps SEC investment-idea classification and UI filters, but removes the numeric score path.

## Current Behavior

GlobalPulse still supports the SEC signal workflow below:

```text
SEC source poll
-> canonical digest rows
-> source/category based SEC filters
-> public GlobalPulse UI
```

The public UI keeps these non-numeric filters:

```text
투자 시그널
전략/계약
M&A/공개매수
지분/기관
내부자
실적
IPO
복합 시그널
```

The UI may label an item as an investment signal when its SEC source or filing text matches one of the supported SEC signal categories. It does not display a numeric investment score.

## Removed For Now

```text
positive_signal_score source registry config
positive_signal_score metadata generation
positive_signal_score based relevance_score override
positive_signal_score based priority_rank override
numeric signal badges in the public UI
numeric signal detail boxes
numeric signal sorting
```

## Future Reintroduction Criteria

Reintroduce scoring only after there is enough observed data to tune it responsibly:

```text
1. Collect examples of useful SEC signals and false positives.
2. Define source-specific scoring rules with clear review criteria.
3. Keep all weights configurable outside parser logic.
4. Validate scores against public UI ordering before exposing them.
5. Document why the score is useful enough to show again.
```

## Guardrails

- No backend digest JSON response shape change.
- No public poll UI.
- No public Source Health UI.
- No frontend framework change.
- No scheduled production polling expansion.
- SEC labels and summaries are idea-discovery aids, not investment recommendations.
