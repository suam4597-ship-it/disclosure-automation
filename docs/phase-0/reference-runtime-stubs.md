# Phase 0 Reference Runtime Stubs

This document explains the lightweight runtime modules added on branch `phase0-foundation`
so the repository can present a coherent Phase 0 story before the full Phoenix/Ecto app is generated.

## Why these stubs exist

Several files in PR #1 already assume module boundaries such as:
- `DisclosureAutomation.Store`
- `DisclosureAutomation.Sources`
- `DisclosureAutomation.Digest`
- `DisclosureAutomation.Ingestion`
- `DisclosureAutomation.Events`
- `DisclosureAutomation.Events.Publisher`
- `DisclosureAutomation.Events.Contracts`

Those boundaries are useful for architecture and job/controller contracts, but they were not yet present in the repo.
The stubs added now keep those boundaries explicit.

## Added modules

### `DisclosureAutomation.Store`
- in-memory `Agent` store
- buckets for sources, delivery windows, and event dispatches
- supports `ensure_started/0`, `put/3`, `get/2`, `list/1`

### `DisclosureAutomation.Sources`
- upserts source and delivery-window maps into the in-memory store
- supports source-health listing, single-source lookup, and recheck enqueue
- marks a source healthy/paused in a conservative way for the reference path

### `DisclosureAutomation.Digest`
- reads `apps/backend/fixtures/daily_feed.sample.json`
- serves `get_latest_digest/2` and `get_digest_by_date_and_edition/3`
- intentionally stays fixture-backed for Phase 0

### `DisclosureAutomation.Ingestion`
- placeholder boundary used by `Retention`
- currently returns a no-op archival result

### `DisclosureAutomation.Events.*`
- `DomainEventDispatch` struct for dispatch state
- `Contracts.default_consumers_for/1` for default consumer wiring
- `Publisher.publish/6` materializes in-memory pending dispatches
- `Events.get_dispatch_by_event_and_consumer/2` and `mark_dispatch_status/3` support worker flows

## What these stubs are **not**

They are not meant to replace the real Phoenix/Ecto application.
They do not provide:
- durable persistence
- Ecto schemas
- Repo-backed queries
- production retry behaviour
- robust event IDs, auditing, or pagination

## How this helps the branch

With these stubs in place, the repo now better matches the architecture implied by:
- bootstrap logic
- controllers
- workers
- docs and OpenAPI contracts

That makes Phase 0 easier to hand off even before Phase 1 Phoenix generation happens.

## Known remaining gaps

1. `apps/web/index.html` still lags the newer dashboard content unless it is updated separately.
2. Existing code still references external dependencies such as `Oban`, `Phoenix`, `Jason`, and `YamlElixir` that are not fully wired in the bare reference runtime.
3. The generated Phoenix app under `apps/backend/disclosure_api` is still a next-step task, not committed in this PR.

## Recommended next move

After this branch is merged or checked out in a Codespace:
1. run `bash apps/backend/scripts/bootstrap_phoenix_api.sh`
2. run `bash apps/backend/scripts/copy_phase0_assets.sh`
3. copy the template controllers/context into the generated app
4. wire router + Oban + dependencies
5. replace in-memory stubs with real Ecto-backed modules incrementally
