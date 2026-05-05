# Source Health Operator Runbook

This runbook describes the bounded operator workflow for source health list, detail, and recheck handling after the internal UI recheck action lock.

This PR is documentation-only. It does not add or modify frontend runtime code, backend runtime code, tests, fixtures, migrations, schema modules, router changes, controllers, templates, API response shapes, provider behavior, materializer behavior, canonical mutation behavior, poll behavior, audit read UI, public API/feed behavior, monitoring behavior, or alerting behavior.

## Baseline

```text
base branch: sec-thin-slice-reconcile-v1
base commit: 464600071ac44c4e1c27717bd62f548a4bd67a38
base source: PR #234 Lock source health internal UI recheck action
stream: source health operator runbook refresh
status: docs-only
```

## Audience

This runbook is for internal operators who need to inspect source health and request bounded source health rechecks.

It is not a developer guide for adding routes, changing response shapes, adding provider calls, expanding poll behavior, or exposing audit internals.

## Scope

Covered workflow:

```text
1. Open internal source health list
2. Select a source health detail page
3. Interpret detail shell state
4. Interpret permission-aware recheck action state
5. Submit or withhold a bounded recheck request
6. Interpret 202 / 403 / 404 results
7. Escalate using bounded information only
```

Routes covered:

```text
GET /admin/source-health
GET /admin/source-health/:source_key
POST /api/admin/source-health/:source_key/recheck
```

Out of scope:

```text
POST /api/admin/sources/:source_key/poll
audit read UI
provider fetch controls
materializer controls
canonical mutation controls
public source health UI
monitoring dashboards and alerts
```

## Operator safety principles

Always keep the workflow bounded.

Do not request, copy, display, or escalate raw/private/canonical material.

Forbidden material includes:

```text
raw_provider_payload
full_article_text
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
provider_credentials
headers
cookies
tokens
```

Do not use source health recheck as a way to trigger poll, provider fetch, materializer, or canonical mutation behavior.

## Step 1: Open the source health list

Open:

```text
GET /admin/source-health
```

Expected bounded list shell:

```text
Source health
fields=source_key,display_name,source_type,region_code,health_status,last_success_at,last_failure_at,active
recheck_action=not_rendered
poll_action=not_rendered
audit_ui=not_rendered
```

Approved list fields:

```text
source_key
display_name
source_type
region_code
health_status
last_success_at
last_failure_at
active
```

The list page is for triage only. It must not expose recheck buttons, poll buttons, audit UI, provider payloads, job internals, or private actor context.

## Step 2: Select a source detail page

Open:

```text
GET /admin/source-health/:source_key
```

Expected bounded detail shell for a known source:

```text
Source health detail
state=found
source_key=<source_key>
display_name=<display_name>
source_type=<source_type>
region_code=<region_code>
health_status=<health_status>
last_success_at=<timestamp-or-empty>
last_failure_at=<timestamp-or-empty>
active=<true-or-false>
cursor_count=<count>
back=/admin/source-health
```

Approved detail fields:

```text
source_key
display_name
source_type
region_code
health_status
last_success_at
last_failure_at
active
cursor_count
back=/admin/source-health
```

If the source is unknown, expected bounded detail state:

```text
Source health detail
state=not_found
source_key=<missing_source_key>
recheck_action=not_available
back=/admin/source-health
```

Do not attempt recheck for a not-found source from the UI.

## Step 3: Interpret health status

Current bounded health status is informational.

Typical operator interpretation:

```text
healthy -> no immediate recheck needed unless investigating a stale upstream signal
unknown -> candidate for bounded recheck if operator has permission
failed -> candidate for bounded recheck after confirming source identity
paused/inactive -> do not recheck without confirming expected operational state
```

Use timestamps as context:

```text
last_success_at -> last known successful source health-related update
last_failure_at -> last known failure marker
```

Do not infer raw provider failure details from the UI. The source health UI intentionally does not show raw transport responses, stack traces, SQL details, or provider credentials.

## Step 4: Interpret permission-aware recheck state

The current internal UI test harness uses request-param-driven permission markers.

Known states:

```text
missing actor_permissions -> recheck_action=not_rendered
source_health:read -> recheck_action=disabled
source_health:read -> recheck_reason=read_only
source_health:recheck -> recheck_action=enabled
unknown source -> recheck_action=not_available
```

Read-only state means the operator must not submit a recheck.

Expected read-only detail markers:

```text
recheck_action=disabled
recheck_reason=read_only
```

Recheck-enabled state means the operator may submit only the locked bounded backend recheck request.

Expected enabled detail markers:

```text
recheck_action=enabled
recheck_method=POST
recheck_target=/api/admin/source-health/:source_key/recheck
idempotency=required
recheck_context=bounded
```

## Step 5: Submit a bounded recheck request

Only submit when all conditions are true:

