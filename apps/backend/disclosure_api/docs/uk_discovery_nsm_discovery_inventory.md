# UK discovery + NSM discovery inventory

This document is for freezing the UK first-vertical input model before implementation.

## Confirmed official findings

The following are now confirmed from FCA public materials and current NSM examples:

- the National Storage Mechanism (NSM) is the FCA's official system for storing regulated announcements and disclosed documents
- public users can search disclosures using company name, LEI, filing date, and keywords or phrases in document content
- public users can view, download, and export search results to CSV for free
- regulatory announcements reach the NSM via Primary Information Providers (PIPs)
- Annual Financial Reports and other regulated information not disseminated in unedited full text via a PIP are submitted through ESS using the NSM upload path
- structured Annual Financial Reports can also be viewed and downloaded on the NSM
- current public entry to the search interface is `https://data.fca.org.uk/#/nsm/nationalstoragemechanism`
- current public detail/archive pages are observed under patterns such as `https://data.fca.org.uk/artefacts/NSM/RNS/<uuid>.html`

These findings are enough to move the UK work from a pure blank page into a partially frozen discovery state.

## Discovery questions to close

### 1) What is the primary discovery surface?

Current best answer:

- the public NSM search interface is the primary discovery surface

Still to close:

- whether there is any structured export or easier machine-consumable search layer worth using instead of the browser search surface

### 2) What is the NSM role?

Current best answer:

- the NSM is both a public discovery surface and an authoritative public archive for at least some regulated disclosures

Still to close:

- whether the first thin slice should treat NSM as both discovery and detail
- whether a separate issuer or RNS surface should still be used as a supporting discovery channel

### 3) What is the stable external identity?

The first UK slice needs one stable immutable identifier for:

- raw document external id
- raw event key seed
- canonical duplicate group seed
- source cursor candidate

Observed candidate patterns:

- artefact URL token
- RNS number
- company + date + title combination

Still to close:

- which of these is always present on the chosen first thin slice
- which one survives corrections best

### 4) What should the cursor be?

Candidate cursor shapes:

- latest published timestamp seen
- latest artefact id seen
- latest search result sequence seen
- latest document id seen

Current recommendation:

- prefer a cursor that is explicit in the public search results or artefact URL, rather than inventing one from title text

The runtime path should not be written until this is explicit.

### 5) What is the first event family?

The first UK thin slice should use a deliberately narrow family.

Current recommendation:

- start with annual financial reports

Why this is the current best first slice:

- FCA materials explicitly describe Annual Financial Reports as a submission path into the NSM
- structured and unstructured annual reports are clearly discussed in the official guidance
- annual report examples are easy to observe in current NSM-linked disclosures

Alternative families for later expansion:

- half-year financial report
- director dealing
- takeover / scheme related update
- broader regulated disclosure

## Implementation gate

Do not add runtime code until the following are written down in one place:

- chosen source key
- chosen adapter key
- chosen parser key
- chosen cursor key
- chosen document identity rule
- chosen first event family
- chosen first canonical event type
