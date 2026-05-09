# GlobalPulse Germany Company Register Pagination, Rate, and Captcha Design

This document records the scheduling-blocker design for the Germany Company Register capital-market information manual candidate.

This is a design-only gate. It does not enable scheduled polling, does not set the source active, does not change the backend public JSON shape, and does not add frontend UI.

## Conclusion

```text
GERMANY_COMPANY_REGISTER_PAGINATION_RATE_CAPTCHA_DESIGN_RECORDED
GERMANY_COMPANY_REGISTER_REMAINS_MANUAL_STAGING_ONLY
GERMANY_COMPANY_REGISTER_OVER_PAGE_CAP_HANDLING_DESIGNED
GERMANY_COMPANY_REGISTER_DUPLICATE_HANDLING_DESIGNED
GERMANY_COMPANY_REGISTER_RATE_AND_CAPTCHA_GUARDS_DESIGNED
GERMANY_COMPANY_REGISTER_ROLLBACK_PATH_DESIGNED
GERMANY_COMPANY_REGISTER_SCHEDULED_POLLING_STILL_BLOCKED
```

## Current Evidence

```text
source_key: de_company_register_capital_market_info
display_name: Germany Company Register Capital Market Information
parser_key: germany_company_register_capital_market_flight_v1
source status: active=false
candidate_status: manual_staging_only
live_fetch_strategy: germany_company_register_token_preflight_v1
smoke date window: 2024-09-30 to 2024-09-30
page_size: 30
max_pages_per_poll: 1
total_pages observed: 7
total_results observed: 188
fetch.records_seen observed: 30
pipeline.records_seen observed: 25
records_inserted observed: 25
over_page_cap observed: true
date-specific digest visibility: pass
fixture fallback: false
```

The source is official and live-compatible, but the proven daily window can exceed the current one-page manual cap. That is acceptable for a manual smoke and is not acceptable as a scheduled polling contract until pagination, duplicate behavior, rate limits, captcha handling, and rollback are covered by a separate staging-smoke path.

## Design Scope

```text
in scope: staging-only pagination exploration for the existing official Company Register capital-market source
in scope: duplicate handling and item-cap behavior for multi-page date windows
in scope: rate/captcha detection and stop conditions
in scope: rollback and pause criteria
out of scope: production scheduled polling
out of scope: active=true source promotion
out of scope: public Source Health UI, public poll UI, audit UI, or dashboard changes
out of scope: changing public feed/digest JSON response shape
out of scope: third-party German register APIs
```

## Pagination Contract

The existing manual candidate fetches the first page only and records `over_page_cap=true` when `total_pages` exceeds `max_pages_per_poll`.

Future staging-only pagination exploration may increase the cap, but only under an explicit canary/smoke branch and only with conservative limits:

```text
initial staging exploration cap: max_pages_per_poll=2
maximum pre-promotion exploration cap: max_pages_per_poll=3
page offset rule: increment from by page_size only
page_size rule: keep page_size=30 unless the official response proves another stable default
item cap rule: preserve max_items_per_poll unless the PR explicitly documents the expected canonical volume
stop if current page has no publicationDto rows
stop if the next requested offset would exceed the configured page cap
stop if the response reports total_pages lower than the current page index
stop if any page lacks the current embedded publication result markers
record pages_fetched, total_pages, total_results, records_seen, records_kept, and over_page_cap
```

The first scheduled-eligibility evidence must be a staging manual/dispatch smoke that proves the chosen multi-page cap behaves deterministically. It must not jump directly from one-page manual smoke to scheduled polling.

## Duplicate Handling

Canonical identity already uses the public publication detail payload rather than the expiring search token:

```text
canonical url: https://www.unternehmensregister.de/en/publication?payload=<encryptedPayload>
external_id: de-company-register:<digest of encryptedPayload>
```

Multi-page exploration must preserve that identity and record duplicate behavior:

```text
dedupe before canonical insert by external_id
dedupe across pages in a single poll
dedupe against existing stored canonical records
record records_seen before canonical max-item trimming
record records_kept after source parser/fetch de-duplication
record records_inserted after storage-level duplicate checks
flag page_overlap_detected=true when the same external_id appears on multiple fetched pages
do not synthesize identity from title, issuer, date, or searchToken
```

