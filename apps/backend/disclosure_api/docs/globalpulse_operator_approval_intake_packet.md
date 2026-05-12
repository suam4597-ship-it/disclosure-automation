# GlobalPulse Operator Approval Intake Packet

Date: 2026-05-12 KST

This document is the operator-facing intake packet for the next GlobalPulse production and source-promotion decisions.

It is documentation-only. It does not create production infrastructure, provision databases, set secrets, deploy production, change frontend config, change backend runtime behavior, change routes or public API response shapes, enable production scheduled polling, promote sources, set candidate sources `active=true`, add public poll UI, add audit UI, or add public Source Health UI.

## Conclusion

```text
GLOBALPULSE_OPERATOR_APPROVAL_INTAKE_PACKET_RECORDED
PRODUCTION_APPROVAL_REQUEST_COMMENT_POSTED
SOURCE_PROMOTION_APPROVAL_REQUEST_COMMENT_POSTED
PRODUCTION_INFRA_CREATION_STILL_BLOCKED
SOURCE_PROMOTION_STILL_BLOCKED
PRODUCTION_SCHEDULED_POLLING_STILL_DISABLED
```

## Current State

```text
public staging frontend: https://suam4597-ship-it.github.io/disclosure-automation/
staging backend: https://globalpulse-backend-staging.fly.dev
primary working branch: phase0-foundation
latest local anchor before this packet: fd249b04852b6c4626ce983cb2fa61509265db01
latest merged PR before this packet: #599 Record production approval request comments
production approval issue: https://github.com/suam4597-ship-it/disclosure-automation/issues/561
source promotion approval issue: https://github.com/suam4597-ship-it/disclosure-automation/issues/565
JP source authority issue: https://github.com/suam4597-ship-it/disclosure-automation/issues/339
```

The approval issues now have request comments, but no operator values or source-specific approvals have been provided yet.

## Production Approval Intake

Production infrastructure work remains blocked until issue #561 contains explicit operator values.

Required non-secret values:

```text
APPROVE_CREATE_PRODUCTION_FLY_APP: yes/no
APP_NAME: globalpulse-backend-production or approved alternative
REGION: approved Fly primary region
APPROVE_CREATE_PRODUCTION_DATABASE: yes/no
DATABASE_PROVIDER: Fly Postgres or approved alternative
DATABASE_PLAN: approved plan
PHX_HOST: approved production backend host
PRODUCTION_FRONTEND_URL: approved URL/domain plan
ALLOWED_ORIGINS: approved CORS origin list
SECRET_OWNER: owner who sets and rotates secrets outside PRs/docs
ROLLBACK_OWNER: owner for production rollback decisions
INCIDENT_CONTACT_PROCESS: owner/process
FIRST_PRODUCTION_DIGEST_EMPTY_OK: yes/no
PRODUCTION_SCHEDULED_POLLING_INITIAL_STATE: disabled recommended
```

Do not paste these secret values anywhere in GitHub issues, PRs, docs, screenshots, or terminal logs:

```text
DATABASE_URL
SECRET_KEY_BASE
provider tokens
database passwords
private keys
session or auth material
```

## Source Promotion Intake

Source promotion work remains blocked until issue #565 contains explicit source-by-source approvals.

Use this block per source:

```text
SOURCE_KEY:
APPROVE_PRODUCTION_PROMOTION: yes/no
APPROVED_SOURCE_AUTHORITY:
APPROVED_ENDPOINT_CONTRACT_DOC:
APPROVED_PARSER_CONTRACT_DOC:
REQUIRED_STAGING_RUN_COUNT:
ACCEPTED_STAGING_FAILURE_COUNT:
LATEST_ACCEPTED_RUN_ID:
PUBLIC_DIGEST_VISIBILITY_REQUIRED: yes/no
APPROVED_CADENCE:
RATE_LIMIT_NOTES:
ROLLBACK_DISABLE_PATH:
PRODUCTION_BACKEND_SMOKE_REQUIRED_FIRST: yes
OPERATOR_APPROVER:
```

Current source tracks:

```text
SEC baseline: live baseline exists, production schedule still requires production approval
India NSE: staging scheduled observation continues
EU canary batch: staging scheduled observation continues
Denmark DFSA OAM: staging scheduled observation continues
HKEX: staging scheduled observation continues toward 7-day / 10-run gate
JP: blocked until issue #339 source authority decision is resolved
KR: deferred until the dedicated backend/source path exists
```

## How To Interpret Replies

Treat these as non-approvals:

```text
looks good
continue observing
staging is healthy
the source appears in the digest
create a plan
prepare templates
```

Treat these as insufficient for execution:

```text
approval without app/database/frontend/CORS values
approval that includes secret values in public text
source approval without source_key
source approval without cadence or rollback path
source approval before production backend smoke when production dependency is required
```

Treat these as actionable only if explicit:

```text
APPROVE_CREATE_PRODUCTION_FLY_APP: yes
APPROVE_CREATE_PRODUCTION_DATABASE: yes
APPROVE_PRODUCTION_PROMOTION: yes
PRODUCTION_SCHEDULED_POLLING_INITIAL_STATE: disabled
```

## Next PR Mapping

If issue #561 receives complete production values:

```text
next PR: Record GlobalPulse production infrastructure decision values
scope: docs-only decision record
runtime changes: none
```

After that docs-only decision PR, and only if still approved:

```text
next PR: Add GlobalPulse production CORS smoke contract
scope: docs-only contract using approved origins
runtime changes: none
```

After the CORS contract and only with approval:

```text
next operation: create and smoke production backend
scope: infrastructure/deployment, not source scheduling
scheduled production polling: still disabled
```

If issue #565 receives complete source-specific approval:

```text
next PR: Record GlobalPulse source production promotion decision for <source_key>
scope: docs-only source decision
runtime changes: none
```

If no approvals arrive:

```text
continue scheduled staging observation summaries
continue public web smoke observation
record digest diversity changes when they occur
keep production and source promotion blocked
```

## Safe Idle Work

These tasks are safe while waiting for scheduled runs or operator approvals:

```text
refresh issue status checks
record new scheduled staging observations when runs appear
record new public web smoke observations when runs appear
record source-health drift if last_error or active flags change
keep handoff/checkpoint docs current after material observations
investigate only high-confidence official endpoint blockers without enabling production
```

These tasks are not safe without explicit approval:

```text
create production Fly app
create production database
set production secrets
deploy production backend
promote frontend runtime config to production
enable production scheduled polling
set candidate sources active=true
start JP live polling
start KR live-source implementation before the dedicated backend/source path exists
```

## Verification For This Packet

```text
docs-only
git diff --check
no Mix tests required
```

## Guardrails

```text
Do not infer approval from staging success.
Do not infer approval from comments that only ask for more work.
Do not paste secrets into GitHub.
Do not reuse staging DB as production.
Do not enable production scheduled polling during first production smoke.
Do not set candidate sources active=true from observation evidence.
Do not change backend digest JSON response shape.
Do not add public poll UI.
Do not add audit UI.
Do not add public Source Health UI.
Do not claim fixture fallback as live success.
Do not start JP live polling before issue #339 is resolved.
Do not start KR live-source implementation before the dedicated backend/source path exists.
```
