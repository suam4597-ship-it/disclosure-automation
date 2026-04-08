# US SEC expansion plan

## Current state
- runtime spine for `sec_current_forms` exists on the SEC thin-slice upload branch
- current closed smoke target is `6-K`
- current next-form hooks already exist in `SECAdapter` for `8-K`, `SC TO-T`, `SC 14D-9`, and `SC 13D/A`

## Phase ordering

### Phase 1a
Goal: close one honest slice end to end.
- `6-K`
- fixture-first smoke
- accepted-time parsing from detail index
- canonical contract, feed snapshot, and event endpoints

### Phase 1b
Goal: add the next high-signal current-event forms that match the current adapter heuristics.
- `8-K`
- `SC TO-T`
- `SC 14D-9`
- `SC 13D/A`

Required work:
- extend `supported_forms_now`
- add fixture coverage for each form
- verify event-family and canonical-event-type mappings
- verify dedupe and filing-date behavior per form

### Phase 1c
Goal: broaden from current-event forms into periodic and proxy forms.
- `10-K`
- `10-Q`
- `20-F`
- `6-K` broader coverage
- `DEF 14A`
- `S-4`

Required work:
- split current-filings feed logic from periodic-filing discovery logic where needed
- add richer parser heuristics per form family
- add more explicit importance-band and event-family mapping tables
- handle issuer home-market overlap and cross-listing review rules

### Phase 2
Goal: mature beyond SEC-only current forms.
- EDGAR ownership / holdings forms where useful
- cross-source joins with SEC press releases
- US exchange notices and issuer IR sources for citation layering

## Work checklist
1. finish applying the local patched workspace over `p21`
2. run `mix format`, `mix ecto.migrate`, and `mix compile`
3. close `6-K` smoke and dedupe checks
4. add fixture sets for `8-K`, `SC TO-T`, `SC 14D-9`, `SC 13D/A`
5. promote those forms from `planned_forms_next` into `supported_forms_now`
6. add tests for accepted-time fallback and filing-date normalization
7. decide whether `10-K`/`10-Q` stay on the same discovery path or move to a separate SEC source key

## Recommendation
Keep the next engineering milestone narrow:
- first complete the `p21 + local patched workspace` merge
- then close `6-K`
- then expand only to the four next-form targets already reflected in the adapter heuristics
