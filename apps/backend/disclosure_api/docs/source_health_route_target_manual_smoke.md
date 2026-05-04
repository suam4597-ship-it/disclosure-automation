# Source health route target manual smoke

This manual smoke checklist validates the source health route-target verification PR.

## Scope

This PR verifies that existing source health controller route targets dispatch and return bounded JSON responses. It does not add replacement controller modules.

It does not add frontend code, fixtures, migrations, schema modules, router changes, templates, UI routes, scheduler work, provider clients, live fetch behavior, public API/feed behavior, materializer behavior, canonical mutations, or storage writes.

## Baseline

```text
base branch: sec-thin-slice-reconcile-v1
base commit: 58172d7511156be5366d05d18491f76d4acd94da
base source: PR #191 Add source health route target realization checklist
stream: source health route-target verification
```

## Expected changed files

Expected files:

```text
apps/backend/disclosure_api/test/source_health_route_target_test.exs
apps/backend/disclosure_api/docs/source_health_route_target_manual_smoke.md
```

No new controller files should be added. Existing source health controllers are defined in:

```text
apps/backend/disclosure_api/lib/disclosure_automation_web/controllers.ex
```

## Static changed-file check

Suggested command:

```powershell
git diff --name-only 58172d7511156be5366d05d18491f76d4acd94da...HEAD
```

Expected output should be limited to the two files above.

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

## Existing behavior check

The test should verify current bounded behavior, not replace it with placeholders:

```text
GET /api/admin/source-health returns 200 JSON with data/page/page_size/total_entries
GET /api/admin/source-health/:missing_source_key returns 404 JSON not_found/source not found
POST /api/admin/source-health/:missing_source_key/recheck returns 404 JSON not_found/source not found
POST /api/admin/sources/:missing_source_key/poll returns 404 JSON not_found/source not found
```

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
replacement controller modules
```

## Stop conditions

Stop and re-scope if the PR:

```text
adds new routes
adds duplicate controller modules
changes public response shapes
mutates canonical data
calls provider clients
triggers scheduler work
triggers materializers
stores raw/private material
returns unbounded diagnostics
```
