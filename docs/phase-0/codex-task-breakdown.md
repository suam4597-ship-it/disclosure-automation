# Phase 0 Codex Task Breakdown

This checklist is written for continuing work on branch `phase0-foundation` and PR `#1`.

## Already landed in PR #1

Infrastructure and branch setup:
- `.devcontainer/devcontainer.json`
- `.devcontainer/post-create.sh`
- `apps/web/vercel.json`
- `docs/phase-1/codespaces-backend-runbook.md`

Backend foundation already added:
- `apps/backend/config/source_registry.sample.yaml`
- `apps/backend/config/delivery_windows.sample.yaml`
- `apps/backend/sql/0001_phase0_core_schema.sql`
- `apps/backend/sql/0001_phase0_core_schema.rollback.sql`
- `apps/backend/ecto_migrations/20260330000100_create_source_registry_and_delivery_windows.exs`
- `apps/backend/ecto_migrations/20260330000200_create_ingestion_pipeline_tables.exs`
- `apps/backend/ecto_migrations/20260330000300_create_domain_event_tables.exs`
- `apps/backend/ecto_migrations/20260330000400_add_oban_jobs_table.exs`
- `apps/backend/mix.exs`
- `apps/backend/lib/disclosure_automation/application.ex`
- `apps/backend/lib/disclosure_automation/bootstrap.ex`
- `apps/backend/lib/disclosure_automation/config/sync.ex`
- `apps/backend/lib/disclosure_automation/env_interpolation.ex`
- `apps/backend/lib/disclosure_automation/jobs.ex`
- `apps/backend/lib/disclosure_automation/market_calendar.ex`
- `apps/backend/lib/disclosure_automation/retention.ex`
- `apps/backend/lib/disclosure_automation/workers/*`
- `apps/backend/lib/disclosure_automation_web/controllers/*`
- `apps/backend/lib/disclosure_automation_web/{endpoint,router,feed_digest_json,source_health_json}.ex`

## Remaining Phase 0 additions

### A. Contracts and docs
- [x] `docs/blueprint/investment_news_blueprint_v2.md`
- [x] `docs/blueprint/phase0-architecture-contract.md`
- [x] `docs/phase-0/codex-task-breakdown.md`

### B. API assets
- [x] `apps/backend/openapi/feed-digest.openapi.yaml`
- [x] `apps/backend/openapi/admin-source-health.openapi.yaml`

### C. Reference runtime assets
- [x] `apps/backend/fixtures/daily_feed.sample.json`
- [x] `apps/backend/config/parser_capabilities.sample.yaml`
- [x] `apps/backend/lib/disclosure_automation/config/yaml_loader.ex`
- [x] `apps/backend/lib/disclosure_automation/parser_capabilities.ex`
- [x] `apps/backend/lib/disclosure_automation/fixtures.ex`
- [x] `apps/backend/lib/disclosure_automation/parser.ex`
- [x] `apps/backend/lib/disclosure_automation/canonicalizer.ex`
- [x] `apps/backend/lib/disclosure_automation/source_poller.ex`

### D. Validation glue
- [x] `scripts/validate_phase0_artifacts.py`

### E. Web entry workaround
- [x] `apps/web/global-pulse-dashboard-v2.html`
- [ ] optional low-level update of existing `apps/web/index.html`

## Recommended continuation order

1. keep PR head SHA noted before each direct connector write
2. add missing new files first via `create_file`
3. use the new dashboard file to satisfy Vercel root without touching existing files
4. only attempt low-level tree/commit mutation for `index.html` if necessary
5. re-check PR changed file list and spot missing links or broken references
6. validate fixture/OpenAPI/doc path consistency

## Known caveats

- shell `git push` can fail in this environment because of DNS/network constraints
- `create_file` works reliably for **new** files on the PR branch
- updating an existing file likely needs a lower-level blob/tree/commit/ref flow
- some Elixir modules still reference broader runtime pieces (`Sources`, `Digest`, `Events`, `Ingestion`, `Store`) that are expected to exist or be filled in during the Phoenix integration phase
- `apps/backend/mix.exs` references `scripts/validate_phase0_artifacts.py`, so that script should remain present once introduced

## Validation checklist

Use this before marking the branch ready for another handoff:
- [ ] PR is still open against `main`
- [ ] PR head branch is still `phase0-foundation`
- [ ] Vercel rewrite destination exists
- [ ] blueprint docs reflect actual endpoints and file paths
- [ ] OpenAPI paths match `DisclosureAutomationWeb.Router`
- [ ] daily fixture shape matches the documented digest contract
- [ ] parser-capability config path matches bootstrap and loader modules
- [ ] `mix validate` path points to an existing script

## Hand-off note

If an existing-file update is still blocked, the branch is still usable as long as:
- `/` resolves through `apps/web/vercel.json`
- `apps/web/global-pulse-dashboard-v2.html` exists
- docs and OpenAPI files are present
- Phase 0 validation script passes its own file/fixture checks
