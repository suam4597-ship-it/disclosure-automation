# GlobalPulse Taiwan MOPS Manual Staging Poll Smoke Results

Date: 2026-05-11 KST

This document records the first Fly staging manual live-poll smoke for the inactive Taiwan MOPS daily material-information source candidate.

This is documentation-only. It does not add runtime code, routes, controllers, templates, migrations, backend response-shape changes, frontend shell changes, workflows, production scheduled polling, public poll UI, audit UI, public Source Health UI, provider behavior, materializer behavior, canonical behavior, dashboards, alerts, or integrations.

## Baseline

```text
candidate PR: #521 Add inactive Taiwan MOPS material information candidate
merge commit: 2d07a5bc3f8d96be38377f3869512c37c5176d5d
Fly app: globalpulse-backend-staging
deployed image: registry.fly.io/globalpulse-backend-staging:deployment-01KRAQTF7V30GTYHH44J5RDZZ2
source_key: tw_mops_daily_material_information
parser_key: tw_mops_daily_material_info_json_v1
edition: breaking
```

## Health Check

Request:

```text
GET https://globalpulse-backend-staging.fly.dev/api/health
```

Observed:

```text
health_status: ok
health_service: disclosure_automation
health_phase: phase1
health_repo: up
```

## Manual Live Poll

Request:

```text
POST https://globalpulse-backend-staging.fly.dev/api/admin/sources/tw_mops_daily_material_information/poll?use_live_fetch=true&edition=breaking
```

Observed:

```text
poll_source_key: tw_mops_daily_material_information
poll_records_seen: 12
poll_records_inserted: 12
fetch_mode: live
fetch_status: 200
fetch_bytes: 3099
fetch_query_date: 2026-05-11
fetch_records_seen: 12
fixture_fallback: false
canonical_item_count: 12
first_canonical: breaking-2026-05-10-tw-mops-1463-1150511-1
```

No detail endpoint or attachment endpoint was fetched for this smoke. The source used only the bounded daily list API.

## Source Health

Request:

```text
GET https://globalpulse-backend-staging.fly.dev/api/admin/source-health/tw_mops_daily_material_information
```

Observed:

```text
source_key: tw_mops_daily_material_information
health_status: healthy
active: false
candidate_status: manual_staging_only
disable_live_fixture_fallback: true
last_success_at: 2026-05-11T05:25:15.953752Z
last_seen_published_at: 2026-05-11T03:58:07.000000Z
last_error: null
```

## Digest Visibility

Request:

```text
GET https://globalpulse-backend-staging.fly.dev/api/feed/digest/latest?edition=breaking
```

Observed:

```text
digest_edition: breaking
digest_date: 2026-05-11
digest_generated_at: 2026-05-11T05:25:36Z
digest_item_count: 12
tw_mops_item_count: 2
metadata_fallback_to_fixture: false
first_tw_fetch_mode: live
```

The first Taiwan MOPS digest item rendered a non-ASCII issuer/headline from the MOPS response. This ASCII smoke note records the source, count, and live fetch metadata rather than copying the full original headline.

## Result

```text
TAIWAN_MOPS_MANUAL_STAGING_LIVE_POLL_PASS
TAIWAN_MOPS_DAILY_MATERIAL_INFO_DIGEST_VISIBLE_LIVE
TAIWAN_MOPS_FIXTURE_FALLBACK_DISABLED_CONFIRMED
TAIWAN_MOPS_SOURCE_REMAINS_INACTIVE
TAIWAN_MOPS_PRODUCTION_SCHEDULED_POLLING_NOT_ENABLED
```

## Remaining Guardrails

```text
Do not activate tw_mops_daily_material_information yet.
Do not enable production scheduled polling.
Do not fetch MOPS detail records or attachments.
Do not point tw_market_disclosures at the MOPS API.
Do not add public poll UI, audit UI, or public Source Health UI.
Do not change public digest JSON response shape.
Do not claim Taiwan production readiness from a single manual smoke.
```

## Next Allowed PR

```text
Repeat Taiwan MOPS manual staging smoke in another observation window.
```
