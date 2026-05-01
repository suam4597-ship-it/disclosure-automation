# Stage 5.1 news overlay feed rendering contract

This document defines the feed rendering contract for displaying raw-staged Reuters news overlay context beside an official TDnet canonical event.

This is a design document only. It does not add runtime code, feed UI code, API code, source adapters, fixtures, tests, database migrations, schedulers, provider fetches, or canonical feed mutations.

## Baseline

```text
base branch: sec-thin-slice-reconcile-v1
base commit: d4fd1b8f437f5dfe1ba879de930194f9f1ad45b3
prior lock PR: #79 Lock Stage 5 news overlay raw staging runtime
stage: Stage 5.1
status: design-only
```

## Rendering goal

The feed should eventually show Reuters overlay context as an attachment to the official TDnet item, not as a second canonical feed item.

The user-visible mental model should be:

```text
Official TDnet disclosure item
  + related Reuters news context
```

It should not be:

```text
TDnet canonical item
Reuters canonical item
```

## Rendering mode

Stage 5.1 rendering uses:

```text
overlay_mode: attach_only
canonical_feed_mutation: false
news_only_event_creation: false
canonicalFactOverride: false
```

The official canonical item remains the only primary feed row.

## Feed card hierarchy

The feed card should render in this order:

```text
1. Official badge / official source tier
2. Official TDnet title
3. Official issuer, security code, event type, and official timestamp
4. Official TDnet citation link
5. News overlay section label
6. Reuters overlay headline or summary-level title
7. Reuters source metadata and article timestamp
8. Reuters overlay citation link
9. Conflict flags or suppressed-state message, if any
```

The official item must visually remain the parent. The overlay must look subordinate.

## Required labels

Official anchor label:

```text
Official exchange disclosure
```

Reuters overlay label:

```text
Related reputable news context
```

Provider label:

```text
Reuters
```

Document role labels:

```text
official_disclosure -> Official disclosure
news_article -> News article
```

## Citation ordering

Feed rendering must preserve citation order:

```text
1. TDnet official citation
2. Reuters overlay citation
```

The Reuters URL must never replace the official TDnet citation. The official citation is the authority for the canonical event.

## Official facts display

The feed card must show official facts from the canonical item:

```text
issuer
security_code
official title
official published_at
official source
canonical event type
official canonical_url
```

These fields must not be overwritten by Reuters overlay values.

## Overlay context display

The overlay section may show only context-level fields:

```text
provider
article title or headline
article published_at
article URL
source_tier
document_role
overlayClaims
conflictFlags
```

It must not imply that Reuters is the official source of the disclosure.

## overlayClaims display policy

Allowed display behavior:

```text
show overlay claims under a Related news context heading
show each claim with Reuters citation association
show claim source tier and document role in detail surfaces
show canonicalFactOverride=false in debug or API detail surfaces
```

Disallowed display behavior:

```text
merge overlay claim text into the official title
use overlay claims as canonical facts
show overlay claims without a Reuters citation
hide that claims are news-only context
promote overlay claims into standalone canonical events
```

## canonicalFactOverride display policy

The feed does not need to show `canonicalFactOverride=false` in compact cards, but detail/debug surfaces should expose it.

Every rendered overlay must be treated as:

```text
canonicalFactOverride=false
```

Any overlay requiring `canonicalFactOverride=true` is outside Stage 5.1 and must be suppressed.

## source_tier display policy

The feed should distinguish source tiers without mixing them.

```text
official TDnet: official_exchange_disclosure
Reuters overlay: reputable_news_source
```

Compact rendering can map these to labels. Detail rendering should expose the raw enum values.

## conflict_flags display policy

Conflict flags should be displayed as overlay-level notices, not as official item errors.

Examples:

```text
published_at_differs_from_official -> News article time differs from official disclosure time.
headline_differs_from_official_title -> News headline differs from official disclosure title.
provider_url_not_official_url -> News article link is separate from official disclosure link.
suppressed_full_text_unavailable -> Full article text was not stored or displayed.
```

Flags must not mutate official fields and must not remove the official citation.

## Suppression states

The feed should support these overlay display states:

```text
visible
hidden_missing_direct_official_identifier
hidden_conflict_requires_review
hidden_full_text_policy
hidden_source_not_allowed
```

Stage 5.1 should prefer hiding overlays that cannot be directly associated with the official item.

## Timestamp policy

The official card timestamp is always the official TDnet timestamp.

```text
official_display_time = official TDnet published_at
overlay_display_time = Reuters article published_at
```

The Reuters timestamp must not become `canonical_feed_item.published_at`.

## URL policy

The official card primary link is always the official canonical URL.

```text
primary_url = TDnet canonical_url
overlay_url = Reuters article URL
```

The Reuters article URL may be shown in the related news section only.

## Empty overlay state

If no valid overlay is found, the feed should render the official TDnet item exactly as it does today.

No empty overlay container should be required.

## Multiple overlay future state

When multiple overlays are later supported, the feed should group them under the same official item.

```text
Official TDnet item
  Related news context
    Reuters overlay
    Bloomberg overlay
    other allowed provider overlay
```

Multiple overlays must not create multiple official feed rows.

## Accessibility and clarity requirements

The rendered copy should make source roles clear:

```text
Official disclosure: TDnet
Related news context: Reuters
```

Avoid ambiguous copy such as:

```text
Reuters disclosure
Reuters official update
Reuters filing
```

## No-go conditions

A feed rendering implementation must fail review if it does any of the following:

```text
renders Reuters as a standalone canonical feed item
hides the TDnet official citation when overlay exists
uses Reuters URL as the primary official URL
uses Reuters published_at as the official card timestamp
uses Reuters headline as the official card title
shows overlay claims without citation separation
creates news-only canonical events
stores or displays full Reuters article text from Stage 5.1
adds live Reuters fetch or provider API integration
```
