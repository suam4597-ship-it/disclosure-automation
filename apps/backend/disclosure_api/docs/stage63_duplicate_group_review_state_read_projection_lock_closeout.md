# Stage 6.3 duplicate group review state read projection lock close-out

This document locks Stage 6.3 duplicate group review state read projection behavior after the design, internal read projection, and admin read route response updates were merged.

## Scope

Stage 6.3 exposes bounded duplicate group review state metadata through existing internal/operator-only duplicate group read paths.

The read behavior remains internal/admin only. It does not add UI, public duplicate group fields, scheduler work, provider clients, live fetch behavior, materializer behavior changes, action write behavior changes, action route behavior changes, or canonical mutations.

## Lock evidence

```text
PR #151 Design Stage 6.3 duplicate group review state read projection
merge commit: 3cfeef64f58940ccd1d18d73c04f56825cd5233a
scope: docs-only read projection design, guardrails, manual smoke

PR #152 Add Stage 6.3 duplicate group review state read projection
merge commit: 4fcb9c5a0e559fc4143658e2b597bd4b52de5d1c
scope: internal read projection update, targeted projection tests, manual smoke

PR #153 Add Stage 6.3 duplicate group admin read route response metadata
merge commit: 5e795eefeb8846d4332430e4c378a1e1d9e4991f
scope: admin read route response serialization, targeted route tests, manual smoke
```

## Locked internal/operator-only read routes

Stage 6.3 keeps the existing internal/operator-only duplicate group read routes:

```text
GET /api/admin/duplicate-groups
GET /api/admin/duplicate-groups/:group_id
```

No new read routes are added by Stage 6.3.

## Locked action routes remain separate

Stage 6.3 does not change these existing operator-only action routes:

```text
POST /api/admin/duplicate-groups/:group_id/confirm
POST /api/admin/duplicate-groups/:group_id/reject
POST /api/admin/duplicate-groups/:group_id/mark-review
POST /api/admin/duplicate-groups/:group_id/clear-review-state
```

Action routes remain the only route layer path that can record duplicate group action state.

## Locked read projection sources

Stage 6.3 read projections may read bounded metadata from:

```text
source_duplicate_group_review_states
source_duplicate_group_action_events
```

Read projection code must treat both tables as read-only sources.

Stage 6.3 read projection code must not write, upsert, backfill, compact, repair, or delete rows in either table.

## Locked current review state summary

Internal duplicate group list and show projections may expose a bounded `review_state_summary` object.

Allowed fields:

```text
review_state
last_action_operation
last_action_request_id_hash
last_action_idempotency_key_hash
reviewed_by_actor_id_hash
reviewed_at
review_reason_redacted
redaction_status
```

Missing review state rows must be represented as bounded null metadata. Missing review state rows must not trigger writes.

## Locked action event summary

Internal duplicate group show projections may expose a bounded `action_event_summary` list.

Allowed fields:

```text
action_operation
required_permission
actor_id_hash
request_id_hash
idempotency_key_hash
result_status
pre_review_state
post_review_state
failure_code
redaction_status
inserted_at
```

The action event summary is locked to the latest five events.

Internal duplicate group list projections must not expose action event history.

## Locked admin read route response behavior

Admin read route responses serialize bounded read projection metadata only.

Locked behavior:

```text
GET /api/admin/duplicate-groups includes review_state_summary per item
GET /api/admin/duplicate-groups does not include action_event_summary
GET /api/admin/duplicate-groups/:group_id includes review_state_summary
GET /api/admin/duplicate-groups/:group_id includes action_event_summary
reviewed_at serializes as ISO8601 string or null
inserted_at serializes as ISO8601 string or null
```

The controller serializes data already present in the internal read projection. It must not directly query or write action state tables.

## Locked action/write separation

Stage 6.3 does not change or bypass:

```text
Stage61DuplicateGroupActionStateWriter.record_action/3
Stage60DuplicateGroupOperatorActionAuthorizationGate
Stage60DuplicateGroupOperatorActionContract
Stage60DuplicateGroupOperatorActionAuditContract
SourceDuplicateGroupActionEvent changeset
SourceDuplicateGroupReviewState changeset
```

