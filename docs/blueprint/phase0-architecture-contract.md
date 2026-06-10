# Phase 0 Architecture Contract

## Intent

Phase 0 is a conservative foundation layer for the disclosure-automation repository.
The goal is **not** to ship the full ingestion product yet. The goal is to lock down:

- source registry and delivery-window contracts
- schema and migration ownership
- digest and source-health API shapes
- a fixture-backed startup path that can boot before full parser/storage work exists
- background-job boundaries for polling, digest generation, and event dispatch

This contract should be read alongside:

- `apps/backend/sql/0001_phase0_core_schema.sql`
- `apps/backend/ecto_migrations/*`
- `apps/backend/config/*.sample.yaml`
- `apps/backend/openapi/*.openapi.yaml`
- `apps/backend/fixtures/daily_feed.sample.json`

## System boundary

Phase 0 currently establishes six durable boundaries.

### 1) Source contract
Configured in `apps/backend/config/source_registry.sample.yaml`.

Required fields:
- `source_key`
- `display_name`
- `source_type`
- `base_url`
- `parser_key`
- `poll_cron`
- `ranking_weight`
- `coverage_tags`
- `active`
- `config`

Operational fields persisted in `source_registry`:
- `health_status`
- `last_seen_published_at`
- `last_success_at`
- `last_failure_at`
- `last_error`

### 2) Delivery-window contract
Configured in `apps/backend/config/delivery_windows.sample.yaml`.

A delivery window defines:
- edition
- channel
- local timezone
- active weekdays
- open/close local times
- cutoff minutes
- channel-specific config

This gives the planner a stable place to decide **when** a digest should be assembled and **where** it should be delivered.

### 3) Ingestion pipeline contract
The SQL and Ecto migrations define three core tables:
- `ingestion_runs`
- `raw_documents`
- `canonical_feed_items`

These exist even if Phase 0 still falls back to fixtures at read time. The design choice is intentional:
schema first, runtime second.

### 4) Domain-event contract
The reference runtime emits or reserves the following event boundary:
- `domain_events`
- `domain_event_dispatches`

Workers and future consumers are expected to communicate through named events instead of direct cross-module coupling.

### 5) Read API contract
The current router exposes:
- `GET /api/feed/digest/latest`
- `GET /api/feed/digest/{digest_date}/{edition}`
- `GET /api/admin/source-health`
- `GET /api/admin/source-health/{source_key}`
- `POST /api/admin/source-health/{source_key}/recheck`

These are the stable external contracts for Phase 0.

### 6) Bootstrap contract
`DisclosureAutomation.Bootstrap.bootstrap/0` currently attempts three startup steps:
1. ensure the reference store is started
2. sync sample YAML contracts into the source/delivery tables
3. load parser capabilities into application env cache

That means a repo checkout can demonstrate config-driven bootstrapping before the full persistence and parser stack is complete.

## Runtime flow

## A. Boot
1. Application starts.
2. Bootstrap runs.
3. Sample YAML contracts are loaded.
4. Parser capabilities are cached.
5. Controllers and workers can serve a reference path.

## B. Poll
1. `PollSourceWorker` receives a `source_key`.
2. `SourcePoller` resolves source metadata and parser capability.
3. A polling envelope is returned for future ingestion persistence.

## C. Digest read
1. `FeedDigestController` receives a digest request.
2. `Digest` resolves latest or requested edition/date.
3. When storage is not ready, fixture fallback is allowed.
4. JSON response returns the digest envelope defined in OpenAPI and sample fixture.

## D. Source-health recheck
1. `AdminSourceHealthController.recheck/2` receives a source key.
2. `Sources.enqueue_source_health_recheck/1` returns an accepted job contract.
3. `RecomputeSourceHealthWorker` performs the background refresh.

## Non-goals for Phase 0

The following are intentionally incomplete or out of scope:
- full parser fidelity for every source type
- production-ready HTTP fetching and retry policy
- sophisticated deduplication / entity resolution
- ranking and summarization models
- notification fanout implementation
- end-user dashboard backed by live API data

## Invariants

These should remain true while extending the branch.

1. **devcontainer stays usable**  
   Codespaces bootstrap must remain intact.

2. **Vercel root stays routable**  
   The repo must keep a static entry that works without a framework build step.

3. **runbook stays truthful**  
   Docs must describe the actual Phase 0/1 bootstrap path in the repository.

4. **sample contracts stay versioned in repo**  
   YAML, SQL, OpenAPI, and fixtures are source-controlled artifacts.

5. **fixture fallback remains allowed**  
   Early boot should not depend on all runtime helpers being production-complete.

6. **new code should narrow, not widen, the contract**  
   Prefer additive helpers over sweeping refactors.

## Exit criteria into the next phase

Phase 0 is considered complete enough to hand off when:
- sample YAML contracts exist for sources, delivery windows, and parser capabilities
- SQL and Ecto migrations cover the foundation tables
- OpenAPI specs document the active routes
- a daily digest fixture exists and validates
- Vercel can render a dashboard entry at `/`
- the runbook still points to the correct bootstrap path
