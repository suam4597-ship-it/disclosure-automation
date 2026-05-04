# Source Health Recheck Idempotency Runtime Close-out

This document closes out the source health recheck idempotency runtime PR after local validation and merge.

This close-out PR is documentation-only. It does not add or modify frontend code, backend runtime code, tests, fixtures, migrations, schema modules, router changes, controllers, templates, UI routes, action endpoint changes, scheduler work, provider clients, live fetch behavior, public API/feed behavior, materializer behavior, canonical mutations, audit persistence, or idempotency enforcement behavior.

## Baseline

```text
base branch: sec-thin-slice-reconcile-v1
base commit before idempotency runtime: 74788046f7109281ad16f26dc68c0c8a148a3feb
base source: PR #213 Design source health recheck idempotency runtime contract
merged runtime gate: PR #214 Add source health recheck idempotency runtime tests
merged runtime commit: 1c74a3163abcde62f2188486278f86bea55c948b
stream: source health recheck idempotency runtime close-out
status: docs-only
```

## Evidence

```text
PR #214 Add source health recheck idempotency runtime tests
head: 9623d4565accc0aad590bb0e6ca8feaf86b09ace
changed files: 3
runtime: apps/backend/disclosure_api/lib/disclosure_automation/sources.ex
controller: apps/backend/disclosure_api/lib/disclosure_automation_web/controllers.ex
test: apps/backend/disclosure_api/test/source_health_recheck_idempotency_runtime_test.exs
merge commit: 1c74a3163abcde62f2188486278f86bea55c948b
```

## Local validation recorded

Targeted idempotency runtime test:

```powershell
$env:MIX_ENV='test'; mix.bat test test/source_health_recheck_idempotency_runtime_test.exs
```

Result:

```text
4 tests, 0 failures
```

Adjacent source health regression:

```powershell
$env:MIX_ENV='test'; mix.bat test test/source_health_route_target_test.exs test/source_health_route_contract_test.exs test/source_health_recheck_behavior_test.exs test/source_health_recheck_authorization_test.exs test/source_health_recheck_positive_characterization_test.exs test/source_health_recheck_bounded_enqueue_contract_test.exs test/source_health_recheck_idempotency_characterization_test.exs test/source_health_recheck_idempotency_storage_migration_test.exs test/source_health_recheck_idempotency_runtime_test.exs
```

Result:

```text
29 tests, 0 failures
```

Validation was also recorded in PR review/comment evidence:

```text
review_id: 4220235019
```

## Locked runtime behavior

PR #214 locks the first runtime idempotency behavior for source health recheck.

Locked behavior:

```text
same source_key + same idempotency_key_hash -> accepted then reused
same source_key + same idempotency_key_hash -> one idempotency record
different idempotency_key_hash values -> separate accepted records
missing idempotency_key_hash -> bounded untracked 202 without storage record
source_health:read -> bounded 403 and no idempotency record
unknown source -> bounded 404 and no idempotency record
```

## Response behavior

Responses remain bounded and admin-safe.

Observed/locked response markers:

```text
source_key
health_checks
idempotency_status: accepted
idempotency_status: reused
idempotency_status: untracked
```

## Storage behavior

The runtime now writes idempotency records only when an idempotency key hash is present and the authorized recheck path accepts new work.

The validated storage behavior is:

```text
same source_key + same idempotency_key_hash remains one record
different idempotency_key_hash values produce separate records
missing idempotency_key_hash does not create a record
read-only actor does not create a record
unknown source does not create a record
```

## Redaction behavior

Local validation confirmed no response leak of:

```text
raw actor identifiers
raw request identifiers
raw idempotency identifiers
unredacted reason
raw/private material
canonical material
```

## Implementation scope

PR #214 changed only:

```text
apps/backend/disclosure_api/lib/disclosure_automation/sources.ex
apps/backend/disclosure_api/lib/disclosure_automation_web/controllers.ex
apps/backend/disclosure_api/test/source_health_recheck_idempotency_runtime_test.exs
```

No duplicate controller modules were added.

Existing source health controller remains:

```text
DisclosureAutomationWeb.AdminSourceHealthController
```

Existing controller location remains:

```text
apps/backend/disclosure_api/lib/disclosure_automation_web/controllers.ex
```

## What remains unimplemented

PR #214 does not implement:

```text
strict missing-key rejection
audit persistence
audit log response references
expired-record cleanup
job result lookup
operator retry policy beyond best-effort dedupe
poll behavior
provider fetch behavior
materializer behavior
canonical mutation
source health internal UI
```

## Recommended next track

Recommended next PR:

```text
Design source health recheck audit persistence contract
```

Recommended scope:

```text
docs-only decision/design first
define audit event table or reuse strategy
define allowed bounded audit fields
define forbidden audit fields
define relationship to idempotency records
define whether audit reference appears in response
no audit runtime implementation yet
keep poll behavior out of scope
keep provider/materializer/canonical mutation out of scope
```

Rationale:

```text
Authorization is locked.
Bounded enqueue is locked.
Runtime idempotency is implemented and validated.
The next backend risk is auditability: recording who triggered recheck, when, and why, without storing raw/private material.
```

## Stop conditions

Stop and re-scope if future work:

```text
adds duplicate controller modules
lets source_health:read trigger recheck for existing source records
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
apps/backend/disclosure_api/docs/source_health_recheck_idempotency_runtime_closeout.md
```

No Codex test command is required for this docs-only close-out PR.
