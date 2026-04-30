# TW MOPS public surface inspection worksheet

Use this worksheet when directly inspecting the MOPS public disclosure/search surface.
This converts live inspection into a frozen runtime contract with minimum ambiguity.

## Candidate family under inspection

Choose one only:

- [ ] `material information / major announcement`
- [ ] `M&A / merger / acquisition / tender-offer style update`
- [ ] `shareholding / director / insider related update`

## Search surface capture

Record the exact search surface used:

- search entry URL: `TODO`
- query endpoint or form path: `TODO`
- query parameters used: `TODO`
- market filter: `TODO`
- company code / company name filter: `TODO`
- date range used: `TODO`
- whether export/download is available: `TODO`

## One deterministic result row

Capture one row only for the first implementation slice:

- row title / subject: `TODO`
- company code: `TODO`
- company name: `TODO`
- filing date / time: `TODO`
- announcement type / category: `TODO`
- detail URL or action target: `TODO`
- visible announcement id / sequence id: `TODO`
- any attachment URL: `TODO`

## Detail page capture

Open the detail page for the same row and record:

- detail URL: `TODO`
- immutable token in URL or parameters: `TODO`
- public announcement id on detail page: `TODO`
- company code / name on detail page: `TODO`
- published timestamp on detail page: `TODO`
- disclosure body text available directly? `TODO`
- any linked attachment URL: `TODO`
- whether detail page alone is sufficient for normalization: `TODO`

## Identity decision

Freeze only one identity field for the first slice:

- chosen stable external identity field: `TODO`
- chosen stable external identity value: `TODO`
- why this is better than the other candidates: `TODO`
- whether this field is visible in both discovery and detail: `TODO`
- whether this field survives corrections / updates: `TODO`

## Cursor decision

Freeze only one cursor field:

- chosen cursor key: `TODO`
- chosen cursor source field: `TODO`
- chosen cursor value: `TODO`
- why this is stable enough: `TODO`
- why title text is not needed: `TODO`

## Date/time normalization

Record date format and conversion rules:

- source date format: `TODO`
- source time format: `TODO`
- timezone: `Asia/Taipei`
- ROC calendar conversion needed? `TODO`
- expected `published_at_local`: `TODO`
- expected `published_at_utc`: `TODO`

## Raw-document minimum set

Choose the smallest deterministic set:

- discovery result payload needed? `TODO`
- detail page needed? `TODO`
- linked attachment needed? `TODO`
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
