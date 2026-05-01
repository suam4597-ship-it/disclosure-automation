# Stage 5.1 news overlay API route exposure design

This document defines the docs-only route exposure design for serving the locked Stage 5.1 news overlay read model through the existing API surface.

This is a design document only. It does not add router code, controller code, serializers, runtime code, tests, fixtures, database migrations, schedulers, feed rendering implementation, provider fetches, or canonical feed mutations.

## Baseline

```text
base branch: sec-thin-slice-reconcile-v1
base commit: 65b3bb3788fb767d7d84671d8ade13ae12477e4f
base commit source: PR #82 Lock Stage 5.1 news overlay read model query
implementation locked: PR #81 Implement Stage 5.1 news overlay read model query
read model: DisclosureAutomation.Runtime.Stage5NewsOverlayReadModel
read model mode: migration-free read-only projection
stage: Stage 5.1 API exposure design
status: design-only
```

## Existing API context

The current router already exposes event and feed endpoints under `/api`.

Relevant existing route shape:

```text
GET /api/events/:event_id
GET /api/feed/hero
GET /api/feed/region/:region_code
GET /api/feed/digest/latest
GET /api/feed/digest/:digest_date/:edition
```

Stage 5.1 API exposure should extend the event detail surface first. It should not change feed list rendering yet.

## Goal

Expose the locked Stage 5.1 read model through an API endpoint so clients can retrieve:

```text
official TDnet canonical event fields
raw-staged Reuters overlay context under item.overlays[]
official citation first
Reuters overlay citation separately
canonicalFactOverride=false for overlays and claims
```

## Non-goals

```text
router implementation: out of scope for this PR
controller implementation: out of scope for this PR
serializer implementation: out of scope for this PR
feed card rendering: out of scope
database migration: out of scope
dedicated overlay attachment table: out of scope
fixture changes: out of scope
scheduler changes: out of scope
live Reuters fetch: out of scope
provider API integration: out of scope
news-only canonical event creation: prohibited
canonical feed item mutation: prohibited
```

## Recommended route

The first API exposure should be a detail endpoint, not a feed list endpoint.

Recommended route:

```text
GET /api/events/:event_id/news-overlay
```

Recommended controller action:

```text
DisclosureAutomationWeb.EventNewsOverlayController.show/2
```

Recommended backing query:

```text
DisclosureAutomation.Runtime.Stage5NewsOverlayReadModel.get_by_event_id(event_id)
```

## Alternate route by stable external id

A later endpoint may support stable external id lookup.

Possible future route:

```text
GET /api/events/by-stable-external-id/:stable_external_id/news-overlay
```

This should not be implemented in the first API PR unless required. The first implementation should prefer one route and one lookup path.

## Why not feed route first

Feed routes should remain unchanged until the event-detail API contract is stable.

Do not implement these first:

```text
GET /api/feed/region/:region_code with overlays embedded
GET /api/feed/hero with overlays embedded
GET /api/feed/digest/:digest_date/:edition with overlays embedded
```

Reason:

```text
feed cards have stronger compatibility and rendering expectations
API detail exposure can validate source namespacing first
feed-visible rendering needs its own design/implementation PR
```

## Response mode

The endpoint should return the read model response shape defined by Stage 5.1:

```text
item.* = official TDnet canonical item fields
item.citations[] = official citations
item.overlays[] = Reuters overlay objects
item.overlays[].citations[] = overlay citations
```

The endpoint must not flatten Reuters fields into official item fields.

## Query parameters

The first implementation should support no query parameters by default.

Allowed future query parameter:

```text
include_hidden=true
```

Rules:

```text
include_hidden=false by default
hidden overlays are omitted from normal responses
hidden overlays are only exposed for detail/debug use after explicit design
```

The first runtime PR may omit `include_hidden` entirely.

## Status codes

Recommended status behavior:

```text
200 OK: official event found; overlays may be empty or visible
404 Not Found: official canonical event not found
422 Unprocessable Entity: invalid event_id shape only if validation is added
500 Internal Server Error: unexpected read model failure
```

An official item with no overlay is still `200 OK` with:

```json
{
  "item": {
    "overlays": []
  }
}
```

## Error shape

Use the existing API error style if one exists. If no shared style exists, use a minimal shape:

```json
{
  "error": {
    "code": "official_event_not_found",
    "message": "Official event was not found."
  }
}
```

Do not include raw SQL, stack traces, secrets, provider request headers, or full Reuters article text in errors.

## Compatibility rule

The new endpoint is additive.

It must not change the behavior of:

```text
GET /api/events/:event_id
GET /api/feed/hero
GET /api/feed/region/:region_code
GET /api/feed/digest/latest
GET /api/feed/digest/:digest_date/:edition
```

## Security and redaction

The endpoint must not expose:

```text
provider credentials
Subscription-Key values
Authorization headers
Cookie headers
signed private URLs
full Reuters article text
internal fetch request headers
raw DB error strings
```

Only safe official fields, overlay metadata, claims, flags, and citation URLs may be returned.

## No-go conditions

A Stage 5.1 API route implementation must fail review if it does any of the following:

```text
adds live Reuters fetch
adds provider API integration
adds fixture changes
adds a migration
mutates canonical_feed_items
creates a Reuters CanonicalFeedItem
creates a news-only CanonicalFeedItem
returns Reuters URL as item.canonicalUrl
returns Reuters publishedAt as item.publishedAt
returns Reuters title as item.title
sets canonicalFactOverride=true
returns full Reuters article text
changes feed list endpoint behavior
```

## Recommended implementation sequence

```text
1. Land this docs-only design PR.
2. Implement one additive route and controller action.
3. Serialize the locked read model response without altering existing event/feed endpoints.
4. Add controller tests for success, no-overlay, and not-found states.
5. Run Stage 5.1 read model regressions and TDnet regressions.
6. Close out the API route implementation with PASS evidence.
```
