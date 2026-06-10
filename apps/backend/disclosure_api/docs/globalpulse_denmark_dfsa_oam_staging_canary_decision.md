# GlobalPulse Denmark DFSA OAM Staging Canary Decision

This document records the decision gate for whether the Denmark DFSA OAM company-announcements candidate may be considered for a staging-only scheduled canary.

This is documentation-only. It does not enable scheduled polling, does not set the source active, does not change workflow schedules, does not change backend response shape, and does not add frontend UI, poll UI, audit UI, or public Source Health UI.

## Conclusion

```text
DENMARK_DFSA_OAM_STAGING_CANARY_DECISION_RECORDED
DENMARK_DFSA_OAM_REPEATED_PAGE_ONE_EVIDENCE_ACCEPTED
DENMARK_DFSA_OAM_STAGING_ONLY_CANARY_ELIGIBLE_FOR_FOLLOW_UP_CONFIG_PR
DENMARK_DFSA_OAM_REMAINS_ACTIVE_FALSE
DENMARK_DFSA_OAM_PRODUCTION_SCHEDULED_POLLING_BLOCKED
DENMARK_DFSA_OAM_PAGE_TWO_PLUS_EXPLORATION_SEPARATE
```

## Baseline

```text
source_key: dk_dfsa_oam_company_announcements
display_name: Denmark DFSA OAM Company Announcements
owner/surface: Danish Financial Supervisory Authority OAM
source_type: api
parser_key: dfsa_oam_company_announcements_json_v1
base_url: https://appft.gold.extension.gopublic.dk/api/9217fa13-5d9a-46c6-9921-69ee7e6cfaf6/search
source status: active=false
candidate_status: manual_staging_only
fixture fallback: disabled
production scheduled polling: not approved
```

Related evidence:

```text
candidate notes: globalpulse_denmark_dfsa_oam_company_announcements_candidate_notes.md
first staging smoke: globalpulse_denmark_dfsa_oam_company_announcements_staging_live_poll_smoke_results.md
cadence/rate/pagination design: globalpulse_denmark_dfsa_oam_cadence_rate_pagination_design.md
second page-1 smoke: globalpulse_denmark_dfsa_oam_repeated_page1_staging_smoke_results.md
```

## Evidence Accepted

The source has now passed two bounded page-1 Fly staging live-poll smokes in separate observation windows.

```text
first smoke last_success_at: 2026-05-10T16:00:46.901927Z
second smoke last_success_at: 2026-05-11T00:49:19.436310Z
first smoke records_seen: 25
second smoke records_seen: 25
first smoke records_inserted: 25
second smoke records_inserted: 25
first smoke fetch.bytes: 7141
second smoke fetch.bytes: 7141
first smoke latest published_at: 2026-05-08T14:13:40.000000Z
second smoke latest published_at: 2026-05-08T14:13:40.000000Z
```

Second smoke workflow evidence:

```text
workflow: GlobalPulse live staging poll
run: https://github.com/suam4597-ship-it/disclosure-automation/actions/runs/25644574112
run_number: 51
source_key: dk_dfsa_oam_company_announcements
run_mode: single_source
health status: 200
poll status: 202
fetch.mode: live
fetch.status_code: 200
fetch.bytes: 7141
records_seen: 25
records_inserted: 25
digest status: 200
digest_date: 2026-05-09
metadata.fallback_to_fixture: false
post-poll source health: healthy
artifact: globalpulse-live-staging-poll-25644574112
artifact id: 6908422977
```

## Decision

The repeated page-1 evidence is sufficient to allow a follow-up workflow/config PR that adds Denmark DFSA OAM to a staging-only scheduled canary path.

That follow-up PR must still be explicit and separate. This document does not make the workflow change.

Allowed follow-up scope:

```text
add exactly dk_dfsa_oam_company_announcements to a staging-only canary source list
keep production scheduled polling disabled
keep source active=false
keep candidate_status manual_staging_only unless a separate status-only PR introduces a bounded staging-only status
keep page=1
keep pageSize=25
keep current category allowlist
keep ShortSelling excluded
keep Shareholder excluded
keep details/document fetch disabled
keep digest JSON response shape unchanged
upload per-source artifacts
continue after other canary source failures and fail at the end if validation fails
```

Not allowed in the follow-up config PR:

```text
production scheduled polling
active=true
page 2 or broader pagination
category expansion
ShortSelling ingestion
Shareholder ingestion
details/document fetch
public poll UI
audit UI
public Source Health UI
backend digest JSON shape changes
frontend framework changes
fixture fallback treated as live success
```

## Source List Contract

If Denmark is added to a staging-only scheduled canary, it should be added as a named second-wave source rather than silently widening the first EU canary baseline.

Minimum source-list change:

