# Stage 5.6 manual trigger credential and redaction checklist

This checklist defines credential sourcing and redaction requirements for any future operator-only manual provider invocation.

This is a documentation-only checklist. It does not add runtime trigger code, tests, fixtures, migrations, schema changes, scheduler code, provider clients, live fetch code, routes, feed/controller changes, materializer changes, API behavior changes, or canonical feed mutations.

## Credential source policy

Future implementation must source credentials only from runtime environment or secret-manager backed runtime configuration.

Allowed repository placeholders:

```text
REDACTED_PROVIDER_KEY
REDACTED_PROVIDER_TOKEN
REDACTED_SUBSCRIPTION_KEY
```

Forbidden in repository files, tests, fixtures, docs, logs, persisted diagnostics, and comments:

```text
real provider keys
real provider tokens
subscription key values
authorization values
cookie values
signed private URLs
request headers
response headers
```

## Required redaction boundaries

Future manual invocation must redact before each boundary:

```text
operator input validation
provider request construction
provider response parsing
adapter result construction
Stage54ProviderIngestionBoundary payload
Stage54-compatible raw staging
Stage55 provider health evaluation
audit or diagnostic output
```

## Request redaction policy

Request metadata may record only:

```text
provider
source_key
canonical_event_id
operator_reason
transport_mode
timeout_ms
retry_count
request_id_hash
started_at
```

Request metadata must not record:

```text
credentials
request headers
cookies
authorization values
signed private URLs
```

## Response redaction policy

Response metadata may record only:

```text
status_code
retry_count
timeout
error_class
fetched_at
request_id_hash
redaction_status
manual_review_reason
```

Response metadata must not record:

```text
response headers
raw response body
full article text
provider credentials
signed private URLs
unbounded error payloads
```

## Error redaction policy

Provider errors must be bounded and redacted.

Allowed error data:

```text
error_class
status_code
timeout
retry_count
request_id_hash
redaction_status
manual_review_reason
```

Forbidden error data:

```text
raw error body
stack trace with headers
credentials
request headers
response headers
raw response body
full article text
signed private URLs
```

## Health redaction policy

Provider health updates must use Stage 5.5 safe state rules.

Allowed health states:

```text
unknown
healthy
degraded
rate_limited
timeout
failed
paused
redaction_violation
manual_review_required
```

Redaction failure must result in:

```text
redaction_violation
manual review required
no visible provider overlay creation
no canonical mutation
```

## Log redaction policy

Future implementation must ensure logs do not include:

```text
credentials
request headers
response headers
raw response bodies
full article text
signed private URLs
```

Logs may include:

```text
provider
source_key
transport_mode
status_code
error_class
retry_count
timeout
redaction_status
request_id_hash
```

## Review checklist for future implementation

Before merge, verify:

```text
no real provider credentials in repo
no provider credentials in test fixtures
no request headers in persisted payloads
no response headers in persisted payloads
no raw response body in persisted payloads
no full article text in persisted payloads
no signed private URLs in persisted payloads
strict redaction grep passes for changed files
operator logs are redacted
health diagnostics are redacted
adapter output is metadata-only
canonical_feed_mutation=false
news_only_event_creation=false
canonical_fact_override=false
```

## Stop conditions

Do not merge a future manual trigger implementation if it:

```text
stores credentials
logs credentials
logs request headers
logs response headers
logs raw response body
stores full article text
stores signed private URLs
allows live fetch by default
allows scheduler-triggered invocation
mutates canonical feed items
creates provider canonical feed items
creates news-only canonical events
changes locked feed/API response shapes unexpectedly
fails changed-file redaction checks
```
