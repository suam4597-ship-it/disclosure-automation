# Stage 5.8 operator action permission checklist

This checklist defines permission requirements for any future provider source health operator action implementation.

This is a documentation-only checklist. It does not add runtime authorization code, runtime action code, tests, fixtures, migrations, schema changes, scheduler code, provider clients, live fetch code, routes, feed/controller changes, UI code, materializer changes, API behavior changes, feed behavior changes, or canonical feed mutations.

## Scope

```text
stage: Stage 5.8 PR A
scope: operator action permission checklist
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

## Locked prerequisites

Future action work must preserve the Stage 5.7 lock:

```text
operator/admin-only access
read-only view remains separate from actions
advisory-only provider source health
redacted bounded source health projection
public access forbidden
unauthenticated access forbidden
no public feed/API source health fields
no canonical feed mutation
```

## Permission inventory

Read-only permissions:

```text
source_health.view
source_health.detail
source_health.export_redacted
```

Action permissions:

```text
source_health.recheck
source_health.pause
source_health.resume
source_health.acknowledge_manual_review
source_health.clear_redaction_violation
source_health.manual_provider_trigger
source_health.export_redacted_diagnostics
```

Administrative meta-permissions, if added later, must be designed separately.

## Permission separation checklist

Future implementation must prove:

```text
source_health.view cannot execute source_health.recheck: PASS
source_health.view cannot execute source_health.pause: PASS
source_health.view cannot execute source_health.resume: PASS
source_health.view cannot execute source_health.acknowledge_manual_review: PASS
source_health.view cannot execute source_health.clear_redaction_violation: PASS
source_health.view cannot execute source_health.manual_provider_trigger: PASS
source_health.detail cannot execute action operations: PASS
action permission does not imply unrelated action permission: PASS
action permission does not imply public API access: PASS
action permission does not imply canonical mutation rights: PASS
```

## Target authorization checklist

Before an action runs, future implementation must verify:

```text
actor is authenticated: PASS
actor has operator/admin role or equivalent internal authorization: PASS
actor has explicit permission for operation: PASS
actor is authorized for target source_key: PASS
target source health record exists or missing behavior is bounded: PASS
operator_reason is present for mutating/enqueueing action: PASS
idempotency_key is present for mutating/enqueueing action: PASS
request fields pass redaction validation: PASS
```

## Action-specific permission checklist

Future implementation must require explicit permission, operator reason, idempotency where applicable, and audit for each action:

```text
source_health.recheck requires source_health.recheck permission: PASS
source_health.pause requires source_health.pause permission: PASS
source_health.resume requires source_health.resume permission: PASS
source_health.acknowledge_manual_review requires source_health.acknowledge_manual_review permission: PASS
source_health.clear_redaction_violation requires source_health.clear_redaction_violation permission: PASS
source_health.manual_provider_trigger requires source_health.manual_provider_trigger permission: PASS
source_health.export_redacted_diagnostics requires source_health.export_redacted_diagnostics permission: PASS
read-only permission cannot run any action: PASS
each action records audit attempt: PASS
each mutating or enqueueing action requires operator_reason: PASS
each mutating or enqueueing action requires idempotency_key: PASS
no action mutates canonical feed items: PASS
no action changes public feed/API response shapes: PASS
```

## Action side-effect checklist

Future action design must prove:

```text
recheck does not trigger live fetch by default: PASS
recheck does not trigger scheduler work by default: PASS
pause is advisory operational state only: PASS
pause does not delete overlays: PASS
resume does not trigger immediate live fetch by default: PASS
resume does not trigger scheduler work by default: PASS
acknowledgement is advisory-only: PASS
acknowledgement preserves provider evidence: PASS
clear redaction violation requires redaction revalidation before clearing: PASS
clear redaction violation preserves violation history: PASS
manual provider trigger preserves fake/default-off transport unless separately approved: PASS
redacted diagnostics export is bounded and allowlisted: PASS
```

## Unauthorized behavior checklist

Future implementation must prove:

```text
unauthenticated action request denied: PASS
unauthorized action request denied: PASS
missing action permission denied: PASS
missing source authorization denied: PASS
missing operator_reason rejected for mutating/enqueueing action: PASS
missing idempotency_key rejected for mutating/enqueueing action: PASS
response body does not reveal source health payload beyond authorized scope: PASS
response body does not reveal provider credentials: PASS
response body does not reveal provider transport metadata: PASS
response body does not reveal raw provider payloads: PASS
response body does not reveal full article text: PASS
```

## Audit permission checklist

Future action implementation must prove:

```text
audit event recorded for allowed action: PASS
audit event recorded for denied action attempt when safe: PASS
audit actor identifier is hashed or bounded: PASS
audit idempotency key is hashed or bounded: PASS
audit operator reason is redacted: PASS
audit payload omits credentials: PASS
audit payload omits provider transport metadata: PASS
audit payload omits raw provider payloads: PASS
audit payload omits full article text: PASS
audit payload omits unbounded diagnostics: PASS
```

## Response-shape checklist

Future permission and action work must not change public response shapes:

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

## Redaction checklist

Permission checks, action requests, action responses, audit records, logs, and error responses must not expose:

```text
provider subscription key values
bearer or basic credential values
session cookie values
provider credentials
provider transport metadata
signed private URLs
raw provider payloads
full article text
unbounded diagnostic payloads
secret-like values
```

## PASS criteria for this docs PR

```text
docs-only changed files: PASS
operator action permission checklist added: PASS
read-only/action permission separation documented: PASS
action-specific permissions documented: PASS
operator_reason requirement documented: PASS
idempotency requirement documented: PASS
audit permission checklist documented: PASS
unauthorized behavior documented: PASS
response-shape guardrails documented: PASS
redaction guardrails documented: PASS
canonical no-mutation guardrail documented: PASS
no runtime/test/fixture/migration/schema changes: PASS
no scheduler/provider/live-fetch/route/feed/UI/materializer/API/canonical code changes: PASS
```
