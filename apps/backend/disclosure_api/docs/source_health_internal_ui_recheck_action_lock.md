# Source Health Internal UI Recheck Action Lock

This document locks the source health internal UI recheck action and bounded submit flow.

This lock PR is documentation-only. It does not add or modify frontend runtime code, backend runtime code, tests, fixtures, migrations, schema modules, router changes, controllers, templates, API response shapes, source health backend behavior, provider behavior, materializer behavior, canonical mutation behavior, poll behavior, audit read UI, public API/feed behavior, or monitoring behavior.

## Baseline

```text
base branch: sec-thin-slice-reconcile-v1
base commit: 3dba0fbb11cdd91f0ffce3ccb2cc2f956a1354bc
base source: PR #233 Add source health internal UI recheck submit flow
stream: source health internal UI recheck action lock
status: docs-only
```

## Scope closed by this lock

This lock covers the internal source health detail UI recheck action state and bounded submit contract for:

```text
GET /admin/source-health/:source_key
POST /api/admin/source-health/:source_key/recheck
```

It does not close out:

```text
source health operator runbook
end-to-end operator smoke testing
monitoring dashboards or alerts
poll route gated stream
audit read UI
public source health UI
```

## Major locked behavior

The internal UI recheck action track now locks:

```text
default detail shell without permission params -> recheck_action=not_rendered
source_health:read -> recheck_action=disabled
source_health:read -> recheck_reason=read_only
source_health:recheck -> recheck_action=enabled
source_health:recheck -> recheck_method=POST
source_health:recheck -> recheck_target=/api/admin/source-health/:source_key/recheck
source_health:recheck -> idempotency=required
unknown source -> bounded 404 detail state
unknown source -> recheck_action=not_available
```

The enabled action targets only the existing bounded backend recheck route:

```text
POST /api/admin/source-health/:source_key/recheck
```

## UI detail shell lock

The internal detail shell remains bounded text output.

Approved displayed source fields remain:

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

The recheck action state may display only the locked bounded markers.

Do not add new detail shell fields that expose raw provider payloads, private actor context, canonical payloads, worker internals, or unbounded diagnostics.

## Permission state lock

Request-param-driven permission state is the current temporary UI test harness.

Current accepted inputs include:

```text
actor_permissions=source_health:read
actor_permissions=source_health:recheck
actor_permissions[]=source_health:read
actor_permissions[]=source_health:recheck
```

Locked behavior:

```text
missing actor_permissions -> legacy unwired detail state
source_health:read without source_health:recheck -> disabled/read_only
source_health:recheck -> enabled bounded action state
unknown source -> not_available regardless of permission params
```

This temporary request-param harness must not be treated as the final production auth/session model.

## Bounded submit contract lock

The enabled detail state may advertise this submit contract:

```text
recheck_method=POST
recheck_target=/api/admin/source-health/:source_key/recheck
recheck_context=bounded
recheck_context_fields=actor_id_hash,actor_permissions,request_id_hash,idempotency_key_hash,reason_redacted,redaction_status,created_at
```

The UI-bounded payload may contain only:

```text
actor_id_hash
actor_permissions
request_id_hash
idempotency_key_hash
reason_redacted
redaction_status
created_at
```

Do not add UI controls or payload fields for:

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

## Bounded result display lock

Approved bounded result messages:

```text
accepted -> Recheck request accepted.
reused -> A similar recent recheck request was reused.
untracked -> Recheck request accepted without tracking.
403 -> You do not have permission to recheck this source.
404 -> Source not found.
```

The UI must not display raw job internals, raw backend payloads, stack traces, SQL details, or unbounded diagnostics.

## Backend response shape lock

The UI recheck action track must not change the backend response shape for:

```text
POST /api/admin/source-health/:source_key/recheck
```

Locked backend outcomes available to the UI:

```text
source_health:recheck -> bounded 202
source_health:read -> bounded 403
unknown source -> bounded 404
idempotency_status -> accepted / reused / untracked when present
```

Audit writes remain internal and must not alter the HTTP response shape.

## Route lock

Approved internal UI routes remain:

```text
GET /admin/source-health
GET /admin/source-health/:source_key
```

Approved backend recheck route remains:

