# Source Health Recheck Idempotency Characterization Close-out

This document closes out the source health recheck idempotency characterization PR after local validation and merge.

This close-out PR is documentation-only. It does not add or modify frontend code, backend runtime code, tests, fixtures, migrations, schema modules, router changes, controllers, templates, UI routes, action endpoint changes, scheduler work, provider clients, live fetch behavior, public API/feed behavior, materializer behavior, canonical mutations, audit persistence, or idempotency storage.

## Baseline

```text
base branch: sec-thin-slice-reconcile-v1
base commit before idempotency characterization: 6b38cc84c55101bcf16b3693bc9d8e8cbe03ba2a
base source: PR #206 Design source health recheck idempotency and audit gate
merged characterization gate: PR #207 Add source health recheck idempotency characterization tests
merged characterization commit: b68829fece173d3d56b81c10940d13e05b0f39e2
stream: source health recheck idempotency characterization close-out
status: docs-only
```

## Evidence

```text
PR #207 Add source health recheck idempotency characterization tests
head: 32c6df157b4e469c18a1a370fe598278f907cd40
changed files: 1
changed file: apps/backend/disclosure_api/test/source_health_recheck_idempotency_characterization_test.exs
scope: test-only idempotency characterization
runtime code changes: none
merge commit: b68829fece173d3d56b81c10940d13e05b0f39e2
```

## Local validation recorded

Targeted idempotency characterization test:

```powershell
$env:MIX_ENV='test'; mix.bat test test/source_health_recheck_idempotency_characterization_test.exs
```

Result:

```text
3 tests, 0 failures
```

Adjacent source health regression:

```powershell
$env:MIX_ENV='test'; mix.bat test test/source_health_route_target_test.exs test/source_health_route_contract_test.exs test/source_health_recheck_behavior_test.exs test/source_health_recheck_authorization_test.exs test/source_health_recheck_positive_characterization_test.exs test/source_health_recheck_bounded_enqueue_contract_test.exs test/source_health_recheck_idempotency_characterization_test.exs
```

Result:

```text
22 tests, 0 failures
```

Validation was also recorded in PR review/comment evidence:

```text
review_id: 4219462652
```

## Locked characterization findings

The idempotency characterization now records current HTTP-level behavior for repeated authorized source health recheck calls.

Observed current behavior:

```text
same idempotency_key_hash repeated calls -> bounded 202 behavior
different idempotency_key_hash repeated calls -> bounded 202 behavior
missing idempotency_key_hash -> bounded 202 behavior
source_key / health_checks characterization -> preserved
raw actor/request/idempotency identifiers -> not exposed
unredacted reason -> not exposed
raw/private/canonical material -> not exposed
```

## Important interpretation

This characterization does not implement idempotency enforcement.

The current behavior should be treated as permissive repeated enqueue at the HTTP contract layer until a future runtime PR explicitly adds deduplication or strict idempotency handling.

This means:

```text
repeated calls are currently accepted
missing idempotency_key_hash is currently accepted
response redaction remains bounded
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

PR #207 does not complete idempotency or audit implementation.

Still not implemented:

```text
idempotency storage
job de-duplication
strict idempotency key requirement
audit log persistence
audit log response references
retry semantics
job result lookup
operator retry policy
provider side-effect instrumentation beyond bounded response checks
scheduler side-effect inspection beyond health_checks response characterization
materializer side-effect instrumentation
canonical no-mutation instrumentation beyond response characterization
```

## Recommended next track

Recommended next PR:

```text
Decide source health recheck idempotency enforcement model
```

Recommended scope:

```text
docs-only decision/design first
compare permissive repeated enqueue vs best-effort dedupe vs strict idempotency
use PR #207 characterization as evidence
keep audit persistence out of scope unless explicitly selected
keep poll behavior out of scope
keep provider/materializer/canonical mutation out of scope
```

Recommended model to evaluate:

```text
best-effort dedupe by source_key + idempotency_key_hash
```

But this should not be implemented until storage, expiry, retry semantics, and response behavior are explicitly designed.

## Stop conditions

Stop and re-scope if future work:

```text
adds duplicate controller modules
lets source_health:read trigger recheck for existing source records
allows request-body operation override to select poll/materialize/canonicalize/provider fetch behavior
allows request body to select queue, worker, or job payload shape
returns raw actor/request/idempotency identifiers
returns unredacted reason
persists or returns secrets, headers, cookies, tokens, raw payloads, full article text, SQL details, stack traces, or unbounded diagnostics
changes public response shapes without a contract PR
calls provider clients inline
triggers materializers inline
mutates canonical data
```

## Validation for this close-out PR

This close-out PR is docs-only and should change only:

```text
apps/backend/disclosure_api/docs/source_health_recheck_idempotency_characterization_closeout.md
```

No Codex test command is required for this docs-only close-out PR.
