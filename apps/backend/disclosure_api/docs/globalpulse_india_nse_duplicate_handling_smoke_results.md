# GlobalPulse India NSE Duplicate Handling Smoke Results

This document records the Fly staging smoke after bounding duplicate raw/canonical references in source poll results.

This is documentation-only. It does not add runtime code, routes, controllers, templates, migrations, backend response-shape changes, frontend shell changes, frontend framework changes, login UI, redirects, identity provider callback routes, poll UI, audit UI, public Source Health UI, provider behavior, materializer behavior, canonical behavior, dashboards, alerts, integrations, or scheduled live polling.

## Conclusion

```text
INDIA_NSE_DUPLICATE_REFERENCE_BOUNDING_DEPLOYED
INDIA_NSE_POLL_RESPONSE_UNIQUE_REFERENCES_PASS
INDIA_NSE_RECORDS_SEEN_REMAINS_PARSER_OUTPUT_COUNT
INDIA_NSE_DIGEST_DIVERSITY_STILL_PASS
INDIA_NSE_SCHEDULED_POLLING_STILL_DISABLED
```

## Baseline

```text
second live smoke PR: #360 Record India NSE second live poll smoke
duplicate handling PR: #361 Bound duplicate references in poll results
branch: phase0-foundation
merge commit: c47b9014ec7091519f8b634a6cdbc3c883b28a79
backend URL: https://globalpulse-backend-staging.fly.dev
public Pages URL: https://suam4597-ship-it.github.io/disclosure-automation/
```

## CI Evidence

The #361 merge commit completed successfully.

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

Fly staging was redeployed after #361.

```text
app: globalpulse-backend-staging
deploy: success
release_command: success
GET /api/health: 200
health status: ok
```

## Live Poll Evidence

Manual staging poll:

```text
POST /api/admin/sources/india_nse_announcements/poll?use_live_fetch=true&edition=breaking
```

Observed result:

```text
fetch.mode: live
fetch.status_code: 200
records_seen: 25
records_inserted: 14
raw_document_count: 14
unique_raw_document_count: 14
canonical_item_count: 14
unique_canonical_item_count: 14
```

Interpretation:

```text
records_seen remains the bounded parser output count.
records_inserted now reflects the unique raw document references returned by the poll response.
raw_documents and canonical_items no longer repeat duplicate IDs/keys in the response.
```

This keeps the response shape stable while making the count/list semantics less confusing for high-volume feeds with repeated references.

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
INDIA_NSE_DUPLICATE_HANDLING_SAFETY_GATE_PASS
INDIA_NSE_REPEATED_REFERENCE_RESPONSE_NOISE_REDUCED
INDIA_NSE_STILL_REQUIRES_SCHEDULED_PROMOTION_DECISION
NEXT_STEP_SCHEDULED_POLLING_PROMOTION_CONTRACT_OR_CADENCE_POLICY
```
