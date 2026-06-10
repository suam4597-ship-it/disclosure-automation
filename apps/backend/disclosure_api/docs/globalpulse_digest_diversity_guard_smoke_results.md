# GlobalPulse Digest Diversity Guard Smoke Results

This document records the Fly staging smoke after adding the backend digest diversity guard.

This is documentation-only. It does not add runtime code, routes, controllers, templates, migrations, backend response-shape changes, frontend shell changes, frontend framework changes, login UI, redirects, identity provider callback routes, poll UI, audit UI, public Source Health UI, provider behavior, materializer behavior, canonical behavior, dashboards, alerts, integrations, or scheduled live polling.

## Conclusion

```text
GLOBALPULSE_DIGEST_DIVERSITY_GUARD_DEPLOYED
GLOBALPULSE_DIGEST_DIVERSITY_GUARD_SMOKE_PASS
INDIA_NSE_NO_LONGER_DOMINATES_TOP_12_DIGEST
REGIONAL_DIGEST_MIX_RESTORED
INDIA_NSE_SCHEDULED_POLLING_STILL_DISABLED
```

## Baseline

```text
decision gate PR: #355 Record India NSE scheduled polling decision gate
source cap PR: #356 Add source-level poll cap for live candidates
source cap smoke PR: #357 Record India NSE source cap smoke
digest diversity PR: #358 Add digest diversity guard
branch: phase0-foundation
merge commit: 49923e82bd5c657d41631b94208914a285fedfaf
backend URL: https://globalpulse-backend-staging.fly.dev
public Pages URL: https://suam4597-ship-it.github.io/disclosure-automation/
```

## CI Evidence

The #358 merge commit completed successfully.

```text
Phase 0 validate: success
Phase 0 report: success
Phase 1 backend verify: success
Phase 1 runtime smoke: success
Phase 1 backend report: success
Phase 1 backend diagnose: success
Phase 1 backend trace: success
```

## Fly Staging Deploy Evidence

Fly staging was redeployed after #358.

```text
app: globalpulse-backend-staging
deploy: success
release_command: success
GET /api/health: 200
health status: ok
```

## Digest Smoke Evidence

```text
GET /api/feed/digest/latest?edition=breaking: 200
digest_date: 2026-05-08
edition: breaking
item_count: 12
metadata.fallback_to_fixture: false
max_source_count: 2
max_region_count: 3
```

Observed source distribution:

```text
india_nse_announcements: 2
sec_press_releases: 1
apac_policy_news: 1
asean_market_news: 1
cn_mainland_disclosures: 1
tw_market_disclosures: 1
india_market_disclosures: 1
hk_market_news: 1
eu_north_disclosures: 1
anz_market_news: 1
eu_central_disclosures: 1
```

Observed primary-region distribution:

```text
india: 3
us: 1
apac: 1
asean: 1
cn: 1
tw: 1
hk: 1
eu_north: 1
anz: 1
eu_central: 1
```

Representative top-12 items:

```text
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
eu_central_disclosures / eu_central / priority 1 / German industrial automation group discloses order backlog expansion
```

## Interpretation

Before the diversity guard, the high-volume NSE live candidate could occupy the public top-12 digest because it produced many fresh priority-ranked items. After #358, the backend still respects priority ordering, but it selects from a wider candidate set and applies bounded source/region caps before returning the public digest.

The public digest JSON response shape remains unchanged. The UI continues to receive a normal `items` array and can group it by region as before.

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
DIGEST_DIVERSITY_SAFETY_GUARD_PASS
INDIA_NSE_TOP_12_IMPACT_BOUNDED
GLOBALPULSE_REGIONAL_MIX_PUBLIC_DIGEST_READY
NEXT_STEP_NSE_DUPLICATE_HANDLING_REVIEW_OR_SECOND_LIVE_POLL_SMOKE
```
