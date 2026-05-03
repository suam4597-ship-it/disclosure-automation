# Stage 6.8 duplicate group public boundary manual smoke

This manual smoke checklist validates the Stage 6.8 duplicate group public boundary design.

Stage 6.8 PR A is docs-only. It does not add frontend code, backend runtime code, tests, fixtures, migrations, schema modules, router changes, controllers, templates, UI routes, action endpoint changes, scheduler work, provider clients, live fetch behavior, public API/feed behavior, materializer behavior, or canonical mutations.

## Baseline

```text
base branch: sec-thin-slice-reconcile-v1
base commit: 79d8328ef417b13d0bd1386c7be3b1e4a7fa16b1
base source: PR #173 Lock Stage 6.7 duplicate group UI polish
stage: Stage 6.8 PR A duplicate group public boundary design
status: docs-only
```

## Expected changed files

Expected files for this PR:

```text
apps/backend/disclosure_api/docs/stage68_duplicate_group_public_boundary_design.md
apps/backend/disclosure_api/docs/stage68_duplicate_group_public_boundary_guardrails.md
apps/backend/disclosure_api/docs/stage68_duplicate_group_public_boundary_manual_smoke.md
```

## Static changed-file check

Suggested command:

```powershell
git diff --name-only 79d8328ef417b13d0bd1386c7be3b1e4a7fa16b1...HEAD
```

Expected output should be limited to the three docs above.

## Scope check

Verify this PR does not change:

```text
frontend code
backend runtime code
tests
fixtures
migrations
schema modules
router
controllers
templates
UI routes
action endpoints
scheduler code
provider clients
live fetch code
public API behavior
public feed behavior
materializer behavior
canonical mutation behavior
```

## Current policy check

Verify the design records the current locked policy:

```text
public duplicate group review/action state fields are absent
operator UI remains internal/admin only
operator review state remains advisory-only and non-canonical
public feed/API response shapes remain unchanged
canonical records remain unchanged
```

## Public surface check

Verify these public surfaces remain unchanged by this design:

```text
GET /api/events/:event_id
GET /api/events/:event_id/news-overlay
GET /api/feed/digest/latest
GET /api/feed/digest/:digest_date/:edition
item.overlays[]
news_overlays[]
feed item_count
feed ordering
official TDnet fields
official citations
public API envelope
public feed envelope
```

## Forbidden field check

Verify the design forbids public exposure of:

```text
public duplicate group IDs
public duplicate group confidence
public duplicate group members
public duplicate group match reasons
public review_state_summary
public action_event_summary
public operator action state
public operator reason
public idempotency metadata
public actor/request metadata
```

## Future gate check

Verify any future public exposure proposal must document:

```text
exact public route or response field names
exact response envelope impact
redaction model
abuse/misinterpretation risk
operator metadata exclusion proof
canonical no-mutation proof
public feed ordering impact
public feed item_count impact
official TDnet field impact
official citation impact
cache/backward compatibility impact
test plan
rollback plan
```

## Redaction check

Verify future public exposure must not render:

```text
source_duplicate_group_action_events
source_duplicate_group_review_states
operator reason material
actor/request/idempotency metadata
raw provider payloads
full article text
canonical payloads
private transport material
unbounded diagnostics
```

## Canonical check

Verify future public exposure must not:

```text
mutate canonical_feed_items
create provider canonical feed items
create news-only canonical events
merge official TDnet events
override official TDnet facts
override official citations
mutate news_overlay_attachments
```

## Provider, scheduler, and materializer check

Verify future public exposure must not:

```text
trigger live provider fetch
call provider clients
enqueue scheduler work
store private provider material
materialize duplicate groups from public read routes
materialize overlays
change materializer behavior
```

## Stop conditions

Stop and re-scope if this PR changes runtime behavior or if future public exposure work:

```text
adds public duplicate group fields without a design gate
changes public response shapes without explicit approval
exposes operator review state
exposes operator action state
exposes action_event_summary
exposes actor/request/idempotency metadata
exposes unredacted operator reasons
exposes provider payloads or full article text
exposes canonical payloads
changes public feed ordering unexpectedly
changes public feed item_count unexpectedly
mutates canonical data
triggers provider/scheduler/live-fetch/materializer work
```

## Test command

No local test run is required for this docs-only boundary PR unless a reviewer asks for targeted checks.
