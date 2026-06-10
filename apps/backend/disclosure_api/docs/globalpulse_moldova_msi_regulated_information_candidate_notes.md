# Moldova MSI Regulated Information Candidate Notes

Status: `MANUAL_SOURCE_REGISTERED_AND_STAGING_LIVE_POLL_PASS`

## Scope

`md_msi_regulated_information` is an inactive/manual staging-only candidate for regulated issuer information published through Moldova's MSI public storage mechanism.

```text
candidate homepage: https://emitent-msi.market.md/en/
candidate data endpoint: https://emitent-msi.market.md/includes/parts/pubdocs-list.php
source owner/surface: Emitent-MSI / Capital Market public storage mechanism
surface label: Official information storage mechanism
```

## Why This Fits

The homepage describes MSI as a centralized software application for storing regulated information under Moldova capital-market law and for access by end users. The public search form exposes issuer company names, document types, publication dates, and public displayfile download links.

This is listed-company or reporting-entity disclosure material, not a central-bank, macro, policy, or generic market commentary feed.

## Observed Shape

The public page renders a search form, then loads records through an AJAX POST:

```text
POST /includes/parts/pubdocs-list.php
content-type: application/x-www-form-urlencoded
body: page=1&lan=en&f1=0&f2=0&f3=01/01/2025&f4=31/12/2026
```

The response is bounded HTML:

```text
Company name
Document type
Date
Download
/en/displayfile/{id}
```

Observed live rows include:

```text
Moldova Agroindbank - Information about events that affect financial and economic activities of the issuer - 08/05/2026
TERMOELECTRICA - Information about events that affect financial and economic activities of the issuer - 08/05/2026
INTACT ASIGURARI GENERALE - Other ads related to the issuer and to be published in the media - 08/05/2026
```

## Guardrails

```text
active=false
candidate_status=manual_staging_only
disable_live_fixture_fallback=true
scheduled polling disabled
page 1 only
bounded search window only
download/detail fetch out of scope
backend digest JSON response shape unchanged
```

## Verification Plan

```text
local registry/capability smoke: PASS
local fixture parser smoke: PASS, 5 bounded records
application live fetch smoke: PASS, HTTP 200, 10 bounded records from page 1
Fly staging live poll smoke: PASS
canonical insert smoke: PASS
date-specific digest top-N visibility smoke: PENDING
public latest UI visibility smoke: PENDING
```

## Local Smoke Evidence

```text
fixture_count: 5
fixture_first_title: Moldova Agroindbank - Information about events that affect financial and economic activities of the issuer
fixture_first_url: https://emitent-msi.market.md/en/displayfile/4933
fixture_first_published_at: 2026-05-08T00:00:00.000000Z
live_status: 200
live_bytes: 2848
live_count: 10
live_first_title: Moldova Agroindbank - Information about events that affect financial and economic activities of the issuer
live_first_url: https://emitent-msi.market.md/en/displayfile/4933
live_first_published_at: 2026-05-08T00:00:00.000000Z
```

## Fly Staging Smoke Evidence

```text
backend: https://globalpulse-backend-staging.fly.dev
candidate merge commit: f29027e39840d874ac4074abb6d0ec312e02810e
source_health_before: registered, active=false, candidate_status=manual_staging_only, disable_live_fixture_fallback=true
poll: POST /api/admin/sources/md_msi_regulated_information/poll?use_live_fetch=true&edition=breaking
fetch.mode: live
fetch.status_code: 200
fetch.bytes: 2848
records_seen: 10
records_inserted: 10
health_status_after: healthy
last_seen_published_at: 2026-05-08T00:00:00.000000Z
date_specific_digest: 200, fallback_to_fixture=false, Moldova top-N visibility pending
latest_digest: 200, current latest date 2026-05-09, Moldova latest UI visibility pending
```

## Open Follow-Up

The first slice uses a static bounded search window for manual staging. Do not promote this source to scheduled polling until a cadence/date-window design is recorded and repeated staging smoke confirms the endpoint remains stable.
