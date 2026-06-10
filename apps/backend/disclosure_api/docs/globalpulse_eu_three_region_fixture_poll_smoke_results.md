# GlobalPulse EU Three Region Fixture Poll Smoke Results

This document records the successful Fly staging fixture polling smoke for the three Europe disclosure source buckets.

This is documentation-only. It does not add runtime code, routes, controllers, templates, migrations, backend response-shape changes, frontend static shell changes, frontend framework changes, login UI, redirects, identity provider callback routes, poll UI, audit UI, public Source Health UI, provider behavior, materializer behavior, canonical behavior, dashboards, alerts, or integrations.

## Baseline

```text
backend app: globalpulse-backend-staging
backend URL: https://globalpulse-backend-staging.fly.dev
edition: breaking
workflow: GlobalPulse regional fixture staging poll
workflow run: https://github.com/suam4597-ship-it/disclosure-automation/actions/runs/25537782520
artifact: globalpulse-regional-fixture-staging-poll-25537782520
artifact id: 6872145186
```

## Related PRs

```text
PR #341 Add three Europe disclosure source fixtures
PR #342 Register regional fixture staging poll workflow
```

PR #341 was deployed to Fly staging before the successful workflow run:

```text
commit: c8fd85b6b0756bd58d5dfc44cb8b13648872bfb3
command: flyctl deploy --remote-only --app globalpulse-backend-staging
release_command: completed successfully
image: globalpulse-backend-staging:deployment-01KR2Z8FCBR3HSPN4B6ZPEFDAB
```

The workflow was registered on the default branch by PR #342:

```text
commit: 52a46f1b252eb89da6f3133bea47a2b3b6fb1146
workflow: .github/workflows/globalpulse-regional-fixture-staging-poll.yml
```

## Workflow Inputs

```text
backend_url: https://globalpulse-backend-staging.fly.dev
source_keys: eu_north_disclosures,eu_central_disclosures,eu_south_disclosures
edition: breaking
use_live_fetch: false
```

## Successful Workflow Result

```text
Health check: success
Poll fixture sources: success
Verify digest: success
Upload smoke outputs: success
```

### Health Check

```text
GET /api/health
HTTP status: 200
response: {"status":"ok","service":"disclosure_automation","phase":"phase1","repo":"up"}
```

### Northern Europe Disclosure Fixture

```text
POST /api/admin/sources/eu_north_disclosures/poll?use_live_fetch=false&edition=breaking
HTTP status: 202
fetch.mode: fixture
fetch.loaded: true
fixture: source_payloads/eu_north_disclosures.xml
fetch.bytes: 1220
records_seen: 2
records_inserted: 2
```

Canonical items:

```text
breaking-2026-05-08-eu-north-disclosure-20260508-nordic-semiconductor-capacity
breaking-2026-05-08-eu-north-disclosure-20260508-grid-interconnector-capex
```

### Central Europe Disclosure Fixture

```text
POST /api/admin/sources/eu_central_disclosures/poll?use_live_fetch=false&edition=breaking
HTTP status: 202
fetch.mode: fixture
fetch.loaded: true
fixture: source_payloads/eu_central_disclosures.xml
fetch.bytes: 1200
records_seen: 2
records_inserted: 2
```

Canonical items:

```text
breaking-2026-05-08-eu-central-disclosure-20260508-industrial-automation-backlog
breaking-2026-05-08-eu-central-disclosure-20260508-healthcare-margin-sensitivity
```

### Southern Europe Disclosure Fixture

```text
POST /api/admin/sources/eu_south_disclosures/poll?use_live_fetch=false&edition=breaking
HTTP status: 202
fetch.mode: fixture
fetch.loaded: true
fixture: source_payloads/eu_south_disclosures.xml
fetch.bytes: 1172
records_seen: 2
records_inserted: 2
```

Canonical items:

```text
breaking-2026-05-08-eu-south-disclosure-20260508-lng-terminal-utilization
breaking-2026-05-08-eu-south-disclosure-20260508-renewable-project-financing
```

### Latest Digest

```text
GET /api/feed/digest/latest?edition=breaking
HTTP status: 200
digest_date: 2026-05-08
generated_at: 2026-05-08T05:01:46Z
generated_by: repo
item_count: 12
metadata.fallback_to_fixture: false
```

EU fixture source keys observed in the digest response:

```text
eu_north_disclosures
eu_central_disclosures
eu_south_disclosures
```

## Current Conclusion

```text
EU_NORTH_DISCLOSURE_FIXTURE_POLL_PASS
EU_CENTRAL_DISCLOSURE_FIXTURE_POLL_PASS
EU_SOUTH_DISCLOSURE_FIXTURE_POLL_PASS
GLOBALPULSE_EU_THREE_REGION_FIXTURE_READY
```

## Guardrails

The EU three-region fixture smoke did not require or introduce:

```text
scheduled live EU polling
frontend framework changes
backend route changes
backend JSON response-shape changes
database schema changes
login UI
identity provider callback routes
poll UI
audit UI
public Source Health UI
provider/materializer/canonical contract expansion
request-param actor_permissions as production authority
raw provider/auth/session/request material in public responses
```

## Next Action

The EU fixture layer is ready for staging coverage. Live EU endpoints remain blocked until verified by the EU live source verification contract.

Recommended next regional step:

```text
Verify one real EU live endpoint candidate
or
start CN/TW fixture/live-source verification if EU live authority remains unresolved
```

KR remains deferred because the Korean disclosure path needs a separate backend/API integration.
