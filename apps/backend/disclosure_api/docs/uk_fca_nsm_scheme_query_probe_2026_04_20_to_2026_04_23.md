# UK FCA NSM scheme query probe (2026-04-20 to 2026-04-23)

This note records actual findings from a user-supplied NSM CSV export.
It is the first concrete public-discovery probe used to tighten the UK source contract.

## Query used

The CSV was described as generated from the NSM search UI with:

- document text query: `scheme of arrangement`
- match mode: `All words match`
- sort / time basis: `Filing Date`
- filing date range: `2026-04-20 00:00` to `2026-04-23 08:29`

## CSV structure observed

Observed columns:

- `Filing Date/Time`
- `Publication Date/Time`
- `Document Date`
- `Source`
- `Disclosing Organisation LEI`
- `Disclosing Organisation Name`
- `Description`
- `Category`
- `ESEF Type`
- `Download Link`
- `Related Organisation(s)`

This is enough to move several contract fields out of the purely speculative stage.

## Result volume

Observed total rows in the CSV:

- `58`

This means document-text search alone is too broad to use as the only first-slice isolator.

## Most relevant rows observed

### Exact category match

Strongest exact candidate row:

- `Filing Date/Time`: `20/04/2026 06:13`
- `Publication Date/Time`: `20/04/2026 06:00`
- `Document Date`: `20/04/2026`
- `Source`: `Regulatory News Services (RNS)`
- `Disclosing Organisation Name`: `BRITISH LAND COMPANY PUBLIC LIMITED COMPANY(THE)`
- `Description`: `Scheme of Arrangement Becomes Effective`
- `Category`: `Scheme of Arrangement`
- `Download Link`: `https://data.fca.org.uk/artefacts/NSM/RNS/5c9e4a51-b4c6-4977-86d3-ac8567261289.html`
- `Related Organisation(s)`: `LIFE SCIENCE REIT PLC (213800RG7JNX7K8F7525)`

### Related but broader hits

Other rows returned by the same query include:

- `Results of Court Meeting and General Meeting` (`Result of Meeting`, RNS)
- `Carnival PLC - Results of the Court Meeting, Special Meetings and Annual General Meetings` (`Result of Meeting`, PRN)
- `Offer Declared Unconditional` (`Offer Update`, RNS)

## What this means

### 1) Text search alone overmatches

The phrase query is useful for discovery, but it is not sufficient as the only family boundary.
The first implementation slice should rely on exported metadata such as:

- `Category`
- `Source`
- `Download Link` namespace / token

and not on text matching alone.

### 2) Takeover / scheme remains a viable first family

Even though text search overmatches, the CSV exposes at least one clean exact-category row:

- `Category = Scheme of Arrangement`
- `Source = Regulatory News Services (RNS)`
- one direct artefact URL

That keeps `takeover / scheme related update` as a viable first-slice candidate.

### 3) Stable external identity is now stronger

Current strongest public stable-id candidate for the first slice:

- `NSM:RNS:5c9e4a51-b4c6-4977-86d3-ac8567261289`

Derived from:

- NSM namespace
- source family implied by the artefact path (`RNS`)
- immutable artefact token from the download URL

### 4) Cursor candidate is now clearer

Because the CSV includes both `Filing Date/Time` and `Download Link`, the first slice can avoid title-text heuristics.

Current best cursor candidate:

- composite cursor using `Filing Date/Time + artefact token`

Example shape:

- `2026-04-20T06:13:00|RNS|5c9e4a51-b4c6-4977-86d3-ac8567261289`

### 5) Minimum raw-document set is likely small

Based on the CSV probe, the first implementation slice should aim for:

- one discovery row metadata fixture
- one artefact HTML/detail fixture
- linked filing payload only if the artefact page is proven insufficient

## Immediate contract impact

The CSV probe strengthens the case for:

- preferred first family: `takeover / scheme related update`
- preferred first exact sample row: the British Land `Scheme of Arrangement Becomes Effective` row
- preferred stable id family: `NSM:RNS:<artefact_uuid>`
- preferred cursor shape: `filing_datetime + artefact_uuid`

It also weakens the case for any implementation that depends only on document-text matching.
