# GlobalPulse Web Remaining Implementation Workflow

Date: 2026-05-12 KST

This document orders the remaining website implementation work from the current public Pages + Fly staging state toward a production-ready GlobalPulse web deployment.

This is planning-only. It does not change frontend code, backend code, routes, public API response shapes, workflow schedules, source activation, secrets, hosting configuration, production infrastructure, production polling, public poll UI, audit UI, or public Source Health UI.

## Conclusion

```text
GLOBALPULSE_WEB_REMAINING_IMPLEMENTATION_WORKFLOW_RECORDED
CURRENT_PUBLIC_WEB_DIGEST_DIVERSITY_OBSERVATION_RECORDED
PRODUCTION_APPROVAL_BLOCKER_STATUS_RECORDED
PUBLIC_PAGES_STAGING_BACKEND_SMOKE_REMAINS_FIRST_CHECKPOINT
PRODUCTION_INFRA_DECISIONS_BLOCK_RUNTIME_PROMOTION
FRONTEND_CONFIG_PROMOTION_BLOCKED_UNTIL_PRODUCTION_BACKEND_SMOKE
SOURCE_PROMOTION_REMAINS_SOURCE_BY_SOURCE
PRODUCTION_SCHEDULED_POLLING_NOT_ENABLED
```

## Current Website State

```text
public frontend: GitHub Pages
public URL: https://suam4597-ship-it.github.io/disclosure-automation/
runtime config: apps/web/config.js
current API base: https://globalpulse-backend-staging.fly.dev
backend state: Fly staging
public web smoke workflow: GlobalPulse public web smoke
source observation workflow: GlobalPulse live staging poll
production frontend: not decided
production backend: not created
production database: not created
production config promotion: not approved
production scheduled polling: not enabled
```

The public website is currently a staging-backed public smoke surface. That is useful and intentional, but it is not a production deployment.

## Remaining Work Order

### 1. Keep Public Staging Smoke Green

Continue validating:

```text
GET public Pages URL: 200
GET public config.js: 200
config.js points to expected staging backend
GET Fly staging /api/health: 200 ok
GET Fly staging /api/feed/digest/latest?edition=breaking: 200
metadata.fallback_to_fixture=false
no raw provider/auth/session/request material exposed
frontend shell renders without fatal browser errors
```

Record a smoke result whenever:

```text
frontend config changes
backend deploy changes public digest behavior
scheduled source observations materially change digest diversity
GitHub Pages deployment changes
public web smoke workflow behavior changes
```

### 2. Track Digest Diversity Separately From Poll Success

Scheduled source poll success is not the same as public top-N digest visibility.

Current evidence shows:

```text
India NSE: poll pass and top-N digest visibility present in recent inspected runs
EU canary: poll pass, but latest inspected top-N digest was India-only
Denmark DFSA OAM: poll pass, but latest inspected top-N digest did not include Denmark
HKEX: poll pass, first scheduled run had HKEX top-N visibility, later top-N artifacts did not
2026-05-12 public web digest observation: public web smoke pass, latest top-N digest India-only, metadata.fallback_to_fixture=false
```

Before production source promotion, record:

```text
poll success count
digest top-N visibility count
top-N displacement observations
source-health state
fallback_to_fixture=false
```

### 3. Record Production Infrastructure Decision Values

This step is blocked until operator approval values exist.

Latest approval status check:

```text
production approval issue #561: open, comments 1, approval request posted
source promotion issue #565: open, comments 1, approval request posted
approval blocker status doc: globalpulse_production_approval_blocker_status_20260512.md
operator approval intake packet: globalpulse_operator_approval_intake_packet.md
production CORS smoke contract template: globalpulse_production_cors_smoke_contract_template.md
production bounded empty digest policy: globalpulse_production_bounded_empty_digest_policy.md
production rollback stop checklist: globalpulse_production_rollback_stop_checklist.md
```

Required values:

```text
production backend app name
production backend region
production database provider and plan
production frontend URL or domain plan
production CORS origin list
rollback owner
incident contact/process
whether first production digest may be empty
```

Tracking issue:

```text
https://github.com/suam4597-ship-it/disclosure-automation/issues/561
```

Do not create production infrastructure before these values are approved.

### 4. Add Production CORS Smoke Contract

After production frontend/backend origins are approved, record an exact CORS smoke contract using `globalpulse_production_cors_smoke_contract_template.md`:

```text
frontend origin
backend origin
GET /api/health from frontend origin
GET /api/feed/digest/latest?edition=breaking from frontend origin
credentials policy
allowed headers
forbidden raw/private material
browser console expectations
rollback check
```

This can be a docs/contract PR before runtime promotion, but it needs approved origins.

### 5. Create And Smoke Production Backend

Only after approval:

```text
create production Fly app
provision dedicated production database
set production secrets without printing values
deploy backend
run release migrations
smoke /api/health
smoke /api/feed/digest/latest?edition=breaking
smoke CORS from approved frontend origin
record production backend smoke
```

The first production backend smoke should remain readonly. Do not enable production scheduled polling just to populate the digest.

### 6. Promote Frontend Runtime Config

Only after production backend smoke passes:

```text
update frontend runtime config target
set production configVersion
deploy Pages or approved production frontend host
verify configVersion
verify backend health display
verify digest rendering
verify fallback if digest is bounded-empty
run public web smoke against production values
record frontend production smoke
```

Rollback must be a config revert, not a backend data mutation.

### 7. Source Promotion And Production Polling

Source promotion must stay source-by-source.

Tracking issue:

```text
https://github.com/suam4597-ship-it/disclosure-automation/issues/565
```

Before any production source schedule:

```text
official/accepted authority
machine-readable endpoint contract
staging success count
staging failure count
digest visibility evidence
source-health state
rate/cadence policy
rollback/disable path
operator approval
```

Initial production web deployment may launch with scheduled polling disabled.

### 8. Monitoring And Incident Readiness

Before production is called stable, decide:

```text
health uptime check owner
digest freshness check owner
source poll failure check owner
Pages availability check owner
database storage/connection check owner
incident contact
rollback decision owner
```

Monitoring should not be enabled as noisy alerting until owners and thresholds are clear.

## Preferred Next PRs

If no production approvals are available:

```text
1. Continue scheduled observation summaries.
2. Keep public web smoke workflow healthy.
3. Record digest diversity observation when non-India rows reappear in latest top-N.
4. Keep the operator approval intake packet current if issue #561/#565 replies change.
5. Investigate only high-confidence official endpoint blockers.
6. Keep production rollback/fix-forward docs current without executing production commands.
```

If production approvals are available:

```text
1. Record production infrastructure decision values.
2. Add production CORS smoke contract.
3. Create and smoke production backend.
4. Promote frontend runtime config.
5. Run production public web smoke.
6. Record source promotion decisions separately.
```

## Guardrails

```text
do not repoint public Pages to an unapproved production backend
do not reuse staging DB as production
do not create production secrets in docs
do not print secret values in logs
do not enable production scheduled polling
do not set candidate sources active=true
do not change backend digest JSON response shape
do not add frontend framework dependencies
do not add public poll UI
do not add audit UI
do not add public Source Health UI
do not claim fixture fallback as live success
do not start JP live polling before issue #339 is resolved
do not start KR live-source implementation before the dedicated backend/source path exists
```
