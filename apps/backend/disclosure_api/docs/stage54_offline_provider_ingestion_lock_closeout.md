# Stage 5.4 offline provider ingestion lock close-out

This document closes the Stage 5.4 offline provider ingestion seam after the provider-backed ingestion design, offline provider boundary, offline provider raw staging, and manual live-fetch design were merged.

## Status

```text
Stage 5.4 provider-backed ingestion design: LOCKED
Stage 5.4 offline provider ingestion boundary: LOCKED
Stage 5.4 offline provider raw staging: LOCKED
Stage 5.4 manual live-fetch design: LOCKED
Stage 5.4 offline provider ingestion close-out: docs-only
```

## Merge evidence

```text
PR #99: Stage 5.4 provider-backed ingestion design
merge commit: f8b18ba70ac2eee8e8facc3548319fc96789d3f3
scope: docs-only provider-backed ingestion design, guardrails, and workset

PR #100: Add Stage 5.4 provider ingestion boundary
merge commit: 791ee4e3dd57fbe3310b56e934e4bd6688342237
scope: offline provider ingestion boundary, redacted result contract, targeted tests, manual smoke doc

PR #101: Add Stage 5.4 offline provider staging
merge commit: cd8ad1c35b8bed1d17b8cacf4c5589acb5e32d91
scope: offline provider raw staging adapter, idempotency tests, manual smoke doc

PR #102: Stage 5.4 manual live-fetch design
merge commit: 34b2950983270d4206071c51c5a151957227ce2d
scope: docs-only manual live-fetch design, smoke checklist, and guardrails
```

## Locked baseline

Stage 5.4 is locked on top of the Stage 5.3 multi-overlay source-of-truth rules:

```text
official canonical source:
  jp_tdnet_timely_disclosure

official TDnet event remains canonical:
  provider overlays do not create canonical feed items
  provider overlays do not mutate official TDnet fields
  provider overlays remain attach-only context
```

Locked response shapes remain unchanged:

```text
read model: item.overlays[]
API: item.overlays[]
feed: news_overlays[]
```

## Locked Stage 5.4 modules

### Provider ingestion boundary

```text
DisclosureAutomation.Runtime.Stage54ProviderIngestionBoundary
```

Locked behavior:

```text
use_live_fetch=false by default
network_access=forbidden
scheduler_enabled=false
storage_mode=metadata_only
overlay_mode=attach_only
canonical_feed_mutation=false
news_only_event_creation=false
canonical_fact_override=false
provider request headers are rejected
provider credentials are rejected
full article body fields are rejected
secret-like header strings are rejected
diagnostics are allowlisted and redacted
```

### Offline provider raw staging

```text
DisclosureAutomation.Runtime.Stage54OfflineProviderRawStaging
```

Locked behavior:

```text
normalizes provider payload through Stage54ProviderIngestionBoundary before staging
stages one raw document for the same provider article
stages one raw event for the same provider article
repeated staging remains idempotent
stable overlay id is generated from official event id + provider article identity
use_live_fetch=false
network_access=forbidden
scheduler_enabled=false
canonical_feed_mutation=false
news_only_event_creation=false
canonical_fact_override=false
unsafe payloads are rejected before staging
live fetch opt-in is rejected before staging
```

## Locked offline provider source key

```text
stage54_offline_provider_fixture
```

The offline provider source is a test/offline staging seam. It is not a live provider integration and must not perform network calls.

## Locked redaction contract

Stage 5.4 must not persist, log, or expose:

```text
Subscription-Key values
Authorization header values
Cookie header values
provider credentials
provider request headers
provider response headers
signed private URLs
raw provider response bodies
full article body text
```

Allowed diagnostics remain bounded and redacted:

```text
provider
status_code
retry_count
timeout
error_class
fetched_at
request_id_hash
```

## Locked manual live-fetch design

Manual live-fetch is design-only at this lock point.

Locked requirements for future live-fetch implementation:

```text
manual trigger only
use_live_fetch=false by default
scheduler disabled by default
no GET request side effects
no feed/API render side effects
bounded timeout
bounded retry count
no request header logging
no response body logging
no credential logging
metadata-only normalization before staging
TDnet failure isolation
canonical no-mutation
redaction failures are stop conditions
```

## Regression evidence

PR #100 recorded PASS evidence for:

```text
stage54 provider ingestion boundary test: PASS
stage53 multi-overlay response contract regression: PASS
stage52 read path/materializer regressions: PASS
stage5 feed/API regressions: PASS
TDnet runtime/http regressions: PASS
compile warning check: PASS
offline boundary/redacted contract guardrails: PASS
```

PR #101 recorded PASS evidence for:

```text
stage54 offline provider staging test: PASS
stage54 provider ingestion boundary regression: PASS
stage53 multi-overlay response contract regression: PASS
stage52 read path/materializer regressions: PASS
stage5 feed/API regressions: PASS
TDnet runtime/http regressions: PASS
offline staging/idempotency/canonical no-mutation: PASS
guardrails/redaction: PASS
```

PR #99 and PR #102 recorded docs-only guardrail PASS evidence for:

```text
docs-only changed files: PASS
no runtime/test/fixture/migration/schema changes: PASS
no scheduler/provider client/live-fetch code changes: PASS
no route/feed-controller/materializer/API/canonical behavior changes: PASS
provider credentials in repo forbidden: PASS
full article text storage forbidden by default: PASS
attach-only overlay rule preserved: PASS
official TDnet source-of-truth preserved: PASS
redaction guardrails recorded: PASS
```

## Close-out PR guardrail

This close-out PR is docs-only and may add only:

```text
apps/backend/disclosure_api/docs/stage54_offline_provider_ingestion_lock_closeout.md
```

It must not add or modify:

```text
runtime code
tests
fixtures
migrations
schema files
scheduler code
provider clients
live fetch code
routes
feed/controller code
materializer code
API response behavior
feed response behavior
canonical feed mutation behavior
```

## Remaining out of scope

The following remain out of scope after Stage 5.4 offline provider ingestion lock:

```text
live Reuters provider integration
live Bloomberg provider integration
real provider credential storage
scheduler-triggered provider fetch
provider request header logging
provider response body logging
full article text storage
provider canonical feed item creation
news-only canonical event creation
automatic canonical fact override
new public API routes
feed/controller response changes
materializer changes for live providers
schema/migration changes
provider source health policy
cross-source duplicate group materialization
attachment review/admin tooling
```

## Final lock statement

Stage 5.4 locks a safe offline provider ingestion seam. Provider-backed ingestion can now be represented as metadata-only, attach-only, non-canonical overlay candidates that pass a redacted boundary and stage idempotently. Live provider fetch remains out of scope until a separate implementation PR satisfies the manual-only, redaction-first, failure-isolated guardrails documented in PR #102.
