# JP discovery inventory

This document tracks official-source discovery work for the first Japan regional vertical.

## Status

No JP official disclosure source is frozen yet.
The sources below are inventory candidates only and must be inspected before any runtime contract is written.

## Candidate source surfaces

| Candidate | Why inspect | First questions | Freeze status |
| --- | --- | --- | --- |
| TDnet / Timely Disclosure Network | Primary timely-disclosure surface for listed companies via TSE/JPX | Are public announcement rows stable? Is there a visible disclosure number or document id? Can one high-signal family be isolated? | not frozen |
| JPX Company Announcements Disclosure Service | Public inspection surface for TDnet disclosures | Does it expose deterministic detail/PDF URLs and disclosure timestamps? | not frozen |
| JPX Listed Company Search | Public historical browsing surface for listed-company disclosures | Can it retrieve deterministic samples from past disclosures without paid access? | not frozen |
| EDINET | FSA-operated statutory disclosure surface | Does it fit the first high-signal as-it-happens use case, or is it better for later periodic/securities-report work? | not frozen |
| TSE listed-company disclosure pages | Exchange-operated disclosure pages | Are they duplicative of TDnet/JPX services or useful as public detail surfaces? | not frozen |

## Initial public-source observations

JPX describes TDnet as a Timely Disclosure Network used for fair, prompt, and wide-ranging timely disclosure.
JPX also describes listed companies as obliged by Securities Listing Regulations to use TDnet when enacting timely disclosure of corporate information.

The public JPX TDnet material indicates that disclosed information can include:

- date and time of disclosure
- listed exchange
- company code
- company name
- disclosure title

The paid TDnet API description also indicates index fields such as security code, stock abbreviation, date/time of disclosure, disclosure number, disclosure history number, title, public item code, and file existence flag.

These observations make TDnet / JPX announcement surfaces the preferred first JP candidate, but not enough to freeze a runtime contract.

## Discovery questions to close

### 1) What is the official public source?

For each candidate, record:

- public discovery URL
- public detail URL shape
- source owner/operator
- whether the surface is exchange-operated, regulator-operated, or archive-like
- whether the source can be treated as `official_exchange_storage` or `official_regulatory_storage`

### 2) What is the first high-signal family?

Do not ingest every JP announcement type.
Evaluate whether a candidate source can isolate one family from this initial order:

1. timely disclosure / material information update
2. M&A / restructuring / major asset transaction style disclosure
3. shareholding / ownership change
4. tender-offer / takeover style update
5. periodic report

### 3) What is the stable external identity?

The first implementation slice needs one stable immutable identifier for:

- raw document external id
- raw event key seed
- canonical duplicate group seed
- source cursor candidate

Candidate patterns to evaluate:

- disclosure number
- disclosure history number
- document id
- TDnet/JPX artefact id
- PDF URL token
- security code + publication date/time + sequence

Do not rely on title text alone.

### 4) What should the cursor be?

Candidate cursor shapes:

- latest disclosure datetime + disclosure number
- latest disclosure datetime + document id
- disclosure number + disclosure history number
- latest publication datetime + stable PDF URL token

The cursor must be deterministic and should not require title-text heuristics.

### 5) What is the minimum raw-document set?

The first isolated slice should use the smallest deterministic set, for example:

- one discovery row
- one detail page
- one PDF/attachment only if the detail page is not enough

## Source inspection checklist

For every candidate source, fill:

- sample issuer/company
- sample security code
- sample title
- publication datetime local
- publication datetime UTC conversion rule
- detail URL
- attachment URL, if required
- visible stable id fields
- cursor field candidates
- category/family filter behavior
- pagination behavior
- whether JavaScript, paid access, session behavior, or retention limits block deterministic capture

## Implementation gate

Do not add runtime code until the following are written down in one place:

- chosen official source
- chosen source key
- chosen adapter key
- chosen parser strategy
- chosen discovery mode
- chosen hydrate mode
- chosen cursor key
- chosen document identity rule
- chosen first event family
- chosen first canonical event type
