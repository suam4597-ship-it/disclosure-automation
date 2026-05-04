# Source health route contract tests manual smoke

This manual smoke checklist validates the source health route contract test PR.

## Scope

This PR adds targeted route inventory tests for the existing source health/operator route surface.

It does not add frontend code, backend runtime code, fixtures, migrations, schema modules, router changes, controllers, templates, UI routes, action endpoint changes, scheduler work, provider clients, live fetch behavior, public API/feed behavior, materializer behavior, or canonical mutations.

## Baseline

```text
base branch: sec-thin-slice-reconcile-v1
base commit: a4556fb3da81fff446ab2a4f0b2ad64051f0c215
base source: PR #185 Choose source health next track
track: source health route contract tests
```

## Expected changed files

Expected files for this PR:

```text
apps/backend/disclosure_api/test/source_health_route_contract_test.exs
apps/backend/disclosure_api/docs/source_health_route_contract_tests_manual_smoke.md
```

## Static changed-file check

Suggested command:

```powershell
git diff --name-only a4556fb3da81fff446ab2a4f0b2ad64051f0c215...HEAD
```

Expected output should be limited to the two files above.

## Test command

Run:

```powershell
$env:MIX_ENV='test'; mix.bat test test/source_health_route_contract_test.exs
```

## Expected test coverage

The test should verify:

```text
GET /api/admin/source-health routes to AdminSourceHealthController.index
GET /api/admin/source-health/:source_key routes to AdminSourceHealthController.show
POST /api/admin/source-health/:source_key/recheck routes to AdminSourceHealthController.recheck
POST /api/admin/sources/:source_key/poll routes to AdminSourcePollController.create
```

## Internal route surface check

The test should verify the source health route surface remains internal/admin-only:

```text
/api/admin/source-health
/api/admin/source-health/:source_key
/api/admin/source-health/:source_key/recheck
/api/admin/sources/:source_key/poll
```

The test should verify no public source health routes were added:

```text
/public source health routes
/api/public source health routes
/admin HTML source health routes
```

## Operation mapping check

The test should preserve route-derived operation expectations:

```text
/api/admin/source-health/:source_key/recheck -> recheck_source_health
/api/admin/sources/:source_key/poll -> poll_source
```

The test should not allow request-body operation override concepts:

```text
operation
action_operation
route_operation
```

## Public route inventory check

The test should confirm existing public routes remain present:

```text
/api/events/:event_id
/api/events/:event_id/news-overlay
/api/feed/digest/latest
/api/feed/digest/:digest_date/:edition
/api/feed/hero
/api/feed/region/:region_code
```

The test should verify no public source health route appears:

```text
/api/public/source-health
/api/public/sources/:source_key/poll
/api/events/:event_id/source-health
/api/feed/source-health
```

## Guardrails

This PR must not change:

```text
runtime code
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

## Stop conditions

Stop and re-scope if the PR:

```text
adds new source health routes
changes existing route behavior
adds controller behavior
adds runtime behavior
adds public source health fields
allows request-body operation override
calls provider clients
triggers scheduler work
triggers materializers
mutates canonical data
changes public feed/API response shapes
```
