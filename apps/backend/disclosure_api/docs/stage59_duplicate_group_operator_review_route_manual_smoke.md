# Stage 5.9 duplicate group operator review route manual smoke

This smoke checklist covers the docs-only design for a future operator-only duplicate group review route.

## Expected files

```text
apps/backend/disclosure_api/docs/stage59_duplicate_group_operator_review_route_design.md
apps/backend/disclosure_api/docs/stage59_duplicate_group_operator_review_authorization_response_guardrails.md
apps/backend/disclosure_api/docs/stage59_duplicate_group_operator_review_route_manual_smoke.md
```

## Scope smoke

Confirm this PR is docs-only.

It must not add or modify:

```text
runtime modules
tests
fixtures
migrations
schema modules
router
controllers
UI code
action endpoints
scheduler code
provider clients
live fetch code
feed/controller behavior
API response behavior
feed response behavior
canonical mutation behavior
materializer behavior
```

## Baseline smoke

Confirm the docs name the correct baseline:

```text
base branch: sec-thin-slice-reconcile-v1
base commit: 1296e8c8eddbb90fb3476229d83db1f9dcbbbeb1
base source: PR #132 Add Stage 5.9 duplicate group internal materializer
```

## Route design smoke

Confirm the future route design is limited to read-only operator/admin routes:

```text
GET /api/admin/duplicate-groups
GET /api/admin/duplicate-groups/:group_id
```

Confirm the design excludes action endpoints such as confirm, reject, update, or delete.

## Authorization smoke

Confirm the design requires:

```text
authenticated operator/admin context
actor_id_hash
request_id_hash
duplicate_group:read permission
fail-closed unauthorized behavior
```

Confirm the design rejects raw actor identifiers, raw request identifiers, anonymous access, and public access.

## Response-shape smoke

Confirm the design allows only bounded internal duplicate group and member fields.

Confirm the design forbids raw provider bodies, full article text, provider private material, transport material, canonical payloads, raw similarity payloads, and unbounded diagnostics.

## Public API/feed smoke

Confirm the design says future implementation must not change:

```text
GET /api/events/:event_id
GET /api/events/:event_id/news-overlay
GET /api/feed/digest/latest
GET /api/feed/digest/:digest_date/:edition
item.overlays[]
news_overlays[]
feed item_count
feed ordering
public API envelope
public feed envelope
```

## Canonical no-mutation smoke

Confirm the design says future implementation must not:

```text
update canonical_feed_items
create provider canonical feed items
create news-only canonical events
merge official TDnet events
override official TDnet facts
override official citations
mutate news_overlay_attachments
trigger duplicate group materialization
trigger live provider fetch
trigger scheduler work
call provider clients
```

## Redaction smoke

Confirm changed files include no non-redacted provider private values, raw header values, cookie values, private operator identifiers, raw request identifiers, raw provider body, full article text, canonical payloads, or unbounded diagnostics.

## Suggested local checks

No mix test is required for this docs-only design PR unless a reviewer asks for targeted checks.

Suggested static checks:

```powershell
git diff --name-only 1296e8c8eddbb90fb3476229d83db1f9dcbbbeb1...HEAD
```

Expected output should be limited to the three docs files listed above.
