# Stage 5.4 manual live-fetch design

This document defines the Stage 5.4 manual live-fetch design after the offline provider ingestion boundary and offline provider staging adapter were merged.

This is a design document only. It does not add live fetch code, provider clients, credentials, scheduler changes, runtime code, tests, migrations, routes, feed/controller changes, materializer changes, API changes, or canonical feed mutations.

## Baseline

```text
base branch: sec-thin-slice-reconcile-v1
base commit: cd8ad1c35b8bed1d17b8cacf4c5589acb5e32d91
base source: PR #101 Add Stage 5.4 offline provider staging
stage: Stage 5.4 PR D manual live-fetch design
status: docs-only
locked official source: jp_tdnet_timely_disclosure
locked offline boundary: Stage54ProviderIngestionBoundary
locked offline staging: Stage54OfflineProviderRawStaging
locked overlay mode: attach_only
locked canonical rule: no canonical feed mutation
```

## Goal

Define the contract for a future manual live-fetch implementation without introducing live network behavior in this PR.

The first live-fetch implementation must be manual-only, disabled by default, redaction-first, and isolated from official TDnet ingestion.

## Non-goals

This PR does not authorize:

```text
live Reuters fetch code
live Bloomberg fetch code
provider credentials in repository files
scheduler-triggered provider fetch
runtime config changes in code
provider client implementation
HTTP client implementation
fixtures
migrations
schema changes
routes
feed/controller changes
materializer changes
API response shape changes
canonical feed mutation
full article text storage
provider canonical feed item creation
news-only canonical event creation
```

## Design principles

Manual live-fetch must preserve the Stage 5.4 offline seam:

```text
1. provider response is fetched only by an explicit manual trigger
2. provider response is normalized through the Stage54ProviderIngestionBoundary contract
3. normalized metadata is staged through the offline-compatible raw staging path
4. provider data remains attach-only overlay context
5. official TDnet remains the canonical source of truth
```

## Runtime configuration plan

Future implementation should read provider secrets only from runtime configuration, environment variables, or secret manager-backed runtime settings.

Repository files may document redacted sample keys only:

```text
REDACTED_REUTERS_API_KEY
REDACTED_BLOOMBERG_API_KEY
REDACTED_SUBSCRIPTION_KEY
REDACTED_AUTHORIZATION
```

Repository files must not contain real values for:

```text
Subscription-Key
Authorization
Cookie
provider bearer tokens
provider usernames/passwords
signed private URLs
```

Recommended runtime configuration shape for future implementation:

```text
provider_live_fetch_enabled=false
provider_live_fetch_manual_only=true
provider_timeout_ms=5000
provider_retry_count=1
provider_store_full_text=false
provider_log_request_headers=false
provider_log_response_body=false
provider_redact_errors=true
```

Default values must remain safe:

```text
use_live_fetch=false
manual_trigger_required=true
scheduler_enabled=false
storage_mode=metadata_only
canonical_feed_mutation=false
news_only_event_creation=false
canonical_fact_override=false
```

## Manual trigger policy

The first live-fetch implementation must require a manual trigger.

Allowed manual trigger sources:

```text
local operator command
explicit admin-only task
explicit test-only helper with network disabled by default
```

Disallowed in the first live-fetch implementation:

```text
automatic scheduler
background polling
GET request side effects
feed request side effects
event detail request side effects
implicit live fetch during API rendering
```

A manual trigger must produce bounded, redacted diagnostics only.

## Provider request policy

Future provider client code must follow these rules:

```text
bounded timeout
bounded retry count
no request header logging
no credential logging
no cookie logging
no signed URL logging
no response body logging
no full article body persistence
```

Allowed diagnostic metadata:

```text
provider
status_code
retry_count
timeout
error_class
fetched_at
request_id_hash
```

Disallowed diagnostic metadata:

```text
request_headers
response_headers
authorization
cookie
subscription_key
raw_response_body
full_article_text
signed_private_url
```

## Provider response normalization policy

