# Stage 5.8 operator actions audit manual smoke

This checklist defines audit and manual-smoke requirements for any future provider source health operator action implementation.

This is a documentation-only checklist. It does not add runtime authorization code, runtime action code, tests, fixtures, migrations, schema changes, scheduler code, provider clients, live fetch code, routes, feed/controller changes, UI code, materializer changes, API behavior changes, feed behavior changes, or canonical feed mutations.

## Scope

```text
stage: Stage 5.8 PR A
scope: operator action audit/manual smoke checklist
mode: docs-only
runtime auth code: none
runtime action code: none
new routes: none
UI code: none
action endpoints: none
scheduler: none
live fetch: none
canonical mutation: none
```

## Audit principle

Future source health action audit records must be bounded, redacted, permission-aware, idempotency-aware, and failure-isolated.

Allowed audit metadata:

```text
actor_id_hash
permission
operation
source_key
request_id_hash
idempotency_key_hash
operator_reason_redacted
started_at
completed_at
result_status
pre_action_health_status
post_action_health_status if available
pre_action_operational_state if available
post_action_operational_state if available
redaction_status
failure_code_redacted
```

Forbidden audit metadata:

```text
provider subscription key values
bearer or basic credential values
session cookie values
provider credentials
provider transport metadata
raw provider payloads
full article text
signed private URLs
unbounded diagnostic payloads
canonical feed item payloads
```

## Action request smoke

For future action implementation, verify every mutating or enqueueing action:

```text
requires authenticated actor: PASS
requires operator/admin authorization: PASS
requires explicit action permission: PASS
requires target source authorization: PASS
requires operator_reason: PASS
requires idempotency_key: PASS
rejects forbidden request fields: PASS
redacts operator note before persistence: PASS
records audit attempt: PASS
returns bounded redacted response: PASS
```

## Action audit smoke

For each future action, verify:

```text
source_health.recheck audit event recorded: PASS
source_health.pause audit event recorded: PASS
source_health.resume audit event recorded: PASS
source_health.acknowledge_manual_review audit event recorded: PASS
source_health.clear_redaction_violation audit event recorded: PASS
source_health.manual_provider_trigger audit event recorded: PASS
source_health.export_redacted_diagnostics audit event recorded: PASS
audit event includes operation: PASS
audit event includes bounded source_key: PASS
audit event includes hashed actor/request/idempotency identifiers where applicable: PASS
audit event includes result_status: PASS
audit event omits credentials: PASS
audit event omits provider transport metadata: PASS
audit event omits raw provider payloads: PASS
audit event omits full article text: PASS
audit event omits canonical feed item payloads: PASS
```

## Permission denial smoke

Future action implementation must safely deny unauthorized attempts:

```text
unauthenticated action attempt denied: PASS
unauthorized action attempt denied: PASS
missing permission denied: PASS
read-only permission cannot run recheck: PASS
read-only permission cannot pause: PASS
read-only permission cannot resume: PASS
read-only permission cannot acknowledge manual review: PASS
read-only permission cannot clear redaction violation: PASS
read-only permission cannot trigger provider work: PASS
denial response omits source health payload beyond authorized scope: PASS
denial response omits credentials: PASS
denial response omits provider transport metadata: PASS
denial response omits raw provider payloads: PASS
denial response omits full article text: PASS
```

## Idempotency smoke

Future mutating or enqueueing action implementation must prove:

```text
missing idempotency_key rejected: PASS
same actor/source/operation/idempotency_key returns stable result when safe: PASS
conflicting idempotency key reuse rejected: PASS
idempotency metadata is bounded: PASS
idempotency metadata is redacted: PASS
idempotency check does not trigger live fetch: PASS
idempotency check does not trigger scheduler work: PASS
idempotency check does not mutate canonical feed items: PASS
```

## Action side-effect smoke

Future action implementation must prove:

```text
recheck action does not live-fetch by default: PASS
recheck action does not scheduler-fetch by default: PASS
pause action does not delete overlays: PASS
pause action does not mutate canonical feed items: PASS
resume action does not live-fetch by default: PASS
resume action does not scheduler-fetch by default: PASS
acknowledgement action is advisory-only: PASS
clear redaction violation action requires redaction revalidation: PASS
manual provider trigger action preserves fake/default-off transport unless separately approved: PASS
export redacted diagnostics action uses bounded allowlist: PASS
```

## Failure isolation smoke

Future action and audit implementation must prove:

```text
action failure does not affect TDnet runtime: PASS
action failure does not affect public feed serving: PASS
action failure does not affect public API serving: PASS
action failure does not delete overlays: PASS
action failure does not mutate canonical feed items: PASS
action failure does not trigger live fetch by default: PASS
action failure does not trigger scheduler work by default: PASS
audit write failure does not affect TDnet runtime: PASS
audit write failure does not affect feed/API serving: PASS
audit write failure returns bounded redacted error only: PASS
```

## Response-shape smoke

Before and after future action implementation, verify:

```text
read model item.overlays[] unchanged: PASS
API item.overlays[] unchanged: PASS
feed news_overlays[] unchanged: PASS
feed item_count unchanged: PASS
feed ordering unchanged: PASS
official TDnet fields unchanged: PASS
official citations unchanged: PASS
API envelope unchanged: PASS
public API source health fields absent: PASS
public feed source health fields absent: PASS
```

## Changed-file guardrail for this docs PR

This PR may add only:

```text
apps/backend/disclosure_api/docs/stage58_source_health_operator_actions_audit_design.md
apps/backend/disclosure_api/docs/stage58_operator_action_permission_checklist.md
apps/backend/disclosure_api/docs/stage58_operator_actions_audit_manual_smoke.md
```

It must not add or modify:

```text
runtime code
tests
fixtures
migrations
schema files
scheduler code
provider clients
live fetch code
routes
feed/controller code
UI code
action endpoints
materializer code
API behavior
feed behavior
canonical feed mutation behavior
```

## PASS criteria for this docs PR

```text
docs-only changed files: PASS
operator action audit design added: PASS
operator action permission checklist added: PASS
operator actions audit manual smoke added: PASS
action permission separation documented: PASS
operator_reason requirement documented: PASS
idempotency requirement documented: PASS
audit redaction documented: PASS
unauthorized action handling documented: PASS
failure isolation documented: PASS
response-shape guardrails documented: PASS
canonical no-mutation guardrail documented: PASS
no runtime/test/fixture/migration/schema changes: PASS
no scheduler/provider/live-fetch/route/feed/UI/materializer/API/canonical code changes: PASS
changed-file strict redaction check: PASS
```
