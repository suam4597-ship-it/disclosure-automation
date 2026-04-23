# UK FCA NSM public surface inspection — takeover / scheme sample (2026-04-20)

This file is a partially completed worksheet using the user-supplied NSM CSV probe.
It is intended to make the remaining unknowns explicit.

## Candidate family under inspection

- [x] `takeover / scheme related update`
- [ ] `major holdings / director dealings`

## Search surface capture

- search entry URL: `public FCA NSM search UI`
- search filters used: `Document Text = scheme of arrangement`, `All words match`
- search query string: `scheme of arrangement`
- date range used: `2026-04-20 00:00` to `2026-04-23 08:29` on filing date basis
- whether the result can be exported to CSV: `yes (user supplied CSV export)`

## One deterministic result row

- row headline / title: `Scheme of Arrangement Becomes Effective`
- issuer / company name: `BRITISH LAND COMPANY PUBLIC LIMITED COMPANY(THE)`
- displayed date / time: `Filing 20/04/2026 06:13`, `Publication 20/04/2026 06:00`, `Document Date 20/04/2026`
- displayed announcement type / category: `Scheme of Arrangement`
- detail / artefact URL: `https://data.fca.org.uk/artefacts/NSM/RNS/5c9e4a51-b4c6-4977-86d3-ac8567261289.html`
- any explicit public id in result row: `artefact token visible in download link`
- any RNS number in result row: `not present in CSV row`
- any unique announcement id in result row: `not present in CSV row`

## Detail / artefact capture

- detail URL: `https://data.fca.org.uk/artefacts/NSM/RNS/5c9e4a51-b4c6-4977-86d3-ac8567261289.html`
- immutable token in URL: `5c9e4a51-b4c6-4977-86d3-ac8567261289`
- public id on detail page: `TODO`
- RNS number on detail page: `TODO`
- unique announcement id on detail page: `TODO`
- issuer name on detail page: `TODO`
- published timestamp on detail page: `TODO`
- any linked filing payload URL: `TODO`
- whether detail page alone is sufficient for normalization: `TODO`

## Identity decision

- chosen stable external identity field: `provisional = NSM namespace + source + artefact token`
- why this is better than the other candidates: `visible in public download link and independent of title text`
- whether this field is visible in both discovery and detail: `discovery = yes`, `detail = assumed yes from URL, page body not yet checked`
- whether this field survives corrections / related update chains: `TODO`

## Cursor decision

- chosen cursor key: `provisional = latest_filing_at_and_artefact_id_seen`
- chosen cursor source field: `Filing Date/Time + artefact token from Download Link`
- why this is stable enough: `uses exported metadata rather than title text`
- why title text is not needed: `CSV already exposes a filing timestamp and deterministic artefact URL`

## Raw-document minimum set

- discovery result payload needed? `yes`
- detail artefact page needed? `yes`
- linked filing payload needed? `TODO`
- minimum raw-document count per item: `provisional = 2`

## Family boundary check

- chosen event family: `provisional = takeover_or_scheme_update`
- adjacent family risk: `text query overmatches Result of Meeting and Offer Update rows`
- reason this item does not belong to a broader mixed bucket: `exact Category = Scheme of Arrangement`

## Freeze outcome

- [ ] family passes contract-freeze exit criteria
- [x] family still needs one direct detail-page inspection before contract freeze is complete

## Next action

- [ ] open the isolated runtime implementation PR for this family
- [x] inspect the detail artefact page directly and finish the missing fields
