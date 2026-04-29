# UK discovery + NSM kickoff

AFM substantial holdings is now locked.

Current locked baseline:

- 6-K
- 8-K
- SC TO-T
- SC 14D-9
- SC 13D/A
- AFM substantial holdings

This file starts the next Stage 4 target:

- `UK discovery + NSM`

## Why this starts as discovery-first

Unlike the AFM first slice, the UK target should not begin by guessing a runtime adapter or fixture shape.
The next step is to freeze the external source model first:

1. discovery entry point
2. archive / detail path
3. stable item identity
4. cursor candidate
5. isolated fixture candidate

Only after those are frozen should the repo add source helpers, sample YAML, fixtures, runtime adapter code, and tests.

## Guardrail

Do not jump to:

- TW
- CN
- JP
- news overlay
- cross-source merge

until the UK discovery + NSM shape is understood and staged.

## Expected Stage 4 flow from here

1. UK discovery + NSM discovery memo
2. freeze source key, adapter shape, and cursor semantics
3. create an isolated sample + fixture path
4. add tests and dedupe SQL
5. lock the first UK vertical
