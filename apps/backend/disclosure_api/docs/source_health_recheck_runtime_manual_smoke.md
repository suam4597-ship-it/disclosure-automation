# Source health recheck runtime manual smoke

This manual smoke checklist validates the source health recheck runtime design.

This PR is documentation-only. It does not add frontend code, backend runtime code, tests, fixtures, migrations, schema modules, router changes, controllers, templates, UI routes, action endpoint changes, scheduler work, provider clients, live fetch behavior, public API/feed behavior, materializer behavior, or canonical mutations.

## Baseline

```text
base branch: sec-thin-slice-reconcile-v1
base commit: 5af195aa1847bffdad8cc64f532b02aaf44e0a90
base source: PR #187 Lock source health route contract tests
stream: source health recheck runtime design
status: docs-only design
```

## Expected changed files

Expected files for this PR:

```text
apps/backend/disclosure_api/docs/source_health_recheck_runtime_design.md
apps/backend/disclosure_api/docs/source_health_recheck_runtime_guardrails.md
apps/backend/disclosure_api/docs/source_health_recheck_runtime_manual_smoke.md
```

## Static changed-file check

Suggested command:

```powershell
git diff --name-only 5af195aa1847bffdad8cc64f532b02aaf44e0a90...HEAD
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

## Target route check

Verify this design covers only:

```text
POST /api/admin/source-health/:source_key/recheck
```

## Operation mapping check

Verify route-derived operation remains:

```text
recheck_source_health
```

Verify request body cannot override operation.

Forbidden override fields:

```text
operation
action_operation
route_operation
recheck_operation
poll_operation
```

## Default behavior check

Verify recheck default behavior is bounded stored-state evaluation:

```text
validate operator authorization
validate source_key shape or allowlist
validate bounded request metadata
read existing source health state
compute bounded freshness/status result
return bounded response metadata
```

Verify recheck does not approve:

```text
provider clients
live provider fetch
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

## Request allowlist check

Allowed request fields:

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

Forbidden request fields:

```text
raw_actor_id
raw_request_id
raw_idempotency_key
unredacted_reason
provider_payload
secret
header
cookie
full_article_text
canonical_payload
private_transport_material
unbounded_diagnostics
```

## Response allowlist check

Allowed response fields:

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

Forbidden response fields:

```text
raw_provider_payload
full_article_text
headers
cookies
secrets
api_keys
raw_transport_response
sql_details
stack_trace
canonical_payload
private_actor_context
unbounded_diagnostics
```

## Authorization check

Verify backend authorization remains authoritative.

Candidate required permission:

```text
source_health:recheck
```

Read-only permission must not authorize recheck:

```text
source_health:read
```

## Idempotency check

If recheck introduces writes, idempotency must be defined before implementation.

Candidate identity:

```text
source_key + recheck_source_health + actor_id_hash + idempotency_key_hash
```

## Source key validation check

Verify source_key validation guidance includes:

```text
non-empty string
bounded length
known source allowlist or configured source registry
no path traversal semantics
no raw URL semantics unless explicitly allowed
```

## Public response-shape check

Verify recheck runtime work must not change:

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
