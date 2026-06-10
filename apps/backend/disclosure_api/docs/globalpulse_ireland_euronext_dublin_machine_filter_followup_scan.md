# GlobalPulse Ireland Euronext Dublin Machine Filter Follow-Up Scan

Date: 2026-05-11 KST

## Conclusion

```text
IRELAND_EURONEXT_DUBLIN_CAO_AUTHORITY_SURFACE_STILL_CONFIRMED
IRELAND_EURONEXT_DUBLIN_UI_FILTER_STILL_VISIBLE
IRELAND_EURONEXT_DUBLIN_MACHINE_FILTER_STILL_NOT_PROVEN
IRELAND_EURONEXT_DUBLIN_DIRECT_FILTER_PROBES_UNSTABLE_FROM_LOCAL_CLIENT
IRELAND_EURONEXT_DUBLIN_SOURCE_REGISTRATION_STILL_BLOCKED
IRELAND_EURONEXT_DUBLIN_NO_LIVE_SOURCE_ENABLED
```

## Scope

This is a follow-up endpoint scan for the Ireland Euronext Dublin Company Announcements Office / OAM candidate.

It does not register a source, does not add a parser, does not add a fixture, does not enable scheduled polling, and does not change backend or frontend runtime behavior.

```text
target country: Ireland
authority surface: Euronext Dublin Company Announcements Office / OAM
public company-news page: https://live.euronext.com/en/products/equities/company-news
global RSS endpoint: https://live.euronext.com/rss/company-pr-release
candidate UI filter: Trading location = Dublin
known Dublin filter id: field_trading_location_target_id[426]
status before this scan: endpoint_filter_blocked
status after this scan: endpoint_filter_blocked
```

## Baseline From Previous Scan

The prior scan recorded:

```text
authority surface confirmed
public company-news UI filter observed
global RSS endpoint observed
Trading location Dublin input observed as field_trading_location_target_id[426]
simple GET filter probes did not produce Dublin-only results
RSS filter probes did not produce Dublin-only results
Drupal Views AJAX probe did not produce Dublin-only results
source registration blocked
```

This follow-up intentionally does not treat the global Euronext company-pr-release RSS feed as an Ireland source.

## Official Surface

The official Euronext Announcement Services Ireland surface describes the Euronext Dublin Company Announcements Office as the dissemination and OAM filing surface for regulatory information for Dublin markets and Ireland OAM filings.

This remains relevant listed-company disclosure material, but authority alone is not enough to register a source. A stable Dublin-only machine-readable query contract is still required.

## UI Filter Reconfirmed

The Euronext Live company-news page still exposes a `Trading location` filter with `Dublin` as an option.

Observed public page:

```text
page: https://live.euronext.com/en/products/equities/company-news
filter group: Trading location
Amsterdam input: field_trading_location_target_id[404]
Brussels input: field_trading_location_target_id[405]
Dublin input: field_trading_location_target_id[426]
Lisbon input: field_trading_location_target_id[406]
Milan input: field_trading_location_target_id[2156]
Oslo input: field_trading_location_target_id[1061]
Paris input: field_trading_location_target_id[408]
unfiltered result count observed by indexed/public page: Displaying 1 - 50 of 5558 results
unfiltered first row observed by indexed/public page: OTELLO CORPORATION
```

The visible UI filter confirms that Dublin is a known Euronext trading-location taxonomy value. It does not prove that a stable backend URL, RSS URL, or AJAX request can be called directly by the GlobalPulse backend.

## Local Direct Probe Results

Local direct probes were run from the Codex environment with a browser user agent and bounded timeouts.

Tested endpoints:

```text
GET https://live.euronext.com/en/products/equities/company-news
GET https://live.euronext.com/en/products/equities/company-news?field_trading_location_target_id=426
GET https://live.euronext.com/en/products/equities/company-news?field_trading_location_target_id%5B426%5D=426
GET https://live.euronext.com/rss/company-pr-release?field_trading_location_target_id%5B426%5D=426
POST https://live.euronext.com/en/views/ajax
```

AJAX POST form shape tested:

```text
view_name=company_press_releases_view
view_display_id=page_3
view_args=
view_path=/listview/company-press-releases
view_base_path=listview/company-press-releases
pager_element=0
field_trading_location_target_id[426]=426
```

Observed local result:

```text
base company-news page: HTTP 504 from local direct client during repeated probe window
simple query filter: HTTP 504 from local direct client
bracket query filter: timeout with 0 bytes from local direct client
RSS bracket filter: HTTP 504 from local direct client
AJAX POST bracket filter: HTTP 504 from local direct client
```

Interpretation:

```text
The follow-up did not prove a Dublin-only machine-readable result set.
The direct query/AJAX surface appears unstable or protection-sensitive from a backend-style local client.
The indexed/public page still shows the global result set and global first rows.
The global RSS endpoint remains machine-readable but not Dublin-specific.
```

This is not a source-registration pass. It is a stronger blocker: even if the UI can filter Dublin in a browser, the backend-safe contract for reproducing that filter has not been proven.

## Why Global RSS Remains Blocked

The global RSS endpoint is already represented by the pan-Euronext candidate:

```text
existing global candidate: eu_euronext_company_press_releases
global RSS endpoint: https://live.euronext.com/rss/company-pr-release
```

Registering Ireland from the same unfiltered RSS would:

```text
duplicate the existing pan-Euronext feed
overclaim Ireland-specific coverage
mix Amsterdam/Brussels/Dublin/Lisbon/Milan/Oslo/Paris rows
make region labeling unreliable
inflate digest diversity without a real Ireland source boundary
```

## Source Registration Decision

Do not register an Ireland source yet.

Required proof before registration:

```text
a Dublin-only RSS, JSON, XML, CSV, or stable API endpoint; or
a documented Euronext query contract that returns only Trading location = Dublin rows; or
a bounded AJAX request that returns Dublin-only result count and Dublin first rows from a backend-style client; or
an official Euronext Dublin CAO/OAM endpoint separate from the global company-news feed.
```

Do not proceed if the only available evidence is:

```text
the global RSS endpoint
the global company-news HTML page
an unverified UI checkbox id
a browser-only filtered state with no reproducible backend request
third-party aggregators
Central Bank policy, macro, financial-stability, or supervisory-news feeds
```

## Guardrails

```text
do not register a new Ireland source from the unfiltered global RSS feed
do not claim Ireland-specific live coverage from eu_euronext_company_press_releases
do not parse the global company-news page as Ireland-only
do not add Central Bank macro/policy feeds
do not add third-party aggregators without explicit approval
do not enable scheduled polling
do not set any source active=true
do not change backend digest JSON response shape
do not add public poll UI, audit UI, or public Source Health UI
do not add frontend framework dependencies
```

## Candidate State

```text
candidate_status: endpoint_filter_blocked
authority: official OAM/company-announcement surface confirmed
machine_readable_global_feed: confirmed
machine_readable_ireland_filter: not proven
backend-safe filter contract: not proven
source_registration: blocked
scheduled_polling: blocked
```

## Next Probe

The next useful probe should use browser developer-network capture or an official Euronext API/data specification, not more guessed query strings.

Recommended next steps:

```text
1. Capture the network request produced by clicking Trading location = Dublin in a real browser session.
2. Verify whether the response body changes result count and first rows to Dublin-only.
3. Replay that exact request from a backend-style client with headers/cookies reduced to the minimum stable contract.
4. If replay fails or requires ephemeral browser state, keep the candidate blocked.
5. If replay succeeds, document the exact request contract before any parser/source PR.
```

Only after the replay proves a Dublin-only machine-readable result set should a parser/source PR be created.