Live provider responses must normalize into the same metadata-only contract as offline provider results.

Required fields before staging:

```text
provider
source_key
article_external_id
canonical_event_id
title
published_at
url
```

Required safe defaults:

```text
use_live_fetch=false unless explicitly passed by manual trigger
network_access=manual_only
scheduler_enabled=false
overlay_mode=attach_only
canonical_feed_mutation=false
news_only_event_creation=false
canonical_fact_override=false
storage_mode=metadata_only
```

The live-fetch implementation must either reuse `Stage54ProviderIngestionBoundary.normalize_result/2` directly or preserve equivalent validation before staging.

## Official match policy

A live provider result may become visible only if it directly matches an official TDnet event.

Acceptable match evidence:

```text
canonical_event_id equals official TDnet event id
matchedCanonicalEventId equals official TDnet event id
matchedOfficialStableExternalId equals official stable external id
provider article metadata references the official TDnet disclosure id
```

Missing or ambiguous match evidence must remain hidden or rejected before visible staging.

## Storage policy

Default storage remains metadata-only.

Allowed storage:

```text
provider
source_key
article_external_id
title metadata
published_at metadata
public citation URL if allowed
language
jurisdiction
overlay claims metadata
redacted diagnostics
```

Forbidden storage:

```text
full article body
raw provider payload dumps
request headers
response headers
credentials
cookies
bearer tokens
signed private URLs
unbounded provider error bodies
```

Any future decision to store full article text requires a separate design, legal/compliance review, storage policy, redaction policy, and tests.

## Failure isolation policy

Provider live-fetch failures must not affect TDnet ingestion or existing feed/API serving.

Required behavior:

```text
TDnet runtime can pass while provider is unavailable
provider timeout does not remove existing overlays
provider error does not mutate official canonical item
provider error does not create canonical feed item
provider error diagnostics are redacted and bounded
feed/API responses continue serving existing materialized data
```

## Rate limit and retry policy

The first manual live-fetch implementation should use conservative bounds:

```text
timeout_ms <= 5000
retry_count <= 1
manual single-event fetch only
no batch fan-out
no scheduler loop
```

Provider rate-limit responses should be redacted and recorded as diagnostics only:

```text
status_code
retry_count
error_class=rate_limited
fetched_at
request_id_hash if available and safe
```

## Redaction policy

All logs, persisted diagnostics, comments, and smoke output must redact:

```text
Subscription-Key values
Authorization header values
Cookie header values
provider credentials
provider request headers
signed private URLs
full article body text
raw provider response bodies
```

Redaction failures are stop conditions.

## Response shape policy

Manual live-fetch implementation must not change locked response shapes:

```text
read model: item.overlays[]
API: item.overlays[]
feed: news_overlays[]
```

Manual live-fetch must not change:

```text
feed item count
feed item ordering
official TDnet fields
official source URL
official citation semantics
top-level API response envelope
```

## Stop conditions

Do not merge a manual live-fetch implementation if it:

```text
adds real provider credentials
turns live fetch on by default
adds scheduler-triggered provider fetch
logs provider request headers
logs provider response bodies
stores full article text
creates provider canonical feed items
creates news-only canonical events
mutates official TDnet canonical fields
changes locked API/feed response shapes unexpectedly
breaks Stage 5.4 offline staging idempotency
breaks Stage 5.3 multi-overlay ordering
breaks citation separation
breaks redaction checks
```

## Recommended future implementation slice

The first manual live-fetch implementation should be split from this design and remain narrow:

```text
manual-only provider client module
redacted fetch result adapter
no scheduler
no credentials in repo
no migrations
no API/feed shape changes
no materializer changes unless separately justified
unit tests with network disabled
manual smoke checklist requiring explicit operator opt-in
```

## Final design statement

Stage 5.4 manual live-fetch must be an opt-in ingestion path that produces the same metadata-only, attach-only, non-canonical provider overlay candidates as the offline seam. It must not become a scheduler, a canonical source, or a side effect of feed/API reads.