If duplicate counts spike or page overlap becomes common, the source stays manual-only until the ordering and pagination behavior are re-evaluated.

## Rate And Captcha Guards

The Company Register fetch path depends on a session, support page, fresh search token, and tokenized search URL. Scheduled eligibility requires conservative request behavior:

```text
use a fresh search token per poll
do not hard-code or persist searchToken values
reuse the same HTTP session only inside one poll
use a delay between paginated search requests during staging exploration
use a per-request timeout and a whole-poll timeout
avoid automatic retry storms; retry at most once for transient network failure during manual staging exploration
do not run Germany Company Register in the first EU scheduled staging canary
do not run this source more than once per day during any future staging-only scheduled canary
```

Hard stop markers:

```text
captcha page or security query marker
login/session-expired page marker
token endpoint response missing token, expiresAt, or status
tokenized search response missing publicationDto/sourceDate/companyNameAtTimeOfPublication markers
HTTP 401, 403, 409, 423, 429, or repeated 5xx from support/token/search endpoints
content type other than expected HTML or token JSON
tokenless search shell returned as if it were a result page
```

When a hard stop marker appears, the adapter must return a source-health error and must not fall back to the fixture.

## Candidate State Machine

```text
manual_staging_only:
  current state; one-page manual live smoke passed; scheduled polling blocked

pagination_staging_design_recorded:
  this document exists; no runtime config change implied

pagination_manual_smoke_ready:
  future implementation can expose a staging-only manual override for max_pages_per_poll=2 or 3

pagination_manual_smoke_pass:
  future evidence proves bounded multi-page live fetch, duplicate handling, rate guards, and digest behavior

scheduled_staging_canary_candidate:
  only after multi-page smoke passes repeatedly and a separate runbook names cadence, rollback, and observation window
```

No state in this document sets `active=true`.

## Staging Smoke Evidence Required Before Scheduling

Before Germany Company Register can be considered for any scheduled staging canary, record a docs-only smoke result with:

```text
backend health status
source active=false
candidate_status=manual_staging_only or explicitly documented staging-only canary status
parser_key
fetch.strategy=germany_company_register_token_preflight_v1
support_status_code=200
token_status_code=200
search_status_code=200 for every fetched page
source_date_from/source_date_to
page_size
max_pages_per_poll
pages_fetched
total_pages
total_results
over_page_cap
records_seen before trimming
records_kept after de-duplication
records_inserted
canonical_items count
duplicate count
page_overlap_detected
fixture fallback=false
date-specific digest visibility
source health after the run
rollback command or config path
```

Required repeated evidence:

```text
at least two successful staging manual/dispatch smokes on different days or different bounded date windows
zero captcha/security-query/login hard stops during the evidence window
no retry storm or repeated timeout behavior
no backend public response-shape change
no public UI change
explicit confirmation that first EU canary results remain unaffected
```

## Rollback And Pause Path

Immediate pause triggers:

```text
captcha/security-query/login marker
HTTP 401/403/429 or repeated 5xx
token endpoint instability
unexpected page-shape change
page overlap or duplicate behavior that invalidates external_id assumptions
digest output dominated by old German register rows
runtime latency high enough to threaten other canary sources
```

Rollback path:

```text
keep source active=false
remove Germany Company Register from any staging canary source list
set any future staging-only candidate status back to manual_staging_only or scheduled_staging_paused
restore max_pages_per_poll=1 for manual smoke if the expanded cap caused instability
do not delete existing canonical records solely as rollback unless a separate data-cleanup plan is approved
record the failure in a docs-only smoke/rollback result
```

## Next Step

```text
Keep the current source manual-only.
Do not add Germany Company Register to the first EU scheduled staging canary.
After the first EU canary observation window, consider a separate staging-only implementation PR for max_pages_per_poll=2 manual/dispatch smoke.
Only after repeated multi-page staging smokes pass should a new runbook consider this source for a scheduled staging canary.
```
