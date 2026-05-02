# Stage 5.7 operator audit manual smoke

This checklist defines audit and manual-smoke requirements for any future provider source health operator view implementation.

This is a documentation-only checklist. It does not add runtime authorization code, tests, fixtures, migrations, schema changes, scheduler code, provider clients, live fetch code, routes, feed/controller changes, UI code, action endpoints, materializer changes, API behavior changes, or canonical feed mutations.

## Scope

```text
stage: Stage 5.7 PR D
scope: operator audit/manual smoke checklist
mode: docs-only
runtime auth code: none
new routes: none
UI code: none
action endpoints: none
scheduler: none
live fetch: none
canonical mutation: none
```

## Audit principle

Future audit records for operator source health views must be bounded, redacted, and action-aware.

Allowed audit metadata:

```text
actor_id_hash
permission
source_key if authorized
operation
request_id_hash
started_at
completed_at
result_status
```

Forbidden audit metadata:

```text
provider credentials
request headers
response headers
raw provider response bodies
full article text
signed private URLs
unbounded diagnostic payloads
```

## Read-only audit smoke

For future read-only operator view implementation, verify:

```text
source_health.view access records read-only operation only: PASS
source_health.detail access records read-only operation only: PASS
audit entry does not include credentials: PASS
audit entry does not include request headers: PASS
audit entry does not include response headers: PASS
audit entry does not include full article text: PASS
audit entry does not include raw provider response body: PASS
audit entry does not mutate source health: PASS
audit entry does not mutate canonical feed items: PASS
```

## Unauthorized access audit smoke

Future unauthorized attempts should be safely auditable without revealing payloads.

Expected:

```text
unauthenticated attempt recorded with bounded metadata: PASS
unauthorized attempt recorded with bounded metadata: PASS
source health payload not returned: PASS
source health payload not copied into audit entry: PASS
credentials absent: PASS
headers absent: PASS
raw provider body absent: PASS
full article text absent: PASS
```

## Action audit policy

Actions remain out of scope for first operator view implementation.

Future action audit must be designed separately for:

```text
enqueue source health recheck
run manual provider trigger
pause provider
resume provider
clear redaction violation
acknowledge manual review
export redacted diagnostic bundle
```

Future action audit must include:

```text
actor_id_hash
permission
operation
source_key
request_id_hash
idempotency_key if applicable
started_at
completed_at
result_status
redaction_status
```

Future action audit must not include:

```text
credentials
request headers
response headers
raw provider response bodies
full article text
signed private URLs
unbounded diagnostics
```

## Failure isolation smoke

Future audit/view implementation must prove:

```text
audit write failure does not affect TDnet runtime: PASS
audit write failure does not affect feed/API serving: PASS
audit write failure does not trigger live fetch: PASS
audit write failure does not trigger scheduler: PASS
audit write failure does not mutate canonical feed items: PASS
audit write failure does not delete overlays: PASS
audit write failure returns bounded redacted error only: PASS
```

## Response-shape smoke

Before and after future operator view/audit implementation, verify:

```text
read model item.overlays[] unchanged: PASS
API item.overlays[] unchanged: PASS
feed news_overlays[] unchanged: PASS
feed item_count unchanged: PASS
feed ordering unchanged: PASS
official TDnet fields unchanged: PASS
official citations unchanged: PASS
API envelope unchanged: PASS
```

## Changed-file guardrail for this docs PR

This PR may add only:

```text
apps/backend/disclosure_api/docs/stage57_operator_view_authorization_design.md
apps/backend/disclosure_api/docs/stage57_operator_permission_checklist.md
apps/backend/disclosure_api/docs/stage57_operator_audit_manual_smoke.md
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
operator authorization design added: PASS
operator permission checklist added: PASS
operator audit manual smoke added: PASS
read-only permission separation documented: PASS
action permission separation documented: PASS
audit redaction documented: PASS
unauthorized access handling documented: PASS
response-shape guardrails documented: PASS
no runtime/test/fixture/migration/schema changes: PASS
no scheduler/provider/live-fetch/route/feed/UI/materializer/API/canonical code changes: PASS
```
