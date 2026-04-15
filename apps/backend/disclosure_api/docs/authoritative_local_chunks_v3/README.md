# authoritative local chunks v3

This directory contains the exact base64 chunk set for the authoritative local `pipeline.ex` used to lock the SEC 6-K path.

Reconstruction rule:
- concatenate `pipeline.ex.b64.chunk001` through `pipeline.ex.b64.chunk015` in lexical order
- decode the concatenated base64 into `lib/disclosure_automation/pipeline.ex`

Verification:
- compare against `docs/sec_authoritative_local_manifest.md`
- then run the minimal 6-K lock verification path
