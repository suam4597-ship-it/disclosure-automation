# GlobalPulse Public Web Digest Diversity Refresh

Date: 2026-05-12 KST

This document records the public Pages + Fly staging digest diversity state after the regional dashboard mapping refresh.

It is documentation-only. It does not change frontend code, backend code, routes, public API response shapes, source activation, workflow schedules, production infrastructure, production scheduled polling, public poll UI, audit UI, or public Source Health UI.

## Conclusion

```text
GLOBALPULSE_PUBLIC_WEB_DIGEST_DIVERSITY_REFRESH_RECORDED
PUBLIC_PAGES_PASS
PUBLIC_CONFIG_REGION_MAPPING_REFRESH_VISIBLE
FLY_STAGING_BACKEND_CONNECTED_PASS
LATEST_TOP_N_DIGEST_HAS_NON_INDIA_ROWS
LATEST_TOP_N_DIGEST_HAS_EU_AND_GREATER_CHINA_ROWS
METADATA_FALLBACK_TO_FIXTURE_FALSE
PRODUCTION_SOURCE_PROMOTION_NOT_APPROVED
PRODUCTION_SCHEDULED_POLLING_NOT_ENABLED
```

## Public Smoke Target

```text
pages_url: https://suam4597-ship-it.github.io/disclosure-automation/
config_url: https://suam4597-ship-it.github.io/disclosure-automation/config.js
backend_url: https://globalpulse-backend-staging.fly.dev
digest_url: https://globalpulse-backend-staging.fly.dev/api/feed/digest/latest?edition=breaking
```

## Observed Results

```text
pages_status: 200
pages_has_region_aliases: true
pages_has_region_order: true
config_status: 200
config_has_region_labels: true
config_has_no_load_adapter: true
config_has_staging_backend: true
health_status: ok
digest_item_count: 12
digest_fallback_to_fixture: false
```

Observed digest region mix:

```text
india: 3
ch: 2
eu: 2
eu_north: 1
eu_central: 1
eu_south: 1
uk: 1
greater_china: 1
```

This updates the previous public web digest diversity observation where the latest inspected top-N digest was India-only. The latest inspected public digest is still live-backed and now includes non-India rows.

## Interpretation

```text
India NSE remains strongly visible in the public top-N digest.
Switzerland SIX and UK FCA NSM are visible in the public top-N digest.
EU generic and EU subregion rows are visible in the public top-N digest.
Greater China/HKEX visibility is present in the public top-N digest.
Top-N visibility remains time-window dependent and is not a production promotion approval.
```

## Guardrails

```text
Do not treat this observation as source promotion approval.
Do not set candidate sources active=true.
Do not enable production scheduled polling.
Do not claim complete regional market coverage from top-N visibility.
Do not change backend digest JSON response shape.
Do not add public poll UI.
Do not add audit UI.
Do not add public Source Health UI.
Do not claim fixture fallback as live.
```
