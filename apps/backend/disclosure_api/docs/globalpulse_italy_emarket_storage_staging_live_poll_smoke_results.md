# GlobalPulse Italy eMarket Storage Staging Live Poll Smoke Results

This document records the first successful staging live poll for the Italy eMarket Storage regulated-communications source candidate.

This is documentation-only. It does not add runtime code, routes, controllers, migrations, backend response-shape changes, frontend static shell changes, frontend framework changes, login UI, redirects, identity provider callback routes, poll UI, audit UI, public Source Health UI, dashboards, alerts, workflow schedules, provider behavior, materializer behavior, canonical behavior, or scheduled polling activation.

## Result

```text
GLOBALPULSE_ITALY_EMARKET_STORAGE_STAGING_DEPLOY_PASS
GLOBALPULSE_ITALY_EMARKET_STORAGE_SOURCE_REGISTERED_MANUAL_ONLY
GLOBALPULSE_ITALY_EMARKET_STORAGE_LIVE_POLL_PASS
GLOBALPULSE_ITALY_EMARKET_STORAGE_LATEST_DIGEST_PASS
GLOBALPULSE_ITALY_EMARKET_STORAGE_PUBLIC_PAGES_DOM_PASS
GLOBALPULSE_ITALY_EMARKET_STORAGE_SCHEDULED_POLLING_STILL_DISABLED
```

## References

```text
source candidate/parser PR: #386 Add Italy eMarket Storage parser candidate
source candidate/parser merge: ce635a66f74be2517261e1b853d9ae02be1e738b
backend app: globalpulse-backend-staging
backend URL: https://globalpulse-backend-staging.fly.dev
public Pages URL: https://suam4597-ship-it.github.io/disclosure-automation/
```

## Source Registration State

```text
source_key: eu_italy_emarket_storage_regulated_communications
display_name: Italy eMarket Storage Regulated Communications
source_type: html
parser_key: emarket_storage_html_v1
active: false
candidate_status: manual_staging_only
base_url: https://www.emarketstorage.it/it/comunicati-finanziari
coverage_tags: eu, eu_south, italy, disclosure, filing, listed_companies, regulated_information, issuer_announcement
```

## Source Health Smoke

```text
request: GET /api/admin/source-health/eu_italy_emarket_storage_regulated_communications
response status: 200
active: false
candidate_status: manual_staging_only
parser_key: emarket_storage_html_v1
health_status before first manual poll: unknown
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

```text
request: POST /api/admin/sources/eu_italy_emarket_storage_regulated_communications/poll?edition=breaking
response status: 202
fetch.mode: live
fetch.status_code: 200
fetch.loaded: true
fetch.bytes: 81163
records_seen: 24
records_inserted: 24
canonical_items: 24
raw_documents: 24
fixture fallback: not used
```

Representative canonical item keys:

```text
breaking-2026-05-08-183735
breaking-2026-05-08-183734
breaking-2026-05-08-183733
```

Representative parser output from the live HTML probe:

```text
MONDO TV FRANCE - Esercizio di n. 1 "Conversion Notice" da parte di Loft Capital Ltd
MONDO TV - Conversione di 2 bond da parte di CLG Capital
DIASORIN - Report on the treasury shares buy-back plan of Diasorin S.p.A. - Period 04/05/2026 - 08/05/2026
```

Observed item metadata:

```text
regions: eu_south
metadata.fetch_mode: live
metadata.source_type: html
category: Comunicati Regolamentati
summary shape: Comunicati Regolamentati | Issuer: <issuer>
canonical_url shape: https://www.emarketstorage.it/sites/default/files/comunicati/<yyyy-mm>/<pdf>.pdf
```

## Latest Digest Smoke

```text
request: GET /api/feed/digest/latest?edition=breaking
response status: 200
digest_date: 2026-05-08
edition: breaking
item_count: 12
Italy eMarket source items present: yes
source.source_key: eu_italy_emarket_storage_regulated_communications
regions include: eu_south
```

Observed latest digest item:

```text
MONDO TV FRANCE - Esercizio di n. 1 "Conversion Notice" da parte di Loft Capital Ltd
```

## Public Pages DOM Smoke

Headless Chrome DOM smoke against the public GitHub Pages URL passed after the Fly staging poll populated the latest digest.

```text
request: https://suam4597-ship-it.github.io/disclosure-automation/
tooling: local Chrome headless --dump-dom --virtual-time-budget=10000
Backend ok: present
Southern Europe: present
Italy eMarket Storage Regulated Communications: present
MONDO TV FRANCE: present
Top Importance includes Italy eMarket item: present
```

## Parser/Runtime Notes

The eMarket Storage public listing is HTML, not RSS. It is not polled with `rss_v1`.

The parser is intentionally bounded:

```text
max rows parsed: 25
accepted row shape: eMarket Storage views-row cards
extracted fields: data_protocollo, PDF URL, timestamp, issuer name, title
rejected payloads: non-eMarket HTML or missing regulated-communications card markers
```

This candidate remains manual-staging-only until the broader EU live-source batch is intentionally selected and rollback is documented.

## Guardrails

```text
scheduled live polling: not enabled
source active flag: remains false
candidate_status: remains manual_staging_only
fixture fallback claimed as live: no
HTML page polled as rss_v1: no
poll UI: not added
audit UI: not added
public Source Health UI: not added
frontend framework: not added
backend public digest JSON response shape: unchanged
JP live polling: unchanged and still blocked pending source authority decision
```

## Next Decision

```text
France Info-Financiere OAM: staging live poll pass
Spain CNMV inside information: staging live poll pass
Spain CNMV other relevant information: staging live poll pass
Netherlands AFM financial reporting: staging live poll pass
Italy eMarket Storage regulated communications: staging live poll pass

Recommended next step:
continue official endpoint/parser discovery for Luxembourg LuxSE OAM, Germany official register surfaces, and Euronext issuer press-release surfaces.

Batch scheduled EU promotion should wait until the target EU batch is intentionally selected and rollback is documented.
```
