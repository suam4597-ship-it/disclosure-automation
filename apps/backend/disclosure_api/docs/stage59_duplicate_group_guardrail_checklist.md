# Stage 5.9 duplicate group guardrail checklist

This checklist defines guardrails for any future cross-source duplicate group implementation.

This is a documentation-only checklist. It does not add runtime grouping code, tests, fixtures, migrations, schema changes, scheduler code, provider clients, live fetch code, routes, feed/controller changes, UI code, action endpoints, materializer changes, API behavior changes, feed behavior changes, or canonical feed mutations.

## Scope

```text
stage: Stage 5.9 PR A
scope: cross-source duplicate group guardrail checklist
mode: docs-only
runtime grouping code: none
new routes: none
UI code: none
action endpoints: none
schema/migrations: none
materializer changes: none
scheduler: none
live fetch: none
canonical mutation: none
```

## Locked prerequisites

Future duplicate group work must preserve these locked baselines:

```text
Stage 5.2 attach-only overlay materializer
Stage 5.3 multi-overlay response contract
Stage 5.7 operator-only source health view
Stage 5.8 operator-only action seam
```

Required preserved behavior:

```text
official TDnet remains source-of-truth: PASS
provider overlays remain attach-only: PASS
provider overlays remain metadata-only: PASS
provider overlays remain non-canonical: PASS
canonical feed item count remains official-only: PASS
public item.overlays[] shape remains unchanged: PASS
public news_overlays[] shape remains unchanged: PASS
```

## Duplicate group identity checklist

Future duplicate group implementation must prove:

```text
group_id is deterministic and bounded: PASS
group_id does not contain full article text: PASS
group_id does not contain raw provider payloads: PASS
group_id does not contain provider credentials: PASS
group_id does not contain provider transport metadata: PASS
group_id can be recomputed from bounded metadata: PASS
group identity is non-canonical advisory metadata: PASS
```

## Membership checklist

Future duplicate group membership must prove:

```text
member records are bounded: PASS
member_kind is allowlisted: PASS
source_key is bounded: PASS
provider is bounded: PASS
official_event_id is preserved when present: PASS
overlay_id is preserved when present: PASS
confidence is allowlisted: PASS
match_reasons are allowlisted: PASS
redaction_status is tracked: PASS
full article text absent: PASS
raw provider payload absent: PASS
provider credential values absent: PASS
provider transport metadata absent: PASS
canonical feed item payload absent: PASS
```

## Confidence checklist

Future confidence states must remain advisory:

```text
unknown does not alter public responses: PASS
candidate does not alter public responses: PASS
likely does not alter public responses: PASS
confirmed_by_operator remains non-canonical unless separately designed: PASS
rejected_by_operator remains internal metadata: PASS
confidence does not override official TDnet facts: PASS
```

## Source precedence checklist

Future duplicate group implementation must prove:

```text
official TDnet facts outrank provider facts: PASS
provider overlay facts do not override official facts: PASS
duplicate group does not override official event identity: PASS
duplicate group does not create canonical feed items: PASS
duplicate group does not merge official events automatically: PASS
duplicate group does not mutate official citations: PASS
```

## Operator review checklist

Future operator review work must prove:

```text
operator/admin authorization required: PASS
read-only review available before mutation: PASS
operator confirm/reject actions require separate design: PASS
audit trail required for future actions: PASS
redaction before display: PASS
redaction before audit: PASS
failure isolation required: PASS
public access forbidden unless separately designed: PASS
```

## Response-shape checklist

Future duplicate group work must not change public response shapes unless separately designed:

```text
read model item.overlays[] unchanged: PASS
API item.overlays[] unchanged: PASS
feed news_overlays[] unchanged: PASS
feed item_count unchanged: PASS
feed ordering unchanged: PASS
official TDnet fields unchanged: PASS
official citations unchanged: PASS
API envelope unchanged: PASS
public API duplicate group fields absent: PASS
public feed duplicate group fields absent: PASS
```

## Canonical no-mutation checklist

Future duplicate group work must not perform:

```text
canonical feed item mutation: PASS
provider canonical feed item creation: PASS
news-only canonical event creation: PASS
official TDnet event merge: PASS
official citation override: PASS
canonical fact override: PASS
public materializer output mutation: PASS
```

## Redaction checklist

Future duplicate group code, docs, tests, diagnostics, logs, comments, views, and audit records must not expose:

```text
provider credential values
provider transport metadata
request metadata
response metadata
signed private URLs
raw provider payloads
full article text
unbounded provider error payloads
secret-like values
```

## PASS criteria for this docs PR

```text
docs-only changed files: PASS
cross-source duplicate group design added: PASS
duplicate group guardrail checklist added: PASS
duplicate group manual smoke added: PASS
Stage 5.2 attach-only overlay baseline preserved: PASS
Stage 5.3 public response shape baseline preserved: PASS
Stage 5.7 operator-view baseline preserved: PASS
Stage 5.8 action seam baseline preserved: PASS
redaction guardrails documented: PASS
canonical no-mutation guardrails documented: PASS
no runtime/test/fixture/migration/schema changes: PASS
no scheduler/provider/live-fetch/route/feed/UI/materializer/API/canonical code changes: PASS
```
