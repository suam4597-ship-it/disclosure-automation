# Stage 5.9 cross-source duplicate group lock close-out

This document locks Stage 5.9 cross-source duplicate group work after the operator-only read route was merged.

## Scope

Stage 5.9 introduced internal/operator-only duplicate group contracts, storage, materialization, read projection, and read-only admin routes for duplicate group review.

The stage remains advisory-only and non-canonical. It does not change public feed/API response shapes and does not mutate canonical disclosure facts.

## Lock evidence

```text
PR #125 Design Stage 5.9 cross-source duplicate groups
merge commit: 19cd328b4ce915c253c26ca496a6b40a4779df36
scope: docs-only duplicate group design/checklist/manual smoke

PR #126 Add Stage 5.9 cross-source duplicate group contract
merge commit: c26ebf8658d389c60994a260003ab571d2e6a317
scope: pure duplicate group contract + targeted tests + manual smoke

PR #127 Add Stage 5.9 duplicate group projection contract
merge commit: 20e024a83fba52ec6734063c8398b4c89dfbb59c
scope: pure internal/operator projection contract + targeted tests + manual smoke

PR #128 Add Stage 5.9 duplicate group noop service
merge commit: b55ee9d4172131ba20dce09a955aaf15425796ed
scope: internal duplicate group no-op preview service + targeted tests + manual smoke

PR #129 Design Stage 5.9 duplicate group storage schema
merge commit: 9efa65c42e26d1c361a2090cd876be90368470df
scope: docs-only internal storage/schema design

PR #130 Add Stage 5.9 duplicate group storage migration
merge commit: 2b3f49920bade1fbb4a8f8233a22489a4e877f4c
scope: source_duplicate_groups and source_duplicate_group_members migration + manual smoke

PR #131 Add Stage 5.9 duplicate group schemas
merge commit: 85326e048717f4585a0dc8629aaaff68da2f9940
scope: SourceDuplicateGroup / SourceDuplicateGroupMember schemas + changeset tests + manual smoke

PR #132 Add Stage 5.9 duplicate group internal materializer
merge commit: 1296e8c8eddbb90fb3476229d83db1f9dcbbbeb1
scope: internal materializer using existing fixture sources only + targeted tests + manual smoke

PR #133 Design Stage 5.9 duplicate group operator review route
merge commit: c297e7d23f2618070af168d7e33fc1a5aa45beb1
scope: docs-only operator review route design/guardrails/manual smoke

PR #134 Add Stage 5.9 duplicate group internal read projection
merge commit: 19badf3ffd80717ea5a8f57b49e5aadefb7efa2c
scope: internal read-only duplicate group projection + targeted tests + manual smoke

PR #135 Add Stage 5.9 duplicate group operator read route
merge commit: b5fdb0409883ccf38dbc95dcc8410f1be52a5223
scope: read-only admin list/show routes + targeted route tests + manual smoke
```

## Locked behavior

Stage 5.9 now locks the following behavior:

```text
internal duplicate group contract validation
bounded internal/operator projection
no-op preview service over locked existing fixture source keys
internal duplicate group storage tables
schema changesets with bounded redaction checks
internal materialization into source_duplicate_groups and source_duplicate_group_members
idempotent group upsert by group_id
idempotent member upsert by group_id + member_id
internal read-only projection over persisted duplicate group rows
read-only admin list/show routes for operator review
bounded route filters: confidence, source_key, member_kind, redaction_status, limit
bounded 400 errors for unsupported filters
bounded 404 errors for missing groups
```

## Locked source allowlist

Stage 5.9 materialization remains restricted to existing locked fixture/source keys:

```text
jp_tdnet_timely_disclosure
stage5_news_overlay_fixture
stage53_news_overlay_fixture
```

Unknown source keys must remain rejected before DB writes.

## Locked internal storage

The Stage 5.9 duplicate group storage tables are internal only:

```text
source_duplicate_groups
source_duplicate_group_members
```

Locked idempotency guarantees:

```text
source_duplicate_groups unique by group_id
source_duplicate_group_members unique by group_id + member_id
rerun must not duplicate rows
```

Allowed group storage remains bounded metadata only:

```text
group_id
confidence
source_keys
match_reasons
member_count
has_official_tdnet_event
has_provider_overlay
redaction_status
inserted_at
updated_at
```

Allowed member storage remains bounded metadata only:

```text
group_id
member_id
member_kind
source_key
provider
external_id_hash
official_event_id
overlay_id
confidence
match_reasons
redaction_status
inserted_at
updated_at
```

## Locked operator read routes

The only Stage 5.9 duplicate group routes locked in this stage are read-only admin routes:

