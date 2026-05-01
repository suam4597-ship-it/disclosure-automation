# JP EDINET type=1 ZIP extraction plan

This document defines how to turn the confirmed EDINET type=1 ZIP payload into a non-secret primary document text fixture for the isolated EDINET runtime.

This is docs-only. It does not add EDINET runtime, fixtures, tests, ops runner, or dedupe SQL.

## Confirmed payload

```text
docID: S100XZXO
request shape: https://api.edinet-fsa.go.jp/api/v2/documents/S100XZXO?type=1&Subscription-Key=<redacted>
HTTP status: 200 OK
content-type: application/octet-stream
content-length: 10329
content-disposition: inline; filename="S100XZXO_1.zip"
payload file: edinet_S100XZXO_type1_payload.bin
first bytes: 50 4B 03 04 14 00 00 00
```

## Secret rule

Never commit:

```text
EDINET API key
unredacted request URL
shell history containing the key
raw logs containing the key
```

All committed request shapes must use:

```text
Subscription-Key=<redacted>
```

## Local ZIP listing command

Use local shell only:

```powershell
$DOCID = 'S100XZXO'
Expand-Archive -LiteralPath "edinet_${DOCID}_type1_payload.bin" -DestinationPath "edinet_${DOCID}_type1_unzipped" -Force
Get-ChildItem "edinet_${DOCID}_type1_unzipped" -Recurse | Select-Object FullName, Length
```

If `Expand-Archive` rejects `.bin`, copy it first:

```powershell
Copy-Item "edinet_${DOCID}_type1_payload.bin" "edinet_${DOCID}_type1.zip"
Expand-Archive -LiteralPath "edinet_${DOCID}_type1.zip" -DestinationPath "edinet_${DOCID}_type1_unzipped" -Force
```

## Candidate extraction priority

Choose the first available readable source:

1. plain text or HTML filing body
2. XBRL/XML document from the ZIP
3. PDF text extraction from the ZIP, if PDF exists
4. minimal metadata-only text fixture only if the ZIP contains no readable body text

## Required extraction output

Before EDINET runtime implementation, provide:

```text
zip file list
selected primary file path inside ZIP
selected primary file content type
extraction method
primary document text excerpt
any encoding note
```

## Non-secret fixture requirement

The future runtime fixture should be a text representation, not the secret-bearing API request.

Preferred fixture path:

```text
apps/backend/disclosure_api/priv/fixtures/source_payloads/jp_edinet_statutory_report_primary_document_S100XZXO.txt
```

Expected fixture content must include enough text to support:

```text
野村アセットマネジメント株式会社
S100XZXO
E12460
臨時報告書（内国特定有価証券）
submitDateTime 2026-04-30 09:00 or equivalent filing timestamp context
```

## Runtime implementation gate

EDINET runtime can start only after the extraction output above is available.

The runtime PR must include exactly one fixture item:

```text
docID: S100XZXO
stable_external_id: EDINET:S100XZXO
event_id: jp.edinet.E12460.20260430.extraordinary_report.statutory_report_update.S100XZXO
```

Do not add:

```text
EDINET broad pagination
multiple EDINET document families
TDnet changes
CNInfo changes
news overlay
cross-source merge
API key material
```
