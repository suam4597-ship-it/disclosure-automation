# GlobalPulse PSE EDGE Access Path Review

Date: 2026-05-11 KST

This document records a focused APAC official-source scan for the Philippine Stock Exchange EDGE disclosure portal.

This is documentation-only. It does not add runtime code, routes, controllers, templates, migrations, backend response-shape changes, frontend shell changes, frontend framework changes, login UI, redirects, identity provider callback routes, poll UI, audit UI, public Source Health UI, provider behavior, materializer behavior, canonical behavior, dashboards, alerts, workflow schedules, source registration, source activation, or scheduled polling.

## Conclusion

```text
PSE_EDGE_OFFICIAL_DISCLOSURE_SURFACE_CONFIRMED
PSE_EDGE_COMPANY_DISCLOSURE_PAGE_CONFIRMED
PSE_CORPORATE_ANNOUNCEMENTS_FEED_PRODUCT_CONFIRMED
PSE_EDGE_PUBLIC_SITE_ACCESS_NOT_ENOUGH_FOR_BACKEND_POLLING
PSE_EDGE_SOURCE_REGISTRATION_BLOCKED_PENDING_APPROVED_DATA_ACCESS_PATH
APAC_SCHEDULED_LIVE_POLLING_NOT_ENABLED
PUBLIC_UI_AND_BACKEND_DIGEST_SHAPE_UNCHANGED
```

## Reviewed Official Surfaces

```text
PSE EDGE portal:
https://edge.pse.com.ph/

PSE EDGE company announcements:
https://edge.pse.com.ph/announcements/form.do

PSE EDGE disclaimer:
https://edge.pse.com.ph/page/disclaimer.do

PSE data products:
https://www.pse.com.ph/data-products/

PSE Corporate Announcements Feed specification:
https://documents.pse.com.ph/wp-content/uploads/sites/15/2021/02/CAF-v6.0.pdf
```

## Official Disclosure Surface

The PSE EDGE homepage displays official company disclosure buckets:

```text
Company Announcements
Financial Reports
Other Reports
Listing Notices
Disclosure Notices
```

The company announcements page describes the target surface as company disclosures and exposes list columns:

```text
Company Name
Template Name
PSE Form Number
Announce Date and Time
Circular Number
```

This is relevant for GlobalPulse listed-company disclosure coverage.

## Official Data-Access Surface

The PSE data-products page identifies official real-time access products for listed-company announcements and exchange notices:

```text
Corporate Announcements Feed (CAF)
ITCH News Feed
```

The CAF specification describes a subscriber feed for listed-company disclosures, listing notices, and disclosure notices. It includes email and FTP delivery, a running 30-day announcement folder, and daily announcement digest fields.

Implication:

```text
PSE has an official data-access path for corporate announcements.
That path appears to be a subscription/data-product path, not an unauthenticated public polling endpoint.
```

## Public-Site Access Restriction

The PSE EDGE disclaimer states that website contents are protected by proprietary rights and that, except as otherwise indicated, users may download, view, or print individual pages only for personal, non-commercial use. It also restricts copying, storing, transmitting, publishing, reproducing, distributing, selling, licensing, renting, leasing, or otherwise transferring contents to third parties without prior written consent.

Implication:

```text
Public PSE EDGE page access is not enough authority for GlobalPulse backend polling or redistribution.
GlobalPulse should not register PSE EDGE as a backend source unless an approved data-access path is documented.
```

## Source Registration Decision

Do not register a PSE EDGE source yet.

Current decision:

```text
source key proposal: ph_pse_edge_company_disclosures
parser/adapter proposal: pse_edge_company_disclosures_v1
registration status: blocked
blocking class: approved_data_access_path_required + parser_required + staging_smoke_required
scheduled polling: not allowed
production polling: not allowed
public UI: not changed
```

## If Access Is Approved Later

If PSE access is approved later, prefer an approved data product or written permission route over public-page scraping:

```text
candidate path: PSE Corporate Announcements Feed or another approved PSE data-access route
source active: false
candidate_status: manual_staging_only
use_live_fetch: true only for manual staging smoke
detail/attachment fetch: disabled by default
stored fields: bounded list metadata first
public digest shape: unchanged
public poll UI: not added
public Source Health UI: not added
```

## Guardrails

```text
Do not add PSE EDGE as an rss_v1 source.
Do not scrape the public HTML listing as a live source.
Do not fetch PSE disclosure PDFs or attachments in an initial candidate.
Do not use third-party PSE mirrors or aggregators by default.
Do not enable ASEAN scheduled live polling.
Do not enable production APAC scheduled live polling.
Do not add public poll UI.
Do not add audit UI.
Do not add public Source Health UI.
Do not change backend digest JSON response shape.
Do not claim fixture fallback as live success.
Keep KR deferred until the dedicated KR backend/source authority path exists.
Keep JP blocked until issue #339 source authority is resolved.
```

## Allowed Next PRs

```text
1. Repeat SET Thailand manual staging smoke in another observation window.
2. Continue APAC official-source scanning within official exchange/OAM surfaces.
3. Revisit PSE only after an approved PSE data-access path is documented.
```
