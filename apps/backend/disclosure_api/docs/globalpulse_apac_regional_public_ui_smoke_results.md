# GlobalPulse APAC Regional Public UI Smoke Results

This document records the APAC fixture-backed public UI smoke after PR #348.

This is documentation-only. It does not add runtime code, routes, controllers, templates, migrations, backend response-shape changes, frontend shell changes, frontend framework changes, login UI, redirects, identity provider callback routes, poll UI, audit UI, public Source Health UI, provider behavior, materializer behavior, canonical behavior, dashboards, alerts, or scheduled live polling.

## Conclusion

```text
GLOBALPULSE_PUBLIC_PAGES_PASS
GLOBALPULSE_BACKEND_CONNECTED_PASS
ASEAN_MARKET_NEWS_UI_PASS
INDIA_MARKET_DISCLOSURE_UI_PASS
ANZ_MARKET_NEWS_UI_PASS
APAC_GENERIC_POLICY_SECTION_PRESENT_EXPECTED
GLOBALPULSE_APAC_REGIONAL_FIXTURE_READY
```

## Baseline

```text
PR: #348 Add GlobalPulse APAC regional fixtures
merge commit: ebdb61d03ef4ac5bb2cb939dbe81bcbe361660f8
branch: phase0-foundation
public Pages URL: https://suam4597-ship-it.github.io/disclosure-automation/
backend URL: https://globalpulse-backend-staging.fly.dev
```

## CI Evidence

The following GitHub Actions checks completed successfully for the #348 merge commit:

```text
Deploy Phase 0 web to GitHub Pages: success
Phase 0 validate: success
Phase 0 report: success
Phase 1 backend verify: success
Phase 1 runtime smoke: success
Phase 1 backend report: success
Phase 1 backend diagnose: success
Phase 1 backend trace: success
```

## Fly Staging Evidence

Fly staging was redeployed from the #348 merge commit.

```text
app: globalpulse-backend-staging
deploy: success
release_command: success
GET /api/health: 200
health status: ok
repo status: up
```

## APAC Fixture Poll Evidence

The following source polls were run with `use_live_fetch=false` and `edition=breaking`.

```text
apac_policy_news: records_seen=1, records_inserted=1, fetch_mode=fixture, status=PASS
asean_market_news: records_seen=2, records_inserted=2, fetch_mode=fixture, status=PASS
india_market_disclosures: records_seen=2, records_inserted=2, fetch_mode=fixture, status=PASS
anz_market_news: records_seen=2, records_inserted=2, fetch_mode=fixture, status=PASS
```

The existing `apac_policy_news` bucket remains intentionally present as generic APAC policy coverage.

## Digest Evidence

```text
GET /api/feed/digest/latest?edition=breaking: 200
digest_date: 2026-05-08
edition: breaking
item_count: 12
metadata.fallback_to_fixture: false
```

Representative APAC items in the digest:

```text
apac_policy_news -> region=apac -> APAC regulators coordinate guidance on market resilience planning
asean_market_news -> region=asean -> Singapore exchange liquidity program lifts ASEAN technology listings
india_market_disclosures -> region=india -> Indian renewable developer files grid-scale storage contract disclosure
anz_market_news -> region=anz -> Australian lithium producers rebound after contract price update
```

## Public UI Smoke Evidence

Browser smoke was run against:

```text
https://suam4597-ship-it.github.io/disclosure-automation/
```

Observed public UI state:

```text
Backend ok
All12
Disclosure tab count: 7
News tab count: 5
Regulatory5
Markets7
High Importance12
```

Observed APAC labels:

```text
ASEAN: PASS
India: PASS
Australia/NZ: PASS
Asia-Pacific: PASS_EXPECTED_GENERIC_BUCKET
```

Representative rendered headlines:

```text
Singapore exchange liquidity program lifts ASEAN technology listings
Indian renewable developer files grid-scale storage contract disclosure
Australian lithium producers rebound after contract price update
APAC regulators coordinate guidance on market resilience planning
```

Screenshot captured locally:

```text
C:\Users\suam4\AppData\Local\Temp\globalpulse-apac-regions-public-smoke.png
```

## Scope Guardrails

This smoke result confirms fixture-backed staging coverage only.

```text
scheduled live APAC polling: not enabled
live endpoint claim: not made
fixture-backed staging coverage: confirmed
backend JSON response shape change: none
frontend framework added: no
poll UI added: no
audit UI added: no
public Source Health UI added: no
```

## Next Step

The APAC fixture/UI track is ready to close. The next safe track is APAC live endpoint candidate verification, split into smaller source-authority tracks:

```text
1. India official live candidate verification
2. ASEAN live candidate verification
3. ANZ live candidate verification
```

Do not claim live success unless a staging run proves:

```text
authority: official or explicitly accepted third-party
machine_readable: RSS, Atom, XML, JSON, or known API shape
http: stable 2xx
parser: rss_v1 compatible or bounded parser PR exists
fallback: metadata.fallback_to_fixture=false
source: fetch.mode=live
UI: item renders in GlobalPulse public Pages
rollback: disabling source does not break SEC live polling
response_shape: public digest JSON response shape unchanged
```

## Explicit Non-Goals

```text
Do not live-poll HTML root URLs with rss_v1.
Do not record fixture fallback as live success.
Do not enable scheduled live polling before staging smoke.
Do not add public poll UI.
Do not add public Source Health UI.
Do not change backend JSON response shape.
Do not add a frontend framework.
Do not enable JP live polling before issue #339 source-authority decision is resolved.
```
