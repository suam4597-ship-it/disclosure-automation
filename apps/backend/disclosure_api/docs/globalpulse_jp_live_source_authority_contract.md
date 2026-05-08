# GlobalPulse JP Live Source Authority Contract

This document defines the authority and acceptance contract for adding a Japan live source to GlobalPulse after the first successful SEC live RSS polling smoke.

This is documentation-only. It does not add runtime code, routes, controllers, templates, migrations, backend response-shape changes, frontend static shell changes, frontend framework changes, login UI, redirects, identity provider callback routes, poll UI, audit UI, public Source Health UI, provider behavior, materializer behavior, canonical behavior, dashboards, alerts, or integrations.

## Baseline

```text
current regional sequence: JP -> EU -> CN/TW -> APAC -> KR
current JP source key: jp_tdnet_disclosures
current JP fixture: source_payloads/jp_tdnet_disclosures.xml
current JP live status: NOT_READY_FOR_SCHEDULED_LIVE_POLLING
```

The regional live source runbook establishes that JP is first in the non-SEC regional sequence, but should not be enabled until source authority and machine-readable endpoint shape are explicitly accepted.

```text
runbook: apps/backend/disclosure_api/docs/globalpulse_regional_live_source_verification_runbook.md
```

## Current JP Source Registry Entry

```text
source_key: jp_tdnet_disclosures
display_name: Japan TDnet Disclosures
source_type: rss
current base_url: https://www.release.tdnet.info/
current parser_key: rss_v1
current fixture: source_payloads/jp_tdnet_disclosures.xml
```

The current `base_url` is not accepted as a live `rss_v1` source.

## Authority Facts

```text
TDnet is the authoritative timely disclosure network for Japan listed companies.
The public TDnet/Company Announcements Disclosure Service exposes documents through a web experience.
JPX describes a TDnet API Service as a paid direct distribution service.
JPX TDnet API test server responses are dummy data.
```

## Observed Endpoint Results

### Official public root

```text
URL: https://www.release.tdnet.info/
HTTP status: 200
content type: text/html
result: public web shell, not RSS
rss_v1 decision: REJECT
```

This URL must not be scheduled as a live `rss_v1` source.

### Third-party RSS candidate

```text
candidate: Yanoshin TDnet WEB-API
URL: https://webapi.yanoshin.jp/webapi/tdnet/list/recent.rss
HTTP status: 200
root: rss
items observed: 300
first observed item title: MARUWA:2026 year-end earnings summary
first observed item link: webapi.yanoshin.jp redirecting to release.tdnet.info PDF
```

This URL is machine-readable, but it is not accepted by default because it is a third-party source.

## Acceptance Contract

A JP live source can be enabled only if one of the following authority paths is accepted.

### Path A: Official JPX/TDnet API

```text
status: preferred
requires:
- official endpoint or paid API access
- credentials or subscription terms, if needed
- response schema documentation
- parser or adapter implementation
- staging smoke with metadata.fallback_to_fixture=false
```

### Path B: Official public machine-readable endpoint

```text
status: acceptable if verified
requires:
- official JPX/TDnet-owned URL
- machine-readable RSS, Atom, XML, JSON, or known API shape
- stable 2xx responses
- compatible parser or bounded parser PR
- staging smoke with metadata.fallback_to_fixture=false
```

### Path C: Third-party RSS/API candidate

```text
status: blocked until explicitly accepted
requires:
- explicit user/project acceptance that the provider is third-party
- terms/rate-limit review
- source display name showing the third-party provider
- coverage tags marking source authority as third_party
- ability to disable without impacting SEC live polling
- staging smoke with metadata.fallback_to_fixture=false
```

## Explicit Rejections

```text
REJECT: using https://www.release.tdnet.info/ as rss_v1 live source
REJECT: claiming JP live success while falling back to fixture data
REJECT: enabling Yanoshin or any third-party source without an explicit authority decision
REJECT: adding public poll UI, audit UI, or public Source Health UI to support JP live polling
REJECT: changing public digest JSON response shape just to support JP
REJECT: exposing raw provider/auth/session/request diagnostics in public responses
```

## Required Smoke Before JP Live Success

Before JP live success can be recorded, run a staging smoke that proves:

```text
Health check: success
Poll live JP source: success
Verify digest: success
fetch.mode: live
metadata.fallback_to_fixture: false
JP item rendered in GlobalPulse Pages UI
rollback/disabling JP source does not break SEC live polling
```

## Current Decision

```text
JP_LIVE_SOURCE_AUTHORITY_NOT_DECIDED
JP_TDNET_PUBLIC_ROOT_REJECTED_FOR_RSS_V1
YANOSHIN_RSS_CANDIDATE_NOT_ACCEPTED_BY_DEFAULT
JP_FIXTURE_BACKED_BEHAVIOR_REMAINS_ALLOWED_FOR_STAGING_UI_COVERAGE
JP_SCHEDULED_LIVE_POLLING_BLOCKED_UNTIL_AUTHORITY_DECISION
```

## Next Allowed PRs

```text
1. Add a disabled/manual JP candidate only after explicit third-party acceptance.
2. Add an official JPX/TDnet API adapter only after credentials/terms are available.
3. Add a machine-readable official JP source if one is verified.
4. Record JP live polling smoke only after staging proves fetch.mode=live and fallback_to_fixture=false.
```

## Stop Conditions

Stop and re-scope if JP live source work requires:

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
