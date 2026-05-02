# Stage 5.8 source health operator actions audit design

This document defines a docs-only design for future provider source health operator actions with an audit trail.

This is a design document only. It does not add runtime action code, tests, fixtures, migrations, schema changes, scheduler code, provider clients, live fetch code, routes, feed/controller changes, UI code, materializer changes, API behavior changes, feed behavior changes, or canonical feed mutations.

## Baseline

```text
base branch: sec-thin-slice-reconcile-v1
base commit: 4f68e5ecbec30b9eebe722d44ee342cb2f0b5599
base source: PR #118 Lock Stage 5.7 provider source health operator view
stage: Stage 5.8 PR A operator actions for source health with audit trail design
status: docs-only
locked operator view: Stage 5.7 provider source health operator view
locked projection contract: Stage57OperatorViewProjectionContract
locked internal projection: Stage57InternalSourceHealthProjection
locked view mode: operator-only, read-only by default, advisory-only, redacted
```

## Goal

Define the action model that future provider source health operator tooling must satisfy before any action endpoint, route, UI, worker, scheduler integration, or source health mutation is implemented.

The design records:

```text
action permission separation
action intent and reason requirements
action idempotency requirements
action audit requirements
action redaction requirements
failure isolation requirements
response-shape and canonical no-mutation guardrails
stop conditions for future implementation
```

## Non-goals

This PR does not authorize or implement:

```text
runtime action endpoints
runtime authorization code
new routes
UI code
source health mutation actions
enqueue source health recheck action
manual provider trigger action
pause provider action
resume provider action
clear redaction violation action
acknowledge manual review action
scheduler-triggered provider work
live provider fetch
provider clients
provider credentials
migrations
schema changes
feed/controller changes
materializer changes
public API source health fields
feed source health fields
canonical feed mutation
provider canonical feed item creation
news-only canonical event creation
```

## Stage 5.7 dependency

Future action implementation must build on the Stage 5.7 operator view lock and must preserve:

```text
operator/admin-only access
read-only view permissions separated from action permissions
advisory-only source health semantics
redacted source health projection
public access forbidden
unauthenticated access forbidden
public_response_shape_mutation=false
trigger_live_fetch=false by default
scheduler_enabled=false by default
canonical_feed_mutation=false
no feed/API response shape changes
```

The future action surface may use the Stage 5.7 internal projection for pre-action and post-action display, but actions must not weaken the projection contract or add source health data to public responses.

## Action families

Future action work should treat each action as a separate explicit operation.

Candidate action families:

```text
source_health.recheck
source_health.pause
source_health.resume
source_health.acknowledge_manual_review
source_health.clear_redaction_violation
source_health.manual_provider_trigger
source_health.export_redacted_diagnostics
```

Each future action must define:

```text
explicit permission
operator reason requirement
idempotency behavior
audit event schema
redaction policy
failure isolation policy
allowed state transition
forbidden side effects
rollback or retry behavior
manual-smoke checklist
```

## Permission model

Read-only permissions remain separate from action permissions.

Read-only permissions:

```text
source_health.view
source_health.detail
source_health.export_redacted
```

Action permissions:

```text
source_health.recheck
source_health.pause
source_health.resume
source_health.acknowledge_manual_review
source_health.clear_redaction_violation
source_health.manual_provider_trigger
source_health.export_redacted_diagnostics
```

A user with only read-only permissions must not be able to execute actions.

A user with an action permission must still be authorized for the target source health record before the action can run.

## Action request contract

Future action requests should require a bounded action envelope.

Required action request fields:

```text
operation
source_key
operator_reason
idempotency_key
request_id
```

Recommended optional fields:

```text
expected_current_health_status
expected_current_operational_state
expected_current_redaction_status
operator_note_redacted
```

Forbidden action request fields:

```text
provider credentials
request headers
response headers
raw provider response body
full article text
signed private URLs
unbounded diagnostics
canonical feed item payloads
provider canonical creation payloads
```

## Operator reason policy

Future mutating or enqueueing actions must require an operator reason.

Required behavior:

```text
operator_reason required for all action operations
operator_reason bounded in length
operator_reason stored only after redaction
operator_reason cannot contain credentials
operator_reason cannot contain request headers
operator_reason cannot contain response headers
operator_reason cannot contain raw provider response bodies
operator_reason cannot contain full article text
operator_reason cannot contain signed private URLs
```

## Idempotency policy

Future actions must be safe to retry.

Required behavior:

```text
idempotency_key required for mutating or enqueueing actions
same actor/source/operation/idempotency_key returns same action result when safe
conflicting idempotency key reuse is rejected
idempotency records use bounded redacted metadata only
idempotency checks do not trigger live fetch
idempotency checks do not trigger scheduler work
idempotency checks do not mutate canonical feed items
```

## Audit event policy

Every future action attempt must record a bounded audit event.

Allowed audit metadata:

```text
actor_id_hash
permission
operation
source_key
request_id_hash
idempotency_key_hash
operator_reason_redacted
started_at
completed_at
result_status
pre_action_health_status
post_action_health_status if available
pre_action_operational_state if available
post_action_operational_state if available
redaction_status
failure_code_redacted
```

Forbidden audit metadata:

```text
provider credentials
request headers
response headers
raw provider response bodies
full article text
signed private URLs
unbounded diagnostics
provider account secrets
canonical feed item payloads
```

Audit records must remain non-canonical operational metadata. They must not become feed items, canonical citations, or public API data.

