# UK FCA NSM public surface inspection worksheet

Use this worksheet when directly inspecting the public NSM search surface and artefact pages.
This worksheet exists to convert live inspection into a frozen runtime contract with minimum ambiguity.

## Candidate family under inspection

Choose one only:

- [ ] `takeover / scheme related update`
- [ ] `major holdings / director dealings`

## Search surface capture

Record the exact search surface used:

- search entry URL: `TODO`
- search filters used: `TODO`
- search query string: `TODO`
- date range used: `TODO`
- whether the result can be exported to CSV: `TODO`

## One deterministic result row

Capture one row only for the first implementation slice:

- row headline / title: `TODO`
- issuer / company name: `TODO`
- displayed date / time: `TODO`
- displayed announcement type / category: `TODO`
- detail / artefact URL: `TODO`
- any explicit public id in result row: `TODO`
- any RNS number in result row: `TODO`
- any unique announcement id in result row: `TODO`

## Detail / artefact capture

Open the detail / artefact page for the same row and record:

- detail URL: `TODO`
- immutable token in URL: `TODO`
- public id on detail page: `TODO`
- RNS number on detail page: `TODO`
- unique announcement id on detail page: `TODO`
- issuer name on detail page: `TODO`
- published timestamp on detail page: `TODO`
- any linked filing payload URL: `TODO`
- whether detail page alone is sufficient for normalization: `TODO`

## Identity decision

Freeze only one identity field for the first slice:

- chosen stable external identity field: `TODO`
- why this is better than the other candidates: `TODO`
- whether this field is visible in both discovery and detail: `TODO`
- whether this field survives corrections / related update chains: `TODO`

## Cursor decision

Freeze only one cursor field:

- chosen cursor key: `TODO`
- chosen cursor source field: `TODO`
- why this is stable enough: `TODO`
- why title text is not needed: `TODO`

## Raw-document minimum set

Choose the smallest deterministic set:

- discovery result payload needed? `TODO`
- detail artefact page needed? `TODO`
- linked filing payload needed? `TODO`
- minimum raw-document count per item: `TODO`

## Family boundary check

Confirm that the item belongs to the intended family only:

- chosen event family: `TODO`
- adjacent family risk: `TODO`
- reason this item does not belong to a broader mixed bucket: `TODO`

## Freeze outcome

Complete only one:

- [ ] family passes contract-freeze exit criteria
- [ ] family fails contract-freeze exit criteria and should not be the first implementation slice

## Next action

Complete only one:

- [ ] open the isolated runtime implementation PR for this family
- [ ] promote the backup family and repeat this worksheet there
