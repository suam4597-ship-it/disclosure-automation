# Source health route target verification close-out

This document closes out the source health route-target verification PR after targeted tests were merged.

This close-out PR is documentation-only. It does not add or modify frontend code, backend runtime code, tests, fixtures, migrations, schema modules, router changes, controllers, templates, UI routes, action endpoint changes, scheduler work, provider clients, live fetch behavior, public API/feed behavior, materializer behavior, or canonical mutations.

## Baseline

```text
base branch: sec-thin-slice-reconcile-v1
base commit: e91f0c29004f8cb0df286fe9a540dc9a311160ac
base source: PR #192 Verify source health route targets
stream: source health route-target verification close-out
status: docs-only
```

## Evidence

```text
PR #192 Verify source health route targets
scope: targeted route-target tests and manual smoke doc
validated target test: 4 tests, 0 failures
validated adjacent route contract test: 4 tests, 0 failures
```

## Important validation finding

Existing source health controllers are defined in:

```text
apps/backend/disclosure_api/lib/disclosure_automation_web/controllers.ex
```

The PR initially attempted replacement controller files, but that would duplicate existing modules.

Those duplicate files were removed before merge.

## Locked route targets

Existing route targets remain:

```text
GET /api/admin/source-health -> AdminSourceHealthController.index/2
GET /api/admin/source-health/:source_key -> AdminSourceHealthController.show/2
POST /api/admin/source-health/:source_key/recheck -> AdminSourceHealthController.recheck/2
POST /api/admin/sources/:source_key/poll -> AdminSourcePollController.create/2
```

## Locked verified behavior

The merged tests verify current behavior:

```text
GET /api/admin/source-health -> 200 JSON with data/page/page_size/total_entries
GET /api/admin/source-health/:missing_source_key -> 404 not_found/source not found
POST /api/admin/source-health/:missing_source_key/recheck -> 404 not_found/source not found
POST /api/admin/sources/:missing_source_key/poll -> 404 not_found/source not found
```

## Locked no-duplicate-module guardrail

Future source health work must not add duplicate controller modules for:

```text
DisclosureAutomationWeb.AdminSourceHealthController
DisclosureAutomationWeb.AdminSourcePollController
```

If route target behavior changes are needed, update the existing definitions in `controllers.ex` or first split the modules in a dedicated refactor PR.

## Locked forbidden material check

Merged tests verify bounded not-found responses do not include:

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

## Known warnings

Validation reported existing compile warnings and one `Phoenix.ConnTest` deprecation warning in the target test path.

These warnings were not introduced by duplicate controller modules after the final fix.

The duplicate module warning disappeared after replacement controller files were removed.

## What remains unimplemented

This route-target verification does not implement new recheck behavior.

Still not implemented by this PR:

```text
bounded stored-state recheck logic
authorization enforcement for source_health:recheck
idempotency handling
request allowlist enforcement
source_key allowlist or registry validation
provider/scheduler/materializer absence instrumentation
canonical no-mutation instrumentation
public response-shape flag assertions at runtime beyond current route behavior
```

## Future implementation gate

Before changing runtime recheck behavior, the next PR should state:

```text
affected existing controller/action
request fields
response fields
authorization model
idempotency model
source_key validation model
read model or storage model
provider/scheduler/materializer impact
canonical impact
public response impact
redaction impact
test plan
rollback plan
```

## Stop conditions

Stop and re-scope if future source health work:

```text
adds duplicate controller modules
adds new routes without design approval
changes public response shapes
adds public source health fields
allows request-body operation override
calls provider clients unexpectedly
triggers scheduler work unexpectedly
triggers materializers unexpectedly
mutates canonical data unexpectedly
shows secrets, headers, cookies, tokens, raw payloads, full article text, or SQL details
returns unbounded diagnostics or stack traces
```

## Validation

This close-out PR is docs-only and should change only:

```text
apps/backend/disclosure_api/docs/source_health_route_target_verification_closeout.md
```

No local test run is required unless a reviewer asks for targeted checks.
