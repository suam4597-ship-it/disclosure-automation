# GlobalPulse India NSE Second Live Poll Smoke Results

This document records the second separated Fly staging live poll for the official NSE online announcements RSS feed after the source-level cap and digest diversity guard were deployed.

This is documentation-only. It does not add runtime code, routes, controllers, templates, migrations, backend response-shape changes, frontend shell changes, frontend framework changes, login UI, redirects, identity provider callback routes, poll UI, audit UI, public Source Health UI, provider behavior, materializer behavior, canonical behavior, dashboards, alerts, integrations, or scheduled live polling.

## Conclusion

```text
INDIA_NSE_SECOND_LIVE_POLL_PASS
INDIA_NSE_SOURCE_CAP_25_STILL_PASS
INDIA_NSE_DIGEST_DIVERSITY_STILL_PASS
INDIA_NSE_DUPLICATE_REFERENCE_REVIEW_NEEDED
INDIA_NSE_SCHEDULED_POLLING_STILL_DISABLED
```

## Baseline

```text
source cap PR: #356 Add source-level poll cap for live candidates
source cap smoke PR: #357 Record India NSE source cap smoke
digest diversity PR: #358 Add digest diversity guard
digest diversity smoke PR: #359 Record digest diversity guard smoke
branch: phase0-foundation
backend URL: https://globalpulse-backend-staging.fly.dev
public Pages URL: https://suam4597-ship-it.github.io/disclosure-automation/
```

## Source State

```text
GET /api/admin/source-health/india_nse_announcements: 200
source_key: india_nse_announcements
active: false
candidate_status: manual_staging_only
parser_key: rss_v1
max_items_per_poll: 25
base_url: https://nsearchives.nseindia.com/content/RSS/Online_announcements.xml
```

The source remains disabled for scheduled operation.

## Live Poll Evidence

Manual staging poll:

```text
POST /api/admin/sources/india_nse_announcements/poll?use_live_fetch=true&edition=breaking
```

Observed result:

```text
fetch.mode: live
fetch.loaded: true
fetch.status_code: 200
fetch.bytes: 599671
records_seen: 25
records_inserted: 25
raw_document_count: 25
unique_raw_document_count: 21
canonical_item_count: 25
unique_canonical_item_count: 21
```

The live feed remained available and the source cap continued to bound parser output to 25 items.

The duplicate count signal is important: NSE can repeat or closely relate announcement references inside the bounded top 25. The current response counted processed records, while unique raw/canonical references were 21. This is acceptable for a manual smoke, but scheduled promotion should still include duplicate-handling cleanup.

## Digest Evidence

```text
GET /api/feed/digest/latest?edition=breaking: 200
digest_date: 2026-05-08
edition: breaking
item_count: 12
metadata.fallback_to_fixture: false
max_source_count: 3
max_region_count: 4
```

Observed source distribution:

```text
india_nse_announcements: 3
sec_press_releases: 1
apac_policy_news: 1
asean_market_news: 1
cn_mainland_disclosures: 1
tw_market_disclosures: 1
india_market_disclosures: 1
hk_market_news: 1
eu_north_disclosures: 1
anz_market_news: 1
```

Observed primary-region distribution:

```text
india: 4
us: 1
apac: 1
asean: 1
cn: 1
tw: 1
hk: 1
eu_north: 1
anz: 1
```

Representative top-12 items:

```text
india_nse_announcements / india / priority 1 / Bank of India
india_nse_announcements / india / priority 1 / Greenpanel Industries Limited
india_nse_announcements / india / priority 1 / Dev Information Technology Limited
sec_press_releases / us / priority 1 / SEC announces enforcement action tied to disclosure controls
apac_policy_news / apac / priority 1 / APAC regulators coordinate guidance on market resilience planning
asean_market_news / asean / priority 1 / Singapore exchange liquidity program lifts ASEAN technology listings
cn_mainland_disclosures / cn / priority 1 / Shanghai-listed robotics supplier discloses capacity expansion plan
tw_market_disclosures / tw / priority 1 / TSMC files advanced packaging capacity update with exchange
india_market_disclosures / india / priority 1 / Indian renewable developer files grid-scale storage contract disclosure
hk_market_news / hk / priority 1 / Hong Kong technology listings pipeline improves after new filings
eu_north_disclosures / eu_north / priority 1 / Nordic semiconductor supplier files capacity expansion disclosure
anz_market_news / anz / priority 1 / Australian lithium producers rebound after contract price update
```

## Guardrails Preserved

```text
scheduled India NSE polling: not enabled
source active flag: false
candidate_status: manual_staging_only
public digest JSON response shape change: none
frontend shell change: none
frontend framework added: no
poll UI added: no
audit UI added: no
public Source Health UI added: no
JP live polling: still blocked pending issue #339 source-authority decision
```

## Current Conclusion

```text
INDIA_NSE_REPEATED_LIVE_POLL_STABLE
INDIA_NSE_SOURCE_CAP_REPEATEDLY_CONFIRMED
INDIA_NSE_DIGEST_DIVERSITY_REPEATEDLY_CONFIRMED
NEXT_STEP_DUPLICATE_HANDLING_CLEANUP
```
