# GlobalPulse AFM Staging Live Poll Smoke Results

This document records the first successful staging live poll for the Netherlands AFM financial-reporting source candidate.

This is documentation-only. It does not add runtime code, routes, controllers, migrations, backend response-shape changes, frontend static shell changes, frontend framework changes, login UI, redirects, identity provider callback routes, poll UI, audit UI, public Source Health UI, dashboards, alerts, workflow schedules, provider behavior, materializer behavior, canonical behavior, or scheduled polling activation.

## Result

```text
GLOBALPULSE_AFM_CSV_STAGING_LIVE_POLL_PASS
GLOBALPULSE_AFM_CSV_FETCH_LIVE_PASS
GLOBALPULSE_AFM_LATIN1_UTF8_NORMALIZATION_PASS
GLOBALPULSE_AFM_RECORDS_SEEN_25
GLOBALPULSE_AFM_RECORDS_INSERTED_25
GLOBALPULSE_AFM_DATE_SPECIFIC_DIGEST_PASS
GLOBALPULSE_AFM_PUBLIC_LATEST_UI_NOT_CLAIMED_DUE_NEWER_DIGEST_DATE
GLOBALPULSE_AFM_SCHEDULED_POLLING_STILL_DISABLED
```

## References

```text
source candidate/parser PR: #381 Add AFM financial reporting parser candidate
bounded parser fix PR: #382 Bound AFM XML parser input before parsing
CSV parser switch PR: #383 Switch AFM candidate to CSV parser
CSV encoding fix PR: #384 Decode AFM CSV payload as UTF-8 safely
CSV encoding fix merge: 8b1d97b5c9eb0a04193f7a84b6479fab6630960c
backend app: globalpulse-backend-staging
backend URL: https://globalpulse-backend-staging.fly.dev
```

## Source Registration State

```text
source_key: eu_netherlands_afm_financial_reporting
display_name: Netherlands AFM Financial Reporting
source_type: api
parser_key: afm_financial_reporting_csv_v1
active: false
candidate_status: manual_staging_only
base_url: https://www.afm.nl/export.aspx?format=csv&type=e8825b05-4004-4301-b736-651e8c61053d
healthcheck_url: https://www.afm.nl/en/sector/registers/meldingenregisters/financiele-verslaggeving
coverage_tags: eu, eu_north, netherlands, disclosure, filing, listed_companies, regulated_information, financial_reporting
```

## Source Health Smoke

```text
request: GET /api/admin/source-health/eu_netherlands_afm_financial_reporting
response status: 200
active: false
candidate_status: manual_staging_only
health_status: healthy
last_error: null
last_failure_at: null
last_success_at: 2026-05-08T17:36:06.306371Z
last_seen_published_at: 2026-05-02T11:29:05.000000Z
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
request: POST /api/admin/sources/eu_netherlands_afm_financial_reporting/poll?edition=breaking
response status: 202
fetch.mode: live
fetch.status_code: 200
fetch.loaded: true
fetch.bytes: 870901
records_seen: 25
records_inserted: 25
canonical_items: 25
raw_documents: 25
fixture fallback: not used
```

Representative canonical item examples:

```text
Ebusco Holding N.V. - Jaarlijkse financiële verslaggeving
Arcona Property Fund N.V. - Jaarlijkse financiële verslaggeving
Morefield Group N.V. - Jaarlijkse financiële verslaggeving
Digi Communications N.V. - Jaarlijkse financiële verslaggeving
Qiagen N.V. - Jaarlijkse financiële verslaggeving
```

Observed item metadata:

```text
regions: eu_north
metadata.fetch_mode: live
metadata.source_type: api
category: Jaarlijkse financiële verslaggeving
summary shape: Reporting year: <year> | Document type: <bounded AFM CSV type>
```

## Date-Specific Digest Smoke

```text
request: GET /api/feed/digest/2026-05-02/breaking
response status: 200
digest_date: 2026-05-02
edition: breaking
metadata.fallback_to_fixture: false
item_count: 1
AFM source items present: yes
```

Observed rendered backend item:

```text
Ebusco Holding N.V. - Jaarlijkse financiële verslaggeving
```

Observed backend fields:

```text
source.display_name: Netherlands AFM Financial Reporting
source.source_key: eu_netherlands_afm_financial_reporting
regions: eu_north
metadata.fetch_mode: live
metadata.source_type: api
canonical_url: https://www.afm.nl/en/sector/registers/meldingenregisters/financiele-verslaggeving
```

## Latest Digest Note

```text
request: GET /api/feed/digest/latest?edition=breaking
response status: 200
latest digest date during smoke: 2026-05-08
latest digest regions during smoke: apac, asean, cn, eu_south, hk, india, tw, us
AFM live item digest date: 2026-05-02
default public latest digest did not need to show the AFM item because newer 2026-05-08 items already existed
date-specific digest confirmed successful ingestion and rendering
```

## Parser/Runtime Notes

The first AFM implementation used the official XML export, but the full XML payload was too memory-heavy for the current small Fly staging machine. The source was switched to the official CSV export because it carries the required bounded fields in a smaller payload.

The CSV export can contain Latin-1 encoded issuer/document text. PR #384 normalizes invalid UTF-8 CSV payloads from Latin-1 to UTF-8 before JSON/DB insertion. The staging live poll and date-specific digest confirmed that the previously failing text now renders as valid UTF-8, including `Jaarlijkse financiële verslaggeving`.

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

Recommended next step:
continue official endpoint/parser discovery for Italy 1Info/eMarket, Luxembourg LuxSE OAM, Germany official register surfaces, and Euronext issuer press-release surfaces.

Batch scheduled EU promotion should wait until the target EU batch is intentionally selected and rollback is documented.
```
