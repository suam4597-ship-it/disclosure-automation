# GlobalPulse EU Info-Financiere Staging Live Poll Smoke Results

This document records the first successful staging live poll for the France Info-Financiere OAM source candidate.

This is documentation-only. It does not add runtime code, routes, controllers, migrations, backend response-shape changes, frontend static shell changes, frontend framework changes, login UI, redirects, identity provider callback routes, poll UI, audit UI, public Source Health UI, provider behavior, materializer behavior, canonical behavior, dashboards, alerts, workflow schedules, or scheduled polling activation.

## Scope

```text
source_key: eu_france_info_financiere_oam
source status: active=false
candidate_status: manual_staging_only
parser_key: info_financiere_oam_v1
backend app: globalpulse-backend-staging
backend URL: https://globalpulse-backend-staging.fly.dev
source URL: https://www.info-financiere.gouv.fr/api/explore/v2.1/catalog/datasets/flux-amf-new-prod/records?limit=25&order_by=uin_dat_amf%20desc
```

## Preconditions

```text
PR #374: Add Info-Financiere OAM parser skeleton
PR #375: Add manual Info-Financiere OAM source candidate
Fly deploy: success
release migration: success
source registration: present in staging
scheduled polling: not enabled
```

## Health Smoke

```text
GET /api/health
status: 200
response.status: ok
response.service: disclosure_automation
response.phase: phase1
response.repo: up
```

## Source Registration Smoke

```text
GET /api/admin/source-health/eu_france_info_financiere_oam
status: 200
active: false
candidate_status: manual_staging_only
source_type: api
parser_key: info_financiere_oam_v1
coverage_tags: eu, france, disclosure, filing, listed_companies, regulated_information
```

## Manual Live Poll Smoke

```text
POST /api/admin/sources/eu_france_info_financiere_oam/poll?edition=breaking
status: 202
fetch.mode: live
fetch.status_code: 200
fetch.loaded: true
fetch.bytes: 65055
records_seen: 25
records_inserted: 25
canonical_items: 25
metadata.fallback_to_fixture: not used on poll result
```

Observed canonical item examples:

```text
breaking-2026-05-07-167812-20260507
breaking-2026-05-07-167810-20260507
breaking-2026-05-07-167808-20260507
```

## Date-Specific Digest Smoke

```text
GET /api/feed/digest/2026-05-07/breaking
status: 200
metadata.fallback_to_fixture: false
item_count: 12
Info-Financiere source items: present
```

Observed rendered backend items:

```text
ABL DIAGNOSTICS - Rapports financiers et d'audit annuels / Modalites de mise a disposition du rapport financier annuel
ABL DIAGNOSTICS - Rapports financiers et d'audit annuels / Rapport financier annuel
TOTALENERGIES EP GABON - Informations privilegiees / Autres communiques
```

Observed item metadata:

```text
source.display_name: France Info-Financiere OAM
source.source_key: eu_france_info_financiere_oam
regions: eu
metadata.fetch_mode: live
metadata.source_type: api
category examples: Annual financial and audit reports, Inside Information
summary examples include bounded type/subtype, ISIN, ticker, and language
```

## Latest Digest Note

```text
GET /api/feed/digest/latest?edition=breaking
status: 200
latest digest date during smoke: 2026-05-08
Info-Financiere live items were dated 2026-05-07
default public latest digest did not need to show the France items because newer 2026-05-08 items already existed
date-specific digest confirmed successful ingestion and rendering
```

## Guardrails Confirmed

```text
scheduled polling remains disabled
source remains active=false
no workflow schedule added
no fixture fallback claimed as live
no public poll UI added
no audit UI added
no public Source Health UI added
no backend response shape change
no frontend framework added
JP live polling remains blocked pending issue #339
```

## Current Conclusion

```text
EU_INFO_FINANCIERE_OAM_STAGING_DEPLOY_PASS
EU_INFO_FINANCIERE_OAM_SOURCE_REGISTERED_MANUAL_ONLY
EU_INFO_FINANCIERE_OAM_LIVE_POLL_PASS
EU_INFO_FINANCIERE_OAM_DIGEST_BY_DATE_PASS
EU_INFO_FINANCIERE_OAM_PUBLIC_LATEST_UI_NOT_CLAIMED_DUE_NEWER_DIGEST_DATE
EU_SCHEDULED_LIVE_POLLING_STILL_DISABLED
```

## Next Safe Steps

```text
1. Add a public UI/date or source visibility smoke if GlobalPulse needs to surface non-latest digest dates.
2. Decide whether to promote eu_france_info_financiere_oam from manual_staging_only to scheduled staging polling.
3. If promoted, add a conservative schedule in the staging poll workflow and record the first scheduled run.
4. Continue EU OAM expansion only after France source behavior remains stable.
```
