# Stage 5.6 manual trigger operator invocation design

This document defines a docs-only operator invocation design for future manual live provider integration after the Stage 5.6 fake transport and redacted result adapter were merged.

This is a design document only. It does not add runtime trigger code, tests, fixtures, migrations, schema changes, scheduler code, provider clients, live fetch code, routes, feed/controller changes, materializer changes, API behavior changes, or canonical feed mutations.

## Baseline

```text
base branch: sec-thin-slice-reconcile-v1
base commit: f7212f8323445321f325de107f6757d3491cd275
base source: PR #111 Add Stage 5.6 redacted provider result adapter
stage: Stage 5.6 PR D manual trigger smoke design
status: docs-only
locked adapter contract: Stage56ManualProviderAdapterContract
locked redacted result adapter: Stage56RedactedProviderResultAdapter
locked ingestion boundary: Stage54ProviderIngestionBoundary
locked health evaluator: Stage55OfflineProviderHealthEvaluator
```

## Goal

Define how a future operator-only manual invocation should be designed and verified without adding runtime trigger code in this PR.

The future operator invocation must remain explicit, bounded, redacted, metadata-only, attach-only, and non-canonical.

## Non-goals

This PR does not authorize:

```text
runtime trigger code
provider credentials in repository files
scheduler-triggered provider fetch
provider HTTP client implementation
live provider fetch by default
routes
feed/controller changes
materializer changes
migrations
schema changes
canonical feed mutation
provider canonical feed item creation
news-only canonical event creation
full article text storage
```

## Operator invocation principle

Future manual invocation must require an explicit operator action.

Allowed future invocation surfaces:

```text
operator-only local command
admin-only task
one-shot smoke helper with explicit opt-in
CI-disabled manual smoke script with fake transport by default
```

Disallowed invocation surfaces:

```text
public API route
unauthenticated route
feed request side effect
event detail request side effect
read model side effect
materializer side effect
scheduler tick
background polling loop
```

## Required invocation inputs

Future implementation should require bounded, explicit inputs:

```text
provider
source_key
canonical_event_id
operator_reason
manual_trigger=true
transport_mode=fake by default
timeout_ms <= 5000
retry_count <= 1
```

Optional safe metadata:

```text
article_external_id
matched_official_stable_external_id
language
jurisdiction
request_id_hash
```

Forbidden inputs:

```text
real provider credentials
request headers
response headers
signed private URLs
raw response bodies
full article text
unbounded provider payloads
```

## Invocation flow

Future implementation should follow this order:

```text
1. validate explicit operator/manual trigger
2. validate transport is fake or separately enabled by a future reviewed PR
3. validate credential source is runtime-only and not persisted
4. run bounded provider transport or fake transport
5. redact result before persistence
6. adapt result through Stage56RedactedProviderResultAdapter
7. normalize through Stage54ProviderIngestionBoundary
8. stage through Stage54-compatible raw staging behavior only when safe
9. evaluate provider health through Stage55 health policy
10. keep feed/API response shapes unchanged
```

## Default-off policy

Future implementation must default to safe behavior:

```text
use_live_fetch=false
transport_mode=fake
manual_trigger_required=true
scheduler_enabled=false
network_access=forbidden unless a future live transport PR explicitly opts in
canonical_feed_mutation=false
news_only_event_creation=false
canonical_fact_override=false
store_full_text=false
```

## Credential sourcing policy

Credentials must come only from runtime environment or secret-manager backed runtime settings.

Repository files may include only redacted placeholders:

```text
REDACTED_PROVIDER_KEY
REDACTED_PROVIDER_TOKEN
REDACTED_SUBSCRIPTION_KEY
```

Repository files must not include real provider keys, tokens, cookie values, authorization values, or signed private URLs.

## Failure handling policy

Operator invocation failures must be isolated:

```text
TDnet runtime remains unaffected
feed/API serving remains unaffected
existing overlays remain available
canonical_feed_items are not mutated
provider canonical feed items are not created
failure diagnostics are redacted and bounded
```

## Audit evidence policy

Future implementation may record bounded operator-safe audit metadata:

```text
operator_reason
provider
source_key
canonical_event_id
transport_mode
status
status_code
retry_count
timeout
error_class
request_id_hash
started_at
completed_at
```

Forbidden audit metadata:

```text
credentials
request headers
response headers
raw response body
full article text
signed private URLs
unbounded error payloads
```

## Response shape policy

Operator invocation must not change locked public response shapes:

```text
read model: item.overlays[]
API: item.overlays[]
feed: news_overlays[]
```

It must not change feed item count, feed item ordering, official TDnet fields, official citations, overlay citation separation, or top-level API envelopes.

## Stop conditions

Do not merge a future manual trigger implementation if it:

```text
adds public route invocation without separate design
allows invocation without explicit operator action
turns live fetch on by default
adds scheduler-triggered invocation
stores credentials
stores request or response headers
stores raw response bodies
stores full article text
mutates official TDnet canonical fields
creates provider canonical feed items
creates news-only canonical events
changes locked API/feed response shapes unexpectedly
breaks Stage 5.6 adapter regressions
breaks Stage 5.5 health regressions
breaks Stage 5.4 staging regressions
breaks redaction checks
```
