# Stage 5.9 duplicate group storage migration manual smoke

This checklist verifies the Stage 5.9 internal duplicate group storage migration.

This PR adds internal duplicate group tables only. It does not add schema modules, runtime grouping materialization, DB write code paths, fixtures, scheduler code, provider clients, live fetch code, routes, feed/controller changes, UI code, action endpoints, materializer changes, API behavior changes, feed behavior changes, or canonical feed mutations.

## Scope

```text
stage: Stage 5.9 PR F
scope: internal duplicate group storage migration
migration files: one
schema modules: none
runtime grouping materialization: none
runtime persistence service: none
fixtures: none
scheduler: none
live fetch: none
routes: none
UI: none
action endpoints: none
materializer changes: none
canonical mutation: none
```

## Files expected in this PR

```text
apps/backend/disclosure_api/priv/repo/migrations/20260503120000_create_stage59_duplicate_group_tables.exs
apps/backend/disclosure_api/docs/stage59_duplicate_group_storage_migration_manual_smoke.md
```

## Migration behavior smoke

Verify the migration creates internal tables only:

```text
source_duplicate_groups table created: PASS
source_duplicate_group_members table created: PASS
group_id unique index created: PASS
group_id + member_id unique index created: PASS
bounded metadata columns only: PASS
no canonical_feed_items changes: PASS
no news_overlay_attachments public semantic changes: PASS
no public API/feed columns added: PASS
no backfill performed: PASS
```

## source_duplicate_groups smoke

Verify allowed fields only:

```text
id: PASS
group_id: PASS
confidence: PASS
source_keys: PASS
match_reasons: PASS
member_count: PASS
has_official_tdnet_event: PASS
has_provider_overlay: PASS
redaction_status: PASS
inserted_at: PASS
updated_at: PASS
```

Verify forbidden fields are absent:

```text
full article text: PASS
raw provider payload: PASS
provider credentials: PASS
provider transport metadata: PASS
canonical feed item payload: PASS
provider canonical creation payload: PASS
unbounded diagnostics: PASS
```

## source_duplicate_group_members smoke

Verify allowed fields only:

```text
id: PASS
group_id: PASS
member_id: PASS
member_kind: PASS
source_key: PASS
provider: PASS
external_id_hash: PASS
official_event_id: PASS
overlay_id: PASS
confidence: PASS
match_reasons: PASS
redaction_status: PASS
inserted_at: PASS
updated_at: PASS
```

Verify forbidden fields are absent:

```text
full article text: PASS
raw provider payload: PASS
provider credentials: PASS
provider transport metadata: PASS
canonical feed item payload: PASS
provider canonical creation payload: PASS
unbounded diagnostics: PASS
```

## Guardrail smoke

Verify this PR does not add or modify:

```text
schema modules
runtime grouping services
runtime persistence services
fixtures
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

## Suggested commands

Run migration check in local test environment:

```powershell
$env:MIX_ENV='test'; mix.bat ecto.migrate
$env:MIX_ENV='test'; mix.bat ecto.rollback --step 1
$env:MIX_ENV='test'; mix.bat ecto.migrate
```

Recommended regressions:

```powershell
$env:MIX_ENV='test'; mix.bat test test/stage59_cross_source_duplicate_group_contract_test.exs
$env:MIX_ENV='test'; mix.bat test test/stage59_duplicate_group_projection_contract_test.exs
$env:MIX_ENV='test'; mix.bat test test/stage59_duplicate_group_noop_service_test.exs
$env:MIX_ENV='test'; mix.bat test test/stage53_multi_overlay_response_contract_test.exs
$env:MIX_ENV='test'; mix.bat test test/stage52_news_overlay_attachment_materializer_test.exs
$env:MIX_ENV='test'; mix.bat test test/stage5_news_overlay_feed_visible_test.exs
$env:MIX_ENV='test'; mix.bat test test/stage5_news_overlay_api_exposure_test.exs
$env:MIX_ENV='test'; mix.bat test test/jp_tdnet_timely_disclosure_runtime_idempotency_test.exs
$env:MIX_ENV='test'; mix.bat test test/jp_tdnet_timely_disclosure_http_smoke_test.exs
```

## Changed-file guardrail

This PR may add only:

```text
apps/backend/disclosure_api/priv/repo/migrations/20260503120000_create_stage59_duplicate_group_tables.exs
apps/backend/disclosure_api/docs/stage59_duplicate_group_storage_migration_manual_smoke.md
```

It must not add or modify:

```text
schema files
runtime code
tests
fixtures
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

## PASS criteria for this PR

```text
migration applies in test environment: PASS
migration rolls back in test environment: PASS
migration reapplies in test environment: PASS
changed files limited to migration and manual smoke doc: PASS
no schema/runtime/test/fixture changes: PASS
no scheduler/provider/live-fetch/route/feed/UI/materializer/API/canonical code changes: PASS
changed-file strict redaction check: PASS
```
