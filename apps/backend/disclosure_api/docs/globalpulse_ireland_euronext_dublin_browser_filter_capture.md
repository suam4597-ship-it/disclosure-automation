# GlobalPulse Ireland Euronext Dublin Browser Filter Capture

Date: 2026-05-11 KST

## Conclusion

```text
IRELAND_EURONEXT_DUBLIN_BROWSER_FILTER_CAPTURE_COMPLETED
IRELAND_EURONEXT_DUBLIN_AJAX_FILTER_REQUEST_CAPTURED
IRELAND_EURONEXT_DUBLIN_AJAX_FILTER_RETURNED_NO_RESULTS
IRELAND_EURONEXT_DUBLIN_POSITIVE_ROW_EVIDENCE_NOT_PROVEN
IRELAND_EURONEXT_DUBLIN_SOURCE_REGISTRATION_STILL_BLOCKED
IRELAND_EURONEXT_DUBLIN_NO_LIVE_SOURCE_ENABLED
```

## Scope

This is a browser-network follow-up for the Ireland Euronext Dublin Company Announcements Office / OAM candidate.

It does not register a source, does not add a parser, does not add a fixture, does not enable scheduled polling, and does not change backend or frontend runtime behavior.

```text
target country: Ireland
authority surface: Euronext Dublin Company Announcements Office / OAM
public company-news page: https://live.euronext.com/en/products/equities/company-news
global RSS endpoint: https://live.euronext.com/rss/company-pr-release
candidate UI filter: Trading location = Dublin
known Dublin filter id: field_trading_location_target_id[426]
status before this capture: endpoint_filter_blocked
status after this capture: endpoint_filter_blocked
```

## Browser Capture

The in-app browser could load the page and observe the current global company-news table, but direct click automation timed out while issuing CDP click/evaluate commands. A temporary repo-external `playwright-core` install was then used with local Chrome to capture the filter request.

Temporary tooling stayed outside the repository:

```text
temporary package path: %TEMP%/codex-playwright-core
package: playwright-core
browser: local Chrome
repo files changed by capture: none
```

Observed unfiltered browser state:

```text
page: https://live.euronext.com/en/products/equities/company-news
HTTP: 200
title: Company press releases - Euronext exchange Live quotes
unfiltered result count: Displaying 1 - 50 of 5348 results
first unfiltered row: OTELLO CORPORATION
global RSS link: /rss/company-pr-release
```

The filter panel exposed the same Dublin checkbox already observed in the static scans:

```text
Amsterdam: field_trading_location_target_id[404]
Brussels: field_trading_location_target_id[405]
Dublin: field_trading_location_target_id[426]
Lisbon: field_trading_location_target_id[406]
Milan: field_trading_location_target_id[2156]
Oslo: field_trading_location_target_id[1061]
Paris: field_trading_location_target_id[408]
```

## Captured AJAX Request

Clicking/applying the Dublin filter produced a Drupal Views AJAX request:

```text
GET /en/views/ajax
_wrapper_format=drupal_ajax
dateRange=customDateRange
field_company_pr_pub_datetime_start=19-01-2001T00:00:00
field_company_pr_pub_datetime_end=T23:59:59
field_trading_location_target_id[426]=426
view_name=company_press_releases_view
view_display_id=page_3
view_args=
view_path=/listview/company-press-releases
view_base_path=listview/company-press-releases
pager_element=0
_drupal_ajax=1
ajax_page_state[theme]=euronext_live
ajax_page_state[libraries]=large page-specific compressed token
```

Observed response:

```text
HTTP: 200
content shape: Drupal AJAX JSON array with an HTML replaceWith command
response body length: 104880 bytes
post-filter page text: NO RESULTS MATCH YOUR SEARCH CRITERIA
post-filter table rows: 0
OTELLO/global first row present in AJAX body: false
Dublin/Irish marker present in AJAX body: true, from filter UI metadata rather than issuer rows
```

## Interpretation

This capture improves the blocker, but it is not a source-registration pass.

The browser did prove an AJAX request containing `field_trading_location_target_id[426]=426`, but the response did not prove a Dublin-only machine-readable issuer result set. It returned no rows in this capture window.

That means a parser/source PR would have no positive row contract to lock yet:

```text
no Dublin issuer row observed
no Dublin result count observed
no Dublin-specific RSS/JSON/XML/CSV endpoint observed
global RSS remains pan-Euronext and already represented by eu_euronext_company_press_releases
captured AJAX URL includes page-specific view_dom_id and ajax_page_state[libraries], so a minimal backend-safe replay contract is not proven
```

## Source Registration Decision

Do not register an Ireland source yet.

Required proof before registration remains one of:

```text
a Dublin-only RSS, JSON, XML, CSV, or stable API endpoint
a documented Euronext query contract that returns Dublin-only rows
a bounded AJAX replay that returns a positive Dublin-only result set from a backend-style client
an official Euronext Dublin CAO/OAM endpoint separate from the global company-news feed
```

Do not proceed if the only evidence is:

```text
the global RSS endpoint
the global company-news HTML page
a UI checkbox id with no positive rows
a browser-only Drupal AJAX request returning no rows
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
browser_ajax_filter_request: captured
positive_dublin_result_rows: not proven
backend_safe_filter_contract: not proven
source_registration: blocked
scheduled_polling: blocked
```

## Next Probe

The next useful probe should look for official Euronext Dublin CAO/OAM data documentation or a date/window that produces positive Dublin rows before attempting parser/source work.

If a positive browser result is found later, replay the exact request with only stable headers and without page-specific `view_dom_id` / `ajax_page_state[libraries]` before registering a source.

