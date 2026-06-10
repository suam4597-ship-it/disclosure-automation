# GlobalPulse Spain CNMV Staging Live Poll Smoke Results

This document records the Spain CNMV listed-company disclosure live smoke after the EU source direction was narrowed to official issuer disclosures and announcements.

This is documentation-only. It does not add runtime code, routes, controllers, migrations, backend response-shape changes, frontend static shell changes, frontend framework changes, login UI, redirects, identity provider callback routes, poll UI, audit UI, public Source Health UI, dashboards, alerts, scheduled polling, provider behavior, materializer behavior, or canonical behavior.

## Result

```text
GLOBALPULSE_BACKEND_CONNECTED_PASS
SPAIN_CNMV_INSIDE_INFORMATION_STAGING_LIVE_POLL_PASS
SPAIN_CNMV_OTHER_RELEVANT_INFORMATION_STAGING_LIVE_POLL_PASS
SPAIN_CNMV_PUBLIC_PAGES_UI_PASS
SPAIN_CNMV_MANUAL_STAGING_ONLY_READY
EU_SCHEDULED_LIVE_POLLING_STILL_BLOCKED_PENDING_BATCH_PROMOTION_DECISION
```

## References

```text
source candidate PR: #377 Add Spain CNMV disclosure source candidates
source candidate merge: 72a723ce01a9c8ab0b5c51b223ed43e2b86c62d1
parser compatibility PR: #378 Handle UTF-8 RSS tag variants
parser compatibility merge: 4bc9023147ebcd31d17c3264fdb8899c61fe2249
backend app: globalpulse-backend-staging
backend URL: https://globalpulse-backend-staging.fly.dev
public Pages URL: https://suam4597-ship-it.github.io/disclosure-automation/
```

## Source Registration State

```text
source_key: eu_spain_cnmv_inside_information
display_name: Spain CNMV Inside Information
source_type: rss
parser_key: rss_v1
active: false
candidate_status: manual_staging_only
base_url: https://www.cnmv.es/portal/informacion-privilegiada/RSS.asmx/GetNoticiasCNMV
```

```text
source_key: eu_spain_cnmv_other_relevant_information
display_name: Spain CNMV Other Relevant Information
source_type: rss
parser_key: rss_v1
active: false
candidate_status: manual_staging_only
base_url: https://www.cnmv.es/portal/Otra-Informacion-Relevante/RSS.asmx/GetNoticiasCNMV
```

## CI Status

Merge commit `4bc9023147ebcd31d17c3264fdb8899c61fe2249` completed the expected phase0/phase1 checks.

```text
Phase 0 validate: success
Phase 0 report: success
Phase 1 backend verify: success
Phase 1 backend report: success
Phase 1 backend diagnose: success
Phase 1 backend trace: success
Phase 1 runtime smoke: success
```

## Fly Staging Deploy

```text
fly app: globalpulse-backend-staging
deploy command: fly deploy --remote-only --app globalpulse-backend-staging
deploy result: success
release_command: success
health check: GET /api/health -> 200
health body: {"status":"ok","service":"disclosure_automation","phase":"phase1","repo":"up"}
```

## Manual Live Poll Smoke

### Spain CNMV Inside Information

```text
request: POST /api/admin/sources/eu_spain_cnmv_inside_information/poll?edition=breaking
response status: 202
fetch.mode: live
fetch.status_code: 200
fetch.bytes: 3639
records_seen: 5
records_inserted: 5
canonical_items: 5
fixture fallback: not used
```

Representative canonical item keys:

```text
breaking-2026-05-08-https-www-cnmv-es-portal-informacion-privilegiada-resultado-ip-aspx-nreg-3209
breaking-2026-05-08-https-www-cnmv-es-portal-informacion-privilegiada-resultado-ip-aspx-nreg-3208
```

### Spain CNMV Other Relevant Information

```text
request: POST /api/admin/sources/eu_spain_cnmv_other_relevant_information/poll?edition=breaking
response status: 202
fetch.mode: live
fetch.status_code: 200
fetch.bytes: 22777
records_seen: 25
records_inserted: 25
canonical_items: 25
fixture fallback: not used
```

Representative canonical item keys:

```text
breaking-2026-05-08-https-www-cnmv-es-portal-otra-informacion-relevante-resultado-oir-aspx-nreg-40752
breaking-2026-05-08-https-www-cnmv-es-portal-otra-informacion-relevante-resultado-oir-aspx-nreg-40751
```

## Digest Smoke

```text
request: GET /api/feed/digest/latest?edition=breaking
response status: 200
digest_date: 2026-05-08
edition: breaking
item_count: 12
Spain CNMV items present: yes
metadata.fetch_mode for CNMV items: live
regions for CNMV items: eu_south
backend JSON response shape changed: no
```

Representative rendered backend items:

```text
ACS, ACTIVIDADES DE CONSTRUCCION Y SERVICIOS, S.A.
GRUPO EZENTIS, S.A.
```

## Public Pages UI Smoke

Browser DOM smoke against `https://suam4597-ship-it.github.io/disclosure-automation/` passed.

```text
Backend ok: present
Backend digest live: present
Southern Europe: present
Spain CNMV Other Relevant Information: present
Spain CNMV Inside Information: present
ACS, ACTIVIDADES DE CONSTRUCCION Y SERVICIOS, S.A.: present
GRUPO EZENTIS, S.A.: present
fatal console errors: none observed
```

## Guardrails

```text
scheduled live polling: not enabled
source active flags: remain false
poll UI: not added
audit UI: not added
public Source Health UI: not added
frontend framework: not added
backend public digest JSON response shape: unchanged
fixture fallback claimed as live: no
HTML page polled as rss_v1: no
JP live polling: unchanged and still blocked pending source authority decision
```

## Next Decision

```text
France Info-Financiere OAM: staging live poll pass
Spain CNMV inside information: staging live poll pass
Spain CNMV other relevant information: staging live poll pass

Recommended next step:
continue official endpoint/parser discovery for Netherlands AFM, Italy 1Info/eMarket, Luxembourg LuxSE OAM, Germany official register surfaces, and Euronext issuer press-release surfaces.

Batch scheduled EU promotion should wait until the target EU batch is intentionally selected and rollback is documented.
```