The Stage 6.1 writer remains the only persistence path for action state.

## Locked forbidden response material

Stage 6.3 read projections and admin read route responses must not expose:

```text
raw actor identifiers
raw request identifiers
raw idempotency keys
unredacted operator reason
raw provider payloads
full article text
canonical payloads
private transport material
unbounded diagnostics
SQL details
provider secrets
request headers
cookies
raw transport metadata
```

`operator_reason_redacted` remains excluded from `action_event_summary` route responses. Current-state reason text may be exposed only as the bounded `review_reason_redacted` field inside `review_state_summary`.

## Public response-shape lock

Stage 6.3 must preserve existing public response shapes:

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

Public duplicate group review/action state fields remain absent.

## Canonical no-mutation lock

Stage 6.3 review state read projections and admin read responses are advisory and internal.

Forbidden by default:

```text
canonical_feed_items mutation
provider canonical feed item creation
news-only canonical event creation
official TDnet event merge
official fact override
official citation override
canonical fact override
news_overlay_attachments mutation
```

## Provider, scheduler, and materializer lock

Stage 6.3 read projections and admin read responses must not:

```text
trigger live provider fetch
call provider clients
enqueue scheduler work
store private provider material
materialize duplicate groups
materialize overlays
change materializer behavior
```

## UI lock

Stage 6.3 does not add UI.

UI remains out of scope until a separate UI design PR explicitly defines scope, route dependencies, authorization, response fields, redaction, tests, and manual smoke.

## Redaction lock

Stage 6.3 projection modules, controllers, tests, docs, review comments, logs, and manual-smoke output must remain redacted and bounded.

Forbidden material includes raw actor identifiers, raw request identifiers, raw idempotency keys, unredacted operator reasons, raw provider payloads, full article text, canonical payloads, private transport material, and unbounded diagnostics.

Allowed placeholder examples:

```text
REDACTED_OPERATOR_ID
REDACTED_REQUEST_ID
REDACTED_IDEMPOTENCY_KEY
REDACTED_PROVIDER_KEY
REDACTED_PROVIDER_TOKEN
```

## Regression suite to preserve

Future Stage 6.3 adjacent work should preserve these checks:

```powershell
$env:MIX_ENV='test'; mix.bat test test/stage59_duplicate_group_internal_read_projection_test.exs
$env:MIX_ENV='test'; mix.bat test test/stage59_duplicate_group_operator_read_route_test.exs
$env:MIX_ENV='test'; mix.bat test test/stage62_duplicate_group_action_route_test.exs
$env:MIX_ENV='test'; mix.bat test test/stage61_duplicate_group_action_state_writer_test.exs
$env:MIX_ENV='test'; mix.bat test test/stage61_duplicate_group_action_state_schema_test.exs
$env:MIX_ENV='test'; mix.bat test test/stage60_duplicate_group_operator_action_authorization_gate_test.exs
$env:MIX_ENV='test'; mix.bat test test/stage60_duplicate_group_operator_action_noop_service_test.exs
$env:MIX_ENV='test'; mix.bat test test/stage60_duplicate_group_operator_action_audit_contract_test.exs
$env:MIX_ENV='test'; mix.bat test test/stage60_duplicate_group_operator_action_contract_test.exs
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

Before any future duplicate group UI, public response, scheduler, provider, materializer, or canonical work, require a separate design PR that states scope, authorization, storage, idempotency, redaction, public response-shape impact, canonical policy, failure behavior, tests, and manual smoke checklist.

Before any future duplicate group read response expansion, require a separate design PR unless the expansion remains strictly internal/operator-only, bounded, redacted, and covered by targeted tests.

## Close-out validation

This close-out PR is docs-only. It must not change runtime code, tests, fixtures, migrations, schema modules, router, controllers, UI code, action endpoints, scheduler code, provider clients, live fetch code, feed/controller behavior, API behavior, feed behavior, materializer behavior, or canonical mutation behavior.
