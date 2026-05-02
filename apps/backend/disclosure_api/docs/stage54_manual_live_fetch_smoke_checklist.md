# Stage 5.4 manual live-fetch smoke checklist

This checklist defines what a future manual live-fetch implementation must prove before merge.

This is a documentation-only checklist. It does not add live fetch code, provider clients, credentials, runtime code, tests, schedulers, migrations, routes, feed/controller changes, materializer changes, or canonical feed mutations.

## Scope

```text
stage: Stage 5.4 PR D
scope: manual live-fetch smoke checklist
mode: docs-only
live fetch code: none
provider credentials: none
scheduler changes: none
runtime code: none
```

## Pre-flight guardrail

Before any future manual live-fetch implementation is tested, confirm:

```text
use_live_fetch default remains false
manual trigger is required
scheduler remains disabled
feed/API reads do not trigger live fetch
provider credentials are not stored in repo
full article text storage remains disabled
canonical_feed_mutation=false
news_only_event_creation=false
canonical_fact_override=false
```

## Required environment handling

Future implementation must load credentials only from runtime environment or secret manager-backed runtime config.

Allowed redacted examples in docs:

```text
REDACTED_REUTERS_API_KEY
REDACTED_BLOOMBERG_API_KEY
REDACTED_SUBSCRIPTION_KEY
REDACTED_AUTHORIZATION
```

Forbidden in repository, logs, test output, comments, persisted diagnostics:

```text
real Subscription-Key values
real Authorization header values
real Cookie header values
provider bearer tokens
provider usernames/passwords
signed private URLs
raw request headers
raw provider response bodies
full article text
```

## Manual trigger smoke

A future manual live-fetch implementation should be invoked only through an explicit operator command or admin-only task.

Smoke expectation:

```text
manual trigger required: PASS
no scheduler path invoked: PASS
no GET request side effect: PASS
no feed/API render side effect: PASS
bounded timeout configured: PASS
bounded retry configured: PASS
```

## Provider request smoke

Verify the request layer:

```text
timeout_ms <= 5000: PASS
retry_count <= 1: PASS
request headers not logged: PASS
credentials not logged: PASS
cookies not logged: PASS
signed URLs not logged: PASS
response body not logged: PASS
```

## Provider response normalization smoke

Verify provider responses normalize into metadata-only output before staging:

```text
provider present: PASS
source_key present: PASS
article_external_id present: PASS
canonical_event_id present: PASS
title metadata present: PASS
published_at metadata present: PASS
url metadata present: PASS
storage_mode=metadata_only: PASS
overlay_mode=attach_only: PASS
canonical_feed_mutation=false: PASS
news_only_event_creation=false: PASS
canonical_fact_override=false: PASS
```

## Official match smoke

Verify direct official match evidence before visible staging:

```text
matchedCanonicalEventId equals official TDnet event id: PASS
matchedOfficialStableExternalId equals official stable external id: PASS
missing match remains hidden or rejected: PASS
ambiguous match remains hidden or rejected: PASS
```

## Raw staging smoke

Verify live provider metadata follows the same raw staging contract as the offline seam:

```text
raw document staged: PASS
raw event staged: PASS
raw document idempotency: PASS
raw event idempotency: PASS
stable overlay id: PASS
canonical_feed_mutation=false: PASS
news_only_event_creation=false: PASS
canonical_fact_override=false: PASS
no full article text stored: PASS
no request headers stored: PASS
no credentials stored: PASS
```

## Failure isolation smoke

Simulate provider failure and confirm:

```text
TDnet ingestion still passes: PASS
provider timeout does not remove existing overlays: PASS
provider error does not mutate official canonical item: PASS
provider error does not create provider canonical feed item: PASS
provider error diagnostics are redacted: PASS
feed/API responses continue serving existing materialized overlays: PASS
```

## Canonical no-mutation smoke

Verify:

```text
canonical_feed_items where event_id = official TDnet event id remains 1
canonical_feed_items where event_id = provider overlay id remains 0
official TDnet headline/title unchanged
official TDnet published_at unchanged
official TDnet official_source_url unchanged
official TDnet stable_external_id unchanged
official citations unchanged
```

## Response shape smoke

Verify locked response shapes remain unchanged:

```text
read model item.overlays[] shape unchanged: PASS
API item.overlays[] shape unchanged: PASS
feed news_overlays[] shape unchanged: PASS
feed item_count unchanged: PASS
feed item ordering unchanged: PASS
official TDnet fields unchanged: PASS
citation separation unchanged: PASS
```

## Redaction smoke

Search changed files, logs, test output, persisted diagnostics, comments, and manual smoke notes.

Must not expose:

```text
Subscription-Key values
Authorization header values
Cookie header values
provider credentials
request headers
response headers
signed private URLs
full article text
raw provider response bodies
```

Allowed only in negative/redacted contexts:

```text
REDACTED_SUBSCRIPTION_KEY
REDACTED_AUTHORIZATION
REDACTED_COOKIE
```

## Required regression set for future implementation

Future manual live-fetch implementation should run new live-fetch tests plus:

```powershell
$env:MIX_ENV='test'; mix.bat test test/stage54_offline_provider_staging_test.exs
$env:MIX_ENV='test'; mix.bat test test/stage54_provider_ingestion_boundary_test.exs
$env:MIX_ENV='test'; mix.bat test test/stage53_multi_overlay_response_contract_test.exs
$env:MIX_ENV='test'; mix.bat test test/stage52_news_overlay_attachment_read_path_test.exs
$env:MIX_ENV='test'; mix.bat test test/stage52_news_overlay_attachment_materializer_test.exs
$env:MIX_ENV='test'; mix.bat test test/stage5_news_overlay_feed_visible_test.exs
$env:MIX_ENV='test'; mix.bat test test/stage5_news_overlay_api_exposure_test.exs
$env:MIX_ENV='test'; mix.bat test test/jp_tdnet_timely_disclosure_runtime_idempotency_test.exs
$env:MIX_ENV='test'; mix.bat test test/jp_tdnet_timely_disclosure_http_smoke_test.exs
```

## PASS criteria

```text
manual trigger only: PASS
scheduler disabled: PASS
no GET side effects: PASS
bounded timeout/retry: PASS
metadata-only normalization: PASS
raw staging idempotency: PASS
canonical no-mutation: PASS
response shapes unchanged: PASS
failure isolation: PASS
redaction check: PASS
no full article text storage: PASS
no credentials in repo/logs/output: PASS
```
