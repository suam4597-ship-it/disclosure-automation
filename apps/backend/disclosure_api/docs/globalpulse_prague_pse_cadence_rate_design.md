# GlobalPulse Prague PSE Cadence and Rate Design

This document records the scheduling-blocker design for the Prague Stock Exchange multi-ISIN issuer-news and issuer-report-calendar manual candidates.

This is a design-only gate. It does not enable scheduled polling, does not set either source active, does not change the backend public JSON shape, and does not add frontend UI.

## Conclusion

```text
PRAGUE_PSE_CADENCE_RATE_DESIGN_RECORDED
PRAGUE_PSE_REMAINS_MANUAL_STAGING_ONLY
PRAGUE_PSE_FANOUT_REQUEST_BUDGET_DESIGNED
PRAGUE_PSE_ISSUER_ROTATION_GATE_DESIGNED
PRAGUE_PSE_NEWS_AND_REPORT_CALENDAR_SEPARATION_DESIGNED
PRAGUE_PSE_SCHEDULED_POLLING_STILL_BLOCKED
```

## Current Evidence

```text
issuer universe: 63 unique ISINs across Prime, Standard, Start, and Free Market pages
issuer universe pages per poll: 4
current max_issuers_per_poll: 10
current issuer selection: deterministic capped subset
current source status: active=false
current candidate_status: manual_staging_only
fixture fallback: disabled
```

Issuer news evidence:

```text
source_key: cz_pse_issuer_news_multi_isin
parser_key: pse_multi_isin_issuer_news_json_v1
fetch.strategy: pse_multi_isin_news_v1
max_news_items_per_issuer: 5
selected_issuer_count observed: 10
issuer_request_count observed: 10
records_seen observed: 15
records_inserted observed: 15
date-specific digest visibility: pass for 2022-02-25 and 2021-06-01
latest digest visibility: top-n/date-limited
```

Issuer report calendar evidence:

```text
source_key: cz_pse_issuer_report_calendar_multi_isin
parser_key: pse_multi_isin_issuer_report_calendar_json_v1
fetch.strategy: pse_multi_isin_report_calendar_v1
max_calendar_items_per_issuer: 8
selected_issuer_count observed: 10
calendar_request_count observed: 10
records_seen observed: 20
records_inserted observed: 20
date-specific digest visibility: pass for 2026-04-30, 2026-04-28, and 2026-04-27
latest digest visibility: top-n/date-limited
```

The sources are official and live-compatible, but both are fan-out candidates. They require cadence, request-budget, issuer-window rotation, duplicate/story grouping, and rollback evidence before scheduled polling.

## Design Scope

```text
in scope: staging-only cadence design for the two existing PSE multi-ISIN sources
in scope: request budget and rate limits for official PSE universe and issuer APIs
in scope: issuer-window rotation gate for the 63-ISIN universe
in scope: duplicate and multi-ISIN story grouping behavior
in scope: rollback and pause criteria
out of scope: production scheduled polling
out of scope: active=true source promotion
out of scope: adding PSE to the first EU scheduled staging canary
out of scope: public Source Health UI, public poll UI, audit UI, or dashboard changes
out of scope: changing public feed/digest JSON response shape
out of scope: registering PSE HTML root, global news, or per-issuer endpoints as standalone rss_v1 sources
```

## Request Budget

The current manual fetch shape makes one source poll bounded but non-trivial:

```text
universe page requests: 4
issuer API requests: max_issuers_per_poll
current one-source request budget: 14 requests per poll
current paired-source request budget if run back-to-back: 28 requests per observation cycle
current timeout: 30000 ms
current per-request delay design baseline: at least 250 ms
```

Future staging-only scheduled eligibility must keep the request budget explicit:

```text
do not run issuer news and report calendar simultaneously
do not run both PSE sources inside the first EU scheduled staging canary
when testing both sources, separate them by at least 15 minutes or run them on alternating observation windows
start with one PSE source per scheduled staging canary observation cycle
keep max_issuers_per_poll=10 until repeated staging evidence proves the request budget is stable
do not raise max_issuers_per_poll above 10 without a separate PR and smoke result
do not raise max_items_per_poll above 25 without a separate digest-impact check
```

Hard stop markers:

```text
HTTP 401, 403, 408, 409, 423, 429, or repeated 5xx from universe or issuer APIs
unexpected HTML response from an issuer JSON endpoint
universe extraction returns zero ISINs
issuer API response lacks expected data or result.data shape
selected_issuer_count exceeds configured max_issuers_per_poll
records_seen exceeds max_items_per_poll by an undocumented margin
fixture fallback appears in any live smoke response
```

