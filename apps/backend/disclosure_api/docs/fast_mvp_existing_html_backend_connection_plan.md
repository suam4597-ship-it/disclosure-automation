# Fast MVP: Existing HTML Backend Connection Plan

This document locks the fast MVP direction for Disclosure Automation.

It exists to prevent workflow drift across future chat sessions and PRs. When a new conversation starts, read this document first and continue from the `Current position` and `Next PR queue` sections unless the project owner explicitly changes the scope.

## 1. Locked fast MVP goal

The fast MVP goal is:

```text
Keep the existing HTML/CSS design as the public website shell.
Connect the existing backend APIs to that shell with small JavaScript changes.
Expose only the existing Source Health operator pages for operations.
Continue production auth/session hardening only where it protects the operator surface.
Avoid broad frontend redesign or new product surfaces until this MVP is closed.
```

This is intentionally narrower than a full product build.

## 2. Baseline evidence and project context

The project already has a public HTML entry shell:

```text
apps/web/index.html
apps/web/styles.css
apps/web/script.js
```

The existing shell should remain the public MVP entry point. The current design has a hero, action buttons, and three card sections. The CSS already defines the visual foundation: `hero`, `container`, `grid`, `card`, and `button`.

The backend already exposes useful routes for the MVP:

```text
GET /api/health
GET /api/feed/hero
GET /api/feed/region/:region_code
GET /api/events/:event_id
GET /api/feed/digest/latest
GET /api/feed/digest/:digest_date/:edition
GET /admin/source-health
GET /admin/source-health/:source_key
GET /api/admin/source-health
GET /api/admin/source-health/:source_key
POST /api/admin/source-health/:source_key/recheck
POST /api/admin/sources/:source_key/poll
```

The Source Health / Poll backend gate stream is already closed out for its scoped backend/internal UI/monitoring/poll guardrails. The current active backend hardening stream is Production Auth / Session Replacement.

Production Auth / Session Replacement progress already includes:

```text
PR #271 Design source health production auth session replacement
PR #272 Add source health production auth contract tests
PR #273 Add source health auth context helper
PR #274 Bridge source health auth context into authorization plugs
PR #275 Use auth context in source health recheck authorization tests
PR #276 Use auth context in source health poll authorization tests
```

## 3. Current position

Current product position under this fast MVP scope:

```text
Fast MVP completion estimate: 45-55%
```

Completed or available:

```text
Existing static HTML shell exists.
Existing CSS design exists.
Existing script.js entry exists.
Backend routes exist for health, feed, digest, events, and source health.
Source Health backend/operator safety work is mostly complete.
Production Auth / Session Replacement is in progress.
```

Still needed:

```text
Connect apps/web/script.js to backend APIs.
Render backend health in the existing HTML shell.
Render feed/digest data in the existing HTML shell.
Add a minimal operator link to /admin/source-health.
Finish Source Health internal UI auth-context migration.
Deny request-param permissions outside the explicit test harness.
Configure frontend -> backend API base URL for deployment.
Add fast MVP smoke checks.
Add fast MVP close-out.
```

## 4. MVP scope

### In scope

```text
Keep apps/web/index.html as the public MVP shell.
Keep apps/web/styles.css mostly unchanged.
Use apps/web/script.js for small fetch/render logic.
Use existing backend API routes before adding any new route.
Display backend health status on the existing page.
Display latest digest/feed data in existing card sections.
Link the public shell to /admin/source-health for operators.
Continue SourceHealthAuthContext migration for operator Source Health pages.
Keep route and response shapes stable unless a small contract PR explicitly allows a change.
```

### Out of scope for this MVP

```text
React/Vue/Next.js frontend rewrite.
New design system.
Large CSS redesign.
Complex navigation rebuild.
Advanced search/filter UX.
Company pages.
Country/market dashboard pages.
User subscription and alert features.
User account dashboard.
Poll UI.
Audit UI.
Public source health UI.
New public Source Health routes.
Provider/materializer/canonical behavior expansion.
Backend response shape changes not required for the existing HTML shell.
```

## 5. Existing HTML preservation rules

The existing HTML/CSS design should be preserved by default.

Allowed changes:

```text
Text copy updates.
Adding id/data-role attributes to existing elements.
Adding small placeholders for API-rendered content.
Adding one operator link to /admin/source-health.
Small script.js rendering functions.
Small CSS utility classes only if unavoidable.
```

Avoid unless explicitly approved:

```text
Changing the overall layout.
Changing color system.
Adding a new framework.
Replacing the card/grid structure.
Adding complex navigation.
Moving away from simple static HTML + JS.
```

## 6. Backend API connection priority

Connect APIs in this order:

```text
1. GET /api/health
2. GET /api/feed/digest/latest
3. GET /api/feed/hero
4. GET /api/feed/region/:region_code
5. GET /api/events/:event_id only after feed item links need detail navigation
```

The frontend JavaScript should be defensive:

```text
Show loading state.
Show empty state.
Show bounded error message.
Never expose raw stack traces or raw backend payloads.
Never assume every optional response field exists.
```

## 7. Operator page scope

Operator surface remains Source Health only:

```text
/admin/source-health
/admin/source-health/:source_key
/api/admin/source-health
/api/admin/source-health/:source_key
/api/admin/source-health/:source_key/recheck
```

