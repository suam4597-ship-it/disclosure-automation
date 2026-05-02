# Stage 5.7 operator view authorization design

This document defines a docs-only authorization design for a future provider source health operator view.

This is a design document only. It does not add runtime authorization code, tests, fixtures, migrations, schema changes, scheduler code, provider clients, live fetch code, routes, feed/controller changes, UI code, action endpoints, materializer changes, API behavior changes, or canonical feed mutations.

## Baseline

```text
base branch: sec-thin-slice-reconcile-v1
base commit: e91f3ed320cbb05e153bf794ebb43015ec148295
base source: PR #116 Add Stage 5.7 internal source health projection
stage: Stage 5.7 PR D operator authorization and audit design
status: docs-only
locked projection contract: Stage57OperatorViewProjectionContract
locked internal projection: Stage57InternalSourceHealthProjection
locked view mode: operator-only, read-only, advisory-only, redacted
```

## Goal

Define the authorization model that future operator view implementations must satisfy before any route, UI, or action endpoint is added.

The first operator view implementation must remain read-only and must separate viewing permissions from action permissions.

## Non-goals

This PR does not authorize:

```text
runtime authorization code
new routes
UI code
action endpoints
source health mutation
scheduler-triggered provider work
live provider fetch
provider credentials
migrations
schema changes
feed/controller changes
materializer changes
canonical feed mutation
provider canonical feed item creation
news-only canonical event creation
```

## Authorization principles

Future implementation must enforce:

```text
operator/admin authorization required
unauthenticated access forbidden
public API exposure forbidden without separate design
read-only permission separated from action permissions
least-privilege permission model
action audit trail required if actions are added later
```

## Permission model

Recommended permission names for future implementation:

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

Action permissions must remain out of scope until a separate action design is approved.

## Read-only access policy

Allowed with read-only permission:

```text
list source health
filter source health by health_status/source_type/active
show source health detail
show cursor keys
show redacted diagnostics summary
```

Forbidden with read-only permission:

```text
enqueue source health recheck
run manual provider trigger
pause/unpause provider
clear redaction violation
acknowledge manual review
mutate source health
mutate canonical feed items
trigger live provider fetch
trigger scheduler work
```

## Public exposure policy

Future operator view must not be public by default.

Forbidden without separate design:

```text
public unauthenticated route
public feed endpoint source health fields
public event detail source health fields
public overlay citation source health fields
public API envelope source health fields
```

## Failure policy

Authorization failures must be safe and non-revealing.

Required behavior:

```text
unauthenticated request returns no source health payload
unauthorized request returns no source health payload
error response does not reveal source keys beyond authorized scope
error response does not include credentials or diagnostics
operator view failure does not affect TDnet runtime
operator view failure does not affect feed/API serving
```

## Audit policy

Read-only access may record bounded audit metadata in a future implementation.

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

## Relationship to Stage 5.7 projection

Future authorized view should use:

```text
Stage57InternalSourceHealthProjection
Stage57OperatorViewProjectionContract
```

It must preserve:

```text
operator_only
read_only
advisory_only
public_response_shape_mutation=false
trigger_live_fetch=false
scheduler_enabled=false
source_health_mutation=false
canonical_feed_mutation=false
```

## Stop conditions

Do not merge a future authorization implementation if it:

```text
allows public or unauthenticated access
mixes read-only view permission with action permission
adds action endpoints in read-only PR
triggers live provider fetch
triggers scheduler work
mutates source health during read-only view
mutates canonical feed items
stores or exposes credentials
stores or exposes request/response headers
stores or exposes full article text
changes locked public feed/API response shapes
breaks redaction checks
```
