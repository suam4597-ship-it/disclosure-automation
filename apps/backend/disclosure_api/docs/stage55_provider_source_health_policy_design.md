# Stage 5.5 provider source health policy design

This document defines a provider source health policy layer after the Stage 5.4 offline provider ingestion seam was locked.

This is a design document only. It does not add runtime code, tests, fixtures, migrations, schema changes, scheduler code, provider clients, live fetch code, routes, feed/controller changes, materializer changes, API behavior changes, or canonical feed mutations.

## Baseline

```text
base branch: sec-thin-slice-reconcile-v1
base commit: 66fefb8132cc54d18afb017bfee8479312f105ef
base source: PR #103 Lock Stage 5.4 offline provider ingestion seam
stage: Stage 5.5 provider source health policy design
status: docs-only
locked official source: jp_tdnet_timely_disclosure
locked offline provider source: stage54_offline_provider_fixture
locked provider boundary: Stage54ProviderIngestionBoundary
locked provider staging: Stage54OfflineProviderRawStaging
locked overlay mode: attach_only
locked canonical rule: no canonical feed mutation
```

## Goal

Stage 5.5 should define a source health policy for provider-backed overlay sources before any broader live provider integration or scheduler work.

The policy should make provider availability, degradation, redaction failures, and stale data visible without affecting TDnet canonical ingestion or feed/API serving.

## Non-goals

This PR does not authorize:

```text
live provider fetch code
provider clients
provider credentials
scheduler-triggered provider fetch
runtime health worker changes
database migrations
schema changes
routes
feed/controller changes
materializer changes
API response changes
canonical feed mutation
provider canonical feed item creation
news-only canonical event creation
full article text storage
```

## Source health principles

Provider health is advisory for overlay ingestion and must not become a canonical fact source.

Required principles:

```text
TDnet canonical source health remains independent
provider health does not mutate official TDnet feed items
provider health does not create canonical feed items
provider health does not trigger feed/API side effects
provider health may gate provider overlay visibility only through explicit future implementation policy
provider health diagnostics must be redacted and bounded
```

## Proposed provider health states

Future implementation may represent provider source health with the following logical states:

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

State meanings:

```text
unknown: no recent provider health evidence
healthy: recent manual/offline check passed and diagnostics are safe
degraded: provider responded but with partial or delayed metadata
rate_limited: provider returned or implied a rate-limit condition
timeout: provider request exceeded bounded timeout
failed: provider request or normalization failed
paused: operator disabled provider ingestion
redaction_violation: credential/header/body redaction policy was violated
manual_review_required: ambiguous official match or conflict requires review
```

## Health evidence policy

Allowed health evidence:

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

Forbidden health evidence:

```text
request headers
response headers
authorization values
cookie values
subscription key values
provider credentials
signed private URLs
raw provider response body
full article text
unbounded provider error body
```

## Health transition policy

Future implementation should keep transitions conservative.

Recommended transitions:

```text
unknown -> healthy after redacted successful check
unknown -> failed after bounded failed check
healthy -> degraded after partial metadata or delayed provider response
healthy -> rate_limited after provider rate-limit response
healthy -> timeout after timeout
healthy -> failed after non-rate-limit provider error
degraded -> healthy after subsequent clean success
rate_limited -> healthy after subsequent clean success
failed -> healthy after subsequent clean success
any -> paused after explicit operator pause
any -> redaction_violation after redaction failure
any -> manual_review_required after ambiguous official match
```

Redaction violations must be sticky until operator review.

## Health gating policy

This design does not implement health gating. Future implementation may use provider health to decide whether provider overlays should be considered visible, hidden, or stale.

Recommended future display policy:

```text
healthy: provider overlay may be visible if all Stage 5.4 match/redaction rules pass
degraded: provider overlay may remain visible with stale/degraded diagnostic if already materialized
rate_limited: do not fetch automatically; keep existing overlays if safe
timeout: do not delete existing overlays; mark provider check failed
failed: do not delete existing overlays; mark provider check failed
paused: do not run provider ingestion
redaction_violation: hide or quarantine provider overlay candidates until reviewed
manual_review_required: hidden until reviewed
```

## Failure isolation policy

Provider health must not affect official TDnet availability.

Required behavior for future implementation:

```text
TDnet runtime can pass while provider is degraded, failed, or paused
provider health failure does not remove existing safe overlays
provider health failure does not mutate official canonical item
provider health failure does not create provider canonical feed item
provider health failure diagnostics are redacted and bounded
feed/API can continue serving existing materialized data
```

## Redaction policy

Health evidence must use the same redaction policy as Stage 5.4 ingestion.

Never persist or log:

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
```

Redaction failure must force:

```text
health_status=redaction_violation
visible overlay creation disabled
manual review required
```

## Manual live-fetch relationship

Stage 5.5 source health policy should not enable live fetch by itself.

Future manual live-fetch implementation may update provider health only after:

```text
manual trigger is explicit
request is bounded
credentials are runtime-only
response is redacted
normalization passes Stage54ProviderIngestionBoundary
no canonical mutation occurs
```

## Scheduler relationship

This design does not authorize scheduler integration.

Scheduler work remains out of scope until:

```text
manual live-fetch implementation is locked
provider health states are tested
default-off behavior is preserved
rate-limit policy is locked
redaction policy is locked
failure isolation is locked
```

## Required evidence for future implementation PRs

Any future Stage 5.5 implementation PR should prove:

```text
provider health defaults to unknown or paused
provider health diagnostics are redacted
redaction violation is detected
provider health failure does not affect TDnet runtime
provider health failure does not mutate canonical feed items
provider health failure does not change API/feed response shape
paused provider does not run ingestion
rate-limited provider does not trigger retries beyond the bounded policy
existing overlays are not deleted by provider health failure
```

## Stop conditions

Do not merge a future source health implementation if it:

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