## Issuer Rotation Gate

The current manual configuration caps the 63-ISIN universe to 10 selected issuers. That proves the parser/fetch path, but it does not prove coverage rotation.

Before any scheduled canary that claims PSE coverage, record an explicit issuer-window contract:

```text
issuer universe ordering: deterministic order extracted from official market pages
issuer window size: max_issuers_per_poll
issuer window selection: documented offset or rotation key
rotation evidence: at least two staging manual/dispatch smokes with different selected issuer windows
coverage evidence: selected ISIN list recorded for every smoke result
stability evidence: no source-health regression after changing the selected window
```

Allowed future rotation designs:

```text
static subset canary: allowed only for endpoint stability, not full-market coverage
date-slot rotation: allowed if the offset can be derived deterministically from UTC date or schedule slot
explicit canary window override: allowed for manual/dispatch staging smoke only
stateful cursor: blocked unless storage, rollback, and replay behavior are designed separately
```

Until a rotation design is implemented and smoke-tested, PSE remains manual-only even though the first selected window has passed staging live smoke.

## Source Separation

Issuer news and report calendar should be treated as separate candidates:

```text
issuer news rows are historical 2020-2022 in the current evidence window
issuer report calendar rows are date-only report rows in 2026 evidence windows
direct file-report rows remain non-canonical because they lack publication-date fields
the two sources have different digest-date behavior and should not share one pass/fail result
```

Future staging-only canary order:

```text
1. issuer report calendar stability canary, because records have bounded date-only report refs
2. issuer news stability canary, because historical rows and multi-ISIN story behavior need separate observation
3. paired-source observation only after both single-source canaries pass
```

## Duplicate And Story Grouping

Current canonical identity is issuer-scoped:

```text
news external_id: pse-news:<query_isin>:<id>
report calendar external_id: pse-report-calendar:<query_isin>:<id or ref>
```

Scheduled eligibility must preserve explicit duplicate accounting:

```text
dedupe within a single issuer response
dedupe across selected issuer responses
dedupe against existing stored canonical records
record duplicate count in smoke docs when available
record multi_isin_row_count when a news row contains multiple ISINs
do not collapse multi-ISIN news rows across issuers unless a separate product decision changes story grouping
do not synthesize direct file-report published_at from year-only data
```

If multi-ISIN rows dominate a smoke result, PSE stays manual-only until story grouping and duplicate display behavior are reviewed.

## Staging Smoke Evidence Required Before Scheduling

Before either PSE source can be considered for scheduled staging, record a docs-only smoke with:

```text
backend health status
source active=false
candidate_status=manual_staging_only or explicitly documented staging-only canary status
parser_key
fetch.strategy
fetch.status_code=200
universe_count
selected_issuer_count
selected ISIN list or selected issuer window identifier
issuer_request_count or calendar_request_count
max_issuers_per_poll
max_items_per_poll
records_seen
records_inserted
canonical_items count
raw_documents count
duplicate count if exposed
fixture fallback=false
date-specific digest visibility
source health after the run
rollback command or config path
```

Required repeated evidence:

```text
at least two successful staging manual/dispatch smokes for the chosen source
at least two different issuer windows before claiming broader PSE coverage
zero hard-stop rate or shape failures during the evidence window
no public digest JSON response-shape change
no public UI change
explicit confirmation that first EU canary results remain unaffected
```

## Rollback And Pause Path

Immediate pause triggers:

```text
HTTP 403, 429, or repeated 5xx from PSE APIs
universe_count unexpectedly drops to zero
selected_issuer_count exceeds cap
unexpected JSON shape change
issuer-window rotation repeats or skips windows without explanation
duplicate/multi-ISIN behavior invalidates issuer-scoped identity assumptions
digest output becomes dominated by old PSE rows
runtime latency threatens other canary sources
```

Rollback path:

```text
keep both sources active=false
remove PSE sources from any staging canary source list
set any future staging-only candidate status back to manual_staging_only or scheduled_staging_paused
restore max_issuers_per_poll=10 if a larger cap caused instability
restore static first-window manual smoke if rotation caused instability
do not delete existing canonical records solely as rollback unless a separate data-cleanup plan is approved
record the failure in a docs-only smoke/rollback result
```

## Next Step

```text
Keep both current PSE candidates manual-only.
Do not add PSE to the first EU scheduled staging canary.
After the first EU canary observation window, consider a separate staging-only implementation PR for issuer-window override or deterministic date-slot rotation.
Only after repeated single-source rotation smokes pass should a new runbook consider PSE for a scheduled staging canary.
```
