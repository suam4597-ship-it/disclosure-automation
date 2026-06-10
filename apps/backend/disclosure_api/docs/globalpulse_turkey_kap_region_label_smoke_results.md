# GlobalPulse Turkey KAP Region Label Smoke Results

This document records the staging/backend and public Pages config smoke after separating Turkey KAP/PDP items from the generic Europe bucket.

The change does not enable scheduled polling, does not set the source active, does not change backend digest JSON shape, and does not add public poll UI, audit UI, public Source Health UI, or a frontend framework.

## Conclusion

```text
TURKEY_KAP_CANONICAL_REGION_TR_PASS
TURKEY_KAP_LATEST_DIGEST_REGION_TR_PASS
GLOBALPULSE_PAGES_TURKEY_REGION_LABEL_CONFIG_PASS
GLOBALPULSE_TURKEY_REGION_LABEL_READY
TURKEY_KAP_SCHEDULED_POLLING_DISABLED
```

## Context

```text
source_key: tr_kap_company_notifications
backend PR: #467 Render Turkey KAP as Turkey region
merge commit: c05056d151a2951a74fb4677c7f39ad32abcf992
Fly app: globalpulse-backend-staging
Pages URL: https://suam4597-ship-it.github.io/disclosure-automation/
smoke date: 2026-05-10
```

## Validation

```text
Fly deploy: PASS
GET /api/health: 200
POST /api/admin/sources/tr_kap_company_notifications/poll?use_live_fetch=true&edition=breaking: 202
fetch.mode: live
records_seen: 25
records_inserted: 25
GET /api/feed/digest/latest?edition=breaking: 200
```

Latest digest Turkey KAP rows now render with the canonical region:

```text
headline: FONET ... - Representation Letter (Consolidated)
regions: tr
source: tr_kap_company_notifications

headline: FONET ... - Operating Review (Consolidated)
regions: tr
source: tr_kap_company_notifications

headline: FONET ... - Financial Report
regions: tr
source: tr_kap_company_notifications
```

Pages config smoke:

```text
GET /disclosure-automation/config.js: 200
contains tr: "Turkey": true
contains turkey normalize branch: true
Deploy Phase 0 web to GitHub Pages for c05056d: success
```

## Guardrails

```text
source active=true: no
scheduled polling enabled: no
EU scheduled canary inclusion changed: no
backend digest JSON shape changed: no
public poll UI added: no
audit UI added: no
public Source Health UI added: no
frontend framework added: no
```
