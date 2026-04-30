# TW discovery inventory

This document tracks the official-source discovery work for the first Taiwan vertical.

## Discovery questions to close

### 1) What is the official public source?

Need to confirm the primary official public disclosure surface.

Candidate source family to investigate:

- Taiwan public listed-company disclosure system / Market Observation Post System style public disclosure surface

Do not freeze source names, URLs, adapter keys, or parser keys until the official surface is verified.

### 2) What is the first high-signal family?

The first TW slice should not ingest every announcement type.

Candidate priority order:

1. material information / major announcement
2. M&A / merger / acquisition / tender-offer style update
3. shareholding / director / insider related update
4. periodic report

### 3) What is the stable external identity?

The first implementation slice needs one stable immutable identifier for:

- raw document external id
- raw event key seed
- canonical duplicate group seed
- source cursor candidate

Candidate patterns to evaluate:

- announcement id
- company code + date/time + sequence
- detail page token
- document id
- filing serial number

### 4) What should the cursor be?

Candidate cursor shapes:

- latest filing datetime + announcement id
- latest disclosure sequence id
- latest detail URL token
- latest public document id

Do not rely on title text alone.

### 5) What is the minimum raw-document set?

The first isolated slice should use the minimum deterministic set, for example:

- one discovery row
- one detail page
- linked attachment only if needed

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
