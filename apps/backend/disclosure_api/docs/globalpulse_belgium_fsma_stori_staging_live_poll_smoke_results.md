# GlobalPulse Belgium FSMA STORI Staging Live Poll Smoke Results

This document records the manual staging smoke for the Belgium FSMA STORI regulated-information source candidate.

This is documentation-only. It does not add runtime code, routes, controllers, migrations, backend response-shape changes, frontend static shell changes, frontend framework changes, login UI, redirects, identity provider callback routes, poll UI, audit UI, public Source Health UI, provider behavior, materializer behavior, canonical behavior, dashboards, alerts, or scheduled polling.

## Conclusion

```text
GLOBALPULSE_BELGIUM_FSMA_STORI_STAGING_DEPLOY_PASS
GLOBALPULSE_BELGIUM_FSMA_STORI_SOURCE_REGISTERED_MANUAL_ONLY
GLOBALPULSE_BELGIUM_FSMA_STORI_LIVE_POLL_PASS
GLOBALPULSE_BELGIUM_FSMA_STORI_LATEST_DIGEST_PASS
GLOBALPULSE_BELGIUM_FSMA_STORI_PUBLIC_PAGES_DOM_PASS
GLOBALPULSE_BELGIUM_FSMA_STORI_SCHEDULED_POLLING_STILL_DISABLED
```

## Source

```text
source_key: eu_belgium_fsma_stori
display_name: Belgium FSMA STORI Regulated Information
authority class: official national regulator / central regulated-information storage mechanism
base_url: https://webapi.fsma.be/api/v1/en/stori/result
healthcheck_url: https://www.fsma.be/en/stori
parser_key: fsma_stori_api_v1
active: false
candidate_status: manual_staging_only
```

## Deployment

```text
repo: suam4597-ship-it/disclosure-automation
branch: phase0-foundation
source PR: #392 Add Belgium FSMA STORI parser candidate
merge commit: c9782bcfce89f735e0e433dc7607fe36ff1f9909
Fly app: globalpulse-backend-staging
release migration: success
deploy result: success
```

## CI Status

The #392 merge commit completed the current CI set successfully.

```text
Phase 0 validate: success
Phase 0 report: success
Phase 1 backend verify: success
Phase 1 runtime smoke: success
Phase 1 backend report: success
Phase 1 backend diagnose: success
Phase 1 backend trace: success
```

## Health Smoke

```text
GET https://globalpulse-backend-staging.fly.dev/api/health
status: 200
response.status: ok
response.service: disclosure_automation
response.phase: phase1
```

## Source Registration Smoke

```text
GET /api/admin/source-health/eu_belgium_fsma_stori
status: 200
active: false
candidate_status: manual_staging_only
parser_key: fsma_stori_api_v1
base_url: https://webapi.fsma.be/api/v1/en/stori/result
last_seen_published_at: 2026-05-08T18:00:00.000000Z
```

## Live Poll Smoke

```text
POST /api/admin/sources/eu_belgium_fsma_stori/poll?edition=breaking
status: 202
fetch.mode: live
fetch.status_code: 200
fetch.bytes: 30333
records_seen: 25
records_inserted: 25
```

The source used the bounded configured POST body:

```text
startRowIndex: 0
pageSize: 25
sortDirection: Descending
sortColumn: DatePublication
```

Observed live records included:

```text
WDP - Announcement of notification of major shareholding
VAN DE VELDE - Announcement of acquisition of own shares
X-FAB SILICON FOUNDRIES - Minutes of ordinary general meeting
```

## Latest Digest Smoke

```text
GET /api/feed/digest/latest?edition=breaking
status: 200
digest_date: 2026-05-08
edition: breaking
item_count: 12
metadata.fallback_to_fixture: false
```

Observed Belgium FSMA STORI digest item:

```text
headline: WDP - Announcement of notification of major shareholding
source.display_name: Belgium FSMA STORI Regulated Information
source.source_key: eu_belgium_fsma_stori
regions: eu_central
metadata.fetch_mode: live
published_at: 2026-05-08T18:00:00.000000Z
summary: FSMA STORI regulated information | Topic: Announcement of notification of major shareholding | Document: 14. WDP - PB Transparantiekennisgeving 08.05.2026 - nl.pdf | ISIN: BE0974349814
```

## Public Pages DOM Smoke

```text
URL: https://suam4597-ship-it.github.io/disclosure-automation/
browser: local headless Chromium via playwright-core
title: GlobalPulse
Backend ok: present
Central Europe section: present
Belgium FSMA STORI Regulated Information: present
Belgium FSMA STORI headline: present
blocking API/CORS errors: none observed
```

Observed DOM snippets included:

```text
Backend ok
Central Europe 2 items / avg 90
WDP - Announcement of notification of major shareholding
FSMA STORI regulated information | Topic: Announcement of notification of major shareholding | Document: 14. WDP - PB Transparantiekennisgeving 08.05.2026 - nl.pdf | ISIN: BE0974349814
Belgium FSMA STORI Regulated Information
```

One generic browser console 404 message was observed, but Playwright did not capture any failed API or page responses during the smoke. It was not tied to the GlobalPulse backend calls and did not block rendering.

## Guardrails

```text
scheduled polling: still disabled
source.active: false
candidate_status: manual_staging_only
fixture fallback claim: not used for live success
backend JSON response shape: unchanged
frontend framework: unchanged
poll UI: not added
audit UI: not added
public Source Health UI: not added
provider/materializer/canonical behavior: unchanged
JP scheduled live polling: untouched and still blocked by source authority decision
```

## Next Step

```text
Continue EU batch candidate work before promotion.
Recommended next candidate: another official listed-company disclosure or issuer-announcement surface with machine-readable access.
Do not enable scheduled EU live polling until the broader EU candidate batch is explicitly promoted.
```
