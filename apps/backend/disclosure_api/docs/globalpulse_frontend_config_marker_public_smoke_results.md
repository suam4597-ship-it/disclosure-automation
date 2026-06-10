# GlobalPulse Frontend Config Marker Public Smoke Results

Date: 2026-05-11 KST

This document records the public smoke result after adding the bounded staging runtime config marker.

This is smoke documentation. It does not change frontend runtime behavior, backend runtime behavior, routes, public API response shapes, source activation, production polling, secrets, hosting configuration, public poll UI, audit UI, or public Source Health UI.

## Conclusion

```text
GLOBALPULSE_PUBLIC_PAGES_CONFIG_MARKER_PASS
GLOBALPULSE_PUBLIC_BROWSER_SMOKE_PASS
GLOBALPULSE_BACKEND_CONNECTED_PASS
GLOBALPULSE_DIGEST_LIVE_PASS
GLOBALPULSE_PUBLIC_WEB_SMOKE_WORKFLOW_MARKER_READY
PRODUCTION_CONFIG_PROMOTION_NOT_DONE
```

## References

```text
config marker PR: #550 Add GlobalPulse frontend config version marker
config marker commit: c3a4b0edcebe776f60a42d9350c2787146a6b1e6
Pages deploy workflow run: 25672615922
Pages deploy conclusion: success
main workflow marker PR: #551 Update public web smoke config marker checks on main
main workflow marker commit: 20c2cf42585afb71e55e9954cbc51b8cc8f0b1dc
```

## Public HTTP Smoke

Targets:

```text
Pages URL: https://suam4597-ship-it.github.io/disclosure-automation/
config URL: https://suam4597-ship-it.github.io/disclosure-automation/config.js
backend URL: https://globalpulse-backend-staging.fly.dev
edition: breaking
```

Result:

```text
GET Pages: 200
GET config.js: 200
configVersion marker: staging-20260511-1 present
runtime config marker: present
allowQueryParamOverride marker: present
backend health: status=ok, service=disclosure_automation
backend digest: edition=breaking
backend digest item_count: 12
metadata.fallback_to_fixture: false
```

## Browser Smoke

Browser URL:

```text
https://suam4597-ship-it.github.io/disclosure-automation/?codexCacheBust=staging-20260511-1
```

Observed:

```text
title: GlobalPulse
GlobalPulse shell visible: yes
Backend ok visible: yes
Backend digest live visible: yes
Source Health link visible: yes
HKEX / Hong Kong / CN-TW regional content visible: yes
fatal console errors: none observed
```

## Workflow Status

The public web smoke workflow is active on the default branch and now contains the config marker checks.

```text
workflow: GlobalPulse public web smoke
workflow file: .github/workflows/globalpulse-public-web-smoke.yml
workflow id: 274668919
first workflow_dispatch run: pending
```

The Codex browser session was not authenticated to GitHub, so the `Run workflow` button was not available from this environment. The next operator with an authenticated GitHub browser session should run the workflow manually and record the workflow run result.

## Guardrails

```text
This is still staging config.
Production backend URL is not configured.
Production frontend config is not promoted.
Production scheduled polling is not enabled.
Candidate sources are not promoted active=true.
Backend digest JSON response shape is unchanged.
Public poll UI is not added.
Audit UI is not added.
Public Source Health UI is not added.
```
