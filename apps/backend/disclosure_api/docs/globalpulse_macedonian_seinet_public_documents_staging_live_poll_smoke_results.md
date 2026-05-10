# North Macedonia SEI-NET Public Documents Staging Live Poll Smoke Results

Status: `MACEDONIAN_SEINET_PUBLIC_DOCUMENTS_STAGING_LIVE_POLL_PASS`

## Scope

This records the first Fly staging live poll smoke for the inactive/manual-staging SEI-NET public documents candidate.

```text
source_key: mk_seinet_public_documents
parser_key: seinet_public_documents_json_v1
source_type: api
candidate_status: manual_staging_only
active: false
disable_live_fixture_fallback: true
deployment commit: dc51edf0ea9505675c342fa1ea067f46f1c7ec89
backend URL: https://globalpulse-backend-staging.fly.dev
```

## Results

```text
GET /api/health: 200
service: disclosure_automation
phase: phase1

GET /api/admin/source-health/mk_seinet_public_documents: 200
active: false
candidate_status: manual_staging_only
disable_live_fixture_fallback: true
live_method: post
live_body.languageId: 2
live_body.channelId: 1
live_body.page: 1

POST /api/admin/sources/mk_seinet_public_documents/poll?use_live_fetch=true&edition=breaking: 202
fetch.mode: live
fetch.status_code: 200
fetch.bytes: 50183
records_seen: 10
records_inserted: 10
canonical_items_count: 10
fixture_fallback: false

GET /api/admin/source-health/mk_seinet_public_documents after poll: 200
health_status: healthy
last_success_at: 2026-05-10T14:21:41.497510Z
last_seen_published_at: 2026-05-08T15:47:00.177000Z
```

## Digest Visibility

```text
GET /api/feed/digest/2026-05-08/breaking: 200
metadata.fallback_to_fixture: false
SEI-NET default digest top-N count: 0

GET /api/feed/digest/latest?edition=breaking: 200
latest digest_date: 2026-05-09
SEI-NET latest top-N count: 0
```

This is recorded as `DATE_SPECIFIC_DIGEST_TOP_N_VISIBILITY_PENDING`, not as a poll failure. The live poll produced canonical item keys for 2026-05-08, but the public digest default top-N selection was already filled by other source rows.

## Guardrails

```text
scheduled polling remains disabled
source remains active=false
fixture fallback disabled
backend digest JSON response shape unchanged
no public poll UI
no audit UI
no public Source Health UI
no frontend framework change
no JP live polling change
```

