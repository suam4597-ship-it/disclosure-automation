# Stage 5.4 manual live-fetch guardrails

This document defines mandatory guardrails for any future Stage 5.4 manual live-fetch implementation.

This is a documentation-only guardrail file. It does not add live fetch code, provider clients, credentials, runtime code, tests, schedulers, migrations, routes, feed/controller changes, materializer changes, or canonical feed mutations.

## Baseline

```text
base source: PR #101 Add Stage 5.4 offline provider staging
locked boundary: Stage54ProviderIngestionBoundary
locked offline staging: Stage54OfflineProviderRawStaging
locked default: use_live_fetch=false
locked network state: network_access=forbidden unless a future manual-only implementation explicitly opts in
locked scheduler state: scheduler_enabled=false
locked storage: metadata_only
locked overlay mode: attach_only
locked canonical rule: no canonical feed mutation
```

## Mandatory default-off guardrail

Future manual live-fetch code must remain off by default.

Required defaults:

```text
use_live_fetch=false
provider_live_fetch_enabled=false
provider_live_fetch_manual_only=true
scheduler_enabled=false
storage_mode=metadata_only
canonical_feed_mutation=false
news_only_event_creation=false
canonical_fact_override=false
```

No GET route, feed route, event route, read model, or controller may trigger provider live fetch.

## Mandatory manual-trigger guardrail

The first live-fetch implementation must require an explicit manual operator action.

Allowed trigger classes:

```text
operator-only command
admin-only task
manual smoke helper with explicit opt-in
```

Disallowed trigger classes:

```text
scheduler
background polling loop
HTTP GET request side effect
feed rendering side effect
event detail rendering side effect
materializer side effect without explicit operator action
```

## Mandatory credential guardrail

Credentials must never be committed to the repository.

Forbidden in code, tests, fixtures, docs, logs, comments, persisted diagnostics, and smoke output:

```text
real Subscription-Key values
real Authorization header values
real Cookie header values
provider bearer tokens
provider usernames/passwords
signed private URLs
raw request headers
raw response headers
```

Allowed only as redacted examples:

```text
REDACTED_SUBSCRIPTION_KEY
REDACTED_AUTHORIZATION
REDACTED_COOKIE
REDACTED_REUTERS_API_KEY
REDACTED_BLOOMBERG_API_KEY
```

## Mandatory request/response guardrail

Future provider clients must use bounded request behavior.

Required:

```text
timeout_ms <= 5000
retry_count <= 1
no request header logging
no response header logging
no response body logging
no credential logging
no cookie logging
no signed private URL logging
```

Provider errors must be converted to redacted diagnostics before persistence.

Allowed diagnostic keys:

```text
provider
status_code
retry_count
timeout
error_class
fetched_at
request_id_hash
```

Disallowed diagnostic keys:

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

## Mandatory normalization guardrail

Provider responses must normalize through the Stage 5.4 metadata-only contract before any staging.

Required before staging:

```text
provider present
source_key present
article_external_id present
canonical_event_id present
title metadata present
published_at metadata present
url metadata present
request headers absent
credentials absent
full article body absent
```

If the response cannot pass this contract, it must not be staged as visible provider context.

## Mandatory official-match guardrail

A live provider overlay may become visible only with direct official TDnet match evidence.

Accepted evidence:

```text
canonical_event_id equals official TDnet event id
matchedCanonicalEventId equals official TDnet event id
matchedOfficialStableExternalId equals official stable external id
provider metadata references official TDnet disclosure id
```

Missing or ambiguous evidence must be rejected or hidden before visible staging.

## Mandatory storage guardrail

Default storage remains metadata-only.

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

## Mandatory canonical no-mutation guardrail

Manual live-fetch must not mutate official TDnet canonical facts.

Must remain unchanged:

```text
official event id
official stable external id
official headline/title
official published_at
official source URL
official source key
official citations
canonical feed item count for official event
```

Must remain zero:

```text
canonical_feed_items where event_id = provider overlay id
provider canonical feed item creation
news-only canonical event creation
```

## Mandatory response-shape guardrail

Manual live-fetch must not change locked read response shapes.

Locked shapes:

```text
read model: item.overlays[]
API: item.overlays[]
feed: news_overlays[]
```

Must not change:

```text
feed item_count
feed item ordering
top-level API response envelope
official TDnet fields
official citation semantics
```

## Mandatory failure-isolation guardrail

Provider failure must not affect TDnet ingestion or existing serving paths.

Required:

```text
TDnet runtime passes while provider unavailable
provider timeout does not delete existing overlays
provider error does not mutate official canonical item
provider error does not create canonical feed item
provider error diagnostics are redacted and bounded
feed/API responses continue serving existing materialized data
```

## Required implementation evidence

Any future manual live-fetch implementation PR must provide evidence for:

```text
manual trigger only
scheduler disabled
use_live_fetch default false
bounded timeout/retry
metadata-only normalization
raw staging idempotency
canonical no-mutation
redaction check
failure isolation
locked response shapes unchanged
Stage 5.4 offline staging regression
Stage 5.3 multi-overlay regression
Stage 5.2 attachment regressions
Stage 5.1 feed/API regressions
TDnet runtime/http regressions
```

## Stop conditions

Do not merge if a future PR:

```text
adds real provider credentials
turns live fetch on by default
adds scheduler-triggered provider fetch
logs request headers
logs response headers
logs response bodies
stores full article text
stores raw provider payload dumps
creates provider canonical feed items
creates news-only canonical events
mutates official TDnet canonical fields
changes locked API/feed response shapes unexpectedly
breaks Stage 5.4 offline staging idempotency
breaks Stage 5.3 multi-overlay ordering
breaks citation separation
breaks redaction checks
```
