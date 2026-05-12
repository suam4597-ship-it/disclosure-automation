# GlobalPulse Regional Frontend Backend Mapping Smoke Results

Date: 2026-05-12 KST

This document records the refreshed public dashboard region-mapping stabilization work.

It replaces the stale/conflicting PR #427 approach with a current `phase0-foundation` implementation. It does not change backend runtime behavior, routes, digest JSON response shapes, source activation, scheduled polling, production infrastructure, public poll UI, audit UI, or public Source Health UI.

## Conclusion

```text
GLOBALPULSE_REGIONAL_MAPPING_REFRESH_RECORDED
CONFIG_REGION_METADATA_AVAILABLE_BEFORE_DASHBOARD_RENDER
LOAD_TIME_DOUBLE_FETCH_REMOVED
BACKEND_REGIONS_RENDER_AS_DISTINCT_DASHBOARD_BUCKETS
PUBLIC_PAGES_STAGING_BACKEND_CONTRACT_UNCHANGED
PRODUCTION_SCHEDULED_POLLING_NOT_ENABLED
```

## Implementation Scope

Changed files:

```text
apps/web/config.js
apps/web/index.html
apps/backend/disclosure_api/docs/globalpulse_regional_frontend_backend_mapping_smoke_results.md
```

`apps/web/config.js` now exposes these shared dashboard values before the inline dashboard script runs:

```text
window.GLOBALPULSE_REGION_LABELS
window.GLOBALPULSE_REGION_ALIASES
window.GLOBALPULSE_REGION_ORDER
```

`apps/web/index.html` now consumes those values directly when normalizing and sorting backend digest regions.

The previous load-event adapter pattern is removed. That avoids overriding `canonicalRegion`/`regionLabel` after first render and avoids calling `loadBackend()` a second time from `config.js`.

## Region Labels Covered

```text
global -> Global
us -> US Americas
greater_china -> CN/TW Greater China
cn -> Mainland China
tw -> Taiwan
hk -> Hong Kong
apac -> Asia-Pacific
asean -> ASEAN
india -> India
anz -> Australia/NZ
eu -> EU Europe
eu_north -> Northern Europe
eu_central -> Central Europe
eu_south -> Southern Europe
uk -> United Kingdom
ch -> Switzerland
tr -> Turkey
kr -> KR Korea
jp -> JP Japan
other -> Other Regions
```

## Current Staging Digest Evidence

Observed from:

```text
GET https://globalpulse-backend-staging.fly.dev/api/feed/digest/latest?edition=breaking
```

Result:

```text
status: 200
edition: breaking
item_count: 12
metadata.fallback_to_fixture: false
digest_date: 2026-05-12
```

Observed primary region buckets:

```text
india: 3
eu: 2
ch: 2
uk: 1
eu_central: 1
eu_north: 1
greater_china: 1
eu_south: 1
```

Representative backend item shape includes the canonical `regions` array:

```text
headline: Voltamp Transformers Limited
source.source_key: india_nse_announcements
regions: india
metadata.fetch_mode: live

headline: Increase/Decrease of issue size
source.source_key: ch_six_ser_official_notices
regions: ch
metadata.fetch_mode: live
```

## Verification

Local static syntax checks:

```text
node --check apps/web/config.js
node --check extracted inline script from apps/web/index.html
```

Expected public smoke contract remains:

```text
GET public Pages URL: 200
GET public config.js: 200
config.js points to https://globalpulse-backend-staging.fly.dev
GET Fly staging /api/health: 200 ok
GET Fly staging /api/feed/digest/latest?edition=breaking: 200
metadata.fallback_to_fixture=false
```

## Guardrails

```text
No backend JSON response shape change.
No route change.
No frontend framework added.
No public poll UI added.
No audit UI added.
No public Source Health UI added.
No source active=true promotion.
No production scheduled polling.
No production infrastructure change.
No fixture fallback claimed as live.
```
