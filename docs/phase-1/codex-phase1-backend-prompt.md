# Codex Task Prompt — Phase 1 Backend Bootstrap

Repository root already contains:
- Phase 0 SQL schema
- Ecto migration templates
- OpenAPI specs
- dashboard prototype in `apps/web/index.html`

## Goal
Turn the repo into a working Phoenix API-only backend project under `apps/backend/disclosure_api`, using:
- module `DisclosureAutomation`
- app `disclosure_automation`
- PostgreSQL
- Oban
- existing migration templates from `apps/backend/ecto_migrations`

## Required outputs
1. Generate Phoenix API-only app
2. Copy migration/openapi/config sample assets
3. Add health endpoint `/api/health`
4. Add digest endpoint `/api/feed/daily`
5. Wire Oban into supervision tree
6. Make `mix ecto.migrate` succeed
7. Ensure `mix phx.server` boots cleanly

## Constraints
- Do not remove existing docs or web files
- Keep Phase 0 SQL and Ecto migration templates
- Do not introduce unnecessary frontend frameworks
- Keep backend foundation clean and conservative

## First commands
```bash
bash apps/backend/scripts/bootstrap_phoenix_api.sh
bash apps/backend/scripts/copy_phase0_assets.sh
```
