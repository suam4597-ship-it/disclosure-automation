# Stage 5.5 provider source health guardrails

This document defines guardrails for any future provider source health implementation after Stage 5.4 locked the offline provider ingestion seam.

This is a documentation-only guardrail file. It does not add runtime code, tests, fixtures, migrations, schema changes, scheduler code, provider clients, live fetch code, routes, feed/controller changes, materializer changes, API behavior changes, or canonical feed mutations.

## Baseline

```text
base source: PR #103 Lock Stage 5.4 offline provider ingestion seam
locked boundary: Stage54ProviderIngestionBoundary
locked offline staging: Stage54OfflineProviderRawStaging
locked default: use_live_fetch=false
locked network state: network_access=forbidden for offline seam
locked scheduler state: scheduler_enabled=false
locked storage: metadata_only
locked overlay mode: attach_only
locked canonical rule: no canonical feed mutation
```

## Mandatory advisory-only guardrail

Provider source health is advisory metadata for provider ingestion. It must not become a canonical data source.

Provider health must not:

```text
mutate official TDnet canonical fields
create provider canonical feed items
create news-only canonical events
trigger feed/API side effects
trigger live fetch by default
delete existing safe overlays solely because a provider check failed
```

## Mandatory default state guardrail

Future implementation must default safely.

Allowed safe defaults:

```text
unknown
paused
```

Unsafe defaults:

```text
healthy without evidence
live_fetch_enabled
scheduler_enabled
canonical_fact_override_enabled
```

## Mandatory state allowlist

Future implementation should use a fixed state allowlist:

```text
unknown
healthy
degraded
rate_limited
timeout
failed
paused
redaction_violation
manual_review_required
```

Any unknown state must be rejected or mapped to `unknown`.

## Mandatory redaction guardrail

Provider health diagnostics must never contain:

```text
Subscription-Key values
Authorization header values
Cookie header values
provider credentials
request headers
response headers
signed private URLs
full article body text
raw provider response bodies
unbounded provider error bodies
```

Allowed diagnostic keys are limited to:

```text
provider
source_key
status
status_code
retry_count
timeout
error_class
last_checked_at
last_success_at
last_failure_at
request_id_hash
redaction_status
manual_review_reason
```

## Mandatory redaction violation behavior

If a redaction violation is detected, future implementation must:

```text
mark provider health as redaction_violation
prevent visible provider overlay creation from that health result
require manual review
avoid persisting the offending secret-bearing value
avoid logging the offending secret-bearing value
```

## Mandatory failure isolation guardrail

Provider health failure must not affect TDnet or existing safe serving paths.

Required behavior:

```text
TDnet runtime remains independent
existing safe overlays remain available
provider failures do not mutate canonical feed items
provider failures do not create canonical feed items
provider failures do not change feed/API response shapes
provider failures record only redacted diagnostics
```

## Mandatory rate-limit guardrail

Rate-limit health must not create retry storms.

Required behavior:

```text
state=rate_limited when provider rate-limit evidence is observed
no automatic unbounded retries
no scheduler fan-out
bounded retry policy preserved
existing safe overlays remain available
```

## Mandatory pause guardrail

Paused provider health must stop provider ingestion work for that source.

Required behavior:

```text
paused provider does not run live fetch
paused provider does not run scheduled fetch
paused provider does not create new overlay candidates
paused provider does not remove existing safe overlays
```

## Mandatory manual review guardrail

Ambiguous official matches must not become visible automatically.

Required behavior:

```text
state=manual_review_required for ambiguous official match
visible overlay creation disabled until review
no canonical mutation
redacted evidence only
```

## Mandatory response-shape guardrail

Provider health must not alter locked response shapes.

Locked shapes:

```text
read model: item.overlays[]
API: item.overlays[]
feed: news_overlays[]
```

Provider health may be exposed in a future API only through a separately designed additive contract.

## Mandatory implementation evidence

Any future source health implementation PR must prove:

```text
state allowlist enforced
safe default state enforced
redaction violation detected and handled
rate limit handled without retry storm
pause prevents provider ingestion
failure isolation from TDnet
canonical no-mutation
existing safe overlays not deleted on health failure
locked API/feed shapes unchanged
Stage 5.4 offline staging regression passes
Stage 5.3 multi-overlay regression passes
redaction checks pass
```

## Stop conditions

Do not merge if a future source health PR:

```text
stores provider credentials
logs request or response headers
logs response bodies
stores full article text
turns live fetch on by default
adds scheduler-triggered provider fetch before manual live-fetch is locked
mutates official TDnet canonical fields
creates provider canonical feed items
creates news-only canonical events
changes locked API/feed response shapes unexpectedly
deletes existing safe overlays on provider health failure
breaks Stage 5.4 offline staging idempotency
breaks Stage 5.3 multi-overlay ordering
breaks redaction checks
```
