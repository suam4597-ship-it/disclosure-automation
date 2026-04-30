# JP TDnet public sample capture attempt

This document records the first post-preflight attempt to capture a deterministic public TDnet sample after PR #40.

This is docs-only. It does not freeze a runtime contract and does not add runtime code, sample YAML, fixtures, tests, ops runner, or dedupe SQL.

## Current status

- base PR: #40 `JP TDnet contract-freeze preflight`
- base merge commit: `61a635ba8733c827dc57d85a030460c25b139f9a`
- current branch: `chatgpt-jp-tdnet-contract-freeze-closeout-v1`
- current goal: determine whether TDnet public sample capture can satisfy contract-freeze gates
- result: `no-go for freeze from this attempt`

## Current locked baseline

Keep these locked:

- SEC 6-K
- SEC 8-K
- SEC SC TO-T
- SEC SC 14D-9
- SEC SC 13D/A
- AFM substantial holdings
- UK FCA NSM takeover/scheme
- TW MOPS material information
- CNInfo ownership-change

## Surfaces attempted

### Company Announcements Disclosure Service landing page

```text
https://www.release.tdnet.info/inbs/I_main_00.html
```

Observed result in this capture environment:

```text
blocked / unavailable to automated fetch
```

Decision:

Do not freeze from the landing page alone. It confirms the expected official public surface from JPX docs, but it did not provide row-level sample values in this capture attempt.

### Generated daily list URL pattern

Common public TDnet list URL shape documented by third-party TDnet scraping writeups:

```text
https://www.release.tdnet.info/inbs/I_list_001_<YYYYMMDD>.html
```

Example shape only:

```text
https://www.release.tdnet.info/inbs/I_list_001_20260501.html
```

Observed result in this capture environment:

```text
not captured from official page
```

Decision:

Do not freeze from the generated URL pattern alone. The runtime contract must rely on a captured official row, not only an inferred URL pattern.

### Official TDnet PDF URL token shape

Secondary public pages and historic references show TDnet PDF URLs with stable-looking numeric file tokens such as:

```text
https://www.release.tdnet.info/inbs/140120260331594728.pdf
```

Potential token from URL:

```text
140120260331594728
```

Observed result in this capture environment:

```text
PDF endpoint unavailable to automated fetch
```

Decision:

A PDF token may become a valid stable identity fallback only after an official row and PDF/document can be captured from the public TDnet or JPX Listed Company Search surface.

## Secondary sample candidates observed

These are not accepted as frozen samples because they were observed through secondary pages, not through the official TDnet row source.

### Candidate A

```text
security_code: 4316
issuer/name from secondary page: ビーマップ
secondary description: 上場廃止へ
secondary-observed PDF URL: https://www.release.tdnet.info/inbs/140120260331594728.pdf
pdf_token: 140120260331594728
```

Reject for freeze because:

- official TDnet row was not captured
- official publication datetime was not captured
- official title was not captured from the row
- official category/material field was not captured
- PDF text was not captured

### Candidate B

```text
security_code: 4626
issuer/name from secondary page: 太陽HD
secondary description: KKRがTOB
secondary-observed PDF URL: https://www.release.tdnet.info/inbs/140120260331595223.pdf
pdf_token: 140120260331595223
```

Reject for freeze because:

- official TDnet row was not captured
- official publication datetime was not captured
- official title was not captured from the row
- official category/material field was not captured
- PDF text was not captured

## What this attempt proves

This attempt is useful but insufficient.

It supports the following:

- TDnet public PDF URL tokens are likely usable as a fallback identity component.
- The public daily list URL pattern is likely deterministic.
- A manual browser or separate fetch path should be able to capture row-level fields.

It does not support the following:

- freezing `stable_external_id`
- freezing `cursor_key`
- freezing `cursor_value`
- freezing `event_id`
- freezing `event_family`
- freezing `canonical_event_type`
- building fixtures
- starting runtime implementation

## No-go decision for this attempt

```text
JP TDnet contract-freeze: NO-GO
reason: no official row-level sample captured in this attempt
```

## Required evidence before freeze

The next capture pass must produce one official row with:

```text
sample issuer
sample security code
sample official title
sample publication date local
sample publication time local
sample publication datetime local with +09:00
sample publication datetime UTC
sample category/material type if visible
sample detail URL if any
sample PDF/document URL
sample stable token or disclosure number
sample document MIME type
```

## Identity/cursor candidates to verify next

Preferred identity after successful capture:

```text
TDNET:<disclosure_number>
```

Fallback identity if no disclosure number is public:

```text
TDNET:<pdf_or_document_token>
```

Preferred cursor after successful capture:

```text
latest_disclosure_datetime_and_disclosure_number_seen
<YYYY-MM-DDTHH:MM:SS+09:00>|<disclosure_number>
```

Fallback cursor if no disclosure number is public:

```text
latest_disclosure_datetime_and_pdf_token_seen
<YYYY-MM-DDTHH:MM:SS+09:00>|<pdf_or_document_token>
```

## Next step

Use the manual capture runbook to save one official TDnet row and linked document metadata, then update `jp_tdnet_contract_freeze_input_sheet.md` with concrete values.
