# Stage 5.1 news overlay API controller contract

This document defines the controller and serializer contract for exposing the locked Stage 5.1 news overlay read model.

This is a design document only. It does not add controller code, serializer code, router code, runtime code, tests, fixtures, database migrations, schedulers, feed rendering implementation, provider fetches, or canonical feed mutations.

## Baseline

```text
base branch: sec-thin-slice-reconcile-v1
base commit: 65b3bb3788fb767d7d84671d8ade13ae12477e4f
base commit source: PR #82 Lock Stage 5.1 news overlay read model query
locked read model: DisclosureAutomation.Runtime.Stage5NewsOverlayReadModel
stage: Stage 5.1 API controller design
status: design-only
```

## Controller goal

The controller should expose the locked read model with no additional ingestion, fetch, merge, or mutation side effects.

Allowed controller behavior:

```text
read event_id from path params
call DisclosureAutomation.Runtime.Stage5NewsOverlayReadModel.get_by_event_id/1
render the returned response as JSON
return 404 when the official event is missing
return redacted generic errors for unexpected failures
```

Disallowed controller behavior:

```text
poll sources
stage overlays
create raw documents
create raw events
create canonical feed items
mutate canonical feed items
fetch Reuters live
call provider APIs
run LLM duplicate decisions
change feed list responses
```

## Recommended controller module

```text
DisclosureAutomationWeb.EventNewsOverlayController
```

Recommended action:

```text
show(conn, %{"event_id" => event_id})
```

Recommended route:

```text
GET /api/events/:event_id/news-overlay
```

## Read model call

The controller should call exactly the locked read model:

```elixir
DisclosureAutomation.Runtime.Stage5NewsOverlayReadModel.get_by_event_id(event_id)
```

Expected return handling:

```text
{:ok, response} -> 200 JSON
{:error, :official_canonical_item_not_found} -> 404 JSON
{:error, reason} -> 500 redacted JSON
```

If the current implementation raises unexpected exceptions, controller-level tests should cover only the expected tuple behavior and generic error fallback if a shared fallback controller exists.

## Response serialization rule

The serializer should preserve the existing read model namespacing:

```text
item.*
item.citations[]
item.overlays[]
item.overlays[].overlayClaims[]
item.overlays[].conflictFlags[]
item.overlays[].citations[]
```

It must not flatten overlay fields into official item fields.

## Official item fields

The controller response should include these official item fields:

```text
id
eventId
stableExternalId
sourceKey
sourceTier
documentRole
issuerName
securityCode
title
publishedAt
canonicalUrl
canonicalEventType
citations
overlays
```

The values must come from the official TDnet canonical event, not from Reuters.

## Overlay fields

Each overlay should include:

```text
overlayId
overlayType
overlayMode
displayState
sourceKey
provider
sourceTier
documentRole
articleExternalId
rawDocumentExternalId
rawEventExternalId
title
publishedAt
url
language
jurisdiction
canonicalFactOverride
overlayClaims
conflictFlags
citations
```

For Stage 5.1 Reuters overlay responses:

```text
canonicalFactOverride: false
displayState: visible when direct official identifier match passes
sourceTier: reputable_news_source
documentRole: news_article
provider: Reuters
```

## Citation contract

The response should preserve citations in source-specific namespaces:

```text
item.citations[] = official citations
item.overlays[].citations[] = Reuters overlay citations
```

If the controller provides a flattened citation helper in the future, the order must be:

```text
1. official TDnet citations
2. Reuters overlay citations
```

The first API implementation should not add a flattened citation field unless required by clients.

## No-overlay behavior

When the official event exists but no valid raw-staged overlay is found:

```text
HTTP status: 200
item.overlays: []
```

This is not an error.

## Not-found behavior

When the official canonical item does not exist:

```text
HTTP status: 404
error.code: official_event_not_found
```

Do not leak whether a Reuters overlay raw event exists for an unknown official event.

## Redaction and safe logging

Controller logs and errors must not include:

```text
Subscription-Key values
Authorization header values
Cookie header values
provider credentials
signed private URLs
full Reuters article text
raw SQL with values
stack traces in JSON responses
```

Debug logs may include safe identifiers:

```text
event_id
stable_external_id
overlay_id
article_external_id
source_key
```

## Tests required for implementation PR

The implementation PR should add controller/API tests for:

```text
returns 200 with official item and overlays=[] before Reuters staging
returns 200 with one Reuters overlay after raw staging
keeps item.sourceKey as jp_tdnet_timely_disclosure
keeps item.title as official TDnet title
keeps item.publishedAt as official TDnet published_at
keeps item.canonicalUrl as official TDnet URL
returns overlay under item.overlays[]
returns overlay.canonicalFactOverride=false
keeps official citations separate from overlay citations
returns 404 for missing official event
```

Regression tests should include:

```text
stage5 read model query test
stage5 raw-staging idempotency regression
TDnet runtime idempotency regression
TDnet HTTP smoke regression
redaction check
```

## No-go conditions

A controller implementation must fail review if it does any of the following:

```text
calls Stage5NewsOverlayRawStaging.stage_once/1 from a GET request
polls TDnet or Reuters from a GET request
writes to raw_documents or raw_events
writes to canonical_feed_items
returns Reuters as item.sourceKey
returns Reuters URL as item.canonicalUrl
returns Reuters publishedAt as item.publishedAt
returns Reuters title as item.title
sets canonicalFactOverride=true
returns full Reuters article text
changes existing /api/events/:event_id behavior without a separate migration plan
changes feed list endpoint behavior
```
