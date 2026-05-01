# Stage 5.1 news overlay API response contract

This document defines the API response contract for exposing raw-staged Reuters news overlay context beside an official TDnet canonical event.

This is a design document only. It does not add API code, runtime code, source adapters, fixtures, tests, database migrations, schedulers, feed-visible implementation, provider fetches, or canonical feed mutations.

## Baseline

```text
base branch: sec-thin-slice-reconcile-v1
base commit: d4fd1b8f437f5dfe1ba879de930194f9f1ad45b3
prior lock PR: #79 Lock Stage 5 news overlay raw staging runtime
stage: Stage 5.1
status: design-only
```

## Contract goal

The API should eventually return official TDnet canonical event data and Reuters overlay context in separate namespaces.

The response must make it impossible for clients to accidentally treat the Reuters article as the canonical event source.

## Top-level response shape

The preferred response shape is:

```json
{
  "item": {
    "id": "canonical-feed-item-id",
    "eventId": "jp.tdnet.4527.20260430.material_information_update.material_information_update.140120260430515474",
    "stableExternalId": "TDNET:4527:20260430:1900:140120260430515474",
    "sourceKey": "jp_tdnet_timely_disclosure",
    "sourceTier": "official_exchange_disclosure",
    "documentRole": "official_disclosure",
    "issuerName": "ロート製薬株式会社",
    "securityCode": "4527",
    "title": "株主提案に関する書面受領のお知らせ",
    "publishedAt": "2026-04-30T10:00:00.000000Z",
    "canonicalUrl": "https://example.tdnet.official/disclosure/140120260430515474",
    "canonicalEventType": "material_information_update",
    "citations": [
      {
        "citationId": "tdnet-official-1",
        "sourceKey": "jp_tdnet_timely_disclosure",
        "sourceTier": "official_exchange_disclosure",
        "documentRole": "official_disclosure",
        "url": "https://example.tdnet.official/disclosure/140120260430515474",
        "label": "TDnet official disclosure",
        "isCanonicalSource": true
      }
    ],
    "overlays": [
      {
        "overlayId": "news_overlay:jp.tdnet.4527.20260430.material_information_update.material_information_update.140120260430515474:ba9e08fb9a92ac57",
        "overlayType": "news_article_context",
        "overlayMode": "attach_only",
        "displayState": "visible",
        "sourceKey": "stage5_news_overlay_fixture",
        "provider": "Reuters",
        "sourceTier": "reputable_news_source",
        "documentRole": "news_article",
        "articleExternalId": "NEWS-FIXTURE:jp:jp_tdnet_timely_disclosure:140120260430515474:reuters-jp-article-001",
        "rawDocumentExternalId": "NEWS-FIXTURE:jp:jp_tdnet_timely_disclosure:140120260430515474:reuters-jp-article-001:article-metadata",
        "rawEventExternalId": "news_overlay:jp.tdnet.4527.20260430.material_information_update.material_information_update.140120260430515474:ba9e08fb9a92ac57:overlay-candidate",
        "title": "Reuters related article headline or fixture title",
        "publishedAt": "2026-04-30T10:30:00Z",
        "url": "https://example.reuters.com/article-placeholder",
        "language": "ja",
        "jurisdiction": "JP",
        "canonicalFactOverride": false,
        "overlayClaims": [
          {
            "claimId": "overlay-claim-1",
            "claimType": "context_summary",
            "text": "Reuters article provides related news context for the official TDnet disclosure.",
            "sourceKey": "stage5_news_overlay_fixture",
            "sourceTier": "reputable_news_source",
            "documentRole": "news_article",
            "citationId": "reuters-overlay-1",
            "canonicalFactOverride": false
          }
        ],
        "conflictFlags": [
          "provider_url_not_official_url"
        ],
        "citations": [
          {
            "citationId": "reuters-overlay-1",
            "sourceKey": "stage5_news_overlay_fixture",
            "sourceTier": "reputable_news_source",
            "documentRole": "news_article",
            "provider": "Reuters",
            "url": "https://example.reuters.com/article-placeholder",
            "label": "Reuters related news article",
            "isCanonicalSource": false
          }
        ]
      }
    ]
  }
}
```

URLs in this example are placeholders. A runtime implementation must use the actual stored official URL and overlay URL values without replacing the official canonical URL.

## Namespacing rule

Official fields remain under:

```text
item.*
```

Overlay fields remain under:

```text
item.overlays[].*
```

The API must not copy overlay fields into official item fields.

## Citation contract

The API should expose citations in two places:

```text
item.citations[]
item.overlays[].citations[]
```

`item.citations[]` contains official citations only for Stage 5.1.

Overlay citations are stored under their overlay object. A combined client view may show official citations first and overlay citations second, but the raw API contract must preserve source namespaces.

## Citation ordering contract

When a client asks for a flattened citation list, the deterministic order must be:

```text
1. item.citations[] in official order
2. overlays[] in overlay sort order
3. each overlay.citations[] in overlay citation order
```

For the locked Reuters fixture, that means:

```text
1. TDnet official citation
2. Reuters overlay citation
```

## canonicalFactOverride contract

Each overlay object must include:

```json
{
  "canonicalFactOverride": false
}
```

Each overlay claim must also include:

```json
{
  "canonicalFactOverride": false
}
```

The Stage 5.1 API must not support `canonicalFactOverride=true`.

## Overlay claim object

The overlay claim object is intentionally constrained.

Required fields:

```text
claimId
claimType
text
sourceKey
sourceTier
documentRole
citationId
canonicalFactOverride
```

Allowed `claimType` values for Stage 5.1:

```text
context_summary
market_or_news_context
activist_or_shareholder_context
related_party_context
article_metadata
```

The API must not return full Reuters article text as claim text.

## Conflict flag object

Stage 5.1 may use simple string flags first.

Allowed initial flags:

```text
published_at_differs_from_official
headline_differs_from_official_title
provider_url_not_official_url
missing_direct_official_identifier
suppressed_full_text_unavailable
```

A later API version may expand flags into objects with severity and display copy.

## Display state contract

Every overlay must include one display state:

```text
visible
hidden_missing_direct_official_identifier
hidden_conflict_requires_review
hidden_full_text_policy
hidden_source_not_allowed
```

The API may omit hidden overlays from normal feed responses, but detail/debug endpoints should be able to expose suppressed overlays with display state and reason if allowed by policy.

## Null and empty behavior

If no overlay exists, the API returns:

```json
{
  "item": {
    "overlays": []
  }
}
```

It must not synthesize empty overlay objects.

## Backward compatibility

Existing clients that read only official feed fields should keep working.

Stage 5.1 should add overlays as an additive field and should not rename existing canonical item fields.

## Security and redaction requirements

The response must not expose:

```text
provider credentials
subscription keys
authorization headers
cookies
signed private URLs
full Reuters article text
internal fetch request headers
```

Only safe article metadata and citation URLs may be exposed.

## No-go conditions

An API implementation must fail review if it does any of the following:

```text
returns Reuters as item.sourceKey for the official TDnet event
returns Reuters URL as item.canonicalUrl
returns Reuters publishedAt as item.publishedAt
returns Reuters title as item.title
sets canonicalFactOverride=true
returns full Reuters article text
creates a Reuters canonical feed item
creates news-only canonical events
hides official TDnet citations when overlays exist
merges official and overlay citations without source labels
```
