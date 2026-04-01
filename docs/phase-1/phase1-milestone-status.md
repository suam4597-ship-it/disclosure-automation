# Phase 1 First Milestone Status

## Done
- Phoenix API-only app added under `apps/backend/disclosure_api`
- Repo/Ecto/Oban wiring added
- source registry, delivery windows, ingestion, canonical item migrations added
- health, digest, and source-health routes added
- `sec_press_releases` vertical slice added with live fetch attempt and fixture fallback
- GitHub Actions backend verification workflow added
- OpenAPI files copied into the new app

## Not done yet
- remote GitHub Actions result was not observable from the current tool surface
- compile/runtime issues, if any, still need one real execution pass in Actions or Codespaces
- broader source families are not migrated yet
- Phase 0 reference-runtime cleanup decision is still pending

## Reviewer checklist
1. Open Codespaces or local dev shell
2. `cd apps/backend/disclosure_api`
3. `mix deps.get`
4. `mix ecto.create && mix ecto.migrate`
5. `mix phx.server`
6. `POST /api/admin/sources/sec_press_releases/poll`
7. `GET /api/feed/digest/latest?edition=breaking`
