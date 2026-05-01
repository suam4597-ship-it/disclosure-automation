# Stage 5.3 second news overlay fixture policy

This document defines the fixture policy for adding a second reputable news overlay fixture after Stage 5.2 attachment storage was locked.

This is a design document only. It does not add fixtures, source adapters, runtime code, tests, database migrations, schedulers, provider fetches, routes, feed/controller changes, or canonical feed mutations.

## Baseline

```text
base branch: sec-thin-slice-reconcile-v1
base commit: ec3d8b408e7ca15a97f5adaea72be94d4c6ee0a0
base commit source: PR #93 Lock Stage 5.2 news overlay attachment storage
stage: Stage 5.3 second overlay fixture policy
status: design-only
```

## Fixture purpose

The second fixture should test multi-overlay behavior, not provider integration.

It should prove:

```text
one official TDnet canonical item can have more than one reputable news overlay
provider identity is preserved per overlay
attachment uniqueness remains stable
API and feed response lists support multiple overlays
citation separation remains deterministic
```

## Fixture type

Allowed:

```text
static source payload fixture
synthetic provider metadata
summary-level claims only
safe citation URL placeholder or public article URL if already allowed
```

Disallowed:

```text
live provider fetch
provider API credentials
full article body text
scraped article text
paywalled content copies
social media rumor payloads
new official disclosure fixtures
```

## Recommended fixture provider

Recommended provider:

```text
Bloomberg
```

Recommended source identity:

```text
source_key: stage53_news_overlay_fixture
adapter_key: stage53_news_overlay_fixture_v1
source_tier: reputable_news_source
document_role: news_article
```

If Bloomberg is not desirable, choose another reputable source from the allowed list in the Stage 5.3 design doc.

## Required fixture file naming

Recommended pattern:

```text
apps/backend/disclosure_api/priv/fixtures/source_payloads/stage53_news_overlay_fixture_jp_tdnet_140120260430515474_<provider>_jp_article_001.json
```

Examples:

```text
stage53_news_overlay_fixture_jp_tdnet_140120260430515474_bloomberg_jp_article_001.json
stage53_news_overlay_fixture_jp_tdnet_140120260430515474_nikkei_jp_article_001.json
```

## Required payload structure

The payload should contain exactly one overlay for the first implementation.

Recommended top-level shape:

```json
{
  "fixtureVersion": "stage53_second_news_overlay_fixture_v1",
  "overlays": [
    {
      "overlayId": "...",
      "articleExternalId": "...",
      "canonicalEventId": "...",
      "sourceKey": "stage53_news_overlay_fixture",
      "sourceTier": "reputable_news_source",
      "documentRole": "news_article",
      "sourceName": "Bloomberg related news article",
      "sourceUrl": "https://example.com/provider/article-placeholder",
      "articleTitle": "...",
      "articlePublishedAt": "2026-04-30T10:45:00Z",
      "articleRetrievedAt": "2026-04-30T11:00:00Z",
      "overlayContextType": "related_news_context",
      "overlayClaims": [],
      "matchEvidence": {},
      "citations": [],
      "conflictFlags": [],
      "officialFactsPreserved": {}
    }
  ]
}
```

## Required official facts preserved

The fixture must explicitly record that official facts are preserved.

Recommended fields:

```text
officialFactsPreserved.eventId
officialFactsPreserved.stableExternalId
officialFactsPreserved.officialTitle
officialFactsPreserved.officialPublishedAt
officialFactsPreserved.officialSourceUrl
officialFactsPreserved.canonicalEventType
officialFactsPreserved.canonicalFactOverride=false
```

## Prohibited content

The fixture must not store full article text.

Prohibited fields:

```text
articleBody
fullText
rawHtml
providerResponseBody
scrapedText
paywalledArticleText
requestHeaders
responseHeaders
credentials
apiKey
authorization
cookie
subscriptionKey
```

If source metadata requires request/response info, it must be synthetic and non-secret.

## Time policy

The second fixture should use a distinct provider article timestamp.

Recommended:

```text
Reuters fixture articlePublishedAt: 2026-04-30T10:30:00Z
second fixture articlePublishedAt: 2026-04-30T10:45:00Z
```

This helps test deterministic ordering without changing official event time.

## Ordering policy

The first multi-overlay implementation should sort overlays deterministically.

Recommended sort key:

```text
1. display_state
2. published_at
3. overlay_provider
4. overlay_external_id
```

This keeps Reuters and the second provider stable across repeated reads.

## Attachment materialization policy

When materialized, the second fixture must create one additional attachment row.

Expected after materializing both fixtures:

```text
news_overlay_attachments where official_event_id = official event id: 2
canonical_feed_items where event_id = official TDnet event id: 1
canonical_feed_items where event_id = second overlay id: 0
```

## API/feed policy

API and feed responses should remain unchanged structurally:

```text
item.overlays[]
news_overlays[]
```

Expected list length after both fixtures:

```text
2
```

No new top-level field is required.

## Test requirements for implementation

The implementation PR should test:

```text
second fixture stages exactly one raw overlay
Reuters fixture still stages exactly one raw overlay
materializer creates two attachment rows after both fixtures
materializer remains idempotent
API response item.overlays length is 2
feed response news_overlays length is 2
official TDnet item count remains 1
no provider canonical item is created
redaction check passes
```

## Stop conditions

Stop if the implementation requires any of the following:

```text
live provider fetch
provider credentials
full article text storage
canonical feed mutation
schema change not covered by Stage 5.2 lock
feed/API response shape redesign
```
