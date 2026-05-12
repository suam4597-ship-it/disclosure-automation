# GlobalPulse Production Bounded Empty Digest Policy

Date: 2026-05-12 KST

This document records the policy for a future first production launch where the production backend may not yet have approved production source data.

It is documentation-only. It does not change backend runtime behavior, digest code, routes, public API response shapes, frontend config, production infrastructure, production scheduled polling, source activation, source promotion, public poll UI, audit UI, or public Source Health UI.

## Conclusion

```text
GLOBALPULSE_PRODUCTION_BOUNDED_EMPTY_DIGEST_POLICY_RECORDED
FIRST_PRODUCTION_DIGEST_EMPTY_STATE_REQUIRES_OPERATOR_APPROVAL
FIXTURE_FALLBACK_MUST_NOT_BE_CLAIMED_AS_PRODUCTION_DATA
PRODUCTION_SCHEDULED_POLLING_MUST_NOT_BE_ENABLED_JUST_TO_POPULATE_DIGEST
SOURCE_PROMOTION_REMAINS_SOURCE_BY_SOURCE
```

## Current Runtime Fact

The current public digest controller calls digest lookup with fixture fallback enabled:

```text
GET /api/feed/digest/latest?edition=breaking
controller: DisclosureAutomationWeb.FeedDigestController.latest/2
digest call: Digest.get_latest_digest(..., fallback_to_fixture: true)
```

The digest layer returns live repository-backed data with:

```text
metadata.fallback_to_fixture: false
generated_by: repo
item_count: length(items)
items: [...]
```

If no repository-backed digest items exist for the requested edition/date, the current path may fall back to fixture data when fixture fallback is enabled.

Interpretation:

```text
metadata.fallback_to_fixture=false is live/repository-backed digest evidence
metadata.fallback_to_fixture=true is not production data evidence
fixture fallback must not be recorded as successful production digest population
```

## Production Empty-State Decision

Issue #561 must explicitly answer:

```text
FIRST_PRODUCTION_DIGEST_EMPTY_OK: yes/no
```

If `yes`, the first production backend smoke may accept an empty or missing digest only if the result is recorded as an approved launch empty state, not as a populated production feed.

If `no`, production launch must wait for an approved production data path before frontend promotion.

## Acceptable First Production Digest Outcomes

### Preferred

```text
GET /api/feed/digest/latest?edition=breaking: 200
metadata.fallback_to_fixture: false
item_count: bounded integer
items: bounded array
```

This is production/repository-backed digest evidence.

### Conditionally Acceptable With Approval

```text
GET /api/feed/digest/latest?edition=breaking: bounded empty or documented not_found
FIRST_PRODUCTION_DIGEST_EMPTY_OK: yes
production scheduled polling: disabled
source promotions: none unless separately approved
frontend empty state: bounded and non-fatal
```

This is acceptable only as a launch-state decision. It is not evidence that production source data is populated.

### Not Acceptable As Production Data Evidence

```text
metadata.fallback_to_fixture: true
fixture payload presented as live production data
staging database reused to make production look populated
one-off candidate source poll without source-specific approval
production scheduled polling enabled just to create a digest
candidate sources set active=true without issue #565 approval
```

## Frontend Behavior

If an empty production digest is explicitly approved, the frontend smoke should verify:

```text
page loads
backend health shows ok
digest request does not crash the UI
empty-state copy is bounded and non-alarming
no raw JSON dump
no secret/auth/session/raw provider material
no public poll UI appears
no public Source Health UI appears
```

The frontend must not hide a fixture-backed digest as if it were production data.

## Backend Smoke Recording

When recording first production backend smoke, include:

```text
production backend URL
production frontend URL or planned frontend URL
GET /api/health status
GET /api/feed/digest/latest?edition=breaking status
digest item_count if present
digest metadata.fallback_to_fixture if present
FIRST_PRODUCTION_DIGEST_EMPTY_OK value from issue #561
whether source promotion approvals exist in issue #565
whether production scheduled polling is disabled
```

If the digest is empty/not_found by approval, record:

```text
PRODUCTION_DIGEST_EMPTY_STATE_APPROVED
PRODUCTION_DIGEST_NOT_POPULATED_YET
PRODUCTION_SCHEDULED_POLLING_DISABLED
NO_FIXTURE_FALLBACK_CLAIMED_AS_PRODUCTION_DATA
```

## Source Data Boundary

Production source data may be introduced only through a separate source-by-source decision:

```text
issue: https://github.com/suam4597-ship-it/disclosure-automation/issues/565
required: source_key
required: approved source authority
required: endpoint/parser contract
required: staging evidence
required: cadence/rate policy
required: rollback/disable path
```

An approved empty production digest does not approve any source schedule.

## Next PR Mapping

If #561 approves empty first production digest:

```text
next PR: Record GlobalPulse first production digest empty-state decision
scope: docs-only
runtime changes: none
```

If #561 rejects empty first production digest:

```text
next PR: Record GlobalPulse production digest population prerequisite
scope: docs-only
runtime changes: none
source promotion still requires #565
```

If runtime must distinguish production fixture fallback from staging fixture fallback:

```text
next PR: Add production digest fallback boundary contract tests
scope: focused test-only or runtime + test depending on approved design
do not change public response shape without explicit contract update
```

## Guardrails

```text
Do not treat fixture fallback as production data.
Do not enable production scheduled polling just to populate the digest.
Do not reuse staging DB as production.
Do not set candidate sources active=true without source-specific approval.
Do not change backend digest JSON response shape in this policy.
Do not add public poll UI.
Do not add audit UI.
Do not add public Source Health UI.
Do not start JP live polling before issue #339 is resolved.
Do not start KR live-source implementation before the dedicated backend/source path exists.
```
