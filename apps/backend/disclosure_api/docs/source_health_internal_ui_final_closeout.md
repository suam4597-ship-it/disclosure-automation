# Source Health Internal UI Final Close-out

This document closes out the current source health internal UI track.

This close-out PR is documentation-only. It does not add or modify frontend runtime code, backend runtime code, tests, fixtures, migrations, schema modules, router changes, controllers, templates, API response shapes, provider behavior, materializer behavior, canonical mutation behavior, poll behavior, audit read UI, public API/feed behavior, monitoring behavior, or alerting behavior.

## Baseline

```text
base branch: sec-thin-slice-reconcile-v1
base commit: 23c6977a4f0747522f322f34f306f8aa6ad6f8d2
base source: PR #237 Add source health operator smoke test
stream: source health internal UI final close-out
status: docs-only
```

## Scope closed by this UI track

This UI track closes the bounded internal source health operator surface for:

```text
GET /admin/source-health
GET /admin/source-health/:source_key
POST /api/admin/source-health/:source_key/recheck
```

The first two are internal UI routes. The third is the existing bounded backend route used by the UI recheck action contract.

This close-out does not close:

```text
monitoring and operational visibility
poll route gated stream
audit read UI
public source health UI
production auth/session replacement for the temporary permission test harness
```

## Major locked behavior

The source health internal UI track now locks:

```text
internal source health list shell
internal source health detail shell
bounded unknown-source detail state
permission-aware recheck action state
bounded recheck submit contract markers
operator runbook
operator smoke test
raw/private/canonical material denylist
no public source health UI routes
no poll UI routes
no audit UI routes
```

## Route inventory lock

Approved internal UI routes remain:

```text
GET /admin/source-health
GET /admin/source-health/:source_key
```

Approved backend recheck route remains:

```text
POST /api/admin/source-health/:source_key/recheck
```

Forbidden UI routes remain:

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

## List shell lock

Locked list route:

```text
GET /admin/source-health
```

Locked list behavior:

```text
Source health
page=<page>
page_size=<page_size>
total_entries=<total_entries>
fields=source_key,display_name,source_type,region_code,health_status,last_success_at,last_failure_at,active
recheck_action=not_rendered
poll_action=not_rendered
audit_ui=not_rendered
```

Approved list row fields:

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

Not approved on the list shell:

```text
recheck buttons
poll buttons
audit UI
provider payloads
job internals
private actor context
canonical payloads
```

## Detail shell lock

Locked detail route:

```text
GET /admin/source-health/:source_key
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

Known-source state:

```text
state=found
```

Unknown-source state:

```text
state=not_found
recheck_action=not_available
back=/admin/source-health
```

Not approved on the detail shell:

```text
raw provider payloads
private actor context
canonical payloads
worker internals
unbounded diagnostics
SQL details
stack traces
provider credentials
```

## Recheck action lock

Locked states:

```text
missing actor_permissions -> recheck_action=not_rendered
source_health:read -> recheck_action=disabled
source_health:read -> recheck_reason=read_only
source_health:recheck -> recheck_action=enabled
source_health:recheck -> recheck_method=POST
source_health:recheck -> recheck_target=/api/admin/source-health/:source_key/recheck
source_health:recheck -> idempotency=required
unknown source -> recheck_action=not_available
```

Temporary test harness inputs remain:

```text
actor_permissions=source_health:read
actor_permissions=source_health:recheck
actor_permissions[]=source_health:read
actor_permissions[]=source_health:recheck
```

This temporary request-param harness is not the final production auth/session model.

## Bounded submit contract lock

The enabled detail state may advertise this submit contract:

```text
recheck_method=POST
recheck_target=/api/admin/source-health/:source_key/recheck
recheck_context=bounded
recheck_context_fields=actor_id_hash,actor_permissions,request_id_hash,idempotency_key_hash,reason_redacted,redaction_status,created_at
```

Approved UI-bounded payload fields:

```text
actor_id_hash
actor_permissions
request_id_hash
idempotency_key_hash
reason_redacted
redaction_status
created_at
```

Forbidden UI controls or payload fields:

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

Approved operator-facing result messages:

```text
accepted -> Recheck request accepted.
reused -> A similar recent recheck request was reused.
untracked -> Recheck request accepted without tracking.
403 -> You do not have permission to recheck this source.
404 -> Source not found.
```

The UI must not display:

```text
raw job internals
raw backend payloads
stack traces
SQL details
unbounded diagnostics
audit event identifiers
```

## Backend boundary lock

The UI track does not change backend response shapes.

Locked backend outcomes available to the UI:

```text
source_health:recheck -> bounded 202
source_health:read -> bounded 403
unknown source -> bounded 404
idempotency_status -> accepted / reused / untracked when present
```

Audit writes remain internal and must not alter HTTP response shape.

## Operator runbook lock

Operator runbook now covers:

```text
internal list triage
internal detail inspection
permission-aware recheck state interpretation
bounded recheck submission
202 accepted/reused/untracked interpretation
403 forbidden interpretation
404 not-found interpretation
bounded escalation checklist
idempotency guidance
audit expectations
poll route out-of-scope warning
```

Runbook file:

```text
apps/backend/disclosure_api/docs/source_health_operator_runbook.md
```

## Operator smoke test lock

Operator smoke test file:

```text
apps/backend/disclosure_api/test/source_health_operator_smoke_test.exs
```

Locked smoke coverage:

```text
operator bounded list shell triage
operator bounded detail recheck contract
operator bounded backend recheck submit
read-only detail disabled state
read-only backend forbidden response
unknown source detail/backend bounded responses
raw/private/canonical material denylist across UI text and JSON responses
```

## Audit UI remains out of scope

The internal UI track does not add audit read UI.

Forbidden display references:

```text
audit_event
audit_event_id
```

Audit read UI may be designed later as a separate track.

## Poll route remains gated

The internal UI track does not add poll UI.

Still gated:

```text
POST /api/admin/sources/:source_key/poll
```

Do not add source health UI controls for:

```text
poll_source
provider_fetch
materialize
canonicalize
inline_feed
use_live_fetch
```

Poll route work must remain a dedicated future stream.

## Redaction and forbidden material lock

Internal UI and operator smoke tests lock that UI text and JSON responses must not expose:

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
audit_event
audit_event_id
```

