# Stage 5.3 multi-overlay lock close-out

This document closes Stage 5.3 after the second news overlay fixture, second-provider staging/materializer support, and multi-overlay response contract tests were merged.

## Status

```text
Stage 5.3 second fixture + source attrs: LOCKED
Stage 5.3 second overlay raw staging + materializer support: LOCKED
Stage 5.3 multi-overlay response contract: LOCKED
Stage 5.3 multi-overlay close-out: docs-only
```

## Merge evidence

```text
PR #94: Stage 5.3 second news overlay fixture design
merge commit: e33127b70d79a3cf230a24695e3d503fdc8d7c41
scope: docs-only design and workset split

PR #95: Add Stage 5.3 second news overlay fixture
merge commit: 76410b14223b28da26dd8a843b0935efeb263ae9
scope: Bloomberg metadata-only fixture, source attrs, fixture policy tests

PR #96: Add Stage 5.3 second overlay staging and materializer support
merge commit: ae0e024accf8991d96ffa296236b6caec4027685
scope: Stage 5.3 raw staging and Stage 5.2 materializer support for second overlay provider

PR #97: Lock Stage 5.3 multi-overlay response contract tests
merge commit: 85c565920a5bb88029409bc5545b9a55c37a306e
scope: response contract tests and manual smoke documentation
Codex review_id: 4214323840
```

## Locked overlay identities

The locked official TDnet event remains the canonical source of truth:

```text
official event id:
  jp.tdnet.4527.20260430.material_information_update.material_information_update.140120260430515474

official source key:
  jp_tdnet_timely_disclosure
```

The locked attach-only overlays are:

```text
Reuters overlay id:
  news_overlay:jp.tdnet.4527.20260430.material_information_update.material_information_update.140120260430515474:ba9e08fb9a92ac57

Reuters source key:
  stage5_news_overlay_fixture

Bloomberg overlay id:
  news_overlay:jp.tdnet.4527.20260430.material_information_update.material_information_update.140120260430515474:bloomberg-jp-article-001

Bloomberg source key:
  stage53_news_overlay_fixture
```

## Locked response contracts

### Read model

```text
DisclosureAutomation.Runtime.Stage5NewsOverlayReadModel.get_by_event_id(event_id)
```

Locked behavior:

```text
item.eventId remains the official TDnet event id
item.sourceKey remains jp_tdnet_timely_disclosure
item.overlays length is 2
item.overlays[0] is Reuters
item.overlays[1] is Bloomberg
item.overlays[].canonicalFactOverride remains false
```

### Event overlay API

```text
GET /api/events/:event_id/news-overlay
```

Locked behavior:

```text
item.overlays[] shape remains stable
item.overlays[0].provider is Reuters
item.overlays[1].provider is Bloomberg
item.citations remains official-citation scope
item.overlays[].citations remains overlay-citation scope
item.overlays[].canonicalFactOverride remains false
```

### Feed digest

```text
GET /api/feed/digest/latest?edition=breaking
```

Locked behavior:

```text
item_count remains 1
items[0].event_id remains the official TDnet event id
items[0].news_overlays[] shape remains stable
news_overlays[0].provider is Reuters
news_overlays[1].provider is Bloomberg
news_overlays[].canonical_fact_override remains false
provider overlay URLs do not replace official_source_url
```

## Locked ordering

The locked visible overlay ordering is:

```text
1. Reuters
2. Bloomberg
```

The ordering is validated across:

```text
read model item.overlays[]
API item.overlays[]
feed news_overlays[]
```

## Locked citation separation

Stage 5.3 locks citation separation by role:

```text
official citations:
  isCanonicalSource=true
  sourceKey=jp_tdnet_timely_disclosure

overlay citations:
  isCanonicalSource=false
  sourceKey order:
    1. stage5_news_overlay_fixture
    2. stage53_news_overlay_fixture
```

The read-model flattened citation helper may include one or more official TDnet canonical citations before overlay citations. The locked contract is that non-canonical overlay citations remain separated by `isCanonicalSource=false` and ordered Reuters then Bloomberg.

## Locked canonical no-mutation rule

Stage 5.3 remains attach-only for news overlays. The locked storage expectation is:

```text
canonical_feed_items where event_id = official TDnet event id: 1
canonical_feed_items where event_id = Reuters overlay id: 0
canonical_feed_items where event_id = Bloomberg overlay id: 0
```

The following official TDnet fields must not be replaced by provider overlay data:

```text
headline/title
published_at_utc
official_source_url
stable_external_id
source_key
source_tier
document_role
```

## Locked redaction rule

Stage 5.3 fixtures, tests, docs, staging payloads, materialized rows, API responses, and feed responses must not expose:

```text
Subscription-Key values
Authorization header values
Cookie header values
Reuters credentials
Bloomberg credentials
signed private URLs
provider request headers
full article text
```

## Regression evidence

PR #97 Codex PASS evidence at head `8af692768cb1479ebbb47a9846cce8150dc88204` recorded:

```text
stage53 multi-overlay response contract test: PASS
stage53 staging/materializer regression: PASS
stage53 fixture policy regression: PASS
stage52 read path/materializer/schema regressions: PASS
stage5 feed/API/read-model/raw-staging regressions: PASS
TDnet runtime/http regressions: PASS
overlay order/citation separation/canonical no-mutation: PASS
guardrails/redaction: PASS
```

## Close-out PR guardrail

This close-out PR is docs-only and may add only:

```text
apps/backend/disclosure_api/docs/stage53_multi_overlay_lock_closeout.md
```

It must not add or modify:

```text
runtime code
tests
fixtures
migrations
schema files
scheduler code
provider/live fetch code
routes
feed/controller code
canonical feed mutation behavior
```

## Remaining out of scope

The following remain out of scope for Stage 5.3 lock close-out:

```text
live Reuters fetch
live Bloomberg fetch
provider credential storage
scheduler integration
provider full article text storage
news-only canonical event creation
provider canonical feed item creation
automatic canonical fact override
additional providers beyond Reuters and Bloomberg
UI rendering changes
new public API routes
schema/migration changes
```

## Final lock statement

Stage 5.3 is locked as a multi-overlay, attach-only news context layer over the official TDnet canonical event. Reuters and Bloomberg overlays may enrich context, but they do not create canonical feed items, do not mutate official TDnet facts, and do not replace official source citations or URLs.
