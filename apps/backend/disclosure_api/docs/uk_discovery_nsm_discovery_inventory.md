# UK discovery + NSM discovery inventory

This document is for freezing the UK first-vertical input model before implementation.

## Discovery questions to close

### 1) What is the primary discovery surface?

Need to lock one of these patterns:

- search / listing page
- archive page
- structured export
- document feed
- detail-only archive with separate discovery layer

### 2) What is the NSM role?

Need to decide whether NSM is:

- the primary discovery surface
- the authoritative detail archive
- both discovery and detail
- a secondary confirmation source behind a different discovery surface

### 3) What is the stable external identity?

The first UK slice needs one stable immutable identifier for:

- raw document external id
- raw event key seed
- canonical duplicate group seed
- source cursor candidate

Possible patterns to test once source details are frozen:

- filing id
- company + date + title hash
- archive document id
- detail url token

### 4) What should the cursor be?

Candidate cursor shapes:

- latest document id seen
- latest published timestamp seen
- latest archive sequence seen
- latest search page anchor seen

The runtime path should not be written until this is explicit.

### 5) What is the first event family?

The first UK thin slice should use a deliberately narrow family, for example:

- regulated disclosure
- annual financial report
- half-year financial report
- director dealing
- takeover / scheme related update

Freeze only one first.

## Implementation gate

Do not add runtime code until the following are written down in one place:

- chosen source key
- chosen adapter key
- chosen parser key
- chosen cursor key
- chosen document identity rule
- chosen first event family
- chosen first canonical event type
