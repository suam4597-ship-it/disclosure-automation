# Stage 5.1 news overlay feed response contract

This document defines the feed response contract for displaying locked Stage 5.1 news overlay context in feed-facing API payloads.

This is a design document only. It does not add feed controller code, route code, renderer code, runtime code, tests, fixtures, database migrations, schedulers, provider fetches, or canonical feed mutations.

## Baseline

```text
base branch: sec-thin-slice-reconcile-v1
base commit: f2c2091e863095b1f2781370541e269bac82da4a
base commit source: PR #85 Lock Stage 5.1 news overlay API exposure
locked event overlay route: GET /api/events/:event_id/news-overlay
locked read model: DisclosureAutomation.Runtime.Stage5NewsOverlayReadModel
stage: Stage 5.1 feed response contract
status: design-only
```

## Contract goal

The feed response should let clients render related Reuters context beside the official TDnet item while preserving all existing official feed item fields.

The contract is additive:

```text
existing feed item fields remain unchanged
new overlay field is added separately
```

## Recommended field

Preferred snake_case response field:

```text
news_overlays
```

If the existing feed JSON uses camelCase for new fields, an implementation may choose:

```text
newsOverlays
```

Only one casing should be used in implementation. The field should be a list.

## Feed item example

Example shape:

```json
{
  "event_id": "jp.tdnet.4527.20260430.material_information_update.material_information_update.140120260430515474",
  "headline_local": "株主提案に関する書面受領のお知らせ",
  "canonical_event_type": "material_information_update",
  "published_at_utc": "2026-04-30T10:00:00.000000Z",
  "official_source_url": "https://www.release.tdnet.info/inbs/140120260430515474.pdf",
  "source_meta": {
    "stable_external_id": "TDNET:4527:20260430:1900:140120260430515474"
  },
  "portable_citations": [
    {
      "source_name": "TDnet current-list row",
      "claim_supported": "disclosure date/time, code, company display name, title, exchange, and PDF token"
    }
  ],
  "news_overlays": [
    {
      "overlay_id": "news_overlay:jp.tdnet.4527.20260430.material_information_update.material_information_update.140120260430515474:ba9e08fb9a92ac57",
      "overlay_type": "news_article_context",
      "overlay_mode": "attach_only",
      "display_state": "visible",
      "source_key": "stage5_news_overlay_fixture",
      "provider": "Reuters",
      "source_tier": "reputable_news_source",
      "document_role": "news_article",
      "article_external_id": "NEWS-FIXTURE:jp:jp_tdnet_timely_disclosure:140120260430515474:reuters-jp-article-001",
      "title": "英ファンドＡＶＩ、ロートの会長解任議案を提出　企業統治改善求める",
      "published_at": "2026-04-30T10:30:00Z",
      "url": "https://jp.reuters.com/markets/global-markets/JKGTTV5MI5PFRGFVTC37DW73GE-2026-04-30/",
      "canonical_fact_override": false,
      "conflict_flags": [
        "provider_url_not_official_url"
      ],
      "overlay_claims": [],
      "citations": []
    }
  ]
}
```

The example is illustrative. The implementation should follow existing feed field names and transform from the locked read model consistently.

## Field mapping from read model

Read model to feed overlay field mapping:

```text
overlayId -> overlay_id
overlayType -> overlay_type
overlayMode -> overlay_mode
displayState -> display_state
sourceKey -> source_key
sourceTier -> source_tier
documentRole -> document_role
articleExternalId -> article_external_id
rawDocumentExternalId -> raw_document_external_id
rawEventExternalId -> raw_event_external_id
publishedAt -> published_at
canonicalFactOverride -> canonical_fact_override
overlayClaims -> overlay_claims
conflictFlags -> conflict_flags
```

If an implementation keeps camelCase read model fields in feed responses, it must do so consistently and document that choice in the PR.

## Required official field invariants

The feed response must keep these official fields unchanged:

```text
event_id
headline/title
canonical_event_type
event_family
published_at_utc
published_at_local
filing_date_local
official_source_url
source_meta.stable_external_id
source_meta.normalized_security_code
source_meta.pdf_document_token
portable_citations
```

Reuters overlay values must not replace any of those fields.

## Overlay object required fields

Each feed overlay object should include:

```text
overlay_id
overlay_type
overlay_mode
display_state
source_key
provider
source_tier
document_role
article_external_id
title
published_at
url
canonical_fact_override
conflict_flags
overlay_claims
citations
```

The first implementation may omit raw ids from compact feed responses if already present in detail API, but should keep `overlay_id` and `article_external_id`.

## Overlay claims

Overlay claims should be rendered as news-only context.

Each claim should include:

```text
claim_id
claim_type
text
source_key
source_tier
document_role
citation_id
canonical_fact_override
```

The implementation must not return full Reuters article text.

## Citations

The existing feed item official citations must remain unchanged.

Overlay citations should be placed under:

```text
news_overlays[].citations[]
```

This avoids breaking existing consumers that already read `portable_citations` as official citations.

## Empty overlay state

Recommended response when no overlay exists:

```json
{
  "news_overlays": []
}
```

This applies per item.

## Response compatibility

The implementation must be backward-compatible:

```text
existing keys remain present
existing values remain unchanged
new overlay key is additive
item ordering remains unchanged
item count remains unchanged
```

## Redaction requirements

Feed responses must not expose:

```text
provider credentials
Subscription-Key values
Authorization headers
Cookie headers
signed private URLs
full Reuters article text
provider request headers
raw DB errors or stack traces
```

## Tests required for implementation PR

The feed-visible implementation PR should test:

```text
digest item has news_overlays=[] before overlay staging
digest item has one Reuters overlay after overlay staging
digest item official fields remain unchanged after overlay staging
digest item count remains unchanged
digest item ordering remains unchanged
portable_citations remain official citations
overlay citations are under news_overlays[].citations[]
Reuters URL does not replace official_source_url
Reuters title does not replace official headline
Reuters published_at does not replace published_at_utc
```

## No-go conditions

A feed response implementation must fail review if it does any of the following:

```text
changes existing official field values
changes digest item count
changes digest item ordering
moves Reuters citation into official portable_citations
uses Reuters URL as official_source_url
uses Reuters timestamp as published_at_utc
stores or returns full Reuters article text
creates a Reuters canonical item
adds live provider fetch
adds migrations or fixtures
```
