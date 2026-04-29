# UK FCA NSM public surface inspection worksheet — takeover / scheme — Greencore

This worksheet is completed from the Greencore takeover / scheme sample.
It is still based on public evidence gathered from the live surfaces rather than direct CSV export.

## Candidate family under inspection

- [x] `takeover / scheme related update`
- [ ] `major holdings / director dealings`

## Search surface capture

- search entry URL: `https://data.fca.org.uk/#/nsm/nationalstoragemechanism`
- search filters used: `Document Text`
- search query string: `scheme of arrangement` (also `takeover scheme` is a plausible variant)
- date range used: `not frozen`
- whether the result can be exported to CSV: `yes, documented by FCA user guidance; actual row not captured here`

## One deterministic result row

- row headline / title: `Results of Extraordinary General Meeting` / paired LSE headline `Result of Meeting`
- issuer / company name: `Greencore Group PLC`
- displayed date / time: `NSM artefact shows 04 July 2025; paired LSE surface shows 13:44:18 04 Jul 2025`
- displayed announcement type / category: `National Storage Mechanism | Additional information` / paired result `Result of Meeting`
- detail / artefact URL: `https://data.fca.org.uk/artefacts/NSM/RNS/5726018.html`
- any explicit public id in result row: `artefact token 5726018 via URL`
- any RNS number in result row: `8538P`
- any unique announcement id in result row: `not publicly observed on the detail HTML`

## Detail / artefact capture

- detail URL: `https://data.fca.org.uk/artefacts/NSM/RNS/5726018.html`
- immutable token in URL: `5726018`
- public id on detail page: `RNS Number 8538P`
- RNS number on detail page: `8538P`
- unique announcement id on detail page: `not observed`
- issuer name on detail page: `Greencore Group PLC`
- published timestamp on detail page: `04 July 2025` (date only visible on NSM artefact)
- any linked filing payload URL: `not required for this sample; paired public source exists at LSE/RNS`
- whether detail page alone is sufficient for normalization: `provisionally yes for the first deterministic item`

## Identity decision

Freeze only one identity field for the first slice:

- chosen stable external identity field: `NSM:RNS:5726018`
- why this is better than the other candidates: `it is directly present in the public artefact URL and does not rely on issuer text or publication-date concatenation`
- whether this field is visible in both discovery and detail: `visible through the detail URL reached from discovery`
- whether this field survives corrections / related update chains: `not fully proven yet; correction/version behavior still needs CSV or additional public evidence`

## Cursor decision

Freeze only one cursor field:

- chosen cursor key: `latest_artefact_token_seen` (provisional)
- chosen cursor source field: `artefact token extracted from NSM artefact URL`
- why this is stable enough: `it is public, explicit, and avoids title-text heuristics`
- why title text is not needed: `the artefact token is a cleaner id candidate than headline text`

## Raw-document minimum set

Choose the smallest deterministic set:

- discovery result payload needed? `yes, at least one discovery row fixture should exist`
- detail artefact page needed? `yes`
- linked filing payload needed? `not for this first sample unless later evidence shows the artefact page omits required metadata`
- minimum raw-document count per item: `2`

## Family boundary check

Confirm that the item belongs to the intended family only:

- chosen event family: `takeover_or_scheme_update`
- adjacent family risk: `meeting result` is visible as a document/result label, but the body clearly places the item inside a scheme/recommended-acquisition chain`
- reason this item does not belong to a broader mixed bucket: `the text explicitly references recommended acquisition, scheme of arrangement, court sanction path, and Takeover Code`

## Freeze outcome

Complete only one:

- [x] family passes contract-freeze exit criteria provisionally enough to open a targeted first implementation contract draft
- [ ] family fails contract-freeze exit criteria and should not be the first implementation slice

## Next action

Complete only one:

- [x] continue tightening the isolated runtime implementation contract for this family
- [ ] promote the backup family and repeat this worksheet there