Allowed operator behavior:

```text
Source list.
Source detail.
Read-only recheck disabled state.
Recheck-permitted enabled state.
Bounded recheck submit.
Bounded not_found state.
```

Forbidden operator/UI behavior for this MVP:

```text
Poll UI.
Audit UI.
Public source health UI.
Provider fetch controls.
Materializer controls.
Canonical mutation controls.
Queue/worker/payload controls exposed in UI.
Raw/private/canonical material in text or JSON responses.
```

## 8. Production auth/session relation

The existing Production Auth / Session Replacement track remains active, but its fast MVP purpose is narrow:

```text
Protect operator Source Health pages and actions.
Remove request-param permission authority from production behavior.
Keep SourceHealthAuthContext as the bounded handoff between auth/session and Source Health gates.
```

Required next auth work:

```text
Use auth context in source health internal UI recheck action.
Use auth context in source health internal UI recheck submit flow.
Use auth context in source health operator smoke test.
Inventory remaining actor_permissions request-param dependencies.
Deny request-param source health permissions outside explicit test harness.
Connect production session/user/role source when ready.
```

## 9. Drift-prevention rules

Every future PR in this fast MVP track must include this checklist in the PR body:

```markdown
## Fast MVP drift check

- [ ] Keeps existing HTML/CSS shell unless this PR explicitly documents a tiny exception.
- [ ] Does not introduce React/Vue/Next.js or another frontend framework.
- [ ] Uses existing backend routes before adding new routes.
- [ ] Does not add poll UI.
- [ ] Does not add audit UI.
- [ ] Does not add public Source Health UI.
- [ ] Does not change provider/materializer/canonical behavior.
- [ ] Does not change backend response shapes unless explicitly scoped.
- [ ] Keeps Source Health auth/session work limited to operator protection.
- [ ] Updates the `Current position` or `Next PR queue` section if this PR changes the workflow state.
```

Every new chat session should start from this prompt:

```text
Read apps/backend/disclosure_api/docs/fast_mvp_existing_html_backend_connection_plan.md first.
Continue from the Current position and Next PR queue sections.
Do not broaden scope beyond existing HTML backend connection + Source Health operator page unless I explicitly say so.
```

## 10. Stop conditions

Stop and re-scope before coding if a proposed change:

```text
Requires a frontend framework rewrite.
Requires broad CSS redesign.
Requires new public Source Health route.
Adds poll UI.
Adds audit UI.
Adds provider/materializer/canonical controls to a UI.
Changes public API/feed response shapes for convenience only.
Uses request query/body actor_permissions as production authority.
Exposes raw actor/session/request identifiers.
Exposes headers, cookies, tokens, provider credentials, raw payloads, canonical payloads, stack traces, SQL details, or unbounded diagnostics.
Adds duplicate controller modules.
```

## 11. Next PR queue

Preferred small-PR sequence:

```text
PR 1. Design fast MVP existing HTML backend connection plan
PR 2. Add frontend API client for existing HTML shell
PR 3. Render backend health status in existing HTML shell
PR 4. Render backend feed digest in existing HTML shell
PR 5. Link existing HTML shell to source health operator page
PR 6. Use auth context in source health internal UI recheck action
PR 7. Use auth context in source health internal UI recheck submit flow
PR 8. Use auth context in source health operator smoke test
PR 9. Deny request-param source health permissions outside test harness
PR 10. Configure frontend API base URL for fast MVP deployment
PR 11. Add fast MVP smoke tests
PR 12. Add fast MVP close-out
```

Compressed sequence if speed matters:

```text
PR 1. Design fast MVP existing HTML backend connection plan
PR 2. Add frontend API client and health status rendering
PR 3. Render feed digest in existing HTML shell
PR 4. Link operator page and finish source health UI auth context
PR 5. Configure deployment API base URL
PR 6. Add fast MVP smoke and close-out
```

## 12. Immediate next implementation after this docs PR

After this docs-only plan PR, the next implementation PR should be:

```text
Add frontend API client and health status rendering
```

Target files:

```text
apps/web/index.html
apps/web/script.js
```

Allowed changes:

```text
Add stable element IDs for health/feed/digest placeholders.
Add a tiny fetchJson helper.
Call GET /api/health.
Render status into the existing status card.
Show bounded fallback text on failure.
Do not change the CSS unless unavoidable.
```

Suggested validation:

```text
Open apps/web/index.html locally.
Confirm no JavaScript error in the browser console.
Run backend locally if available and confirm /api/health renders.
Stop backend and confirm the page shows a bounded unavailable message rather than breaking.
```

## 13. MVP completion criteria

The fast MVP is complete when:

```text
/ renders the existing HTML design.
/ displays backend health status.
/ displays latest digest/feed data or a safe empty state.
/ links to /admin/source-health for operators.
/admin/source-health and /admin/source-health/:source_key remain bounded operator pages.
Source Health recheck action state uses auth context instead of request-param authority.
Production mode does not trust actor_permissions query/body values.
Frontend can reach backend API in the chosen deployment setup.
Fast MVP smoke checks pass.
A close-out document records the final MVP scope, validation, and remaining future work.
```
