# GlobalPulse CN/TW Regional Public UI Smoke Results

This document records the successful CN/TW regional fixture and public GitHub Pages browser smoke after splitting Greater China coverage into separately renderable buckets.

This is documentation-only. It does not add runtime code, routes, controllers, templates, migrations, backend response-shape changes, frontend static shell changes, frontend framework changes, login UI, redirects, identity provider callback routes, poll UI, audit UI, public Source Health UI, provider behavior, materializer behavior, canonical behavior, dashboards, alerts, or integrations.

## Baseline

```text
frontend: GitHub Pages
frontend URL: https://suam4597-ship-it.github.io/disclosure-automation/
backend: https://globalpulse-backend-staging.fly.dev
backend app: globalpulse-backend-staging
relevant PR: #346 Add GlobalPulse CN/TW regional fixtures
relevant merge commit: 0a99fc5783a3d98a29b2691d940f9cfeb2d16e7c
smoke source: user-provided browser/Fly validation and screenshot
screenshot path on local machine: C:/Users/suam4/AppData/Local/Temp/globalpulse-cntw-regions-public-smoke.png
```

## Related Work

```text
PR #346 Add GlobalPulse CN/TW regional fixtures
HKEX official listed-company endpoint scan: globalpulse_hkex_listed_company_endpoint_scan.md
```

## CI Status for PR #346 Merge Commit

GitHub connector verification for commit `0a99fc5783a3d98a29b2691d940f9cfeb2d16e7c`:

```text
Phase 0 validate: success
Phase 0 report: success
Phase 1 backend verify: success
Phase 1 runtime smoke: success
Phase 1 backend report: success
Phase 1 backend diagnose: success
Phase 1 backend trace: success
```

## Deployment and Data Baseline

Reported deployment state:

```text
GitHub Pages deploy: success
Fly staging redeploy: success
new CN/TW source poll: success
old Greater China duplicate rows suppressed: 2
```

PR #346 added or preserved these coverage buckets:

```text
Mainland China Disclosures
Taiwan Market Disclosures
Hong Kong Market News
CN/TW Greater China generic market-news bucket
```

Backend region codes added or verified:

```text
greater_china
cn
tw
hk
```

Pages UI labels added or verified:

```text
CN/TW Greater China
Mainland China
Taiwan
Hong Kong
```

## Public Browser Smoke Result

Public URL:

```text
https://suam4597-ship-it.github.io/disclosure-automation/
```

Observed browser UI:

```text
Backend ok: PASS
All: 12
공시: 8
뉴스: 4
```

CN/TW regional rendering:

```text
Mainland China: PASS
Taiwan: PASS
Hong Kong: PASS
CN/TW Greater China: PASS
```

The generic CN/TW Greater China bucket remains expected because it represents the existing bundled Greater China market-news fixture separately from the new Mainland China, Taiwan, and Hong Kong source buckets.

## Current Conclusion

```text
GLOBALPULSE_PUBLIC_PAGES_PASS
GLOBALPULSE_BACKEND_CONNECTED_PASS
CN_MAINLAND_DISCLOSURE_UI_PASS
TW_MARKET_DISCLOSURE_UI_PASS
HK_MARKET_NEWS_UI_PASS
GREATER_CHINA_GENERIC_NEWS_SECTION_PRESENT_EXPECTED
GLOBALPULSE_CNTW_REGIONAL_FIXTURE_READY
```

## Guardrails

The CN/TW regional fixture and public UI smoke did not require or introduce:

```text
scheduled live CN/TW polling
frontend framework changes
backend route changes
backend JSON response-shape changes
database schema changes
login UI
identity provider callback routes
poll UI
audit UI
public Source Health UI
provider/materializer/canonical contract expansion
request-param actor_permissions as production authority
raw provider/auth/session/request material in public responses
```

## Next Action

The CN/TW fixture layer is now visible in the public GlobalPulse UI.

An HKEXnews official listed-company publication surface has now been scanned. It is relevant, but source registration remains blocked until a backend-compatible query contract and parser shape are accepted.

Recommended next options:

```text
1. Run a Fly/application-runtime probe against a bounded HKEXnews listed-company title-search URL.
2. Search official HKEX/HKEXnews assets for a stable latest/recent query contract.
3. Move to APAC regional fixture/live-source verification.
4. Keep JP deferred and tracked through issue #339 until source authority is decided.
```

Live CN/TW endpoints remain blocked until source authority and machine-readable endpoint shape are verified.
