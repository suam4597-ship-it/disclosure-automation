# Source health route target manual smoke

This manual smoke checklist validates the minimal source health route-target realization PR.

## Scope

This PR realizes existing source health route targets with bounded placeholder JSON responses only.

It does not add frontend code, fixtures, migrations, schema modules, router changes, templates, UI routes, scheduler work, provider clients, live fetch behavior, public API/feed behavior, materializer behavior, canonical mutations, or storage writes.

## Baseline

```text
base branch: sec-thin-slice-reconcile-v1
base commit: 58172d7511156be5366d05d18491f76d4acd94da
base source: PR #191 Add source health route target realization checklist
stream: source health route-target realization
```

## Expected changed files

Expected files:

```text
apps/backend/disclosure_api/lib/disclosure_automation_web/controllers/admin_source_health_controller.ex
apps/backend/disclosure_api/lib/disclosure_automation_web/controllers/admin_source_poll_controller.ex
apps/backend/disclosure_api/test/source_health_route_target_test.exs
apps/backend/disclosure_api/docs/source_health_route_target_manual_smoke.md
```

## Static changed-file check

Suggested command:

```powershell
git diff --name-only 58172d7511156be5366d05d18491f76d4acd94da...HEAD
```

Expected output should be limited to the four files above.

## Test command

Run:

```powershell
$env:MIX_ENV='test'; mix.bat test test/source_health_route_target_test.exs
```

Recommended adjacent check:

```powershell
$env:MIX_ENV='test'; mix.bat test test/source_health_route_contract_test.exs
```

## Route target check

Expected routes:

```text
GET /api/admin/source-health
GET /api/admin/source-health/:source_key
POST /api/admin/source-health/:source_key/recheck
POST /api/admin/sources/:source_key/poll
```

Expected controller targets:

```text
AdminSourceHealthController.index/2
AdminSourceHealthController.show/2
AdminSourceHealthController.recheck/2
AdminSourcePollController.create/2
```

## Placeholder response check

All route-target responses should be bounded JSON placeholders.

Required safe flags:

```text
redaction_status = passed
public_response_shape_mutation = false
canonical_feed_mutation = false
trigger_live_fetch = false
scheduler_enabled = false
materializer_triggered = false
network_access = forbidden
```

## Operation mapping check

Route-derived operations must win over request body fields:

```text
POST /api/admin/source-health/:source_key/recheck -> recheck_source_health
POST /api/admin/sources/:source_key/poll -> poll_source
```

The request body may contain attempted operation override fields in tests, but response operation must remain route-derived.

## Forbidden material check

Responses must not include:

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
raw_actor_id
raw_request_id
raw_idempotency_key
unredacted_reason
```

## Forbidden side effects

This PR must not introduce:

```text
provider client calls
live fetch
scheduler enqueue
materializer execution
canonical mutation
public response mutation
storage writes
new routes
new schemas
new migrations
```

## Stop conditions

Stop and re-scope if the PR:

```text
adds new routes
changes public response shapes
mutates canonical data
calls provider clients
triggers scheduler work
triggers materializers
stores raw/private material
returns unbounded diagnostics
```