## Action-specific design requirements

### Recheck source health

Future `source_health.recheck` should be an explicit operator action and must not run from read-only view access.

Required future behavior:

```text
requires source_health.recheck permission
requires operator_reason
requires idempotency_key
audit event required
bounded enqueue request only
no live fetch unless separately designed
no scheduler-triggered work unless separately designed
no canonical feed mutation
no public response shape change
```

### Pause provider source

Future `source_health.pause` should mark a provider source as operationally paused only after separate runtime/schema design.

Required future behavior:

```text
requires source_health.pause permission
requires operator_reason
requires idempotency_key
audit event required
advisory operational state only
no deletion of source health history
no deletion of overlays
no canonical feed mutation
no public response shape change
```

### Resume provider source

Future `source_health.resume` should reverse an advisory operational pause only after separate runtime/schema design.

Required future behavior:

```text
requires source_health.resume permission
requires operator_reason
requires idempotency_key
audit event required
advisory operational state only
no immediate live fetch by default
no scheduler-triggered fetch by default
no canonical feed mutation
no public response shape change
```

### Acknowledge manual review

Future `source_health.acknowledge_manual_review` should record that an operator has reviewed an advisory health condition.

Required future behavior:

```text
requires source_health.acknowledge_manual_review permission
requires operator_reason
requires idempotency_key
audit event required
acknowledgement is advisory-only
acknowledgement does not clear provider evidence
acknowledgement does not change canonical feed items
acknowledgement does not expose source health publicly
```

### Clear redaction violation

Future `source_health.clear_redaction_violation` must be conservative and should only be available after a separate redaction-specific implementation design.

Required future behavior:

```text
requires source_health.clear_redaction_violation permission
requires operator_reason
requires idempotency_key
audit event required
requires redaction revalidation before clearing
must preserve redaction violation history
must not restore forbidden raw payloads
must not expose credentials or headers
must not mutate canonical feed items
```

### Manual provider trigger

Future `source_health.manual_provider_trigger` must remain explicit, operator-only, and default-off.

Required future behavior:

```text
requires source_health.manual_provider_trigger permission
requires operator_reason
requires idempotency_key
audit event required
fake/default-off transport preserved unless separately approved
live fetch disabled by default
scheduler disabled by default
credentials sourced only from runtime environment or secret-manager-backed runtime configuration
redaction before persistence, staging, health evaluation, diagnostics, and audit
no canonical feed mutation
```

### Export redacted diagnostics

Future `source_health.export_redacted_diagnostics` must export only bounded redacted metadata.

Required future behavior:

```text
requires source_health.export_redacted_diagnostics permission
requires operator_reason
audit event required
bounded record count
bounded field allowlist
no credentials
no request headers
no response headers
no raw provider response bodies
no full article text
no public download URL without separate design
```

## Failure isolation policy

Future action implementation must isolate failures from public serving and canonical data.

Required behavior:

```text
action failure does not affect TDnet runtime
action failure does not affect public feed serving
action failure does not affect public API serving
action failure does not delete provider overlays
action failure does not mutate canonical feed items
action failure does not trigger live fetch by default
action failure does not trigger scheduler work by default
action failure returns bounded redacted errors only
```

## Response-shape policy

Future action implementation must not alter locked public response shapes:

```text
read model item.overlays[] unchanged
API item.overlays[] unchanged
feed news_overlays[] unchanged
feed item_count unchanged
feed ordering unchanged
official TDnet fields unchanged
official citations unchanged
API envelope unchanged
```

Action responses, if later implemented, must be internal/operator-only and must not be reused as public feed/API payloads without separate design.

## Canonical no-mutation policy

Future source health actions must not mutate canonical financial disclosure data.

Forbidden:

```text
canonical feed item mutation
provider canonical feed item creation
news-only canonical event creation
official TDnet event override
official citation override
canonical fact override
public materializer output mutation
```

## Redaction policy

Future action requests, action responses, audit records, diagnostics, logs, comments, and manual-smoke outputs must not expose:

```text
Subscription-Key values
Authorization header values
Cookie header values
provider credentials
request headers
response headers
signed private URLs
raw provider response bodies
full article text
unbounded provider error payloads
secret-like values
```

Allowed redacted placeholders:

```text
REDACTED_PROVIDER_KEY
REDACTED_PROVIDER_TOKEN
REDACTED_SUBSCRIPTION_KEY
```

## Implementation sequence

Recommended future sequence:

```text
1. Docs-only action design and guardrails
2. Pure action contract module with no DB writes, no routes, no network calls
3. Targeted action audit contract with bounded redacted fields
4. Internal action service with fake/no-op side effects only
5. Runtime authorization integration
6. Internal route implementation behind operator/admin auth
7. UI implementation after route and audit behavior are locked
8. Optional scheduler/live-fetch integration only after separate design
```

This PR covers only step 1.

## Stop conditions

Do not merge a future implementation if it:

```text
adds public or unauthenticated action access
mixes read-only permission with action permission
runs an action from view/detail access
triggers live provider fetch by default
triggers scheduler work by default
stores provider credentials in repository files
logs request headers
logs response headers
logs raw provider response bodies
stores full article text
stores unbounded diagnostics
mutates canonical feed items
creates provider canonical feed items
creates news-only canonical events
changes public feed/API response shapes
adds action endpoint without audit design
adds action endpoint without idempotency behavior
adds action endpoint without redaction tests or smoke checks
```
