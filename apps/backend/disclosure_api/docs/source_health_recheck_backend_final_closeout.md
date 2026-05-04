# Source Health Recheck Backend Final Close-out

This document closes out the source health recheck backend safety track.

This close-out PR is documentation-only. It does not add or modify frontend code, backend runtime code, tests, fixtures, migrations, schema modules, router changes, controllers, templates, UI routes, action endpoint changes, scheduler work, provider clients, live fetch behavior, public API/feed behavior, materializer behavior, canonical mutations, audit query APIs, or source health UI behavior.

## Baseline

```text
base branch: sec-thin-slice-reconcile-v1
base commit: 89a35c1bb14a4c44ec33787c0faa369e9378d294
base source: PR #221 Lock source health recheck audit runtime
stream: source health recheck backend final close-out
status: docs-only
```

## Scope closed by this track

This backend track covers:

```text
POST /api/admin/source-health/:source_key/recheck
```

It does not close out:

```text
POST /api/admin/sources/:source_key/poll
source health internal UI
operator runbook finalization
end-to-end UI smoke testing
monitoring dashboards or alerts
```

## Major locked behavior

The source health recheck backend track now locks:

```text
unknown source key -> bounded 404
source_health:read -> bounded 403 for existing source recheck
source_health:recheck -> bounded 202 for existing source positive path
request body operation override -> cannot select another operation
bounded health_checks enqueue model -> approved and tested
idempotency storage -> dedicated table and indexes
runtime idempotency -> accepted / reused / untracked behavior
audit storage -> dedicated table and indexes
audit runtime -> accepted / reused / untracked / forbidden / not_found events
raw/private/canonical response material -> forbidden
raw/private/canonical audit storage material -> forbidden
no duplicate source health controller modules
```

## Route and controller lock

Existing source health controller modules remain in:

```text
apps/backend/disclosure_api/lib/disclosure_automation_web/controllers.ex
```

Do not add duplicate controller modules for:

```text
DisclosureAutomationWeb.AdminSourceHealthController
DisclosureAutomationWeb.AdminSourcePollController
```

The recheck route remains:

```text
POST /api/admin/source-health/:source_key/recheck
```

## Authorization lock

Locked behavior:

```text
source_health:read cannot trigger recheck for an existing source
source_health:recheck can trigger bounded recheck for an existing source
unknown source remains 404
```

Read-only denial and unknown-source behavior are also audited.

## Bounded enqueue lock

Authorized source health recheck uses the bounded health-check path.

Locked behavior:

```text
202 Accepted
source_key present in bounded response
health_checks characterization present
request body cannot choose queue, worker, operation, or payload shape
```

Not approved:

```text
poll route expansion
inline provider fetch
inline materializer execution
canonical mutation
public API/feed response changes
raw/private response material
```

## Idempotency lock

Storage table:

```text
source_health_recheck_idempotency_keys
```

Runtime behavior:

```text
same source_key + same idempotency_key_hash -> accepted then reused
same source_key + same idempotency_key_hash -> one idempotency record
different idempotency_key_hash values -> separate accepted records
missing idempotency_key_hash -> bounded untracked 202 without storage record
source_health:read -> 403 and no idempotency record
unknown source -> 404 and no idempotency record
```

The current implementation keeps missing idempotency hashes temporarily accepted for compatibility.

Still not implemented:

```text
strict missing-key rejection
expired-record cleanup job
job result lookup
operator retry policy beyond best-effort dedupe
```

## Audit lock

Storage table:

```text
source_health_recheck_audit_events
```

Runtime audit outcomes:

```text
accepted
reused
untracked
forbidden
not_found
```

Audit route operation remains fixed as:

```text
source_health:recheck
```

Request body operation override cannot alter the audit route operation.

The HTTP response does not expose audit event references.

Forbidden response references:

```text
audit_event
audit_event_id
```

## Redaction and forbidden material lock

Responses and audit storage must not expose or persist:

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

## Validation evidence across the track

Recent locked validations include:

```text
source health route target/contract/recheck/idempotency/audit regression: 36 tests, 0 failures
source health recheck audit runtime test: 4 tests, 0 failures
source health recheck audit storage migration test: 3 tests, 0 failures
source health recheck idempotency runtime test: 4 tests, 0 failures
source health recheck idempotency storage migration test: 3 tests, 0 failures
```

Known warning status:

```text
existing compile warnings remain
existing Phoenix.ConnTest deprecation warning remains
no new duplicate controller warning was validated in the recent test runs
```

## Final source health recheck backend test command

Recommended targeted backend regression command:

```powershell
$env:MIX_ENV='test'; mix.bat test test/source_health_route_target_test.exs test/source_health_route_contract_test.exs test/source_health_recheck_behavior_test.exs test/source_health_recheck_authorization_test.exs test/source_health_recheck_positive_characterization_test.exs test/source_health_recheck_bounded_enqueue_contract_test.exs test/source_health_recheck_idempotency_characterization_test.exs test/source_health_recheck_idempotency_storage_migration_test.exs test/source_health_recheck_idempotency_runtime_test.exs test/source_health_recheck_audit_storage_migration_test.exs test/source_health_recheck_audit_runtime_test.exs
```

Expected latest known result:

```text
36 tests, 0 failures
```

## Remaining non-backend work

After this backend close-out, the remaining source health stream should move to:

```text
source health internal UI
operator runbook finalization
end-to-end operator smoke testing
monitoring and operational visibility
poll route gated stream
```

## Recommended next track

Recommended next PR:

```text
Design source health internal UI track
```

Recommended scope:

```text
docs-only design first
list source health UI pages and states
show how 202 / 403 / 404 are displayed
show how read-only permission disables recheck
ensure raw/private/canonical material is not displayed
keep poll route gated and out of scope
```

## Poll route remains gated

The poll route remains a separate high-risk track:

```text
POST /api/admin/sources/:source_key/poll
```

Do not expand poll behavior as part of source health recheck backend close-out or UI work unless a dedicated poll design/test-gate track is opened.

## Stop conditions for future work

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
apps/backend/disclosure_api/docs/source_health_recheck_backend_final_closeout.md
```

No Codex test command is required for this docs-only final close-out PR.
