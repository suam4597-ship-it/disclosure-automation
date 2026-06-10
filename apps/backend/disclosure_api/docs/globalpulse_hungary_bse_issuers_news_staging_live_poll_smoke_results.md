# GlobalPulse Hungary BSE Issuers News staging live poll smoke results

## Summary

```text
HUNGARY_BSE_ISSUERS_NEWS_SOURCE_REGISTERED
HUNGARY_BSE_ISSUERS_NEWS_STAGING_LIVE_POLL_PASS
HUNGARY_BSE_ISSUERS_NEWS_DATE_SPECIFIC_DIGEST_PASS
HUNGARY_BSE_ISSUERS_NEWS_PUBLIC_LATEST_UI_VISIBILITY_PENDING_EXPECTED
HUNGARY_BSE_ISSUERS_NEWS_SCHEDULED_POLLING_DISABLED
```

## Scope

```text
source_key: hu_bse_issuers_news
display_name: Hungary Budapest Stock Exchange Issuers News
source_type: html
parser_key: bse_issuers_news_html_v1
source URL: https://www.bse.hu/issuers_news
authority: official Budapest Stock Exchange issuer-news surface
mode: manual staging live poll only
scheduled polling: disabled
```

## Deployment

```text
phase0-foundation merge commit: 15e813777025a9d13fdee1a40d91977c259158f3
Fly app: globalpulse-backend-staging
Fly URL: https://globalpulse-backend-staging.fly.dev/
Fly deploy: success
release_command: success
Fly image: registry.fly.io/globalpulse-backend-staging:deployment-01KR57XBY7EGAAY2DE60G42VS7
CI:
- Phase 0 validate: success
- Phase 0 report: success
- Phase 1 backend verify: success
- Phase 1 runtime smoke: success
- Phase 1 backend report: success
- Phase 1 backend diagnose: success
- Phase 1 backend trace: success
```

## Automated checks

```text
local compile: PASS
local format check: PASS
local fixture parser smoke: PASS, 2 records, first external_id=129459382
local live parser smoke: PASS, 10 records, first external_id=129459518
```

Note:

```text
compile emitted existing Phoenix dependency typing warnings in output but exited 0.
```

## Staging API smoke

```text
GET /api/health
status: 200
body.status: ok
body.service: disclosure_automation
```

```text
POST /api/admin/sources/hu_bse_issuers_news/poll?use_live_fetch=true&edition=breaking
status: 202
fetch.mode: live
fetch.status_code: 200
fetch.bytes: 158451
records_seen: 10
records_inserted: 10
canonical_items: 10
metadata.fallback_to_fixture: false
```

## Digest smoke

Latest digest:

```text
GET /api/feed/digest/latest?edition=breaking
status: 200
digest_date: 2026-05-09
metadata.fallback_to_fixture: false
result: latest digest currently contains India 2026-05-09 items, so Hungary 2026-05-08 items are not expected in latest UI yet.
```

Date-specific digest:

```text
GET /api/feed/digest/2026-05-08/breaking
status: 200
digest_date: 2026-05-08
item_count: 12
metadata.fallback_to_fixture: false
hungary_count: 1
```

First Hungary item:

```text
source: Hungary Budapest Stock Exchange Issuers News
region: eu_central
headline: MULTIHOME Nyrt. - Közgyűlési előterjesztések, határozati javaslatok
canonical_url: https://www.bse.hu/site/newkib/hu/2026.05./MULTIHOME_Nyrt._-_Kozgyulesi_eloterjesztesek_hatarozati_javaslatok_129459518
summary: Budapest Stock Exchange issuer news | Issuer: MULTIHOME Nyrt.
published_at: 2026-05-08T19:48:00Z
```

## Public UI status

```text
PUBLIC_LATEST_UI_VISIBILITY_PENDING_EXPECTED
```

Reason:

```text
The public Pages shell renders the latest digest date.
After the BSE poll, latest digest remained 2026-05-09 with India items.
The Hungary live records are dated 2026-05-08, so they are verified through the date-specific digest endpoint rather than the public latest UI.
```

## Guardrails

```text
No scheduled polling promotion.
No public poll UI.
No audit UI.
No public Source Health UI.
No backend JSON response shape change.
No frontend framework change.
No central-bank, macro, or policy source added.
No fixture fallback claimed as live success.
```