```text
POST /api/admin/source-health/:source_key/recheck
```

Do not add:

```text
/admin/source-health/:source_key/recheck
/admin/source-health/:source_key/poll
/admin/source-health/:source_key/audit
/admin/source-health/audit
/source-health
/public/source-health
/api/public/source-health
/api/source-health
```

The poll route remains gated and separate:

```text
POST /api/admin/sources/:source_key/poll
```

## Audit UI lock

The recheck action UI must not display audit event identifiers.

Forbidden display references:

```text
audit_event
audit_event_id
```

Audit read UI is a separate future track.

## Poll route remains out of scope

Do not add poll UI or poll submit behavior as part of source health recheck UI work.

Still gated:

```text
POST /api/admin/sources/:source_key/poll
```

## Redaction and forbidden material lock

The UI and bounded submit flow tests lock that responses must not expose:

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

## Validation evidence across this UI recheck track

Recent locked validations include:

```text
PR #232 focused source health internal UI recheck action test: 4 tests, 0 failures
PR #232 adjacent source health/UI regression: 51 tests, 0 failures
PR #233 focused source health internal UI recheck submit flow test: 4 tests, 0 failures
PR #233 adjacent source health/UI regression: 55 tests, 0 failures
```

Validated boundaries include:

```text
basic detail shell remains compatible
read-only disabled state
recheck enabled bounded target
unknown source 404/not_available
bounded submit contract rendered
bounded UI payload POST returns 202
read-only actor POST returns bounded 403
unknown source POST returns bounded 404
no new routes
no backend response shape changes
no POST/form/JS expansion beyond the bounded contract markers
no poll UI
no audit UI
no operation/queue/worker/payload controls
no provider/materializer/canonical controls
no raw/private/canonical material exposure
no duplicate source health controller warning introduced
```

Known warning status:

```text
existing compile warnings remain
existing Phoenix.ConnTest deprecation warning remains
no new duplicate controller warning was validated in the recent test runs
```

## Recommended final source health/UI recheck regression command

Recommended targeted UI recheck regression command:

```powershell
$env:MIX_ENV='test'; mix.bat test test/source_health_internal_ui_recheck_action_test.exs test/source_health_internal_ui_recheck_submit_flow_test.exs
```

Recommended adjacent source health/UI regression command:

```powershell
$env:MIX_ENV='test'; mix.bat test test/source_health_internal_ui_route_inventory_test.exs test/source_health_internal_ui_list_shell_test.exs test/source_health_internal_ui_detail_shell_test.exs test/source_health_internal_ui_recheck_action_test.exs test/source_health_internal_ui_recheck_submit_flow_test.exs test/source_health_route_target_test.exs test/source_health_route_contract_test.exs test/source_health_recheck_behavior_test.exs test/source_health_recheck_authorization_test.exs test/source_health_recheck_positive_characterization_test.exs test/source_health_recheck_bounded_enqueue_contract_test.exs test/source_health_recheck_idempotency_characterization_test.exs test/source_health_recheck_idempotency_storage_migration_test.exs test/source_health_recheck_idempotency_runtime_test.exs test/source_health_recheck_audit_storage_migration_test.exs test/source_health_recheck_audit_runtime_test.exs
```

Expected latest known result:

```text
55 tests, 0 failures
```

## Remaining work after this lock

After this source health UI recheck action lock, the remaining source health stream should move to:

```text
operator runbook
end-to-end operator smoke test design
source health internal UI final close-out
monitoring and operational visibility
poll route gated stream
```

## Recommended next PR

Recommended next PR:

```text
Add source health operator runbook
```

Recommended scope:

```text
docs-only runbook first
operator list -> detail -> recheck flow
read-only behavior
202 accepted/reused/untracked meaning
403 forbidden meaning
404 not-found meaning
redaction expectations
poll route remains out of scope
```

## Stop conditions for future work

Stop and re-scope if future work:

```text
lets source_health:read trigger recheck
adds recheck UI target other than /api/admin/source-health/:source_key/recheck
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

## Validation for this lock PR

This lock PR is docs-only and should change only:

```text
apps/backend/disclosure_api/docs/source_health_internal_ui_recheck_action_lock.md
```

No Codex test command is required for this docs-only lock PR.
