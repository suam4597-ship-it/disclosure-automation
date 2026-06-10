# GlobalPulse Source Production Promotion Decision Template

Date: 2026-05-12 KST

This document is a template for future docs-only PRs that record source-by-source production promotion decisions.

This is template-only. It does not set sources `active=true`, enable production scheduled polling, create or change workflows, create production infrastructure, deploy production, change backend runtime behavior, change routes, change public API response shapes, change frontend config, add public poll UI, add audit UI, or add public Source Health UI.

## Template Status

```text
SOURCE_PRODUCTION_PROMOTION_DECISION_TEMPLATE_ADDED
NO_SOURCE_PROMOTED
NO_PRODUCTION_SCHEDULE_ENABLED
NO_RUNTIME_CHANGE
```

## Required Approval Source

Do not use this template as approval by itself.

Each source decision must link to an explicit approval block in:

```text
https://github.com/suam4597-ship-it/disclosure-automation/issues/565
```

Required approval block:

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

If any required field is missing, keep the source blocked.

## Decision Record Fields

For each approved source, record:

```text
source_key:
region:
market/country:
source authority:
endpoint contract doc:
parser contract doc:
staging smoke result docs:
scheduled observation docs:
latest accepted run id:
records_seen / records_inserted summary:
metadata.fallback_to_fixture:
public digest visibility evidence:
source-health state:
approved cadence:
rate-limit policy:
rollback/disable path:
operator approver:
approval comment id:
```

## Required Evidence

Minimum evidence before promotion:

```text
official or accepted source authority
machine-readable endpoint contract
parser/source contract
staging live smoke with metadata.fallback_to_fixture=false
accepted observation run count
bounded failure count
source-health reachable or bounded reason if not applicable
public digest visibility if required by approval
rollback/disable path
production backend/frontend smoke status if required
```

Manual staging evidence is not production approval by itself.

## Approval Outcomes

If approved:

```text
SOURCE_PRODUCTION_PROMOTION_APPROVED_FOR_<source_key>
PRODUCTION_CADENCE_APPROVED_FOR_<source_key>
ROLLBACK_DISABLE_PATH_RECORDED_FOR_<source_key>
```

If rejected or incomplete:

```text
SOURCE_PRODUCTION_PROMOTION_BLOCKED_FOR_<source_key>
MISSING_APPROVAL_FIELD_<field>
SOURCE_REMAINS_STAGING_ONLY
```

Do not mark a source as production-ready if the approval says `no`, is ambiguous, or only asks for more observation.

## Implementation Boundary After Decision

This template records the decision only. A later implementation PR may be required to:

```text
enable a production schedule
set a production-specific source allowlist
promote frontend labeling
adjust source-health monitoring thresholds
```

That later PR must remain source-scoped and must not batch-promote unrelated sources.

## Rollback And Disable Path

Every approved source must include:

```text
how to disable production polling for this source
how to stop the source without affecting staging observation
how to verify digest/source-health after disable
who owns rollback
what evidence triggers rollback
```

Do not use canonical feed mutation as rollback.

## Public Response Boundary

Promotion must not change:

```text
public digest JSON shape
/api/health shape
frontend shell layout
public poll UI
public Source Health UI
audit UI
```

If a source introduces new item fields, they must remain bounded and compatible with the existing public digest contract.

## Source-Specific Guardrails

```text
SEC: live baseline exists, but production schedule still requires explicit production approval.
HKEX: continue observation until the successful-run gate is reached and approved.
India NSE: use accepted scheduled observations only; do not infer all-market coverage from latest-window rows.
EU canary: do not batch-promote all EU sources unless the batch is explicitly approved.
Denmark DFSA OAM: repeated staging evidence is required before promotion.
JP: blocked until issue #339 resolves source authority.
KR: deferred until the dedicated backend/source path exists.
```

## PR Title Template

Use:

```text
Record GlobalPulse source production promotion decision for <source_key>
```

For a batch decision, use only if issue #565 explicitly approves a batch:

```text
Record GlobalPulse source production promotion decision for <batch_name>
```

## Guardrails

```text
Do not set candidate sources active=true in this decision PR.
Do not enable production scheduled polling in this decision PR.
Do not create or change GitHub Actions workflows in this decision PR.
Do not create production infrastructure.
Do not change backend digest JSON response shape.
Do not add public poll UI.
Do not add audit UI.
Do not add public Source Health UI.
Do not claim fixture fallback as live or production success.
Do not fetch PDF/attachment/detail bodies as part of promotion evidence.
Do not start JP live polling before issue #339 is resolved.
Do not start KR live-source implementation before the dedicated backend/source path exists.
```
