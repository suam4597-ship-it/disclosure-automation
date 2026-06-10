# GlobalPulse Ireland Euronext Dublin CAO Endpoint Scan

Date: 2026-05-11 KST

## Conclusion

```text
IRELAND_EURONEXT_DUBLIN_CAO_AUTHORITY_SURFACE_CONFIRMED
IRELAND_EURONEXT_DUBLIN_COMPANY_NEWS_UI_FILTER_OBSERVED
IRELAND_EURONEXT_DUBLIN_MACHINE_FILTER_NOT_PROVEN
IRELAND_EURONEXT_DUBLIN_SOURCE_REGISTRATION_BLOCKED
IRELAND_EURONEXT_DUBLIN_NO_LIVE_SOURCE_ENABLED
```

## Scope

This scan evaluates Ireland as a future listed-company disclosure source. It does not register a source, does not add a parser, and does not enable scheduled polling.

```text
target country: Ireland
authority surface: Euronext Dublin Company Announcements Office / OAM
public company-news page: https://live.euronext.com/en/products/equities/company-news
global RSS endpoint: https://live.euronext.com/rss/company-pr-release
candidate filter: Trading location = Dublin
```

## Why This Is Relevant

Euronext describes the Euronext Dublin Company Announcements Office as the dissemination path for regulatory information for instruments listed or admitted to trading on Dublin markets, and as Ireland's officially appointed mechanism under the Transparency Directive.

This is listed-company disclosure and issuer-announcement material, not a central-bank, macro, policy, or broad market-commentary feed.

## Observed Public Surface

The live Euronext company-news page exposes a `Trading location` filter. The observed HTML includes:

```text
Amsterdam: field_trading_location_target_id[404]
Brussels: field_trading_location_target_id[405]
Dublin: field_trading_location_target_id[426]
Lisbon: field_trading_location_target_id[406]
Milan: field_trading_location_target_id[2156]
Oslo: field_trading_location_target_id[1061]
Paris: field_trading_location_target_id[408]
```

The same page exposes a global RSS link:

```text
https://live.euronext.com/rss/company-pr-release
```

This global RSS endpoint is already represented by the existing `eu_euronext_company_press_releases` candidate. It is not Ireland-specific.

## Machine-Filter Probe

Simple GET/RSS query attempts did not prove a Dublin-only result set.

Tested examples:

```text
GET /en/products/equities/company-news?field_trading_location_target_id=426
GET /en/products/equities/company-news?field_trading_location_target_id%5B426%5D=426
GET /rss/company-pr-release?field_trading_location_target_id=426
GET /rss/company-pr-release?field_trading_location_target_id%5B426%5D=426
```

Observed result:

```text
HTTP status: 200
result count remained global: Displaying 1 - 50 of 5558
first row remained non-Dublin/global: OTELLO CORPORATION
RSS first rows remained the global company-pr-release feed
```

Drupal Views AJAX was also probed with the observed view metadata:

```text
ajax path: /en/views/ajax
view_name: company_press_releases_view
view_display_id: page_3
view_path: /listview/company-press-releases
view_base_path: listview/company-press-releases
filter: field_trading_location_target_id[426]=426
```

Observed result:

```text
HTTP status: 200
result count remained global: Displaying 1 - 50 of 5558
first row remained non-Dublin/global: OTELLO CORPORATION
```

This means the UI filter may require additional client-side state, a different parameter contract, or a server-side search path that was not proven in this scan. Registering a Dublin source from the global RSS or global HTML page would duplicate the existing pan-Euronext feed and would overclaim Ireland-specific coverage.

## Blocker

```text
No bounded Dublin-only machine-readable endpoint has been proven.
The global RSS endpoint is machine-readable but not Dublin-specific.
The public HTML/AJAX probes returned global results, not Dublin-only results.
```

## Guardrails

```text
do not register a new Ireland source from the unfiltered global RSS feed
do not claim Ireland-specific live coverage from eu_euronext_company_press_releases
do not parse the global company-news page as Ireland-only
do not add Central Bank macro/policy feeds
do not add third-party aggregators without explicit approval
do not enable scheduled polling
do not change backend digest JSON response shape
do not add public poll UI, audit UI, or public Source Health UI
```

## Candidate State

```text
candidate_status: endpoint_filter_blocked
authority: official OAM/company-announcement surface confirmed
machine_readable_global_feed: confirmed
machine_readable_ireland_filter: not proven
source_registration: blocked
scheduled_polling: blocked
```

## Next Probe

Before registering an Ireland source, prove one of these:

```text
1. a Dublin-only RSS, JSON, CSV, XML, or stable API endpoint;
2. a documented Euronext query contract that returns only trading_location=Dublin rows;
3. a bounded AJAX request whose result count and first rows change to Dublin-only; or
4. an official Euronext Dublin CAO/OAM endpoint separate from the global company-news feed.
```

Only after one of those passes should a parser/source PR be created.
