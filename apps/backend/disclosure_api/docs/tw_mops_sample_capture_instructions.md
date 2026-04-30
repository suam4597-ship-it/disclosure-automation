# TW MOPS sample capture instructions

This document describes the minimum user/browser-side capture needed to finish the TW MOPS contract freeze.

## Why this is needed

The TW discovery-first branch has identified MOPS / 公開資訊觀測站 material information as the current preferred first source family.
However, the runtime contract should not be frozen until one concrete public result and its detail page have been captured.

## Target family

Preferred first family:

- `material information / major announcement`

Preferred public path family:

- `https://mops.twse.com.tw/mops/web/t05st01`

## Minimum capture needed

Capture exactly one deterministic row and its detail page.

### 1) Search result row

Record or export one row with:

- company code
- company name
- announcement date
- announcement time, if present
- title / subject
- category / type, if present
- any sequence id / announcement id / detail token
- detail URL or action target

### 2) Detail page

Open the same row and save or copy:

- full detail page HTML, or a screenshot plus copied text if HTML save is unavailable
- detail URL
- visible announcement id or sequence id
- company code / name
- announcement date/time
- full disclosure body
- any attachment URL

### 3) Date/time format

Record whether the page uses:

- Gregorian year, e.g. `2026`
- ROC year, e.g. `115`
- local timezone implied by page, expected `Asia/Taipei`

### 4) Identity candidate

Identify the strongest stable id candidate in this order:

1. explicit announcement id / sequence id
2. stable detail URL token or query params
3. company code + date/time + sequence
4. company code + date + title only as last resort

## Acceptable handoff formats

Any one of these is enough to continue:

- exported CSV / XLS / HTML from the result page
- copied search-result row text + saved detail HTML
- screenshot plus copied detail body text
- browser network response payload if available

## What not to capture first

Do not start with broad all-announcements results.
Do not capture periodic financial reports unless material-information identity/cursor semantics cannot be frozen.

## After capture

Once the sample is available, fill:

- `tw_mops_public_surface_inspection_worksheet.md`
- `tw_mops_contract_freeze_input_sheet.md`

Then open the isolated implementation PR.
