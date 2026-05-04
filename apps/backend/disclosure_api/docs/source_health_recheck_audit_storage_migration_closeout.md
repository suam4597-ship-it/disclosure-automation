# Source Health Recheck Audit Storage Migration Close-out

This document closes out the source health recheck audit storage migration PR after local validation and merge.

This close-out PR is documentation-only. It does not add or modify frontend code, backend runtime code, tests, fixtures, migrations, schema modules, router changes, controllers, templates, UI routes, action endpoint changes, scheduler work, provider clients, live fetch behavior, public API/feed behavior, materializer behavior, canonical mutations, audit runtime writes, or idempotency enforcement behavior.

## Baseline

```text
base branch: sec-thin-slice-reconcile-v1
base commit before audit storage migration: cb7220711e3b26fc91b6bcbd2d94fb1eff1483bc
base source: PR #216 Design source health recheck audit contract
merged migration gate: PR #217 Add source health recheck audit storage migration tests
merged migration commit: 40eaef4bfd24cad0600a1925313a01fcf8a6def3
stream: source health recheck audit storage migration close-out
status: docs-only
```

## Evidence

```text
PR #217 Add source health recheck audit storage migration tests
head: bef70433d8b0d8127599e307832effe528a12d39
changed files: 2
migration: apps/backend/disclosure_api/priv/repo/migrations/20260504131500_create_source_health_recheck_audit_events.exs
test: apps/backend/disclosure_api/test/source_health_recheck_audit_storage_migration_test.exs
merge commit: 40eaef4bfd24cad0600a1925313a01fcf8a6def3
```

## Local validation recorded

Targeted audit storage migration test:

```powershell
$env:MIX_ENV='test'; mix.bat test test/source_health_recheck_audit_storage_migration_test.exs
```

Result:

```text
3 tests, 0 failures
```

Adjacent source health regression:

```powershell
$env:MIX_ENV='test'; mix.bat test test/source_health_route_target_test.exs test/source_health_route_contract_test.exs test/source_health_recheck_behavior_test.exs test/source_health_recheck_authorization_test.exs test/source_health_recheck_positive_characterization_test.exs test/source_health_recheck_bounded_enqueue_contract_test.exs test/source_health_recheck_idempotency_characterization_test.exs test/source_health_recheck_idempotency_storage_migration_test.exs test/source_health_recheck_idempotency_runtime_test.exs test/source_health_recheck_audit_storage_migration_test.exs
```

Result:

```text
32 tests, 0 failures
```

Validation was also recorded in PR review/comment evidence:

```text
review_id: 4221727624
```

## Locked audit storage structure

The migration/test gate locks the dedicated table:

```text
source_health_recheck_audit_events
```

Required bounded columns verified by tests:

```text
id
source_key
route_operation
result_status
idempotency_status
actor_id_hash
request_id_hash
idempotency_key_hash
idempotency_key_id
reason_redacted
redaction_status
occurred_at
metadata
inserted_at
updated_at
```

Required indexes verified by tests:

```text
source_health_recheck_audit_source_key_idx
source_health_recheck_audit_route_operation_idx
source_health_recheck_audit_result_status_idx
source_health_recheck_audit_idem_status_idx
source_health_recheck_audit_occurred_at_idx
source_health_recheck_audit_idem_key_id_idx
```

The audit table may optionally link to source health recheck idempotency records through:

```text
idempotency_key_id
```

## Forbidden storage fields remain absent

Tests verify the table does not contain forbidden raw/private/canonical fields including:

```text
raw_actor_id
raw_request_id
raw_idempotency_key
unredacted_reason
headers
cookies
tokens
provider_credentials
raw_provider_payload
full_article_text
sql_details
stack_trace
canonical_payload
private_actor_context
unbounded_diagnostics
```

The validation redaction scan confirmed no private key, header, or cookie exposure. The `tokens` string appears only as a forbidden-column negative assertion in the test.

## No duplicate controller finding

Local validation did not identify new duplicate controller evidence.

The source health controller remains the existing module:

```text
DisclosureAutomationWeb.AdminSourceHealthController
```

Existing controller location remains:

```text
apps/backend/disclosure_api/lib/disclosure_automation_web/controllers.ex
```

## What remains unimplemented

PR #217 adds audit storage structure and DB tests only.

Still not implemented:

```text
audit runtime writes
audit schema module
audit event response references
audit query/read APIs
strict missing-key rejection
idempotency cleanup
job result lookup
poll behavior
provider fetch behavior
materializer behavior
canonical mutation
source health internal UI
```

## Recommended next track

Recommended next PR:

```text
Design source health recheck audit runtime contract
```

Recommended scope:

```text
docs-only decision/design first
define when audit events are written
define result_status and idempotency_status mapping
define optional idempotency_key_id linkage
define whether audit write failure blocks recheck or is best-effort
define response-shape non-change
keep poll behavior out of scope
keep provider/materializer/canonical mutation out of scope
```

## Stop conditions

Stop and re-scope if future work:

```text
adds duplicate controller modules
lets source_health:read trigger recheck for existing source records
allows request-body operation override to select audit route operation
allows request-body operation override to select poll/materialize/canonicalize/provider fetch behavior
allows request body to select queue, worker, or job payload shape
stores or returns raw actor/request/idempotency identifiers
stores or returns unredacted reason
persists or returns secrets, headers, cookies, tokens, raw payloads, full article text, SQL details, stack traces, or unbounded diagnostics
changes public response shapes without a contract PR
calls provider clients inline
triggers materializers inline
mutates canonical data
```

## Validation for this close-out PR

This close-out PR is docs-only and should change only:

```text
apps/backend/disclosure_api/docs/source_health_recheck_audit_storage_migration_closeout.md
```

No Codex test command is required for this docs-only close-out PR.
