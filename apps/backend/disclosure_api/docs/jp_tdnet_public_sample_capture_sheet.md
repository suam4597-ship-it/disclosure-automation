# JP TDnet public sample capture sheet

Use this sheet to capture the exact public TDnet/JPX sample before closing the JP contract-freeze.

Do not create runtime files from this sheet alone.

## Target source candidate

- target source candidate: `TDnet / JPX Company Announcements Disclosure Service`
- target source key candidate: `jp_tdnet_timely_disclosure`
- target first family candidate: `timely_disclosure_update`
- target canonical event type candidate: `material_information_update`
- backup event family candidate: `major_transaction_update`
- backup canonical event type candidate: `major_investment_or_asset_sale`

## Public source surfaces to inspect

Inspect these surfaces in this order:

1. JPX Company Announcements Disclosure Service
2. JPX Listed Company Search
3. TDnet API documentation as identity/cursor reference only
4. EDINET only if TDnet/JPX public sample capture fails

## Exact working source request

Fill after live inspection:

```text
method: TODO
url: TODO
headers required: TODO
query params: TODO
response status: TODO
captured at: TODO
```

## Exact discovery row or metadata

Paste the exact public row or normalized source metadata here.

```json
{
  "disclosure_number": "TODO",
  "disclosure_history_number": "TODO",
  "security_code": "TODO",
  "company_name": "TODO",
  "listed_exchange": "TODO",
  "disclosure_date": "TODO",
  "disclosure_time": "TODO",
  "disclosure_datetime_jst": "TODO",
  "title": "TODO",
  "public_item_code": "TODO",
  "file_existence_flag": "TODO",
  "detail_url": "TODO",
  "attachment_url": "TODO"
}
```

Do not fill unknown fields with guessed values.
Remove fields only if the source response truly does not provide them.

## Required public sample fields

The sample cannot freeze until these fields are known:

- company / issuer
- security code
- title
- source category or family indicator
- disclosure datetime local, JST
- disclosure datetime UTC
- stable identity field or document token
- detail URL, if used
- attachment/PDF URL, if used
- minimum raw-document set

## Stable identity evidence

Record the source field that will become the stable external identity.

Preferred evidence:

```text
source field name: TODO
source field value: TODO
stable_external_id rule: TODO
stable_external_id sample: TODO
```

Preferred rule:

```text
TDNET:<disclosure_number>:<disclosure_history_number>
```

Fallback rule:

```text
TDNET:<security_code>:<disclosure_datetime_jst>:<pdf_or_document_token>
```

Do not use title text as the stable external identity.

## Cursor evidence

Record the source fields that will become the cursor.

Preferred cursor:

```text
cursor_key = latest_disclosure_datetime_and_disclosure_number_seen
cursor_value = <YYYY-MM-DDTHH:MM:SS+09:00>|<disclosure_number>|<disclosure_history_number>
```

Fallback cursor:

```text
cursor_key = latest_disclosure_datetime_and_document_token_seen
cursor_value = <YYYY-MM-DDTHH:MM:SS+09:00>|<pdf_or_document_token>
```

Do not use title text as the cursor.

## Timestamp conversion

Fill after capture:

```text
published_at_local = TODO
published_at_utc = TODO
filing_date_local = TODO
```

Default assumption:

```text
source timezone = Asia/Tokyo / JST / UTC+09:00
```

## Raw-document set decision

Choose one:

```text
1. discovery row + detail page
2. discovery row + attachment/PDF
3. discovery row + detail page + attachment/PDF
```

For each raw document, record:

- raw document external id rule
- document identity rule
- document role
- MIME type
- source URL

## Derived contract values

Fill only after the exact public sample is captured.

### Event id

Candidate shape:

```text
jp.tdnet.<security_code>.<YYYYMMDD>.<canonical_event_type>.<event_family>.<stable_id_tail>
```

Fill after capture:

```text
event_id = TODO
```

### Event family and canonical event type

Preferred:

```text
event_family = timely_disclosure_update
canonical_event_type = material_information_update
```

Backup if the chosen sample is narrower:

```text
event_family = major_transaction_update
canonical_event_type = major_investment_or_asset_sale
```

## Required validation before freeze

Before the JP TDnet contract can be frozen, verify:

- source is official JPX/TSE/TDnet or official-regulatory EDINET
- row security code matches the chosen sample
- row title matches the chosen disclosure
- row disclosure datetime can produce deterministic local and UTC times
- stable identity is visible without title text
- cursor is visible without title text
- detail/PDF URL is stable enough for fixture capture
- minimum raw-document set is small and deterministic

## If public TDnet sample capture fails

Do not guess.

Either:

1. use JPX Listed Company Search to capture a historical TDnet disclosure sample; or
2. switch to EDINET as a periodic/statutory fallback in a separate candidate contract.

## Guardrail

If this sheet cannot be completed with public-source evidence, do not open JP runtime implementation.
Return to source discovery and choose a different sample or source surface.
