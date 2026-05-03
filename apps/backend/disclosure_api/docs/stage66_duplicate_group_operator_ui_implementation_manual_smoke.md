# Stage 6.6 duplicate group operator UI implementation manual smoke

This manual smoke checklist validates the Stage 6.6 duplicate group operator UI implementation design.

Stage 6.6 PR A is docs-only. It does not add frontend code, backend runtime code, tests, fixtures, migrations, schema modules, router changes, controllers, templates, UI routes, action endpoint changes, scheduler work, provider clients, live fetch behavior, public API/feed behavior, materializer behavior, or canonical mutations.

## Baseline

```text
base branch: sec-thin-slice-reconcile-v1
base commit: 686a3d3be22b32c7f0bdd9ebe7b3b2bbdf6ccbd7
base source: PR #160 Lock duplicate group operator runbook
stage: Stage 6.6 PR A duplicate group operator UI implementation design
status: docs-only
```

## Expected changed files for this PR

This design PR should change only these files:

```text
apps/backend/disclosure_api/docs/stage66_duplicate_group_operator_ui_implementation_design.md
apps/backend/disclosure_api/docs/stage66_duplicate_group_operator_ui_implementation_guardrails.md
apps/backend/disclosure_api/docs/stage66_duplicate_group_operator_ui_implementation_manual_smoke.md
```

## Static changed-file check

Suggested command:

```powershell
git diff --name-only 686a3d3be22b32c7f0bdd9ebe7b3b2bbdf6ccbd7...HEAD
```

Expected output:

```text
apps/backend/disclosure_api/docs/stage66_duplicate_group_operator_ui_implementation_design.md
apps/backend/disclosure_api/docs/stage66_duplicate_group_operator_ui_implementation_guardrails.md
apps/backend/disclosure_api/docs/stage66_duplicate_group_operator_ui_implementation_manual_smoke.md
```

If any runtime, router, controller, template, frontend, test, fixture, migration, schema, scheduler, provider, live-fetch, feed, API, materializer, or canonical file appears, stop and re-scope the PR.

## Documentation scope check

Verify the design records:

```text
Stage 6.6 PR A is docs-only
baseline commit is PR #160 merge commit
next implementation PR is a minimal internal/admin shell route PR
existing JSON APIs remain the only data/action dependencies
future UI routes are /admin/duplicate-groups and /admin/duplicate-groups/:group_id
future UI routes remain distinct from /api routes
current app is JSON-only and should not assume an existing browser/template/asset stack
a dedicated UI shell controller is preferred over reusing AdminDuplicateGroupController
```

## Locked route dependency check

Verify the design references only locked read routes:

```text
GET /api/admin/duplicate-groups
GET /api/admin/duplicate-groups/:group_id
```

Verify the design references only locked action routes:

```text
POST /api/admin/duplicate-groups/:group_id/confirm
POST /api/admin/duplicate-groups/:group_id/reject
POST /api/admin/duplicate-groups/:group_id/mark-review
POST /api/admin/duplicate-groups/:group_id/clear-review-state
```

No new read/action/write API routes should be introduced by this design.

## Candidate UI route check

Verify the design allows only these future internal/admin UI routes:

```text
GET /admin/duplicate-groups
GET /admin/duplicate-groups/:group_id
```

Verify the design forbids public route namespaces:

```text
/public/duplicate-groups
/api/public/duplicate-groups
/api/events duplicate group fields
/api/feed duplicate group fields
```

## PR 162 implementation-readiness check

Verify the design defines PR 162 as shell-only and excludes list/detail/action functionality.

PR 162 expected candidate files:

```text
apps/backend/disclosure_api/lib/disclosure_automation_web/router.ex
apps/backend/disclosure_api/lib/disclosure_automation_web/controllers/admin_duplicate_group_ui_controller.ex
apps/backend/disclosure_api/test/stage66_duplicate_group_operator_ui_shell_route_test.exs
apps/backend/disclosure_api/docs/stage66_duplicate_group_operator_ui_shell_route_manual_smoke.md
```

Verify PR 162 is expected to test:

```text
/admin/duplicate-groups returns an internal shell
/admin/duplicate-groups/:group_id returns an internal shell
shell response is text/html
shell embeds no raw/private identifiers
shell does not call read projection or action writer code
existing JSON API behavior remains unchanged
```

