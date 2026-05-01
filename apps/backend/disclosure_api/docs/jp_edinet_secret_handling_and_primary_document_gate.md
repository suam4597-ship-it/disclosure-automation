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
runtime status: blocked
```

Runtime remains blocked because the type=1 primary document payload/text has not been captured.

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

curl.exe -sS -D "edinet_${DOCID}_headers.txt" `
  -o "edinet_${DOCID}_type1_payload.bin" `
  "https://api.edinet-fsa.go.jp/api/v2/documents/${DOCID}?type=1&Subscription-Key=$env:EDINET_API_KEY"
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

The latest type=1 attempt returned an HTTP 200 transport response with a JSON body that indicated EDINET authorization failure:

```text
statusCode: 401
message: Access denied due to invalid subscription key. Make sure to provide a valid key for an active subscription.
```

The documents list endpoint still returned:

```text
metadata.status: 200
metadata.message: OK
metadata.resultset.count: 384
```

Interpretation:

```text
the current list API access is not enough to implement EDINET runtime
primary document access remains blocked until a key/subscription with type=1 access succeeds
```

## Required payload before runtime

Provide one of:

```text
1. extracted primary document text for docID S100XZXO
2. type=1 response headers plus a stable extraction plan and a non-secret payload fixture
```

Minimum acceptable runtime fixture evidence:

```text
docID: S100XZXO
request shape: https://api.edinet-fsa.go.jp/api/v2/documents/S100XZXO?type=1&Subscription-Key=<redacted>
content-type: TODO
content-disposition: TODO
content-length: TODO
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

If type=1 access continues to fail, create only a docs PR marking EDINET runtime as blocked and proceed to Stage 5 kickoff with EDINET explicitly deferred.
