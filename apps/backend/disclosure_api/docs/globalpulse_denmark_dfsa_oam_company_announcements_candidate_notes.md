# Denmark DFSA OAM Company Announcements Candidate Notes

Status: `MANUAL_SOURCE_REGISTERED_LOCAL_AND_LIVE_PARSER_SMOKE_FLY_STAGING_LIVE_POLL_PASS_CADENCE_RATE_PAGINATION_DESIGN_RECORDED`

## Scope

`dk_dfsa_oam_company_announcements` is an inactive/manual staging-only candidate for issuer announcements published through the Danish Financial Supervisory Authority OAM company-announcements database.

```text
candidate page: https://www.dfsa.dk/financial-themes/capital-market/company-announcements
extension host: https://appft.gold.extension.gopublic.dk
search endpoint: https://appft.gold.extension.gopublic.dk/api/9217fa13-5d9a-46c6-9921-69ee7e6cfaf6/search
details endpoint pattern: https://appft.gold.extension.gopublic.dk/api/9217fa13-5d9a-46c6-9921-69ee7e6cfaf6/details/{id}
source owner/surface: Danish Financial Supervisory Authority OAM
```

## Why This Fits

The DFSA page describes the OAM database as containing publicly available announcements submitted to the Danish FSA, including company announcements from issuers. This is listed-company disclosure material, not a central-bank, macro, policy, or generic market commentary feed.

The first slice filters the search API to issuer/company announcement categories and excludes the explicit `ShortSelling` category from the request.

## Observed Shape

The public page embeds a GoPublic extension backed by a Nuxt app. Its configuration exposes a search API:

```text
POST /api/9217fa13-5d9a-46c6-9921-69ee7e6cfaf6/search
content-type: application/json
```

The bounded request body uses page 1, page size 25, publication date descending sort, and selected issuer/company announcement categories:

```json
{
  "query": "",
  "page": 1,
  "pageSize": 25,
  "sorting": {
    "key": "PublicationDateColumn",
    "direction": "descending"
  },
  "filters": [
    {
      "type": "dropdown",
      "key": "CategoryFilter",
      "options": [
        "YearlyFinancialReport",
        "ChangeInRightsAttachedToSecurities",
        "HalfYearlyFinancialReport",
        "HomeMemberState",
        "InsideInformation",
        "OwnShares",
        "PaymentsToGovernments",
        "Prospectus",
        "RelatedPartyTransactions",
        "TakeoverBid",
        "TotalVotingRightsAndShareCapital"
      ]
    }
  ]
}
```

Implementation note:

```text
The extension API returned HTTP 500 for the same filtered request when the JSON object was encoded from an unordered map by the Erlang :httpc path.
The source therefore stores live_body as an ordered JSON string matching the browser/Nuxt request shape: query, filters, page, pageSize, sorting.
```

The response is bounded JSON:

```text
paging.page
paging.pageSize
paging.totalCount
data.rows[].id
data.rows[].HeadlineColumn
data.rows[].IssuerColumn
data.rows[].CategoryColumn
data.rows[].PublicationDateColumn
```

Observed live rows include:

```text
Danske Bank A/S, transactions by persons discharging managerial responsibilities - DANSKE BANK A/S - Issuer - 08-05-2026 14:13:40
Share buy-back programme in SP Group A/S - SP GROUP A/S - Issuer - 08-05-2026 13:19:55
Approval of base prospectus for Nykredit Realkredit A/S (EMTN) - NYKREDIT REALKREDIT A/S - Prospectus - 08-05-2026 12:49:58
```

## Guardrails

```text
active=false
candidate_status=manual_staging_only
disable_live_fixture_fallback=true
scheduled polling disabled
page 1 only
pageSize 25 only
detail document fetch out of scope
ShortSelling category excluded from live request
backend digest JSON response shape unchanged
```

## Verification Plan

```text
local registry/capability smoke: PASS
local fixture parser smoke: PASS, 5 bounded records
application live fetch smoke: PASS, HTTP 200, 10 bounded records
Fly staging live poll smoke: PASS, HTTP 200, 25 records seen/inserted
date-specific digest visibility smoke: PENDING, top-N does not yet include Denmark DFSA OAM rows
public latest UI visibility smoke: PENDING, latest digest date is newer than Denmark DFSA OAM rows
```

## Local Smoke Evidence

```text
fixture_count: 5
fixture_first_title: Danske Bank A/S, transactions by persons discharging managerial responsibilities
fixture_first_url: https://appft.gold.extension.gopublic.dk/api/9217fa13-5d9a-46c6-9921-69ee7e6cfaf6/details/300008701
fixture_first_published_at: 2026-05-08T14:13:40.000000Z
live_status: 200
live_bytes: 2931
live_count: 10
live_first_title: Danske Bank A/S, transactions by persons discharging managerial responsibilities
live_first_url: https://appft.gold.extension.gopublic.dk/api/9217fa13-5d9a-46c6-9921-69ee7e6cfaf6/details/300008701
live_first_published_at: 2026-05-08T14:13:40.000000Z
live_first_category: Issuer
```

## Fly Staging Smoke Evidence

```text
Fly deploy: success
release_command: success
GET /api/health: 200
source health before poll: registered, active=false, candidate_status=manual_staging_only
poll URL: POST /api/admin/sources/dk_dfsa_oam_company_announcements/poll?use_live_fetch=true&edition=breaking
fetch.mode: live
fetch.status_code: 200
fetch.bytes: 7141
records_seen: 25
records_inserted: 25
post-poll health_status: healthy
last_seen_published_at: 2026-05-08T14:13:40.000000Z
date-specific digest: 200, fallback_to_fixture=false, top_n=12, Denmark row visibility pending
latest digest: 200, latest digest date 2026-05-09, Denmark row visibility pending
```

## Open Follow-Up

Do not promote this source to scheduled polling until cadence, rate-limit, pagination, and category-selection behavior are documented and repeated staging smoke confirms the endpoint remains stable.

The cadence/rate/pagination gate is recorded in `globalpulse_denmark_dfsa_oam_cadence_rate_pagination_design.md`. It keeps the source manual-only, preserves the page-1 canary, and requires repeated staging smoke before any scheduled staging canary consideration.
