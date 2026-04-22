# AFM substantial holdings kickoff

SEC sibling forms are already locked and closed:

- 6-K
- 8-K
- SC TO-T
- SC 14D-9
- SC 13D/A

This file starts Stage 4 regional vertical expansion with an isolated AFM first slice.

## Scope

Target source:

- `afm_substantial_holdings`
- display name: `AFM Substantial Holdings and Gross Short Positions`
- region: `nl`
- adapter: `afm_substantial_holdings_v1`

## First-slice rule

Do not jump to:

- UK discovery + NSM
- TW
- CN
- JP
- news overlay
- cross-source merge

until the AFM isolated fixture path is green.

## Initial runtime shape

The AFM first slice follows the runtime adapter contract already used by SEC:

1. `discover`
2. `hydrate`
3. `parse`
4. `normalize`

This kickoff keeps the scope intentionally narrow:

- one isolated XML fixture row
- one raw event
- two raw documents (`register-export` and `detail-page`)
- one canonical feed item
- one stable source cursor
