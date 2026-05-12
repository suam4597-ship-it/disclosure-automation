# GlobalPulse Production Frontend Empty-State Smoke Checklist

Date: 2026-05-12 KST

This document defines the frontend smoke checklist for a future production launch where the first approved production digest may be empty.

This is docs-only. It does not change frontend code, frontend config, backend runtime behavior, routes, public API response shapes, production infrastructure, production scheduled polling, source activation, source promotion, public poll UI, audit UI, or public Source Health UI.

## Status

```text
PRODUCTION_FRONTEND_EMPTY_STATE_SMOKE_CHECKLIST_ADDED
FRONTEND_CONFIG_NOT_PROMOTED
PRODUCTION_BACKEND_NOT_CREATED
PRODUCTION_SCHEDULED_POLLING_NOT_ENABLED
SOURCE_CANDIDATES_NOT_PROMOTED
```

## When To Use

Use this checklist only after issue #561 explicitly records:

```text
FIRST_PRODUCTION_DIGEST_EMPTY_OK: yes
approved production backend URL
approved production frontend URL
approved production CORS origins
rollback owner
```

If `FIRST_PRODUCTION_DIGEST_EMPTY_OK` is missing or `no`, do not use an empty digest as an acceptable launch state.

## Preconditions

Before frontend empty-state smoke:

```text
production backend health smoke passed
production digest endpoint returns bounded response
production CORS smoke passed from approved frontend origin
frontend configVersion is known
rollback commit is known
production scheduled polling remains disabled unless separately approved
source promotion approvals remain source-by-source in issue #565
```

The empty state is a launch-state decision. It is not source success, not schedule approval, and not evidence of production data coverage.

## Backend Digest Facts To Record

Record:

```text
GET /api/feed/digest/latest?edition=breaking status
item_count if present
metadata.fallback_to_fixture if present
generated_by if present
FIRST_PRODUCTION_DIGEST_EMPTY_OK value
production scheduled polling state
source promotion approval state
```

Acceptable empty-state backend facts:

```text
HTTP 200 bounded JSON with item_count=0
or bounded documented empty/not_found response if approved
metadata.fallback_to_fixture is absent or false
no raw provider/auth/session/request/private material
```

Stop if:

```text
metadata.fallback_to_fixture=true
raw fixture payload is presented as production data
response shape expands beyond the public digest contract
raw provider/auth/session/request/private material appears
```

## Frontend Visual Smoke

From the approved production frontend URL, verify:

```text
page loads with HTTP 200
GlobalPulse header is visible
configVersion matches the intended production value
backend status card shows a bounded successful or unavailable state
digest area renders a bounded empty-state message
digest area does not show a raw JSON dump
page layout remains stable on desktop viewport
page layout remains stable on mobile viewport if checked
no fatal console error
no secret/token/session/private material appears in DOM text
no public poll UI appears
no audit UI appears
no public Source Health UI appears
```

The empty-state copy should be calm and bounded. It should not imply that production data is populated or that all market coverage is complete.

## Browser Console Checks

Record only bounded console facts:

```text
fatal JavaScript error: yes/no
CORS error: yes/no
failed health fetch: yes/no
failed digest fetch: yes/no
raw/private material visible in console: yes/no
```

Do not paste full response bodies, secrets, cookies, auth headers, or provider payloads into PRs or issue comments.

## Public Web Smoke Workflow

If using the GitHub Actions smoke:

```text
workflow: GlobalPulse public web smoke
pages_url: approved production frontend URL
backend_url: approved production backend URL
edition: breaking
```

Record:

```text
workflow run id
pages status
config status
configVersion
health status
digest status
digest item_count
fallback_to_fixture
artifact name
```

If the current smoke workflow requires non-empty items, do not weaken that check silently. Record a separate empty-state smoke result or add an explicit approved-empty mode in a focused workflow PR.

## Pass Result

The production frontend empty-state smoke can pass only with:

```text
PRODUCTION_FRONTEND_EMPTY_STATE_APPROVED
PRODUCTION_FRONTEND_EMPTY_STATE_RENDERED
PRODUCTION_DIGEST_NOT_POPULATED_YET
NO_FIXTURE_FALLBACK_CLAIMED_AS_PRODUCTION_DATA
NO_PUBLIC_POLL_UI
NO_AUDIT_UI
NO_PUBLIC_SOURCE_HEALTH_UI
ROLLBACK_READY
```

## Failure Handling

Use `globalpulse_production_rollback_stop_checklist.md` if any of these fail:

```text
frontend configVersion mismatch
backend health display broken
digest empty state does not render
digest fetch crashes the UI
CORS error appears
fixture fallback appears
public response shape expands unexpectedly
secret/private material appears
fatal browser error appears
```

Rollback should be a frontend config revert or backend release rollback, not a data mutation to make the digest look populated.

## Guardrails

```text
Do not promote frontend config without production approval.
Do not enable production scheduled polling just to fill the empty state.
Do not set candidate sources active=true without source-specific approval.
Do not change backend digest JSON response shape.
Do not hide fixture fallback as production data.
Do not add public poll UI.
Do not add audit UI.
Do not add public Source Health UI.
Do not add frontend framework dependencies.
Do not start JP live polling before issue #339 is resolved.
Do not start KR live-source implementation before the dedicated backend/source path exists.
```

## Next Gate

This checklist is ready for the future production frontend promotion path only after issue #561 provides the required values. Until then, keep using staging public web smoke and scheduled observation docs.
