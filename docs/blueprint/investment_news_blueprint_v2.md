# Investment News Blueprint v2

## Product framing

This repository is building an **investment event intelligence** workflow rather than a generic news reader.

Target outcome:
- watch official disclosures, exchange notices, central-bank updates, and selected financial media
- normalize them into a canonical story shape
- remove duplicates where possible
- publish edition-based digests for dashboard, email, and alert channels

The current branch focuses on the **Phase 0 foundation** needed to support that workflow.

## Core user problem

Analysts and portfolio operators often lose time because high-signal updates are fragmented across:
- regulator press releases
- exchange notices
- central-bank statements
- issuer updates
- financial media landing pages

The system should convert that fragmented stream into a digest that answers:
- what changed?
- why does it matter?
- which market, sector, or ticker is exposed?
- is this a fresh event or a duplicate follow-up?

## Phase 0 scope in this PR

This branch does **not** finish the whole product. It puts the contracts in place.

Included now:
- Codespaces/devcontainer bootstrap
- Vercel static entry strategy
- Phase 0 SQL schema
- Ecto migrations for source registry, ingestion tables, domain events, and Oban jobs
- sample YAML contracts for source registry, delivery windows, and parser capabilities
- fixture-backed digest startup path
- lightweight API controllers for digest and source health
- OpenAPI specs for active endpoints
- runbook and task breakdown docs

Deferred:
- live source fetching
- complete parser implementations per source family
- canonical ranking logic
- durable Phoenix/Ecto integration inside a full generated app
- delivery fanout to email/slack/webhook channels

## Information model

### Source registry
Each source defines:
- identity: `source_key`, `display_name`
- fetch location: `base_url`, `healthcheck_url`
- parse strategy: `parser_key`
- scheduling: `poll_cron`
- weighting and coverage metadata
- source-specific config such as fixture path, selectors, canonical domain, and dedupe strategy

### Delivery windows
Delivery windows define the digest cadence:
- `apac-open`
- `europe-midday`
- `us-close`
- `breaking`

Each window has:
- channel
- local timezone
- open/close range
- weekday activation
- cutoff and per-channel config

### Canonical feed item
The canonical story contract centers on:
- `story_key`
- `headline`
- `summary`
- `canonical_url`
- `published_at`
- `tickers`
- `regions`
- `sectors`
- `sentiment_label`
- `relevance_score`
- `duplicate_group_key`
- `metadata`

This is the record that should eventually back every downstream digest.

## Reference source families

The sample registry currently demonstrates five representative families:
- official regulatory source: SEC press releases
- official macro source: Federal Reserve press releases
- exchange/operator source: NYSE press room
- financial media HTML list source: Financial Times markets page
- APAC central-bank source: Bank of Japan announcements

These are examples chosen to exercise multiple parser types rather than to finalize the source universe.

## API surface in Phase 0

Read APIs:
- `GET /api/feed/digest/latest?edition=...&timezone=...`
- `GET /api/feed/digest/{digest_date}/{edition}`

Admin APIs:
- `GET /api/admin/source-health`
- `GET /api/admin/source-health/{source_key}`
- `POST /api/admin/source-health/{source_key}/recheck`

The digest endpoints may use fixture fallback so the frontend and docs can stabilize before the full storage path is complete.

## Background job boundaries

The current worker set defines the first job boundaries:
- `PollSourceWorker`
- `BuildDigestWorker`
- `DispatchDomainEventWorker`
- `RecomputeSourceHealthWorker`

These jobs establish where polling, digest assembly, event dispatch, and health recomputation will live as the branch matures.

## Data-flow sketch

1. poll configured sources
2. capture raw documents
3. parse and normalize content
4. canonicalize into feed items
5. dedupe/rank per digest edition
6. publish digest payload
7. dispatch notifications or downstream events

Phase 0 only hardens steps 1, 4, 6, and 7 at the contract level; it does not fully implement all runtime steps yet.

## Repository map for this blueprint

- `apps/backend/config/` — sample source, delivery-window, and parser-capability contracts
- `apps/backend/sql/` — SQL bootstrap schema
- `apps/backend/ecto_migrations/` — Ecto migration equivalents
- `apps/backend/lib/disclosure_automation/` — reference runtime helpers and workers
- `apps/backend/openapi/` — route contracts
- `apps/backend/fixtures/` — fixture-backed digest payload
- `apps/web/` — static dashboard entry
- `docs/blueprint/` — architecture and product contracts
- `docs/phase-0/` — implementation breakdown for Codex/continuation work

## Success bar for this blueprint revision

This blueprint revision is “good enough” when:
- docs match the code and fixture contracts in the PR
- a newcomer can understand the Phase 0 intent from the repo alone
- the Vercel root path renders a meaningful static dashboard entry
- OpenAPI, fixture JSON, and YAML contracts are all present in source control
