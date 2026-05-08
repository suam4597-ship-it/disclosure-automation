# GlobalPulse Regional Live Source Verification Runbook

This document defines the safe sequence for adding regional live sources after the first successful SEC live RSS polling smoke.

This is documentation-only. It does not add runtime code, routes, controllers, templates, migrations, backend response-shape changes, frontend static shell changes, frontend framework changes, login UI, redirects, identity provider callback routes, poll UI, audit UI, public Source Health UI, provider behavior, materializer behavior, canonical behavior, dashboards, alerts, or integrations.

## Current Baseline

```text
first stable live source: sec_press_releases
live source URL: https://www.sec.gov/news/pressreleases.rss
staging poll result: LIVE_SEC_POLL_PASS
records_seen: 25
records_inserted: 25
digest item_count: 11
metadata.fallback_to_fixture: false
```

Recorded in:

```text
apps/backend/disclosure_api/docs/globalpulse_live_sec_polling_smoke_results.md
```

## Regional Order

KR is intentionally moved to the end because the Korean disclosure path needs a separate backend/API integration instead of a simple RSS source swap.

```text
1. JP live source verification
2. EU live source verification
3. CN/TW live source verification
4. APAC live source verification
5. KR live source backend integration
```

## Live Source Acceptance Gates

Before a regional source can be scheduled or treated as live-data ready, it must pass all gates below:

```text
authority: source is official or explicitly accepted as third-party
machine_readable: response is RSS, Atom, XML, JSON, or a known API shape
http: live endpoint returns stable 2xx responses
parser: current parser can parse the payload or a bounded parser PR exists
fallback: successful smoke proves metadata.fallback_to_fixture=false
scope: no poll UI, audit UI, or public Source Health UI is required
privacy: no raw provider/auth/session/request material is exposed
response_shape: public backend response shape remains stable
operations: rate limits, terms, and credentials are documented
rollback: disabling the source does not break SEC live polling
```

## JP Verification Notes

Current sample registry entry:

```text
source_key: jp_tdnet_disclosures
display_name: Japan TDnet Disclosures
current base_url: https://www.release.tdnet.info/
current parser_key: rss_v1
current fixture: source_payloads/jp_tdnet_disclosures.xml
```

Observed quick smoke on 2026-05-08:

```text
GET https://www.release.tdnet.info/
HTTP status: 200
content_type: text/html
result: public web shell, not an RSS feed
decision: do not live-poll this URL with rss_v1
```

Official JPX/TDnet facts to preserve:

```text
TDnet is the authoritative timely disclosure network for Japan listed companies.
Company Announcements Disclosure Service exposes public documents for a limited inspection period.
JPX describes TDnet API Service as a paid direct distribution service.
JPX TDnet API test server responses are dummy data.
```

Unofficial RSS candidate observed:

```text
candidate: Yanoshin TDnet WEB-API
URL: https://webapi.yanoshin.jp/webapi/tdnet/list/recent.rss
HTTP status: 200
root: rss
items observed: 300
first observed item title: MARUWA:2026 year-end earnings summary
first observed item link host path: webapi.yanoshin.jp redirecting to release.tdnet.info PDF
```

Decision:

```text
Do not replace jp_tdnet_disclosures.base_url with Yanoshin RSS by default.
Do not schedule JP live polling until official-vs-third-party authority is decided.
Do not treat the existing release.tdnet.info root URL as an RSS live source.
Keep JP fixture-backed behavior separate from live-source readiness.
```

## JP Next PR Options

Safe implementation options, in preferred order:

```text
1. Add a JP source verification contract that rejects HTML root URLs for rss_v1 live polling.
2. Add a disabled/manual JP candidate source only after source authority is accepted.
3. Add a bounded parser or adapter for an official JPX TDnet API only after credentials/terms are available.
4. Add a staging-only manual workflow input example for JP after a live endpoint is accepted.
```

JP live success should only be recorded after a staging run proves:

```text
Health check: success
Poll live JP source: success
Verify digest: success
fetch.mode: live
metadata.fallback_to_fixture: false
```

## EU/CN/TW/APAC Notes

The current sample registry uses placeholder URLs for these sources:

```text
eu_market_news: https://example.com/globalpulse/eu-market-news
greater_china_market_news: https://example.com/globalpulse/greater-china-market-news
apac_policy_news: https://example.com/globalpulse/apac-policy-news
```

Decision:

```text
Do not live-poll placeholder example.com URLs.
Do not convert fixture-backed placeholder sources into scheduled live sources.
Verify one real endpoint at a time.
Keep source additions stacked and reversible.
```

## KR Deferred Scope

KR is deferred because it needs a separate backend/API integration path.

```text
current sample source_key: kr_dart_disclosures
current base_url: https://dart.fss.or.kr/
current state: not ready for simple RSS live polling
required next shape: dedicated backend/API adapter or proxy integration
priority: after JP, EU, CN/TW, and APAC verification work
```

KR should not block the non-KR regional sequence.

## Stop Conditions

Stop and re-scope if a regional source requires:

```text
adding login UI
adding identity provider callback routes
adding poll UI
adding audit UI
adding public Source Health UI
changing public digest response shape
trusting request-param actor_permissions as production authority
returning raw provider/auth/session/request material
using fixture fallback while claiming live success
using an unofficial source without an explicit policy decision
```