```text
GET /api/admin/duplicate-groups
GET /api/admin/duplicate-groups/:group_id
```

These routes must remain read-only and must be backed by the internal read projection.

They must not:

```text
trigger duplicate group materialization
write source_duplicate_groups rows
write source_duplicate_group_members rows
mutate canonical data
trigger live provider fetch
trigger scheduler work
call provider clients
```

## Locked non-goals

Stage 5.9 does not lock or authorize:

```text
public duplicate group fields
public API duplicate group exposure
public feed duplicate group exposure
UI duplicate group review
confirm/reject duplicate group actions
action endpoints
audit writes
operator mutation behavior
scheduler-triggered grouping
provider live fetch
provider clients
canonical feed mutation
provider canonical feed item creation
news-only canonical event creation
official TDnet event merge
official fact override
official citation override
```

Any future work in these areas requires a new docs/design PR before implementation.

## Public response-shape lock

Stage 5.9 must preserve existing public response shapes:

```text
GET /api/events/:event_id
GET /api/events/:event_id/news-overlay
GET /api/feed/digest/latest
GET /api/feed/digest/:digest_date/:edition
item.overlays[]
news_overlays[]
feed item_count
feed ordering
official TDnet fields
official citations
public API envelope
public feed envelope
```

Public duplicate group fields remain absent unless a future response-shape design explicitly changes that policy.

## Canonical no-mutation lock

Stage 5.9 duplicate grouping remains advisory and non-canonical.

Forbidden canonical behavior remains locked:

```text
canonical_feed_items mutation
provider canonical feed item creation
news-only canonical event creation
official TDnet event merge
official fact override
official citation override
canonical fact override
```

## Redaction lock

Stage 5.9 changed files, storage, projections, routes, tests, docs, logs, review comments, and manual-smoke output must not include non-redacted private provider or operator material.

Forbidden material:

```text
provider secret values
provider transport material
request header values
response header values
cookie values
raw provider response bodies
full article text
canonical feed payloads
provider canonical creation payloads
raw body similarity payloads
full text similarity payloads
unbounded diagnostics
raw actor identifiers
raw request identifiers
```

Allowed placeholders:

```text
REDACTED_PROVIDER_KEY
REDACTED_PROVIDER_TOKEN
REDACTED_OPERATOR_ID
REDACTED_REQUEST_ID
```

## Regression suite to preserve

Future Stage 5.9 adjacent work should preserve these checks:

```powershell
$env:MIX_ENV='test'; mix.bat test test/stage59_duplicate_group_operator_read_route_test.exs
$env:MIX_ENV='test'; mix.bat test test/stage59_duplicate_group_internal_read_projection_test.exs
$env:MIX_ENV='test'; mix.bat test test/stage59_duplicate_group_internal_materializer_test.exs
$env:MIX_ENV='test'; mix.bat test test/stage59_duplicate_group_schema_test.exs
$env:MIX_ENV='test'; mix.bat test test/stage59_duplicate_group_noop_service_test.exs
$env:MIX_ENV='test'; mix.bat test test/stage59_duplicate_group_projection_contract_test.exs
$env:MIX_ENV='test'; mix.bat test test/stage59_cross_source_duplicate_group_contract_test.exs
$env:MIX_ENV='test'; mix.bat test test/stage53_multi_overlay_response_contract_test.exs
$env:MIX_ENV='test'; mix.bat test test/stage52_news_overlay_attachment_materializer_test.exs
$env:MIX_ENV='test'; mix.bat test test/stage5_news_overlay_feed_visible_test.exs
$env:MIX_ENV='test'; mix.bat test test/stage5_news_overlay_api_exposure_test.exs
$env:MIX_ENV='test'; mix.bat test test/jp_tdnet_timely_disclosure_runtime_idempotency_test.exs
$env:MIX_ENV='test'; mix.bat test test/jp_tdnet_timely_disclosure_http_smoke_test.exs
```

## Future work gates

Before any future duplicate group UI, action, audit, public exposure, scheduler, provider, or canonical work, require a separate design PR that states:

```text
scope and non-goals
authorization and permission model
audit requirements
redaction policy
idempotency policy
public response-shape impact
canonical no-mutation or explicit mutation design
failure isolation behavior
targeted tests
manual smoke checklist
```

## Close-out validation

This close-out PR is docs-only.

It must not change:

```text
runtime code
tests
fixtures
migrations
schema modules
router
controllers
UI code
action endpoints
scheduler code
provider clients
live fetch code
feed/controller behavior
API response behavior
feed response behavior
materializer behavior
canonical mutation behavior
```
