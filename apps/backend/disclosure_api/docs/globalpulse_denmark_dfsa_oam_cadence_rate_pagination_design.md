# GlobalPulse Denmark DFSA OAM Cadence, Rate, and Pagination Design

This document records the scheduling-blocker design for the Denmark DFSA OAM company-announcements manual candidate.

This is a design-only gate. It does not enable scheduled polling, does not set the source active, does not change the backend public JSON shape, and does not add frontend UI.

## Conclusion

```text
DENMARK_DFSA_OAM_CADENCE_RATE_PAGINATION_DESIGN_RECORDED
DENMARK_DFSA_OAM_REMAINS_MANUAL_STAGING_ONLY
DENMARK_DFSA_OAM_PAGE_ONE_CANARY_DESIGNED
DENMARK_DFSA_OAM_CATEGORY_ALLOWLIST_DESIGNED
DENMARK_DFSA_OAM_PAGINATION_PROMOTION_GATE_DESIGNED
DENMARK_DFSA_OAM_SCHEDULED_POLLING_STILL_BLOCKED
```

## Current Evidence

```text
source_key: dk_dfsa_oam_company_announcements
display_name: Denmark DFSA OAM Company Announcements
parser_key: dfsa_oam_company_announcements_json_v1
source status: active=false
candidate_status: manual_staging_only
fixture fallback: disabled
base_url: https://appft.gold.extension.gopublic.dk/api/9217fa13-5d9a-46c6-9921-69ee7e6cfaf6/search
details_url_pattern: https://appft.gold.extension.gopublic.dk/api/9217fa13-5d9a-46c6-9921-69ee7e6cfaf6/details/{id}
```

Local and staging smoke evidence:

```text
local fixture parser smoke: PASS, 5 bounded records
application live parser smoke: PASS, HTTP 200, 10 bounded records
Fly staging live poll: PASS
fetch.status_code: 200
fetch.bytes: 7141
records_seen: 25
records_inserted: 25
post-poll source health: healthy
last_seen_published_at: 2026-05-08T14:13:40.000000Z
date-specific digest visibility: top-N pending
latest public UI visibility: date/top-N pending
```

Observed search paging:

```text
page: 1
pageSize: 25
totalCount: 51267
totalPages: 2051
sort: PublicationDateColumn descending
```

The source is official and live-compatible, but it is backed by a large search index. Scheduled eligibility requires explicit page-window, request-budget, category, duplicate, and rollback evidence. The current smoke proves only a bounded page-1 canary.

## Design Scope

```text
in scope: staging-only cadence design for the existing Denmark DFSA OAM source
in scope: bounded page-1 scheduled canary design
in scope: future manual pagination exploration gate
in scope: category allowlist and exclusion guardrails
in scope: duplicate and public digest top-N behavior
in scope: rollback and pause criteria
out of scope: production scheduled polling
out of scope: active=true source promotion
out of scope: adding Denmark DFSA OAM to the first EU scheduled staging canary without repeated evidence
out of scope: public Source Health UI, public poll UI, audit UI, or dashboard changes
out of scope: changing public feed/digest JSON response shape
out of scope: details/document fetch
out of scope: ShortSelling category ingestion
```

## Request Contract

The current manual source uses an ordered JSON string for `live_body` because the GoPublic extension API returned HTTP 500 on the Erlang `:httpc` path when the same request was encoded from an unordered map.

Required request contract:

```text
method: POST
content-type: application/json
field order: query, filters, page, pageSize, sorting
query: empty string
page: 1
pageSize: 25
sorting.key: PublicationDateColumn
sorting.direction: descending
timeout: 30000 ms
```

The source must not replace this ordered body with an unordered map until application live fetch proves the endpoint accepts the encoded order.

## Category Allowlist

The first slice intentionally includes issuer/company announcement categories and excludes explicit short-selling material.

Allowed categories:

```text
YearlyFinancialReport
ChangeInRightsAttachedToSecurities
HalfYearlyFinancialReport
HomeMemberState
InsideInformation
OwnShares
PaymentsToGovernments
Prospectus
RelatedPartyTransactions
TakeoverBid
TotalVotingRightsAndShareCapital
```

Excluded categories:

```text
ShortSelling
Shareholder
```

Rationale:

```text
ShortSelling is not listed-company issuer disclosure.
Shareholder notifications can be valuable, but the first source slice is issuer/company-announcement focused and already has enough volume.
Adding Shareholder requires a separate PR, duplicate/top-N impact check, and public digest review.
```

Do not widen the category list inside the same PR that changes cadence, pagination, or scheduled status.

