# Stage 5.9 cross-source duplicate group design

This document defines a docs-only design for future cross-source duplicate grouping across provider-backed news overlays and official TDnet disclosures.

This is a design document only. It does not add runtime grouping code, tests, fixtures, migrations, schema changes, scheduler code, provider clients, live fetch code, routes, feed/controller changes, UI code, action endpoints, materializer changes, API behavior changes, feed behavior changes, or canonical feed mutations.

## Baseline

```text
base branch: sec-thin-slice-reconcile-v1
base commit: b9379c76c8b8d83a91a0a985b4d87b2b00ee8f9f
base source: PR #124 Lock Stage 5.8 source health operator actions seam
stage: Stage 5.9 PR A cross-source duplicate group design
status: docs-only
locked Stage 5.2 materializer: attach-only overlay materialization
locked Stage 5.3 response contract: multi-overlay response shape unchanged
locked Stage 5.7 operator view: operator-only read-only source health view
locked Stage 5.8 operator actions: operator-only no-op action seam
```

## Goal

Define how future duplicate group detection and materialization should be designed before any grouping runtime, schema, route, UI, materializer, public API, or feed behavior is added.

The design records:

```text
duplicate group identity model
group membership rules
confidence and evidence rules
source precedence rules
operator-only inspection policy
redaction policy
non-canonical advisory semantics
response-shape guardrails
stop conditions for future implementation
```

## Non-goals

This PR does not authorize or implement:

```text
runtime duplicate grouping code
new duplicate group tables
migrations
schema changes
materializer changes
feed/controller changes
public API duplicate group fields
public feed duplicate group fields
UI/admin tooling
action endpoints
source health mutation
provider overlay mutation
canonical feed mutation
canonical event merge
provider canonical feed item creation
news-only canonical event creation
scheduler-triggered duplicate grouping
live provider fetch
provider clients
provider credentials
```

## Relationship to locked overlay semantics

Stage 5.9 must preserve the existing overlay model:

```text
official TDnet remains canonical source of truth
provider overlays remain metadata-only
provider overlays remain attach-only
provider overlays remain non-canonical
canonical_fact_override remains false unless separately designed
canonical feed item count remains official-only
```

Future duplicate groups may reference overlays and official events, but must not turn overlays into canonical disclosures.

## Duplicate group concept

A duplicate group is an advisory internal grouping that says two or more records likely discuss the same external disclosure/news event.

A duplicate group may include:

```text
one official TDnet disclosure event
zero or more provider overlay attachments
zero or more provider-staged candidate records in future design
```

A duplicate group must not include:

```text
new canonical event payloads
canonical feed item replacements
full article text
raw provider payloads
provider credentials
provider transport metadata
unbounded diagnostics
```

## Group identity design

Future duplicate group IDs should be deterministic and bounded.

Recommended group identity inputs:

```text
official_event_id when present
official_stable_external_id when present
normalized issuer/security code when available
normalized publication date bucket
normalized provider external IDs when no official event is present
```

Forbidden group identity inputs:

```text
full article text
raw provider response body
provider credential values
request/response transport metadata
unbounded diagnostics
private signed URLs
```

## Membership rules

Future duplicate group membership should be explicit, bounded, and explainable.

Allowed membership fields:

```text
group_id
member_id
member_kind
source_key
provider
external_id_hash or bounded external_id
official_event_id if present
overlay_id if present
confidence
match_reasons
redaction_status
created_at
updated_at
```

Member kinds:

```text
official_tdnet_event
news_overlay_attachment
provider_staged_candidate
operator_review_candidate
```

Forbidden membership fields:

```text
full article text
raw provider payloads
provider credentials
request headers
response headers
canonical feed item payloads
unbounded diagnostic payloads
```

## Match reason design

Future matching should use bounded explainable reasons.

Allowed match reasons:

```text
same_official_event_id
same_official_stable_external_id
same_security_code
same_disclosure_date
same_provider_external_id_hash
same_title_fingerprint
same_url_fingerprint
same_provider_citation_target
operator_confirmed_duplicate
```

Forbidden match reasons:

```text
raw_body_similarity_score_with_unbounded_payload
credential_or_transport_metadata_match
private_url_match_without_redaction
full_text_similarity_payload
```

## Confidence policy

Duplicate groups are advisory unless separately designed.

Recommended confidence states:

```text
unknown
candidate
likely
confirmed_by_operator
rejected_by_operator
```

Required semantics:

```text
candidate does not alter public responses
likely does not alter public responses
confirmed_by_operator remains non-canonical unless separately designed
rejected_by_operator remains internal advisory metadata
```

## Source precedence policy

Official TDnet remains source-of-truth.

Precedence rules:

```text
official TDnet facts outrank provider overlay facts
provider overlays cannot override official TDnet fields
duplicate groups cannot override official event identity
duplicate groups cannot create canonical feed items
duplicate groups cannot merge official events automatically
```

## Operator review policy

Future duplicate group review should be operator-only.

Required future behavior:

```text
operator/admin authorization required
read-only review before mutation
operator actions require separate design
audit trail required for future confirm/reject actions
redaction before display and audit
failure isolation required
```

Stage 5.9 PR A does not add any operator route, UI, or action endpoint.

## Response-shape policy

Future duplicate group implementation must not change locked public response shapes unless separately designed:

```text
read model item.overlays[] unchanged
API item.overlays[] unchanged
feed news_overlays[] unchanged
feed item_count unchanged
feed ordering unchanged
official TDnet fields unchanged
official citations unchanged
API envelope unchanged
public API duplicate_group fields absent
public feed duplicate_group fields absent
```

Duplicate groups may be exposed only through separately designed internal/operator routes.

## Canonical no-mutation policy

Duplicate grouping must not mutate canonical financial disclosure data.

Forbidden:

```text
canonical feed item mutation
provider canonical feed item creation
news-only canonical event creation
official TDnet event merge
official citation override
canonical fact override
public materializer output mutation
```

## Redaction policy

Future duplicate group design, diagnostics, logs, comments, operator views, audit records, and manual-smoke outputs must not expose:

```text
provider credential values
provider transport metadata
request headers
response headers
signed private URLs
raw provider response bodies
full article text
unbounded provider error payloads
secret-like values
```

Allowed redacted placeholders:

```text
REDACTED_PROVIDER_KEY
REDACTED_PROVIDER_TOKEN
REDACTED_SUBSCRIPTION_KEY
```

## Future implementation sequence

Recommended future sequence:

```text
1. Docs-only duplicate group design and guardrails
2. Pure duplicate group contract module with no DB writes, no routes, no network calls
3. Pure duplicate group projection contract with bounded redacted fields
4. Internal no-op grouping service using existing overlay fixtures only
5. Optional schema/migration design for internal duplicate group storage
6. Internal materialization implementation after schema design is locked
7. Operator-only review route after authorization/audit design is locked
8. UI implementation after route and audit behavior are locked
```

This PR covers only step 1.

## Stop conditions

Do not merge a future implementation if it:

```text
adds public duplicate group fields without separate response-shape design
changes item.overlays[] shape
changes news_overlays[] shape
changes feed item_count or ordering
mutates canonical feed items
creates provider canonical feed items
creates news-only canonical events
merges official TDnet events automatically
overrides official TDnet facts
stores provider credentials in repository files
logs provider transport metadata
logs raw provider payloads
stores full article text
adds scheduler-triggered provider work
triggers live provider fetch by default
adds routes/UI/action endpoints in a pure contract PR
breaks redaction checks
```
