# GlobalPulse Regional Frontend/Backend Mapping Smoke Results

This document records the local frontend/backend region mapping closeout for Europe and the existing non-Europe regional buckets.

This is documentation-only evidence for the mapping change. It does not add runtime backend routes, controllers, migrations, backend JSON response-shape changes, frontend framework changes, login UI, redirects, identity provider callback routes, poll UI, audit UI, public Source Health UI, provider behavior, materializer behavior, canonical behavior, dashboards, alerts, or scheduled live polling.

## Baseline

```text
branch baseline: phase0-foundation
baseline commit: 7f5b88dc11e973b80bf5638eeed16a6ee7bb9d23
backend URL checked: https://globalpulse-backend-staging.fly.dev
frontend target: apps/web/index.html
runtime config target: apps/web/config.js
```

## Mapping Scope

The frontend now consumes the same canonical region buckets emitted by `DisclosureAutomation.Canonicalizer.infer_regions/1` without waiting for a post-load monkey patch.

Canonical buckets covered:

```text
global
us
kr
jp
greater_china
cn
tw
hk
apac
asean
india
anz
eu
eu_north
eu_central
eu_south
uk
ch
other
```

Alias coverage includes:

```text
usa -> us
europe_north -> eu_north
europe_central -> eu_central
europe_south -> eu_south
united_kingdom / gb / great_britain -> uk
switzerland -> ch
korea -> kr
japan -> jp
cn_tw / greaterchina -> greater_china
china / mainland_china -> cn
taiwan -> tw
hong_kong / hongkong -> hk
southeast_asia / south_east_asia -> asean
in -> india
australia_nz / australia / new_zealand -> anz
```

## Staging API Check

```text
GET /api/health: 200
status: ok
repo: up

GET /api/feed/digest/latest?edition=breaking: 200
digest_date: 2026-05-09
edition: breaking
item_count: 3
metadata.fallback_to_fixture: false
observed latest region: india
```

The latest public digest was India-only at the time of this check, so the local render smoke used a bounded synthetic digest payload to exercise Europe and remaining regional buckets without changing backend response shape.

## Local Frontend Smoke

Commands run:

```text
node --check apps/web/config.js
inline index.html script parse smoke
dashboard region render smoke with synthetic digest
```

Render smoke labels verified:

```text
Northern Europe
Central Europe
Southern Europe
Hong Kong
ASEAN
India
Australia/NZ
```

Result:

```text
GLOBALPULSE_REGION_CONFIG_SYNTAX_PASS
GLOBALPULSE_INDEX_INLINE_SCRIPT_PARSE_PASS
GLOBALPULSE_EU_SUBREGION_MAPPING_PASS
GLOBALPULSE_REMAINING_REGION_MAPPING_PASS
GLOBALPULSE_OTHER_REGION_FALLBACK_NOT_USED_FOR_KNOWN_BUCKETS
```

## Backend Validation

Commands run:

```text
python scripts/validate_phase0_artifacts.py
mix deps.get
mix format --check-formatted
MIX_ENV=test mix compile --warnings-as-errors
```

Result:

```text
PHASE0_ARTIFACT_VALIDATE_PASS
BACKEND_FORMAT_CHECK_PASS
BACKEND_TEST_COMPILE_PASS
```

Temporary verification artifacts were removed after validation:

```text
apps/backend/disclosure_api/deps
apps/backend/disclosure_api/_build
apps/backend/disclosure_api/mix.lock
```

## Guardrails Preserved

```text
scheduled live polling unchanged
candidate sources remain manual-only where already configured
JP live polling not promoted
backend digest JSON response shape unchanged
frontend framework added: no
poll UI added: no
audit UI added: no
public Source Health UI added: no
```
