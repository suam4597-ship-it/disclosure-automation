# Router Notes for Phase 1 Phoenix Bootstrap

After copying the controller templates into the generated Phoenix app, wire the routes into
`apps/backend/disclosure_api/lib/disclosure_automation_web/router.ex`.

## Minimum routes

```elixir
scope "/api", DisclosureAutomationWeb do
  pipe_through :api

  get "/health", HealthController, :show
  get "/feed/daily", FeedController, :daily
end
```

## Why these two routes first?

- `/api/health` proves the generated Phoenix app boots correctly
- `/api/feed/daily` proves the app can serve the checked-in Phase 0 fixture from `priv/fixtures`

## Suggested follow-up

Once the app boots cleanly, move on to:
- copying the OpenAPI specs into `priv/openapi`
- wiring Oban into `config/config.exs` and the supervision tree
- migrating from fixture reads to the Phase 0 digest/source-health runtime modules
