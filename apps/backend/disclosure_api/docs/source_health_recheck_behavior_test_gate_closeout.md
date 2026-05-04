# Source Health Recheck Behavior Test Gate Close-out

This document closes out the source health recheck behavior test-gate PR after targeted local validation and merge.

This close-out PR is documentation-only. It does not add or modify frontend code, backend runtime code, tests, fixtures, migrations, schema modules, router changes, controllers, templates, UI routes, action endpoint changes, scheduler work, provider clients, live fetch behavior, public API/feed behavior, materializer behavior, or canonical mutations.

## Baseline

```text
base branch: sec-thin-slice-reconcile-v1
base commit before test gate: bfe51530ff72e9a645bd5ca817484b6085a4b69c
base source: PR #194 Choose source health recheck implementation test gate
merged test gate: PR #195 Add source health recheck behavior test gate
merged test gate commit: 5b8f86091d4aa405b68162c66cc292e1fb673b01
stream: source health recheck behavior test-gate close-out
status: docs-only
```

## Evidence

```text
PR #195 Add source health recheck behavior test gate
head: 370743ad50705e83607c27a3480b4007ecde67c1
changed files: 1
changed file: apps/backend/disclosure_api/test/source_health_recheck_behavior_test.exs
scope: test-only source health recheck behavior gate
runtime code changes: none
merge commit: 5b8f86091d4aa405b68162c66cc292e1fb673b01
```

## Local validation recorded

Required targeted test:

```powershell
$env:MIX_ENV='test'; mix.bat test test/source_health_recheck_behavior_test.exs
```

Result:

```text
3 tests, 0 failures
```

Adjacent regression check:

```powershell
$env:MIX_ENV='test'; mix.bat test test/source_health_route_target_test.exs test/source_health_route_contract_test.exs test/source_health_recheck_behavior_test.exs
```

Result:

```text
11 tests, 0 failures
```

## Locked behavior from PR #195

The test gate locks the currently safe unknown-source path for:

```text
POST /api/admin/source-health/:source_key/recheck
```

The merged tests verify:

```text
request body operation override payloads remain bounded
read-only actor payloads do not produce accepted unknown-source work
unknown source keys return bounded 404 JSON
error response shape remains public and bounded
accepted job fields are not returned for the unknown-source path
raw/private material is not exposed in the response
```

## Important scope finding

The PR was confirmed as test-only.

It changed only:

```text
apps/backend/disclosure_api/test/source_health_recheck_behavior_test.exs
```

No runtime code changed.

Existing source health controllers remain in:

```text
apps/backend/disclosure_api/lib/disclosure_automation_web/controllers.ex
```

No duplicate controller warning was introduced.

## Known warnings

Local validation still shows existing compile warnings and the existing `Phoenix.ConnTest` deprecation warning.

These warnings are non-blocking for the recheck behavior test-gate close-out.

## What remains unimplemented

PR #195 did not implement runtime recheck behavior.

Still not implemented by PR #195:

```text
positive-path source_health:recheck authorization enforcement
read-only denial for existing source records
idempotency behavior for repeated recheck calls
request allowlist enforcement for existing source records
stored-state-only recheck runtime behavior
provider side-effect absence instrumentation
scheduler side-effect absence instrumentation
materializer side-effect absence instrumentation
canonical no-mutation instrumentation
accepted/queued response contract for authorized existing-source recheck
```

## Recommended next track

The next PR should stay small and choose one of these tracks:

```text
Track A: source health recheck authorization gap close-out/design
Track B: source health recheck positive-path fixture/test design
Track C: source health recheck side-effect boundary audit
```

Recommended next step:

```text
Track A: source health recheck authorization gap close-out/design
```

Rationale:

```text
The unknown-source gate is now locked.
The current tests cannot yet prove read-only denial for an existing source record.
Before runtime behavior changes, the authorization model for source_health:recheck should be made explicit.
```

## Stop conditions

Stop and re-scope if future source health recheck work:

```text
adds duplicate controller modules
changes public response shapes without a contract PR
allows request-body operation override to select poll/materialize/canonicalize/provider fetch behavior
lets source_health:read trigger recheck for existing source records without explicit design approval
calls provider clients unexpectedly
triggers scheduler work unexpectedly
triggers materializers unexpectedly
mutates canonical data unexpectedly
shows secrets, headers, cookies, tokens, raw payloads, full article text, SQL details, stack traces, or unbounded diagnostics
```

## Validation for this close-out PR

This close-out PR is docs-only and should change only:

```text
apps/backend/disclosure_api/docs/source_health_recheck_behavior_test_gate_closeout.md
```

No local test run is required unless a reviewer asks for targeted checks.