## List screen design check

Verify the future list screen is limited to:

```text
GET /api/admin/duplicate-groups
```

Allowed filters:

```text
confidence
source_key
member_kind
redaction_status
limit
```

Allowed list fields:

```text
group_id
confidence
source_keys
match_reasons
member_count
has_official_tdnet_event
has_provider_overlay
redaction_status
review_state_summary.review_state
review_state_summary.last_action_operation
review_state_summary.reviewed_at
```

Verify list screen excludes:

```text
action_event_summary
raw actor identifiers
raw request identifiers
raw idempotency keys
provider payloads
canonical payloads
full article text
unbounded diagnostics
```

## Detail screen design check

Verify the future detail screen is limited to:

```text
GET /api/admin/duplicate-groups/:group_id
```

Allowed detail sections:

```text
group summary
member summary table
review_state_summary
latest-five action_event_summary
action control placeholder area
redaction/guardrail notice
```

Verify detail screen preserves show-only latest-five action event summary behavior.

## Action control design check

Verify action controls map exactly to locked routes:

```text
Confirm duplicate group -> POST /api/admin/duplicate-groups/:group_id/confirm
Reject duplicate group -> POST /api/admin/duplicate-groups/:group_id/reject
Mark needs review -> POST /api/admin/duplicate-groups/:group_id/mark-review
Clear review state -> POST /api/admin/duplicate-groups/:group_id/clear-review-state
```

Verify the design forbids sending an `action_operation` field that could override route-derived operation.

## Action request allowlist check

Allowed future action request fields:

```text
actor_id_hash
actor_permissions
roles
request_id_hash
idempotency_key_hash
operator_reason_redacted
result_status
redaction_status
pre_review_state
post_review_state
failure_code
created_at
```

Forbidden future action request material:

```text
raw actor identifiers
raw request identifiers
raw idempotency keys
unredacted operator reasons
provider payloads
full article text
canonical payloads
private transport material
unbounded diagnostics
```

## Authorization check

Verify the design preserves:

```text
authenticated actor required
operator or admin role required for shell access
duplicate_group:read permission required for list/detail data
action-specific permissions required for action controls
backend authorization remains authoritative
read-only permission does not authorize actions
```

## Idempotency check

Verify the design preserves locked idempotency identity:

```text
group_id + action_operation + actor_id_hash + idempotency_key_hash
```

Verify the design states:

```text
same intended action retries reuse the same idempotency key hash
new intended actions use a new idempotency key hash
UI duplicate-click prevention is advisory and backend idempotency remains authoritative
```

## Public response-shape check

Verify the design says future UI work must not change:

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

Verify public duplicate group review/action state fields remain absent.

## Canonical no-mutation check

Verify the design says future UI work must not:

```text
mutate canonical_feed_items
create provider canonical feed items
create news-only canonical events
merge official TDnet events
override official TDnet facts
override official citations
mutate news_overlay_attachments
```

## Provider, scheduler, and materializer check

Verify the design says future UI work must not:

```text
trigger live provider fetch
call provider clients
enqueue scheduler work
store private provider material
materialize duplicate groups
materialize overlays
change materializer behavior
```

## Redaction check

Search changed docs for forbidden raw/private material.

Suggested command:

```powershell
git grep -n -E "raw actor|raw request|raw idempotency|provider payload|canonical payload|full article text|SQL detail|cookie|secret" -- apps/backend/disclosure_api/docs/stage66_duplicate_group_operator_ui_implementation_*.md
```

Expected result: only guardrail/checklist references to forbidden material, no actual raw/private values.

## Test command

No mix test run is required for this docs-only design PR unless a reviewer asks for targeted checks.

If a reviewer requests a smoke check, run the changed-file check above and confirm no runtime files changed.

## Stop conditions

Stop and re-scope this PR if it changes any of these:

```text
frontend code
backend runtime code
tests
fixtures
migrations
schema modules
router
controllers
templates
UI routes
action endpoints
scheduler code
provider clients
live fetch code
feed/controller behavior
public API response behavior
public feed response behavior
materializer behavior
canonical mutation behavior
```