```text
source exists
operator has source_health:recheck
recheck_action=enabled
recheck_target=/api/admin/source-health/:source_key/recheck
idempotency=required
```

Submit only to:

```text
POST /api/admin/source-health/:source_key/recheck
```

Approved bounded request context fields:

```text
actor_id_hash
actor_permissions
request_id_hash
idempotency_key_hash
reason_redacted
redaction_status
created_at
```

Do not submit payload controls for:

```text
operation
action_operation
route_operation
action
queue
worker
payload
provider_fetch
materialize
canonicalize
poll
```

Do not submit raw actor ID, raw request ID, raw idempotency key, unredacted reason, headers, cookies, tokens, provider credentials, raw provider payloads, or full article text.

## Step 6: Interpret recheck result

### 202 Accepted

A 202 means the backend accepted or reused a bounded source health recheck request.

Approved operator display messages:

```text
accepted -> Recheck request accepted.
reused -> A similar recent recheck request was reused.
untracked -> Recheck request accepted without tracking.
```

Meaning:

```text
accepted -> new bounded health_checks work was accepted
reused -> same source_key + idempotency_key_hash was recently seen and deduped
untracked -> request was accepted without idempotency storage because idempotency key was missing
```

Operator action:

```text
accepted -> wait for normal health update path or proceed to bounded follow-up checks
reused -> do not repeatedly click; use the existing recent request as the current operator action
untracked -> record that tracking was unavailable and avoid retries unless directed
```

Do not expose raw job internals.

Forbidden response details:

```text
raw job payload
worker internals
queue override controls
raw idempotency key
raw request ID
raw actor ID
audit event ID
```

### 403 Forbidden

Approved display message:

```text
You do not have permission to recheck this source.
```

Meaning:

```text
operator does not have source_health:recheck
backend denied the request
no recheck should be considered accepted
```

Operator action:

```text
stop recheck attempt
confirm permission state
ask an authorized operator to perform the recheck if needed
record only bounded source_key and bounded request context
```

Do not bypass the permission check by changing operation, route operation, queue, worker, or payload fields.

### 404 Not Found

Approved display message:

```text
Source not found.
```

Meaning:

```text
source_key does not resolve to a known source registry record
backend did not accept recheck work for this source
```

Operator action:

```text
return to /admin/source-health
confirm source_key spelling
confirm whether the source was removed or never registered
escalate bounded source_key only if needed
```

Do not retry with poll routes, provider fetch controls, or canonical mutation controls.

### Other errors

Approved display message category:

```text
bounded generic error text only
```

Operator action:

```text
record the bounded route, source_key, response status, and request_id_hash if available
escalate without raw payloads, stack traces, SQL details, headers, cookies, or tokens
```

## Idempotency guidance

Preferred behavior:

```text
one deliberate recheck click -> one idempotency_key_hash
retry of the same UI submission -> same idempotency_key_hash
new deliberate operator action -> new idempotency_key_hash
```

Interpretation:

```text
accepted -> first tracked request in the idempotency window
reused -> duplicate tracked request in the idempotency window
untracked -> backend accepted without idempotency tracking
```

Operators should not repeatedly submit recheck actions to force a different result. Repeated submissions may be reused by design.

## Audit expectations

The backend writes bounded audit events internally for source health recheck outcomes.

Audit outcomes may include:

```text
accepted
reused
untracked
forbidden
not_found
```

The operator UI must not display audit event references.

Forbidden display references:

```text
audit_event
audit_event_id
```

Audit read UI is a separate future track and is not part of this runbook.

## Poll remains gated

Do not use this runbook to operate poll behavior.

Still gated:

```text
POST /api/admin/sources/:source_key/poll
```

Do not add or use UI controls for:

```text
poll_source
provider_fetch
materialize
canonicalize
inline_feed
use_live_fetch
```

## Escalation checklist

When escalating a source health recheck issue, include only bounded information:

```text
source_key
display_name if visible
source_type
region_code
health_status
last_success_at
last_failure_at
active
cursor_count
HTTP status: 202 / 403 / 404 / other
idempotency_status if visible: accepted / reused / untracked
request_id_hash if available
redaction_status if available
```

Do not include:

```text
raw actor ID
raw request ID
raw idempotency key
unredacted reason
headers
cookies
tokens
provider credentials
raw provider payload
full article text
raw transport response
SQL details
stack traces
canonical payload
private actor context
unbounded diagnostics
audit event IDs
```

## Operator decision table

```text
state=not_found + recheck_action=not_available -> return to list and verify source_key
recheck_action=not_rendered -> no action control available in the current shell
recheck_action=disabled + recheck_reason=read_only -> do not submit; request authorized operator if needed
recheck_action=enabled + idempotency=required -> submit bounded POST only to locked recheck target
202 accepted -> accepted bounded work; avoid repeated clicks
202 reused -> duplicate recent request reused; do not force retry
202 untracked -> accepted without tracking; avoid repeated clicks and record bounded context
403 forbidden -> stop and verify permission
404 not_found -> return to list and verify source registry state
other error -> escalate bounded status/context only
```

