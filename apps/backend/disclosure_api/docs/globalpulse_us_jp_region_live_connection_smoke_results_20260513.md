# GlobalPulse US/JP Region Live Connection Smoke Results - 2026-05-13

This document records the staging verification after connecting the public
GlobalPulse region pages to the existing US SEC history window and the official
Japan TDnet public HTML source.

This is documentation-only. It does not add runtime code, routes, controllers,
templates, migrations, backend response-shape changes, frontend static shell
changes, frontend framework changes, login UI, redirects, identity provider
callback routes, poll UI, audit UI, public Source Health UI, provider behavior,
materializer behavior, canonical behavior, dashboards, alerts, or integrations.

## Merged Changes

```text
PR #628: Expose SEC history on US region page
merge commit: 491d0783ffc102f69163e91e2942ddf1df19d96f

PR #629: Connect JP TDnet official HTML source
merge commit: cd772351184b4100a4e2c7694f8236e0a071c90a
```

## Deployment

```text
app: globalpulse-backend-staging
deploy command: flyctl deploy --remote-only --app globalpulse-backend-staging
release_command: completed successfully
health: GET /api/health returned status=ok
```

## US SEC Region Detail Smoke

Endpoint:

```text
GET /api/feed/digest/latest?edition=breaking&region=us&limit=100&recent_date_limit=60
```

Observed result:

```text
digest_date: 2026-05-13
region: us
source: sec_press_releases
item_count: 29
contains live SEC RSS items: true
contains historical SEC fixture-created items: true
metadata.fallback_to_fixture: false
```

Pages verification:

```text
URL: https://suam4597-ship-it.github.io/disclosure-automation/?region=us
visible title: 미국 전체
visible region chip: 미국 29건 / 평균 90
top item: SEC announces enforcement action tied to disclosure controls
status: rendered successfully
```

## JP TDnet Official HTML Live Smoke

Source health after deploy:

```text
source_key: jp_tdnet_disclosures
source_type: html
parser_key: tdnet_public_list_html_v1
base_url: https://www.release.tdnet.info/inbs/I_list_001_{date}.html
active: true
source_authority: official_public_html
disable_live_fixture_fallback: true
```

Manual live poll:

```text
POST /api/admin/sources/jp_tdnet_disclosures/poll?use_live_fetch=true&edition=breaking
```

Observed poll result:

```text
fetch.mode: live
fetch.strategy: tdnet_public_list_html_v1
fetch.url: https://www.release.tdnet.info/inbs/I_list_001_20260513.html
fetch.query_date: 2026-05-13
fetch.status_code: 200
fetch.fixture_fallback: false
fetch.records_seen: 100
records_seen: 25
records_inserted: 25
```

Digest verification:

```text
GET /api/feed/digest/latest?edition=breaking&region=jp&limit=100&recent_date_limit=60

digest_date: 2026-05-13
region: jp
source: jp_tdnet_disclosures
item_count: 27
fetch_modes observed: live, fixture
metadata.fallback_to_fixture: false
```

Pages verification:

```text
URL: https://suam4597-ship-it.github.io/disclosure-automation/?region=jp
visible title: 일본 전체
visible region chip: 일본 27건 / 평균 90
top item: 大林組 - 2026年3月期 決算短信〔日本基準〕（連結）
status: rendered successfully with Japanese TDnet headlines
```

## Decision State

```text
US_SEC_REGION_DETAIL_READY
JP_TDNET_OFFICIAL_HTML_LIVE_POLL_PASS
JP_THIRD_PARTY_RSS_NOT_USED
JP_SCHEDULED_LIVE_POLLING_STILL_BLOCKED_UNTIL_REPEATED_SMOKE
GLOBALPULSE_US_AND_JP_REGION_PAGES_READY
```

## Guardrails Preserved

```text
production scheduled polling unchanged
public poll UI not added
audit UI not added
public Source Health UI not added
backend digest JSON shape unchanged
frontend framework not added
Yanoshin or other third-party JP source not enabled
fixture fallback not claimed as JP live success
```

## Follow-Up

```text
1. Repeat JP TDnet official HTML live smoke in a later observation window.
2. Record repeated JP smoke before considering scheduled JP polling.
3. Consider adding source display normalization from "Japan TDnet Disclosures" to a Korean label in the static shell.
4. Consider a compact per-item live/fixture badge only if it can be done without changing public digest JSON shape.
```
