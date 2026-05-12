# Montenegro MNSE Corporate News Candidate Notes

Status: `MANUAL_SOURCE_REGISTERED_LOCAL_PARSER_SMOKE_PASS_LIVE_FETCH_BLOCKED_HTTP_CLIENT_TLS`

## Scope

`me_mnse_corporate_news` is an inactive/manual staging-only candidate for listed-company corporate announcements published by Montenegro Stock Exchange.

```text
candidate URL: https://www.mnse.me/code/navigate.asp?Id=852
HTTPS page probe: local PowerShell/WinHTTP returns 200, but application live fetch closed the TLS connection during the initial smoke.
HTTP page probe: redirects to HTTPS; it does not avoid the application TLS blocker.
surface label: Korporativne novosti
source owner: Montenegro Stock Exchange
```

## Why This Fits

The page is an official exchange surface for issuer corporate news. The bounded HTML rows expose issuer name, publication date/time, announcement title, and a document URL under `/upload/documents/issuer/`.

This is not a central-bank, macro, policy, or generic market commentary feed.

## Guardrails

```text
active=false
candidate_status=manual_staging_only
disable_live_fixture_fallback=true
scheduled polling disabled
detail/PDF fetching out of scope
backend digest JSON response shape unchanged
```

## Verification Plan

```text
local registry/capability smoke: PASS
local fixture parser smoke: PASS, 3 bounded records
external endpoint probe: PASS, HTTP 200 text/html via PowerShell/WinHTTP
application live fetch smoke: BLOCKED, Erlang :httpc closes TLS connection to mnse.me/www.mnse.me
Fly staging live poll smoke: BLOCKED, HTTP retry redirects to HTTPS and fails on the same TLS path
date-specific digest visibility smoke
public latest UI visibility smoke when top-N/date selection includes MNSE rows
```

## Open Blocker

PowerShell can fetch both `https://www.mnse.me/code/navigate.asp?Id=852` and `https://mnse.me/code/navigate.asp?Id=852` with HTTP 200. The Elixir/Erlang `:httpc` path returns `{:failed_connect, ... :closed}` during TLS connection setup. A staging retry with the HTTP URL did not solve the issue because `http://www.mnse.me/code/navigate.asp?Id=852` returns `301 Location: https://www.mnse.me/code/navigate.asp?Id=852`, so the application still reaches the blocked HTTPS path.

Do not claim staging live poll success or promote this source until the application fetch path has a bounded workaround.
