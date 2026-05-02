# Stage 5.7 operator permission checklist

This checklist defines permission requirements for any future provider source health operator view implementation.

This is a documentation-only checklist. It does not add runtime authorization code, tests, fixtures, migrations, schema changes, scheduler code, provider clients, live fetch code, routes, feed/controller changes, UI code, action endpoints, materializer changes, API behavior changes, or canonical feed mutations.

## Scope

```text
stage: Stage 5.7 PR D
scope: operator permission checklist
mode: docs-only
runtime auth code: none
new routes: none
UI code: none
action endpoints: none
scheduler: none
live fetch: none
canonical mutation: none
```

## Required future permissions

Recommended permission names:

```text
source_health.view
source_health.detail
source_health.export_redacted
source_health.recheck
source_health.pause
source_health.resume
source_health.acknowledge_manual_review
source_health.clear_redaction_violation
```

First runtime implementation should allow only:

```text
source_health.view
source_health.detail
```

## Read-only permission checklist

A user with read-only permission may:

```text
list source health
filter source health by health_status
filter source health by source_type
filter source health by active flag
view source health detail
view cursor keys
view redacted diagnostics summary
```

A user with read-only permission must not:

```text
enqueue source health recheck
run manual provider trigger
pause provider
resume provider
clear redaction violation
acknowledge manual review
mutate source health
mutate canonical feed items
trigger live provider fetch
trigger scheduler work
```

## Unauthorized access checklist

Future implementation must prove:

```text
unauthenticated access denied
unauthorized access denied
response body does not reveal source health payload
response body does not reveal provider credentials
response body does not reveal request headers
response body does not reveal response headers
response body does not reveal full article text
response body does not reveal raw provider response bodies
```

## Action separation checklist

Future action endpoints must be separate from read-only view work.

Actions requiring separate design:

```text
enqueue source health recheck
run manual provider trigger
pause provider
resume provider
clear redaction violation
acknowledge manual review
export diagnostic bundle
```

Each future action must define:

```text
explicit permission
audit trail
idempotency behavior
redaction policy
failure isolation
stop conditions
```

## Response-shape checklist

Future permission work must not change public response shapes:

```text
read model item.overlays[] unchanged
API item.overlays[] unchanged
feed news_overlays[] unchanged
feed item_count unchanged
feed ordering unchanged
official TDnet fields unchanged
official citations unchanged
API envelope unchanged
```

## Redaction checklist

Permission checks and error responses must not expose:

```text
Subscription-Key values
Authorization header values
Cookie header values
provider credentials
request headers
response headers
signed private URLs
raw provider response bodies
full article text
unbounded diagnostic payloads
```

## PASS criteria for future runtime work

```text
read-only permission allows list/detail only: PASS
read-only permission blocks actions: PASS
unauthenticated access blocked: PASS
unauthorized access blocked: PASS
no public feed/API exposure: PASS
no live fetch side effects: PASS
no scheduler side effects: PASS
no source health mutation from read-only view: PASS
no canonical mutation: PASS
redaction check: PASS
```
