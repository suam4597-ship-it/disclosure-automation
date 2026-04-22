# UK FCA NSM live source inspection worksheet

Use this worksheet during the direct inspection pass for the current preferred UK family.
The purpose is to capture enough structure from one public discovery row and one detail artefact page to freeze the source contract.

## Target family

Current preferred family:

- `takeover / scheme related update`

Fallback family if needed:

- `major holdings / director dealings`

## Capture set A — public search result row

For one representative item, capture the following exactly:

- search query or filter used
- result title text
- issuer / company name text
- published date text
- result summary text if present
- public detail URL
- any exposed immutable id field
- any exposed RNS number
- any exposed unique announcement id
- any exposed category / family label
- whether the row links directly to the artefact page or to an intermediate page

## Capture set B — public detail / artefact page

For the matching artefact page, capture the following exactly:

- final resolved URL
- immutable URL token candidate
- page title
- displayed issuer / company name
- displayed published timestamp
- displayed category / announcement type label
- downloadable filing links if any
- linked document count
- whether the page alone is enough for the first fixture
- whether an additional linked payload is required for a meaningful first parse

## Capture set C — identity decision

Decide explicitly which field is the best stable external identity:

- artefact URL token
- unique announcement id
- RNS number
- other public field

Also record why the rejected candidates are weaker.

## Capture set D — cursor decision

Decide explicitly which field is the best first cursor:

- latest immutable artefact id seen
- latest unique announcement id seen
- latest published timestamp seen
- other field

Also record why a title-based cursor is rejected.

## Capture set E — family boundary decision

Record whether the inspected row fits cleanly inside:

- `takeover_or_scheme_update`
- `ownership_or_director_change_watch`
- neither cleanly

If neither fits cleanly, stop and re-evaluate the first family choice before code is opened.

## Exit test

This worksheet is complete only when one family can answer all of the following with evidence:

- one deterministic public discovery path
- one deterministic detail path
- one stable immutable identity
- one cursor field
- one minimal raw-document set
- one clean event-family mapping