## Cadence Design

The endpoint is a large public OAM search API with current evidence of more than 50,000 matching rows across the selected categories. Scheduled staging, if attempted later, should start with a conservative page-1 canary:

```text
initial canary window: page=1 only
initial pageSize: 25
minimum cadence: no more than every 4 hours during business days
do not run more than one Denmark DFSA OAM scheduled canary per observation slot
do not pair with another high-volume OAM source in the same minute
record source health before and after every scheduled canary observation
record records_seen, records_inserted, fetch.bytes, and latest published_at
```

Recommended first scheduled-staging cadence, after repeated manual evidence:

```text
cron candidate: 37 */4 * * 1-5
mode: staging canary only
source status: active=false until a separate workflow/source-list gate names the source
rollback: remove source from canary source list, leave source registry active=false
```

This document does not enable that cadence.

## Pagination Gate

The current source is intentionally page-1 only. Total pages are large enough that unbounded pagination would create unnecessary load and public digest volume.

Future pagination exploration may be considered only as manual staging smoke:

```text
initial manual pagination cap: max_pages_per_poll=2
maximum pre-promotion cap: max_pages_per_poll=3
pageSize remains 25
page order remains PublicationDateColumn descending
stop when a page returns zero rows
stop on any non-2xx response
stop on unexpected JSON shape
stop on timeout
record totalCount, totalPages, pages_fetched, records_seen, records_inserted, duplicate count if exposed
```

Hard blockers for scheduled pagination:

```text
totalPages changes unexpectedly by a large margin without explanation
page 2 overlaps page 1 heavily
rows are reordered between repeated page requests inside one smoke
HTTP 401, 403, 408, 409, 423, 429, or repeated 5xx
endpoint returns HTML, captcha, login, or generic error page
fixture fallback appears in any live smoke response
```

No scheduled source should fetch beyond page 1 until at least two manual pagination smokes pass and a separate PR records the result.

## Duplicate And Story Identity

Canonical identity currently uses the DFSA OAM row id:

```text
external_id: dfsa-oam:{id}
canonical_url: https://appft.gold.extension.gopublic.dk/api/9217fa13-5d9a-46c6-9921-69ee7e6cfaf6/details/{id}
```

Scheduled eligibility must preserve:

```text
dedupe by external_id before canonical insert
dedupe across repeated page-1 polls
dedupe across any future paginated pages
do not synthesize identity from title, issuer, date, or category
do not fetch details/documents as part of the canary unless separately designed
```

If duplicates dominate repeated page-1 canaries, keep the source manual-only until duplicate accounting is exposed in smoke docs.

## Staging Smoke Evidence Required Before Scheduling

Before this source can be considered for a scheduled staging canary, record:

```text
backend health status
source active=false
candidate_status=manual_staging_only or explicitly documented staging-only canary status
parser_key
request field-order contract
category allowlist
page
pageSize
totalCount
totalPages
fetch.status_code
fetch.bytes
records_seen
records_inserted
canonical_items count
fixture fallback=false
source health after the run
date-specific digest visibility
latest public UI visibility
rollback command or config path
```

Required repeated evidence:

```text
at least two successful page-1 staging live smokes on different observation windows
zero unexpected 5xx from the ordered request body
zero rate/captcha/login hard-stop markers
no backend public response-shape change
no public UI change
explicit confirmation that broader EU canary results remain unaffected
```

## Rollback And Pause Path

Immediate pause triggers:

```text
HTTP 401, 403, 408, 409, 423, 429, or repeated 5xx
GoPublic extension config endpoint changes module id or category vocabulary
search response lacks paging/data.rows/id/headline/issuer/category/publication fields
ordered request body starts returning 500
ShortSelling or Shareholder categories appear without explicit config change
digest output becomes dominated by Denmark OAM rows
runtime latency threatens other canary sources
```

Rollback path:

```text
keep source active=false
remove Denmark DFSA OAM from any staging canary source list
restore page=1 and pageSize=25 if a larger cap caused instability
restore the previous category allowlist if category expansion caused instability
do not delete existing canonical records solely as rollback unless a separate data-cleanup plan is approved
record the failure in a docs-only smoke/rollback result
```

## Next Step

```text
Keep the source manual-only.
Do not add Denmark DFSA OAM to production scheduled polling.
Run at least one more page-1 staging live smoke in a later observation window.
Only after repeated page-1 evidence passes should a separate PR consider adding the source to a staging-only EU canary list.
Treat any page-2+ exploration as a separate manual-staging smoke track.
```