## Validation evidence across the UI track

Recent locked validations include:

```text
PR #232 focused source health internal UI recheck action test: 4 tests, 0 failures
PR #232 adjacent source health/UI regression: 51 tests, 0 failures
PR #233 focused source health internal UI recheck submit flow test: 4 tests, 0 failures
PR #233 adjacent source health/UI regression: 55 tests, 0 failures
PR #237 focused source health operator smoke test: 6 tests, 0 failures
PR #237 adjacent source health/UI regression: 61 tests, 0 failures
```

Docs-only close-out/design/runbook PRs:

```text
PR #234 Lock source health internal UI recheck action
PR #235 Refresh source health operator runbook
PR #236 Design source health operator smoke test
```

Known warning status:

```text
existing compile warnings remain
existing Phoenix.ConnTest deprecation warning remains
no new duplicate source health controller warning was validated in recent test runs
```

## Recommended final source health UI regression command

Recommended targeted source health UI regression command:

```powershell
$env:MIX_ENV='test'; mix.bat test test/source_health_internal_ui_route_inventory_test.exs test/source_health_internal_ui_list_shell_test.exs test/source_health_internal_ui_detail_shell_test.exs test/source_health_internal_ui_recheck_action_test.exs test/source_health_internal_ui_recheck_submit_flow_test.exs test/source_health_operator_smoke_test.exs
```

Recommended adjacent source health/UI regression command:

```powershell
$env:MIX_ENV='test'; mix.bat test test/source_health_internal_ui_route_inventory_test.exs test/source_health_internal_ui_list_shell_test.exs test/source_health_internal_ui_detail_shell_test.exs test/source_health_internal_ui_recheck_action_test.exs test/source_health_internal_ui_recheck_submit_flow_test.exs test/source_health_operator_smoke_test.exs test/source_health_route_target_test.exs test/source_health_route_contract_test.exs test/source_health_recheck_behavior_test.exs test/source_health_recheck_authorization_test.exs test/source_health_recheck_positive_characterization_test.exs test/source_health_recheck_bounded_enqueue_contract_test.exs test/source_health_recheck_idempotency_characterization_test.exs test/source_health_recheck_idempotency_storage_migration_test.exs test/source_health_recheck_idempotency_runtime_test.exs test/source_health_recheck_audit_storage_migration_test.exs test/source_health_recheck_audit_runtime_test.exs
```

Expected latest known adjacent result:

```text
61 tests, 0 failures
```

## Remaining work after this close-out

After this source health internal UI close-out, remaining work should be tracked separately:

```text
monitoring and operational visibility
poll route gated stream
audit read UI if needed
production auth/session model replacement for request-param test harness
```

## Recommended next PR

Recommended next PR:

```text
Design source health monitoring and operational visibility
```

Recommended scope:

```text
docs-only design first
bounded source health recheck metrics
bounded audit/event counts without raw identifiers
operator-visible health status freshness signals
alert thresholds without raw payloads
poll route remains out of scope
```

Alternative next PR if monitoring is deferred:

```text
Design source health poll route gated stream
```

Only choose the poll stream when ready to explicitly design/test gate poll behavior.

## Stop conditions for future work

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
calls provider clients inline
triggers materializers inline
mutates canonical data
```

## Validation for this close-out PR

This final close-out PR is docs-only and should change only:

```text
apps/backend/disclosure_api/docs/source_health_internal_ui_final_closeout.md
```

No Codex test command is required for this docs-only final close-out PR.
