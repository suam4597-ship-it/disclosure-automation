# JP EDINET sample capture API-key gate

This document records the immediate EDINET sample-capture gate after the post-lock broad expansion sequencing PR.

This is docs-only. It does not implement EDINET runtime and does not create synthetic EDINET fixtures.

## Current state

- JP TDnet timely disclosure is locked.
- EDINET remains a separate official-regulatory fallback/runtime candidate.
- EDINET sample capture is required before runtime implementation.
- In the current environment, no EDINET API sample was captured.

## Why EDINET cannot be promoted yet

The EDINET v0 contract requires a real official API/document sample with:

```text
docID
EDINET code or filer identity
submission date or datetime
document type / docTypeCode
primary document request shape
primary document format
stable external id
cursor value
```

Do not invent these values.

## API-key gate

EDINET API access should be captured through the official API flow with the required authentication/key setup for the current EDINET API version.

Until a real API response is captured, EDINET runtime remains blocked.

## Required sample output

Provide one official EDINET document-list row and one primary document payload or text representation.

Minimum values:

```text
sample filer / issuer
sample EDINET code
sample securities code, if available
sample docID
sample document type / docTypeCode
sample document title or description
sample submission date local
sample submission datetime local, if available
sample submission datetime UTC or date-only convention
sample API discovery request shape
sample primary document request shape
sample document format
stable_external_id
cursor_key
cursor_value
event_family
canonical_event_type
event_id
raw document external ids
```

## Candidate contract if sample is captured

```text
source_key: jp_edinet_statutory_report
adapter_key: jp_edinet_statutory_report_v1
source_tier: official_regulatory_storage
stable_external_id: EDINET:<docID>
preferred cursor_key: latest_submit_datetime_and_doc_id_seen
fallback cursor_key: latest_submit_date_and_doc_id_seen
event_family: statutory_report_update or periodic_report_update
canonical_event_type: periodic_report
```

## No-go condition

If no API key or official API response is available, do not create EDINET runtime.

Create only:

```text
jp_edinet_sample_capture_no_go.md
```

Then proceed to JP TDnet broad ingestion readiness or CN broad expansion readiness.

## Guardrails

Do not add:

```text
synthetic EDINET docID values
EDINET runtime without an official sample
TDnet changes
CN broad changes
news overlay
cross-source merge
```

## Current decision

EDINET runtime is blocked until an official EDINET API sample is supplied.
