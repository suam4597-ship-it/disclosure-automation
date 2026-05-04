# Source Health Recheck Bounded Enqueue Contract Close-out

This document closes out the source health recheck bounded enqueue contract PR after local validation and merge.

This close-out PR is documentation-only. It does not add or modify frontend code, backend runtime code, tests, fixtures, migrations, schema modules, router changes, controllers, templates, UI routes, action endpoint changes, scheduler work, provider clients, live fetch behavior, public API/feed behavior, materializer behavior, or canonical mutations.

## Baseline

```text
base branch: sec-thin-slice-reconcile-v1
base commit before bounded enqueue contract: 30e6aab0ab845de13a67392ed55ba76364f9bc03
base source: PR #203 Decide source health recheck side-effect model
merged contract gate: PR #204 Add source health recheck bounded enqueue contract tests
merged contract commit: 898c4c87d2684b1e7fd5086085b3e40436c10343
stream: source health recheck bounded enqueue contract close-out
status: docs-only
```

## Evidence

```text
PR #204 Add source health recheck bounded enqueue contract tests
head: 7f7c86d9ec6a1b6372b9916066c6cf6662781046
changed files: 1
changed file: apps/backend/disclosure_api/test/source_health_recheck_bounded_enqueue_contract_test.exs
scope: test-only bounded enqueue contract
runtime code changes: none
merge commit: 898c4c87d2684b1e7fd5086085b3e40436c10343
```

## Local validation recorded

Targeted bounded enqueue contract test:

```powershell
$env:MIX_ENV='test'; mix.bat test test/source_health_recheck_bounded_enqueue_contract_test.exs
```

Result:

```text
3 tests, 0 failures
```

Adjacent source health regression:

```powershell
$env:MIX_ENV='test'; mix.bat test test/source_health_route_target_test.exs test/source_health_route_contract_test.exs test/source_health_recheck_behavior_test.exs test/source_health_recheck_authorization_test.exs test/source_health_recheck_positive_characterization_test.exs test/source_health_recheck_bounded_enqueue_contract_test.exs
```

Result:

```text
19 tests, 0 failures
```

Validation was also recorded in PR review/comment evidence:

```text
review_id: 4219270314
```

## Locked behavior from PR #204

The bounded enqueue contract now locks the following HTTP-level behavior for:

```text
POST /api/admin/source-health/:source_key/recheck
actor permission: source_health:recheck
source_key: existing source
```

Locked behavior:

```text
authorized source_health:recheck returns 202 Accepted
response includes source_key
response includes health_checks characterization
response does not include an error object
request-body operation override material does not appear in response
request-body queue/worker/payload override material does not appear in response
source_health:read still receives bounded 403 for existing source
unknown source still receives bounded 404
raw/private/canonical material does not appear in response
```

Override material checked includes:

```text
operation
action_operation
route_operation
action
use_live_fetch
inline_feed
queue
worker
payload
```

Forbidden response material checked includes:

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

## Interpretation

The bounded enqueue model is now approved and tested at the HTTP contract layer for authorized source health recheck.

This is still a narrow approval.

It does not approve:

```text
poll route expansion
inline provider fetch
inline materializer execution
canonical mutation
public API/feed response changes
raw/private response material
request-controlled queue or worker selection
```

## What remains unimplemented

PR #204 does not complete the full operational lifecycle.

Still not locked by this close-out:

```text
job-level queue inspection beyond HTTP response characterization
worker-level payload inspection beyond HTTP response characterization
idempotency behavior for repeated authorized recheck calls
audit log contract for authorized recheck
operator retry behavior
job result lookup or polling behavior
provider side-effect absence beyond the bounded enqueue contract
scheduler side-effect scope beyond the health_checks response characterization
materializer side-effect absence beyond the bounded enqueue contract
canonical no-mutation instrumentation beyond response characterization
```

## Recommended next track

Recommended next PR:

```text
Design source health recheck idempotency and audit gate
```

Recommended scope:

```text
docs-only decision/design first
define repeated authorized recheck behavior
define idempotency key usage or explicitly defer it
define audit fields and redaction rules
keep poll behavior out of scope
keep provider/materializer/canonical mutation out of scope
```

Rationale:

```text
The authorization boundary is locked.
The positive-path bounded enqueue contract is locked.
The next operational risk is repeated calls and auditability.
```

## Stop conditions

Stop and re-scope if future work:

```text
adds duplicate controller modules
lets source_health:read trigger recheck for existing source records
allows request-body operation override to select poll/materialize/canonicalize/provider fetch behavior
allows request body to select queue, worker, or job payload shape
changes public response shapes without a contract PR
calls provider clients inline
triggers materializers inline
mutates canonical data
shows secrets, headers, cookies, tokens, raw payloads, full article text, SQL details, stack traces, or unbounded diagnostics
```

## Validation for this close-out PR

This close-out PR is docs-only and should change only:

```text
apps/backend/disclosure_api/docs/source_health_recheck_bounded_enqueue_contract_closeout.md
```

No Codex test command is required for this docs-only close-out PR.
