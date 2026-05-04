# Source Health Internal UI Route Lock

## Status

Route design lock for the source health internal UI track.

This document is docs-only. It does not add UI routes, controllers, templates, frontend code, backend runtime behavior, tests, provider behavior, materializer behavior, canonical behavior, audit query UI, or poll behavior.

## Baseline

```text
base branch: sec-thin-slice-reconcile-v1
base commit: 5d70ad0c7a377fc24f7afec64ac1bd1a256748b6
base source: PR #223 Design source health internal UI track
stream: source health internal UI route lock
status: docs-only route design
```

## Purpose

Before implementing source health UI pages, lock the internal route inventory and the route boundaries.

The first source health UI work should be internal-only and read-safe.

## Approved internal UI routes

The following internal browser routes are approved for future implementation:

```text
GET /admin/source-health
GET /admin/source-health/:source_key
```

Route meaning:

```text
/admin/source-health -> source health list page
/admin/source-health/:source_key -> source health detail page
```

## Route namespace

Use the existing internal browser namespace:

```text
/admin
```

Do not add source health UI pages under public API or public frontend paths.

## Explicitly forbidden public UI routes

Do not add:

```text
/public/source-health
/api/public/source-health
/source-health
/sources/:source_key/health
```

The source health UI is an internal operator surface only.

## Recheck action route boundary

The UI may call the existing bounded backend action:

```text
POST /api/admin/source-health/:source_key/recheck
```

The UI must not create a new recheck backend route.

The UI must not allow operators to choose operation, queue, worker, provider, materializer, canonical, or poll behavior.

## Poll route remains out of scope

The following route remains gated and out of scope for the UI track:

```text
POST /api/admin/sources/:source_key/poll
```

Do not add a poll button or poll page as part of this UI route track.

## Audit UI remains out of scope

The first source health UI route set does not include audit history pages.

Do not add:

```text
/admin/source-health/:source_key/audit
/admin/source-health/audit
```

Audit read/query UI should be a separate future track.

## Approved page responsibilities

### GET /admin/source-health

The list page may show bounded source summary fields:

```text
source_key
display_name
source_type
region_code
health_status
last_success_at
last_failure_at
active
```

The list page should link to detail pages.

### GET /admin/source-health/:source_key

The detail page may show bounded source health fields and a recheck action area.

The detail page should handle:

```text
loading
not found
read-only mode
recheck allowed mode
bounded success/error messages
```

## Permission behavior

The UI must distinguish:

```text
source_health:read -> list/detail only
source_health:recheck -> list/detail and recheck action
source_health:poll -> out of scope
```

The detail page may show a disabled recheck button or explanatory text for read-only users.

## Forbidden UI material

The UI must not display forbidden sensitive material, unbounded diagnostics, raw provider/debug data, or canonical internals.

The UI should use only bounded backend response fields.

## Required future tests

Before UI route implementation is considered locked, add tests proving:

```text
GET /admin/source-health exists when UI route is implemented
GET /admin/source-health/:source_key exists when UI route is implemented
no public source health UI route exists
no poll UI route exists
no audit UI route exists in the first UI implementation
```

## Recommended next PR

Recommended next PR:

```text
Add source health internal UI route inventory tests
```

Recommended scope:

```text
test-only or route-test-first
no UI templates yet
no backend response changes
no poll route exposure
no audit UI exposure
```

## Non-goals

This PR does not implement:

```text
router changes
UI controllers
HTML templates
frontend components
API changes
recheck button behavior
audit UI
poll UI
monitoring UI
```

## Stop conditions

Stop and re-scope if future UI work:

```text
adds public source health UI routes
adds poll UI controls
adds audit UI before a dedicated audit-read track
adds duplicate controller modules
exposes forbidden sensitive material
lets read-only users trigger recheck
changes backend response shapes without contract approval
```

## Validation

This PR is docs-only and should change only:

```text
apps/backend/disclosure_api/docs/source_health_internal_ui_route_lock.md
```

No Codex test command is required for this docs-only route lock PR.
