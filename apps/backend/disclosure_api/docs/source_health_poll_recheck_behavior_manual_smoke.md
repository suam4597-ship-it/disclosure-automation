# Source health poll/recheck behavior manual smoke

This manual smoke checklist validates the source health poll/recheck behavior design.

This PR is documentation-only. It does not add frontend code, backend runtime code, tests, fixtures, migrations, schema modules, router changes, controllers, templates, UI routes, action endpoint changes, scheduler work, provider clients, live fetch behavior, public API/feed behavior, materializer behavior, or canonical mutations.

## Baseline

```text
base branch: sec-thin-slice-reconcile-v1
base commit: e1619a9c5f8b2446ed5eb54ff1402282118f111d
base source: PR #181 Design source health route contract lock
stream: source health poll/recheck behavior design
status: docs-only design
```

## Expected changed files

Expected files for this PR:

```text
apps/backend/disclosure_api/docs/source_health_poll_recheck_behavior_design.md
apps/backend/disclosure_api/docs/source_health_poll_recheck_behavior_guardrails.md
apps/backend/disclosure_api/docs/source_health_poll_recheck_behavior_manual_smoke.md
```

## Static changed-file check

Suggested command:

```powershell
git diff --name-only e1619a9c5f8b2446ed5eb54ff1402282118f111d...HEAD
```

Expected output should be limited to the three docs above.

## Scope check

Verify this PR does not change:

```text
frontend code
backend runtime code
tests
fixtures
migrations
schema modules
router
controllers
templates
UI routes
action endpoints
scheduler code
provider clients
live fetch code
public API behavior
public feed behavior
materializer behavior
canonical mutation behavior
```

## Route check

Verify the design covers only:

```text
POST /api/admin/source-health/:source_key/recheck
POST /api/admin/sources/:source_key/poll
```

## Recheck behavior check

Verify recheck default allowed behavior is bounded to:

```text
validate operator authorization
validate source_key shape or allowlist
record bounded request metadata if implementation supports it
inspect existing stored source health metadata
return bounded source health status/result metadata
avoid public response changes
avoid canonical mutation
avoid provider/scheduler/materializer side effects
```

Verify recheck default forbidden behavior includes:

```text
live provider fetch
provider client call
scheduler enqueue
source poll
source materialization
overlay materialization
canonical materialization
canonical mutation
public API/feed response mutation
raw provider payload rendering
secret/header/cookie rendering
unbounded diagnostics
```

## Poll behavior check

Verify poll is described as high-risk and not routine remediation until a concrete contract is locked.

Future poll implementation must state:

```text
source_key allowlist
operator permission model
idempotency model
rate limit model
external network behavior
provider client interaction
scheduler interaction
materializer interaction
canonical impact
public response impact
stored private provider material impact
test plan
rollback plan
```

## Operation mapping check

Verify route-derived operation remains authoritative:

```text
POST /api/admin/source-health/:source_key/recheck -> recheck_source_health
POST /api/admin/sources/:source_key/poll -> poll_source
```

Verify request body must not override route-derived operation.

Forbidden request body fields:

```text
operation
action_operation
route_operation
poll_operation
recheck_operation
```

## Request/response boundedness check

Allowed request metadata:

```text
actor_id_hash
actor_permissions
roles
request_id_hash
idempotency_key_hash
reason_redacted
redaction_status
created_at
```

Allowed response metadata:

```text
source_key
operation
required_permission
authorized
accepted
result_status
request_id_hash
idempotency_key_hash
redaction_status
public_response_shape_mutation
canonical_feed_mutation
trigger_live_fetch
scheduler_enabled
materializer_triggered
network_access
last_checked_at
last_success_at
last_failure_at
last_error_code
retry_after
freshness_status
failure_code
```

Forbidden request/response material:

```text
raw provider payload
full article text
request headers
cookies
secrets
API keys
raw transport responses
SQL details
stack traces
canonical payloads
private actor context
unbounded diagnostics
raw actor identifier
raw request identifier
raw idempotency key
unredacted reason
provider payload
private transport material
```

## Authorization/idempotency check

Verify backend authorization remains authoritative.

Verify read-only permission does not authorize recheck or poll:

```text
source_health:read
```

Verify candidate idempotency identity:

```text
source_key + operation + actor_id_hash + idempotency_key_hash
```

## Rate limit check

Verify future poll behavior must define:

```text
per source_key limit
per actor limit
global limit
retry_after semantics
failure response shape
operator override policy
```

## Public response-shape check

Verify poll/recheck behavior must not change:

```text
GET /api/events/:event_id
GET /api/events/:event_id/news-overlay
GET /api/feed/digest/latest
GET /api/feed/digest/:digest_date/:edition
GET /api/feed/hero
GET /api/feed/region/:region_code
public API envelope
public feed envelope
feed ordering
feed item_count
official TDnet fields
official citations
```

## Canonical/provider/scheduler/materializer check

Verify this design does not approve:

```text
canonical mutation
live provider fetch
provider client calls
scheduler enqueueing
stored private provider material
source materialization
overlay materialization
canonical materialization
materializer behavior changes
```

## Test command

No local test run is required for this docs-only design PR unless a reviewer asks for targeted checks.
