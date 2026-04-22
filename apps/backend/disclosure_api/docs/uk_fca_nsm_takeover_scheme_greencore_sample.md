# UK FCA NSM takeover / scheme sample — Greencore Group PLC

This document records the first concrete takeover / scheme sample used to tighten the UK NSM source contract.

## Sample identity

- issuer: `Greencore Group PLC`
- related context: `Bakkavor Group plc recommended acquisition`
- sample kind: `Results of Extraordinary General Meeting / Result of Meeting`
- family signal: `takeover / scheme related update`

## Discovery hints

Reproducible search approaches observed during investigation:

- NSM UI `Document Text = scheme of arrangement`
- NSM UI `Document Text = takeover scheme`
- external discovery support query: `site:data.fca.org.uk/artefacts/NSM/RNS "scheme of arrangement" "Greencore Group PLC"`

## Detail artefact

- NSM artefact URL: `https://data.fca.org.uk/artefacts/NSM/RNS/5726018.html`
- namespace / source path: `NSM/RNS`
- artefact token: `5726018`

## Public ids observed on the detail page or paired public surfaces

- RNS Number: `8538P`
- RNS END code: `ROMBDGDRBSGDGUS`
- LSE article id: `17120644`
- public issuer name: `Greencore Group PLC`

Not observed directly on the public detail HTML:

- `UniqueAnnouncementID`
- version field

## Time values observed

- NSM detail page shows date: `04 July 2025`
- paired LSE / RNS result shows time: `13:44:18 04 Jul 2025`

## Paired original / external public link

- NSM artefact HTML: `https://data.fca.org.uk/artefacts/NSM/RNS/5726018.html`
- paired LSE / RNS page: `https://www.londonstockexchange.com/news-article/GNC/result-of-meeting/17120644`

## Why this is a valid takeover / scheme sample

The artefact text contains strong takeover / scheme indicators including:

- `recommended acquisition`
- `Scheme`
- `Court-sanctioned scheme of arrangement`
- `Takeover Code`

The body explains that resolutions relating to the acquisition of Bakkavor Group plc passed at the EGM and that the transaction is expected to proceed by a court-sanctioned scheme of arrangement under Part 26 of the Companies Act 2006.

## Provisional stable-id ranking from this sample

1. `NSM:RNS:5726018`
2. `UniqueAnnouncementID + Version` once exposed in CSV or another public metadata surface
3. `RNS Number + publication date + issuer`
4. `LSE article id`
5. tracking-only: `RNS END code`

## Contract impact

This sample materially strengthens the current preferred UK first-slice family:

- `takeover / scheme related update`

It also provides enough evidence to prefer the following provisional implementation direction:

- source family based on FCA NSM `RNS` artefact pages
- raw detail document based on `artefacts/NSM/RNS/<token>.html`
- parser strategy based on HTML extraction plus RNS header parsing

## Remaining uncertainty

The following are still not fully frozen from this sample alone:

- whether `artefact token` is the best cursor field for repeated polling
- whether the public CSV export exposes a stronger immutable id or version signal
- whether a linked filing payload is ever required for the first deterministic normalization path
- exact category / headline-code value to preserve from the official metadata layer
