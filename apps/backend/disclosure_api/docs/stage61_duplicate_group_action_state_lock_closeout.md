# Stage 6.1 duplicate group action state lock close-out

This document locks Stage 6.1 duplicate group operator action state storage after the internal writer was merged.

## Scope

Stage 6.1 introduced internal storage, schema validation, and a writer for duplicate group operator action state and action events.

The stage remains internal and operator-only. It does not add routes, controllers, UI, public response fields, scheduler work, provider clients, live fetch behavior, materializer behavior changes, or canonical mutations.

## Lock evidence

```text
PR #143 Design Stage 6.1 duplicate group action state storage
merge commit: f83487ea2d855d36bbed37a8ed265c2c3845e7e2
scope: docs-only internal review state/action event storage design

PR #144 Add Stage 6.1 duplicate group action state storage migration
merge commit: 05a063e9546b701e865368b07f4ede8c7fbf1987
scope: internal review state/action event migration + manual smoke

PR #145 Add Stage 6.1 duplicate group action state schemas
merge commit: 5adb9f1e350f70154cbf2038546492397fc32f41
scope: SourceDuplicateGroupReviewState and SourceDuplicateGroupActionEvent schemas + changeset tests + manual smoke

PR #146 Add Stage 6.1 duplicate group action state writer
merge commit: 60c79da204c52c123532e7b7fc9d7b83956c65b2
scope: internal transaction writer + idempotency tests + manual smoke
```

## Locked storage tables

Stage 6.1 locks these internal tables:

```text
source_duplicate_group_review_states
source_duplicate_group_action_events
```

These tables are internal/operator-only and must not be used as public API or public feed response tables.

## Locked review state behavior

Allowed review state fields:

```text
group_id
review_state
last_action_operation
last_action_request_id_hash
last_action_idempotency_key_hash
reviewed_by_actor_id_hash
reviewed_at
review_reason_redacted
redaction_status
inserted_at
updated_at
```

Allowed review states:

```text
unknown
confirmed_by_operator
rejected_by_operator
needs_review
cleared
```

Review state uniqueness:

```text
group_id
```

## Locked action event behavior

Allowed action event fields:

```text
group_id
action_operation
required_permission
actor_id_hash
request_id_hash
idempotency_key_hash
operator_reason_redacted
result_status
pre_review_state
post_review_state
failure_code
redaction_status
inserted_at
```

Allowed action operations:

```text
confirm_duplicate_group
reject_duplicate_group
mark_duplicate_group_needs_review
clear_duplicate_group_review_state
```

Allowed result statuses:

```text
pending
accepted
denied
rejected
failed
completed
skipped
```

Action event idempotency uniqueness:

```text
group_id + action_operation + actor_id_hash + idempotency_key_hash
```

## Locked writer behavior

The Stage 6.1 writer must:

```text
use Stage60DuplicateGroupOperatorActionAuthorizationGate before DB writes
use SourceDuplicateGroupActionEvent changeset
use SourceDuplicateGroupReviewState changeset
use Repo.transaction for event/state writes
insert action events idempotently
reuse existing action event on repeated idempotency identity
upsert one review state row per group_id
return bounded internal result metadata only
```

The writer must write no rows when authorization, action validation, event validation, schema validation, or guardrail validation fails.

## Locked no-public-surface guardrails

Stage 6.1 does not add:

```text
routes
controllers
UI code
action endpoints
public duplicate group fields
public action state fields
public audit fields
```

Future public exposure requires a separate public response-shape design PR.

## Public response-shape lock

Stage 6.1 must preserve existing public response shapes:

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

Public duplicate group action state fields remain absent.

## Canonical no-mutation lock

Stage 6.1 action state is advisory and internal.

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

## Provider and scheduler lock

Stage 6.1 storage/writer behavior must not:

```text
trigger live provider fetch
call provider clients
enqueue scheduler work
store private provider material
materialize duplicate groups
materialize overlays
```

## Redaction lock

Stage 6.1 storage, schemas, writer, tests, docs, review comments, logs, and manual-smoke output must remain redacted and bounded.

Forbidden material includes raw actor identifiers, raw request identifiers, raw idempotency keys, unredacted operator reasons, raw provider payloads, full article text, canonical payloads, private transport material, and unbounded diagnostics.

Allowed placeholder examples:

```text
REDACTED_PROVIDER_KEY
REDACTED_PROVIDER_TOKEN
REDACTED_OPERATOR_ID
REDACTED_REQUEST_ID
REDACTED_IDEMPOTENCY_KEY
```

## Regression suite to preserve

Future Stage 6.1 adjacent work should preserve these checks:

```powershell
$env:MIX_ENV='test'; mix.bat test test/stage61_duplicate_group_action_state_writer_test.exs
$env:MIX_ENV='test'; mix.bat test test/stage61_duplicate_group_action_state_schema_test.exs
$env:MIX_ENV='test'; mix.bat test test/stage60_duplicate_group_operator_action_authorization_gate_test.exs
$env:MIX_ENV='test'; mix.bat test test/stage60_duplicate_group_operator_action_noop_service_test.exs
$env:MIX_ENV='test'; mix.bat test test/stage60_duplicate_group_operator_action_audit_contract_test.exs
$env:MIX_ENV='test'; mix.bat test test/stage60_duplicate_group_operator_action_contract_test.exs
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

Before any future duplicate group action endpoint, UI, public response, scheduler, provider, materializer, or canonical work, require a separate design PR that states scope, authorization, storage, idempotency, redaction, public response-shape impact, canonical policy, failure behavior, tests, and manual smoke checklist.

## Close-out validation

This close-out PR is docs-only. It must not change runtime code, tests, fixtures, migrations, schema modules, router, controllers, UI code, action endpoints, scheduler code, provider clients, live fetch code, feed/controller behavior, API behavior, feed behavior, materializer behavior, or canonical mutation behavior.