## Public response guardrails

Source health operator work must not change:

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

## Canonical no-mutation guardrails

Source health operator workflow must not:

```text
mutate canonical_feed_items
create provider canonical feed items
create news-only canonical events
merge official TDnet events
override official TDnet facts
override official citations
mutate news_overlay_attachments
```

unless a separate canonical-impact design explicitly approves the behavior.

## Provider, scheduler, and materializer guardrails

This runbook does not approve:

```text
live provider fetch
provider client calls
scheduler enqueueing beyond the locked health_checks recheck path
stored private provider material
source materialization
overlay materialization
canonical materialization
materializer behavior changes
```

## Operator do-not-do list

Do not:

```text
manually write source health rows
manually write canonical rows
manually alter provider payloads
manually enqueue scheduler work outside approved route behavior
manually run materializers as part of source health review
paste secrets, headers, cookies, tokens, full text, raw payloads, or stack traces into tickets
use public routes for operator source health checks
```

## Post-action verification

After a bounded recheck, verify only bounded state:

```text
GET /admin/source-health/:source_key
```

Confirm:

```text
health_status is updated or unchanged in a bounded way
last_success_at or last_failure_at changed only if expected
source identity remains correct
no public response shape changed
no canonical mutation occurred
no unexpected provider/scheduler/materializer side effect occurred
```

If backend/API verification is needed, use only approved bounded API routes and do not inspect raw/private/canonical data.

## Validation evidence

Recent locked validations feeding this runbook:

```text
PR #232 focused source health internal UI recheck action test: 4 tests, 0 failures
PR #232 adjacent source health/UI regression: 51 tests, 0 failures
PR #233 focused source health internal UI recheck submit flow test: 4 tests, 0 failures
PR #233 adjacent source health/UI regression: 55 tests, 0 failures
PR #234 source health internal UI recheck action lock: docs-only, no tests required
```

Known warning status:

```text
existing compile warnings remain
existing Phoenix.ConnTest deprecation warning remains
no new duplicate source health controller warning was validated in recent test runs
```

## Optional validation command

This runbook PR is docs-only and requires no test command.

Optional source health/UI regression for confidence:

```powershell
$env:MIX_ENV='test'; mix.bat test test/source_health_internal_ui_route_inventory_test.exs test/source_health_internal_ui_list_shell_test.exs test/source_health_internal_ui_detail_shell_test.exs test/source_health_internal_ui_recheck_action_test.exs test/source_health_internal_ui_recheck_submit_flow_test.exs test/source_health_route_target_test.exs test/source_health_route_contract_test.exs test/source_health_recheck_behavior_test.exs test/source_health_recheck_authorization_test.exs test/source_health_recheck_positive_characterization_test.exs test/source_health_recheck_bounded_enqueue_contract_test.exs test/source_health_recheck_idempotency_characterization_test.exs test/source_health_recheck_idempotency_storage_migration_test.exs test/source_health_recheck_idempotency_runtime_test.exs test/source_health_recheck_audit_storage_migration_test.exs test/source_health_recheck_audit_runtime_test.exs
```

Latest known adjacent result:

```text
55 tests, 0 failures
```

## Remaining work after this runbook

After this runbook, the remaining source health stream should move to:

```text
end-to-end operator smoke test design
source health internal UI final close-out
monitoring and operational visibility
poll route gated stream
```

## Recommended next PR

Recommended next PR:

```text
Design source health operator smoke test
```

Recommended scope:

```text
docs-only or test-design-first
list -> detail -> recheck -> bounded result
read-only denial path
unknown source path
no poll UI
no audit UI
no raw/private/canonical exposure
```

## Stop conditions

Stop and re-scope if future work:

```text
lets source_health:read trigger recheck
adds recheck target other than /api/admin/source-health/:source_key/recheck
adds operation/action_operation/route_operation controls
adds queue/worker/payload controls
adds poll UI without a dedicated poll gate
shows audit event identifiers
shows raw backend payloads or job internals
shows raw actor/request/idempotency identifiers
shows unredacted reason
shows secrets, headers, cookies, tokens, provider credentials, raw payloads, full article text, SQL details, stack traces, canonical payloads, private actor context, or unbounded diagnostics
changes backend response shapes without a contract PR
adds public source health UI routes
adds duplicate controller modules
```

## Validation for this runbook PR

This runbook PR is docs-only and should change only:

```text
apps/backend/disclosure_api/docs/source_health_operator_runbook.md
```

No Codex test command is required for this docs-only runbook PR.
