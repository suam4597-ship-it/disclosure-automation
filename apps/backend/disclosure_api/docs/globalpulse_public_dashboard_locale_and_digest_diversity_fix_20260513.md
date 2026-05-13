# GlobalPulse Public Dashboard Locale And Digest Diversity Fix

Date: 2026-05-13 KST

This document records the fix for two public dashboard issues observed on the live Pages UI:

```text
1. Public dashboard chrome still showed several English labels.
2. Latest breaking digest rendered only India rows after India NSE produced the newest digest_date.
```

## Cause

The public dashboard shell was already `lang=ko`, but many static labels remained English:

```text
Backend Snapshot
Region Mix
Top Importance
Delivery Schedule
Backend digest live
Backend Connected
Priority / Importance
```

The digest diversity issue came from backend latest-digest selection semantics. `GET /api/feed/digest/latest?edition=breaking` selected the newest `digest_date` first, then diversified only inside that one date. When the newest date was populated by India NSE only, the candidate pool itself was India-only, so the public top-N view rendered India only.

## Fix

Frontend:

```text
apps/web/index.html
apps/web/config.js
```

Changes:

```text
dashboard chrome labels localized to Korean
region labels localized to Korean
filter labels localized to Korean
source labels mapped for the major staging sources
status rail wraps instead of showing a horizontal scrollbar
button text no longer wraps vertically
```

Backend:

```text
apps/backend/disclosure_api/lib/disclosure_automation/pipeline.ex
```

Changes:

```text
latest digest now builds candidates from recent digest dates, default 5
date-specific digest endpoint remains date-specific
existing top_n field and item response shape remain unchanged
existing max_per_source and max_per_region diversity caps remain in place
```

This keeps the public JSON response shape stable while making the latest public dashboard less likely to collapse to one region when one source has the newest same-day feed.

## Important Product Boundary

Live source item titles and summaries remain source-language content. For example, India NSE and HKEX official feeds commonly provide English issuer titles and summaries. This fix localizes the GlobalPulse dashboard interface and source labels; it does not add automatic translation of official disclosure text.

Automatic translation would be a separate feature and should have its own source-text, audit, latency, and cost policy before being enabled.

## Validation

```text
node --check apps/web/config.js: pass
inline apps/web/index.html script syntax check: pass
MIX_ENV=test mix.bat compile --warnings-as-errors: pass
local browser smoke with mocked multi-region digest: pass
local browser console fatal errors: none observed
```

## Guardrails

```text
backend digest JSON response shape unchanged
date-specific digest route remains date-specific
production scheduled polling not enabled
candidate sources not set active=true
public poll UI not added
public Source Health UI not added
frontend framework not added
automatic translation not added
```
