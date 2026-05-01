# EDINET runtime promotion gate

This document defines the next gate for promoting EDINET from fallback candidate to isolated runtime work.

This is docs-only. It does not implement EDINET runtime.

## Current state

EDINET has candidate docs but no frozen sample and no runtime.

Existing candidate direction:

```text
source_key candidate: jp_edinet_statutory_report
adapter_key candidate: jp_edinet_statutory_report_v1
source_tier candidate: official_regulatory_storage
family candidate: statutory_report_update / periodic_report
identity candidate: EDINET:<docID>
cursor candidate: latest_submit_datetime_and_doc_id_seen or latest_submit_date_and_doc_id_seen
```

## Promotion condition

Promote EDINET only when one deterministic official sample has:

```text
docID or equivalent official stable ID
EDINET code or filer identity
submission date or datetime
primary document request shape
primary document format
one document type / family
one primary document fixture strategy
```

## Preferred v0 sample

Preferred sample properties:

```text
one EDINET document-list API row
one statutory report / periodic report family
one docID
one primary PDF or JSON/text representation
```

Avoid first v0 samples requiring:

```text
multiple XBRL packages
multiple attachments
broad date pagination
many document types
issuer-title-only identity
```

## EDINET v0 contract fields to freeze

```text
source_key
adapter_key
display_name
region_code = jp
source_class = regulatory_filing_feed
source_tier = official_regulatory_storage
source_type allowed by current DB enum
parser_strategy
discovery_mode
hydrate_mode
stable_external_id
cursor_key
cursor_value
event_family
canonical_event_type
event_id
raw document identities
minimum raw-document set
```

## Required docs before runtime

Either create a close-out with concrete values:

```text
apps/backend/disclosure_api/docs/jp_edinet_statutory_report_contract_freeze_closeout.md
apps/backend/disclosure_api/docs/jp_edinet_statutory_report_runtime_workset_plan.md
```

Or create a no-go:

```text
apps/backend/disclosure_api/docs/jp_edinet_sample_capture_no_go.md
```

## Runtime PR guardrails

The first EDINET runtime PR must not include:

```text
TDnet broad ingestion
JPX Listed Company Search adapter
CN broad expansion
news overlay
cross-source merge
multiple EDINET document families
broad EDINET pagination
```

## Current recommendation

Next concrete task: capture or choose one EDINET API sample and fill `jp_edinet_contract_freeze_input_sheet.md`.
