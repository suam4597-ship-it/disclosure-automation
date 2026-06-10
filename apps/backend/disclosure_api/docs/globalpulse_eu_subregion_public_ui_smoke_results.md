# GlobalPulse EU Subregion Public UI Smoke Results

This document records the successful public GitHub Pages browser smoke for separate Europe disclosure subregion rendering.

This is documentation-only. It does not add runtime code, routes, controllers, templates, migrations, backend response-shape changes, frontend static shell changes, frontend framework changes, login UI, redirects, identity provider callback routes, poll UI, audit UI, public Source Health UI, provider behavior, materializer behavior, canonical behavior, dashboards, alerts, or integrations.

## Baseline

```text
frontend: GitHub Pages
frontend URL: https://suam4597-ship-it.github.io/disclosure-automation/
backend: https://globalpulse-backend-staging.fly.dev
backend app: globalpulse-backend-staging
relevant PR: #344 Render Europe disclosure subregions separately
relevant merge commit: 2f3b8106436dff7a2fd140032cda6e1aabe67e70
smoke source: user-provided browser verification and screenshot
screenshot path on local machine: C:/Users/suam4/AppData/Local/Temp/globalpulse-eu-subregions-public-smoke.png
```

## Related Work

```text
PR #341 Add three Europe disclosure source fixtures
PR #342 Register regional fixture staging poll workflow
PR #343 Record EU three-region fixture poll smoke
PR #344 Render Europe disclosure subregions separately
```

## CI Status for PR #344 Merge Commit

GitHub connector verification for commit `2f3b8106436dff7a2fd140032cda6e1aabe67e70`:

```text
Phase 0 validate: success
Phase 0 report: success
Phase 1 backend verify: success
Phase 1 runtime smoke: success
Phase 1 backend report: success
Phase 1 backend diagnose: success
Phase 1 backend trace: success
```

## Deployment and Data Baseline

Reported deployment state:

```text
GitHub Pages deploy: success
Fly staging redeploy: success
EU fixture poll: success
```

EU fixture source poll results:

```text
eu_north_disclosures: PASS, 2 items
eu_central_disclosures: PASS, 2 items
eu_south_disclosures: PASS, 2 items
```

Fly digest result:

```text
digest_date: 2026-05-08
edition: breaking
item_count: 12
```

## Public Browser Smoke Result

Public URL:

```text
https://suam4597-ship-it.github.io/disclosure-automation/
```

Observed browser UI:

```text
Backend ok: PASS
All: 12
공시: 9
뉴스: 3
```

Europe subregion rendering:

```text
Northern Europe: PASS
Central Europe: PASS
Southern Europe: PASS
```

The existing generic EU section is also present:

```text
EU Europe: PASS_EXPECTED
```

Rationale:

```text
EU Europe remains expected because the original Europe Market News source is still present separately from the new three Europe disclosure source buckets.
```

## Current Conclusion

```text
GLOBALPULSE_PUBLIC_PAGES_PASS
GLOBALPULSE_BACKEND_CONNECTED_PASS
EU_NORTH_DISCLOSURE_UI_PASS
EU_CENTRAL_DISCLOSURE_UI_PASS
EU_SOUTH_DISCLOSURE_UI_PASS
EU_GENERIC_MARKET_NEWS_SECTION_STILL_PRESENT_EXPECTED
GLOBALPULSE_EU_THREE_REGION_PUBLIC_UI_READY
```

## Guardrails

The public UI smoke did not require or introduce:

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

The EU three-region fixture layer is now visible in the public GlobalPulse UI.

Recommended next options:

```text
1. Verify one real EU company-disclosure live endpoint candidate.
2. Start CN/TW regional fixture/live-source verification.
3. Keep JP deferred and tracked through issue #339 until source authority is decided.
```

Live EU endpoints remain blocked until verified by the EU live source verification contract.
