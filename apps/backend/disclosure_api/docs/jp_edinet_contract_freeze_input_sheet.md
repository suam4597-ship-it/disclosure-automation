# JP EDINET contract-freeze input sheet

Use this sheet only if TDnet / JPX fails the final manual or Listed Company Search sample gate and EDINET is promoted as the fallback JP source.

This sheet is docs-only. Filling it does not start runtime implementation.

## Scope

```text
source candidate: EDINET
source_key candidate: jp_edinet_statutory_report
adapter_key candidate: jp_edinet_statutory_report_v1
source_tier candidate: official_regulatory_storage
first family candidate: statutory_report_update or periodic_report_update
```

## Promotion precondition

- [ ] TDnet Company Announcements manual capture failed or was explicitly deferred
- [ ] JPX Listed Company Search historical capture failed or was explicitly deferred
- [ ] EDINET is being evaluated as a separate official-regulatory fallback, not mixed with TDnet

## EDINET source evidence

Record the source/API evidence used for this sample:

```text
official/API catalog URL: TODO
EDINET API guide URL: TODO
API version, if visible: TODO
discovery endpoint/request shape: TODO
primary document endpoint/request shape: TODO
```

## Sample metadata

Capture exactly one EDINET document-list row and one primary document.

```text
sample filer / issuer: TODO
sample EDINET code: TODO
sample securities code: TODO or not available
sample docID: TODO
sample document type / docTypeCode: TODO
sample document title or description: TODO
sample submission date local: TODO
sample submission datetime local: TODO or not available
sample submission datetime UTC: TODO
sample document format: TODO
sample primary document request shape: TODO
```

## Stable identity decision

Preferred:

```text
stable_external_id: EDINET:<docID>
raw_event_key_seed: EDINET:<docID>
duplicate_group_seed: EDINET:<docID>
```

Fallback, only if `docID` is unavailable but equivalent official metadata is stable:

```text
stable_external_id: EDINET:<EDINETCode>:<submitDateTime>:<docTypeCode>
```

Chosen identity:

```text
stable_external_id: TODO
raw_event_key_seed: TODO
duplicate_group_seed: TODO
```

Reject if identity requires filer name, issuer name, or document title.

## Cursor decision

Preferred:

```text
cursor_key: latest_submit_datetime_and_doc_id_seen
cursor_value: <YYYY-MM-DDTHH:MM:SS+09:00>|<docID>
```

Fallback for date-only sample:

```text
cursor_key: latest_submit_date_and_doc_id_seen
cursor_value: <YYYY-MM-DD>|<docID>
```

Chosen cursor:

```text
cursor_key: TODO
cursor_value: TODO
```

## Family decision

Preferred:

```text
event_family: statutory_report_update
canonical_event_type: periodic_report
```

Alternative:

```text
event_family: periodic_report_update
canonical_event_type: periodic_report
```

Chosen family:

```text
event_family: TODO
canonical_event_type: TODO
```

## Raw document set

Preferred v0 set:

```text
raw_document_1_external_id: EDINET:<docID>:document-list-row
raw_document_1_role: discovery_metadata
raw_document_1_mime_type: application/json

raw_document_2_external_id: EDINET:<docID>:primary-document:<document_format>
raw_document_2_role: primary_regulatory_disclosure
raw_document_2_mime_type: TODO
```

Chosen raw documents:

```text
raw_document_1_external_id: TODO
raw_document_1_role: discovery_metadata
raw_document_1_mime_type: application/json

raw_document_2_external_id: TODO
raw_document_2_role: primary_regulatory_disclosure
raw_document_2_mime_type: TODO
```

## Expected normalized values

Fill only after capture:

```text
source_key: jp_edinet_statutory_report
adapter_key: jp_edinet_statutory_report_v1
region_code: jp
source_tier: official_regulatory_storage
stable_external_id: TODO
cursor_key: TODO
cursor_value: TODO
event_id: TODO
event_family: TODO
canonical_event_type: TODO
published_at_local: TODO
published_at_utc: TODO
filing_date_local: TODO
```

## Freeze pass criteria

- [ ] TDnet final gate failed or was explicitly deferred
- [ ] one EDINET document-list row captured
- [ ] one primary document captured or represented
- [ ] stable `docID` or equivalent stable official ID captured
- [ ] cursor does not use title text
- [ ] one family selected
- [ ] raw-document set is limited to two documents
- [ ] timestamp convention is explicit
- [ ] future runtime PR can stay one source, one family, one fixture item

## Freeze decision

```text
TODO: freeze / do not freeze / return to TDnet
```
