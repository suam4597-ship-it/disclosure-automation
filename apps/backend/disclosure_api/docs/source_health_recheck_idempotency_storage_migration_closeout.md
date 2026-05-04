# Source Health Recheck Idempotency Storage Migration Close-out

This document closes out the source health recheck idempotency storage migration PR after local validation and merge.

This close-out PR is documentation-only. It does not add or modify frontend code, backend runtime code, tests, fixtures, migrations, schema modules, router changes, controllers, templates, UI routes, action endpoint changes, scheduler work, provider clients, live fetch behavior, public API/feed behavior, materializer behavior, canonical mutations, audit persistence, or idempotency runtime enforcement.

## Baseline

```text
base branch: sec-thin-slice-reconcile-v1
base commit before idempotency storage migration: ea26092b34260ac686cea325b55d25836bab5854
base source: PR #210 Design source health recheck idempotency storage contract
merged migration gate: PR #211 Add source health recheck idempotency storage migration tests
merged migration commit: cd0c6dcf189f6e3a95c50f2e74bcd5619b5d922f
stream: source health recheck idempotency storage migration close-out
status: docs-only
```

## Evidence

```text
PR #211 Add source health recheck idempotency storage migration tests
initial head: 3881a00863f2498134928b6b482ba543c85b649d
validated head: 6f6b3cbd59a10405c79ccbd5ab733a888b1b30ec
changed files: 2
migration: apps/backend/disclosure_api/priv/repo/migrations/20260504114000_create_source_health_recheck_idempotency_keys.exs
test: apps/backend/disclosure_api/test/source_health_recheck_idempotency_storage_migration_test.exs
merge commit: cd0c6dcf189f6e3a95c50f2e74bcd5619b5d922f
```

## Initial validation failure

The first local validation failed on the migration test.

Cause:

```text
Postgrex encode error from inserting a string UUID into a :binary_id column through Repo.insert_all/3
```

Fix applied on the PR branch:

```elixir
Ecto.UUID.generate() |> Ecto.UUID.dump!()
```

The fix was test-only and kept the migration contract unchanged.

## Final local validation recorded

Validated head:

```text
6f6b3cbd59a10405c79ccbd5ab733a888b1b30ec
```

Targeted storage migration test:

```powershell
$env:MIX_ENV='test'; mix.bat test test/source_health_recheck_idempotency_storage_migration_test.exs
```

Result:

```text
3 tests, 0 failures
```

Adjacent source health regression:

```powershell
$env:MIX_ENV='test'; mix.bat test test/source_health_route_target_test.exs test/source_health_route_contract_test.exs test/source_health_recheck_behavior_test.exs test/source_health_recheck_authorization_test.exs test/source_health_recheck_positive_characterization_test.exs test/source_health_recheck_bounded_enqueue_contract_test.exs test/source_health_recheck_idempotency_characterization_test.exs test/source_health_recheck_idempotency_storage_migration_test.exs
```

Result:

```text
25 tests, 0 failures
```

Validation was also recorded in PR review/comment evidence:

```text
review_id: 4219795213
```

## Locked storage structure

The migration/test gate locks the dedicated table:

```text
source_health_recheck_idempotency_keys
```

The locked best-effort dedupe key is:

```text
source_key + idempotency_key_hash
```

Required bounded columns verified by tests:

```text
id
source_key
idempotency_key_hash
request_id_hash
actor_id_hash
status
job_reference
expires_at
last_seen_at
metadata
inserted_at
updated_at
```

Required indexes verified by tests:

```text
source_health_recheck_idem_source_key_hash_uidx
source_health_recheck_idem_source_key_idx
source_health_recheck_idem_expires_at_idx
source_health_recheck_idem_status_idx
```

Uniqueness verified by tests:

```text
source_key + idempotency_key_hash
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

PR #211 adds storage structure and DB tests only.

Still not implemented:

```text
runtime idempotency lookup
runtime idempotency insert/reuse path
accepted vs reused response field
strict missing-key rejection
idempotency expiry cleanup
audit log persistence
audit log response references
retry semantics
job result lookup
poll behavior
provider fetch behavior
materializer behavior
canonical mutation
```

## Recommended next track

Recommended next PR:

```text
Design source health recheck idempotency runtime contract
```

Recommended scope:

```text
docs-only decision/design first
choose runtime lookup/insert/reuse flow
choose accepted vs reused response contract
choose behavior when idempotency_key_hash is missing
choose how expires_at is calculated
choose whether job_reference is returned or only stored
keep audit persistence out of scope unless explicitly selected
keep poll behavior out of scope
keep provider/materializer/canonical mutation out of scope
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
apps/backend/disclosure_api/docs/source_health_recheck_idempotency_storage_migration_closeout.md
```

No Codex test command is required for this docs-only close-out PR.