```text
existing EU canary sources: unchanged unless a config PR explicitly says otherwise
new second-wave source: dk_dfsa_oam_company_announcements
high-volume source pairing: avoid scheduling Denmark in the same minute as another high-volume OAM source
Germany Company Register: still excluded from Denmark decision
Prague/PSE fan-out sources: still excluded from Denmark decision
Ireland Euronext Dublin: still blocked until Dublin-only machine-readable filter is proven
```

The follow-up PR must state whether Denmark is appended to the existing EU canary run or routed through a separate Denmark-specific schedule.

Preferred first follow-up:

```text
route Denmark through a separate staging-only schedule or manual dispatch alias
do not change the existing first EU canary source list in the same PR
run at most one Denmark source per scheduled observation
```

Acceptable alternate follow-up:

```text
append Denmark to the existing EU canary only if the PR records the expected extra runtime and artifact naming
confirm the existing first-canary sources keep their current validation contract
```

## Cadence And Request Budget

Recommended first scheduled-staging cadence:

```text
mode: staging canary only
minimum cadence: no more than every 4 hours during business days
cron candidate if separate: 37 */4 * * 1-5
request method: POST
content-type: application/json
page: 1
pageSize: 25
max source requests per observation: 1 search request
max records_seen per observation: 25
max canonical_items per observation: 25
max raw_documents per observation: 25
details requests per observation: 0
```

The workflow should record:

```text
health status before poll
poll HTTP status
fetch.mode
fetch.status_code
fetch.bytes
records_seen
records_inserted
canonical_items count
raw_documents count
latest published_at
latest digest status
latest digest fallback_to_fixture
source health after poll
```

## Expected Duplicate Behavior

The repeated page-1 smokes inserted the same 25 bounded records across two observation windows. That is acceptable while the source is manual and page-1 only, but the scheduled canary must make duplicate behavior visible.

Expected behavior:

```text
external_id remains dfsa-oam:{id}
canonical_url remains details/{id}
repeated page-1 observations should not create duplicate canonical stories with different identities
records_inserted may be lower than records_seen once the same page is observed again
records_inserted=0 with records_seen=25 can be a healthy no-new-data canary result
```

Pause if:

```text
the same DFSA id maps to multiple canonical URLs
the same DFSA id maps to multiple external_id values
title/date based fallback identity appears
records_inserted exceeds records_seen
canonical_items count exceeds records_seen
raw_documents count exceeds records_seen
```

## Latest Digest And Top-N Impact

The current latest digest is not dominated by Denmark rows. Denmark latest top-N visibility remains pending because the latest digest date is newer than the current Denmark rows.

Known state:

```text
latest digest date after second smoke: 2026-05-09
Denmark latest page-1 newest published_at: 2026-05-08T14:13:40.000000Z
latest digest top-N Denmark visibility: pending
metadata.fallback_to_fixture: false
```

The follow-up scheduled-staging PR must record the expected impact:

```text
Denmark rows may be absent from latest top-N when newer sources dominate
absence from latest top-N is not a failure if date-specific digest/source health proves the live poll
Denmark rows must not dominate the digest after a single scheduled observation
public digest JSON shape must remain unchanged
Pages UI must keep rendering existing sections
```

## Pause Triggers

Immediate pause triggers:

```text
HTTP 401, 403, 408, 409, 423, 429, or repeated 5xx
fetch.mode is not live
fixture fallback appears in a live success claim
GoPublic extension module id changes
category vocabulary changes unexpectedly
ordered request body starts returning 500
search response lacks paging/data.rows/id/headline/issuer/category/publication fields
records_seen exceeds 25 without an explicit config PR
ShortSelling appears in the response
Shareholder appears in the response
public digest JSON response shape changes
Pages UI smoke fails after the scheduled observation
runtime threatens other staging canary sources
```

Rollback path:

```text
remove dk_dfsa_oam_company_announcements from the staging canary source list or schedule
keep source active=false
keep candidate_status=manual_staging_only unless a separate pause status exists
restore page=1 and pageSize=25 if any wider test caused instability
restore the prior category allowlist if a category change caused instability
do not delete canonical records without a separate data-cleanup plan
record rollback evidence in a docs-only PR
```

## Required First Scheduled Observation Result

After any workflow/config PR includes Denmark in staging canary coverage, record a docs-only result PR with:

```text
workflow run URL
workflow event
resolved source list
cron expression or manual dispatch input
artifact name and id
health status
poll status
fetch.mode
fetch.status_code
fetch.bytes
records_seen
records_inserted
canonical_items count
raw_documents count
source health before and after
latest digest status
latest digest fallback_to_fixture
date-specific digest or source-health note if latest top-N does not show Denmark rows
rollback action if any validation fails
```

## Current Status

```text
Denmark DFSA OAM may be considered for a separate staging-only workflow/config PR.
This PR does not add Denmark to any workflow.
This PR does not enable production scheduled polling.
This PR does not set active=true.
This PR does not widen pagination or categories.
Ireland remains blocked until a Dublin-only machine-readable filter is proven.
```
