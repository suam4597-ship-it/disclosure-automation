# JP EDINET secret handling and primary document gate

This document records the required secret-handling policy for EDINET runtime work after the EDINET contract-freeze PR.

This is docs-only. It does not add EDINET runtime, fixtures, tests, ops runner, or dedupe SQL.

## Current EDINET status

```text
contract-freeze PR: #56
source_key: jp_edinet_statutory_report
adapter_key: jp_edinet_statutory_report_v1
docID: S100XZXO
stable_external_id: EDINET:S100XZXO
runtime status: extraction pending
```

The type=1 primary document endpoint now returns a real ZIP payload for `S100XZXO`, but the ZIP contents have not yet been listed or converted into a non-secret text fixture.

## Secret handling policy

Do not commit, log, print, or store the EDINET API key in:

```text
source code
fixtures
docs
PR bodies
commit messages
ops scripts
test output
portable citations
runtime metadata
raw documents
```

Use only:

```text
EDINET_API_KEY
```

as the local environment variable or CI secret name.

All request shapes committed to the repository must use:

```text
Subscription-Key=<redacted>
```

## Exposed key rotation note

An EDINET API key was shared in chat during the workflow. Treat it as exposed.

Recommended action:

```text
revoke/rotate the exposed key in the EDINET portal
use a newly generated key only as EDINET_API_KEY in the local shell or CI secret store
```

Do not copy the exposed key into this repository.

## Local primary document capture command

Use a local shell only. Do not paste the real key into the command history if avoidable.

```powershell
$env:EDINET_API_KEY = '<local secret value>'
$DOCID = 'S100XZXO'
$requestShape = "https://api.edinet-fsa.go.jp/api/v2/documents/${DOCID}?type=1&Subscription-Key=<redacted>"
$requestUrl = $requestShape.Replace('<redacted>', [uri]::EscapeDataString($env:EDINET_API_KEY))

curl.exe -sS -D "edinet_${DOCID}_headers.txt" `
  -o "edinet_${DOCID}_type1_payload.bin" `
  $requestUrl
```

Before sharing output, redact any secret-bearing value.

Share only:

```text
response status
content-type
content-disposition
content-length
body summary
extracted primary document text, if extraction succeeds
request shape with Subscription-Key=<redacted>
```

## Current observed type=1 result

The latest type=1 attempt returned a real ZIP payload.

```text
docID: S100XZXO
request shape: https://api.edinet-fsa.go.jp/api/v2/documents/S100XZXO?type=1&Subscription-Key=<redacted>
HTTP status: 200 OK
content-type: application/octet-stream
content-length: 10329
content-disposition: inline; filename="S100XZXO_1.zip"
payload_file_name: edinet_S100XZXO_type1_payload.bin
payload_size_bytes: 10329
payload_check: ZIP payload
first bytes: 50 4B 03 04 14 00 00 00
```

The documents list endpoint also returned:

```text
metadata.status: 200
metadata.message: OK
metadata.resultset.count: 384
```

Interpretation:

```text
type=1 access is confirmed for docID S100XZXO
primary document runtime still needs a non-secret text fixture or stable extraction plan from the ZIP payload
```

## Required payload before runtime

Provide one of:

```text
1. extracted primary document text for docID S100XZXO
2. ZIP file listing plus selected text/XBRL/PDF extraction plan and a non-secret text fixture
```

Minimum acceptable runtime fixture evidence:

```text
docID: S100XZXO
request shape: https://api.edinet-fsa.go.jp/api/v2/documents/S100XZXO?type=1&Subscription-Key=<redacted>
content-type: application/octet-stream
content-disposition: inline; filename="S100XZXO_1.zip"
content-length: 10329
zip first bytes: 50 4B 03 04 14 00 00 00
zip file list: TODO
primary document text excerpt: TODO
extraction method: TODO
```

## Runtime blocker

Do not implement EDINET runtime until primary document fixture evidence exists.

Do not work around this by:

```text
inventing EDINET primary document text
using only the document-list row as the primary document
committing an API key
adding broad EDINET pagination
mixing TDnet or CNInfo code changes into EDINET runtime
```

## Next safe step

Extract or list the local ZIP payload, choose the primary text/XBRL/PDF source, and create a non-secret text fixture plan. Then implement the isolated `jp_edinet_statutory_report_v1` runtime with one fixture item only.
