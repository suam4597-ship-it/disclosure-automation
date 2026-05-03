# Stage 6.1 duplicate group action state storage manual smoke

This smoke checklist covers the docs-only Stage 6.1 duplicate group action state and event storage design.

## Expected files

```text
apps/backend/disclosure_api/docs/stage61_duplicate_group_action_state_storage_design.md
apps/backend/disclosure_api/docs/stage61_duplicate_group_action_state_storage_guardrails.md
apps/backend/disclosure_api/docs/stage61_duplicate_group_action_state_storage_manual_smoke.md
```

## Scope smoke

Confirm this PR is docs-only.

It must not add or modify:

```text
runtime code
tests
fixtures
migrations
schema modules
router
controllers
UI code
action endpoints
scheduler code
provider clients
live fetch code
feed/controller behavior
API response behavior
feed response behavior
materializer behavior
canonical mutation behavior
```

## Baseline smoke

Confirm the design names the correct baseline:

```text
base branch: sec-thin-slice-reconcile-v1
base commit: c1ef26f81bcb3401a10a5df9e8a7a90e9562f66f
base source: PR #142 Lock Stage 6.0 duplicate group operator actions
```

## Candidate table smoke

Confirm the design describes internal-only candidate tables:

```text
source_duplicate_group_review_states
source_duplicate_group_action_events
```

Confirm the design does not add migrations or schema modules.

## Review state smoke

Confirm review state storage is bounded and internal only.

Allowed review states:

```text
unknown
confirmed_by_operator
rejected_by_operator
needs_review
cleared
```

Recommended review state uniqueness:

```text
group_id
```

## Action event smoke

Confirm action event storage is bounded and redacted.

Allowed operations:

```text
confirm_duplicate_group
reject_duplicate_group
mark_duplicate_group_needs_review
clear_duplicate_group_review_state
```

Recommended event idempotency uniqueness:

```text
group_id + action_operation + actor_id_hash + idempotency_key_hash
```

## Transaction smoke

Confirm future runtime writer guidance requires:

```text
validate action request before DB write
validate authorization before DB write
validate audit event before DB write
insert or reuse idempotent action event
update review state in same transaction
avoid partial event/state writes
return bounded error on conflict or failure
```

## Public response smoke

Confirm the design says future storage work must not change:

```text
GET /api/events/:event_id
GET /api/events/:event_id/news-overlay
GET /api/feed/digest/latest
GET /api/feed/digest/:digest_date/:edition
item.overlays[]
news_overlays[]
feed item_count
feed ordering
official TDnet fields
official citations
public API envelope
public feed envelope
```

## Canonical no-mutation smoke

Confirm future storage work must not:

```text
mutate canonical_feed_items
create provider canonical feed items
create news-only canonical events
merge official TDnet events
override official TDnet facts
override official citations
mutate news_overlay_attachments
```

## Provider and scheduler smoke

Confirm future storage work must not:

```text
trigger live provider fetch
call provider clients
enqueue scheduler work
read provider credentials
store provider credentials
store provider transport metadata
materialize duplicate groups
materialize overlays
```

## Redaction smoke

Confirm changed files include no non-redacted provider secret values, raw header values, cookie values, raw operator identifiers, raw request identifiers, raw idempotency keys, raw provider bodies, full article text, canonical payloads, or unbounded diagnostics.

## Suggested static checks

No mix test is required for this docs-only design PR unless a reviewer asks for targeted checks.

Suggested check:

```powershell
git diff --name-only c1ef26f81bcb3401a10a5df9e8a7a90e9562f66f...HEAD
```

Expected output should be limited to the three docs files listed above.
