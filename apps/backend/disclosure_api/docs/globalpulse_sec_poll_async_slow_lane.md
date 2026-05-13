# GlobalPulse SEC Poll Async Slow Lane

Date: 2026-05-14

## Result

GlobalPulse now keeps the normal SEC poll path available while moving heavier SEC sources onto a bounded async slow lane.

This is intended to reduce Fly proxy timeout and memory pressure without increasing Fly machine size first.

## Runtime Shape

- `source_polling` queue concurrency is reduced to `2`.
- `source_polling_slow` queue is added with concurrency `1`.
- Sources with `poll_async_default: true` return a bounded `202 accepted` enqueue response from the poll API.
- Existing lightweight/manual sync sources remain synchronous unless `async=true` is requested.
- `async=false` can still force a synchronous manual poll for debugging.

## SEC Heavy Source Bounds

The following source config fields are now used for heavy SEC live detail fetches:

- `poll_async_default`
- `poll_queue`
- `max_items_per_poll`
- `detail_fetch_limit`
- `detail_fetch_timeout_ms`
- `detail_fetch_max_bytes`

Large SEC submission text is skipped before expensive summary parsing when it exceeds `detail_fetch_max_bytes`.
The record remains available with feed-level metadata instead of forcing a large detail summary.

## Guardrails

- No Fly spec increase in this change.
- No public poll UI.
- No backend digest JSON response shape change.
- No frontend framework change.
- No production scheduled polling expansion.

## Follow-Up Smoke

After deploy, verify:

```text
POST /api/admin/sources/sec_edgar_current_schedule_to_tender_offers/poll?use_live_fetch=true&edition=breaking
```

Expected:

```text
HTTP 202
status=accepted
operation=source_poll
job.queue=source_polling_slow
```

Then check Fly logs and digest freshness. The first success criterion is that the HTTP request returns quickly and does not trigger a Fly proxy timeout or OOM kill.
