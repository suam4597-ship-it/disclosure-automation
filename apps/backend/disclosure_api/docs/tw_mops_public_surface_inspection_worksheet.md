# TW MOPS public surface inspection worksheet

This worksheet records the concrete TW MOPS material-information sample used to freeze the first TW implementation contract.

## Candidate family under inspection

- [x] `material information / major announcement`
- [ ] `M&A / merger / acquisition / tender-offer style update`
- [ ] `shareholding / director / insider related update`

## Search surface capture

- search entry URL: `https://mops.twse.com.tw/mops/web/t05st01`
- query endpoint or form path: `https://mopsov.twse.com.tw/mops/web/ajax_t05st01`
- query parameters used: `TYPEK=all&co_id=2330&firstin=1&seq_no=1&skey=2330202604301&spoke_date=20260430&spoke_time=162938&step=2`
- market filter: `上市公司 / listed company`
- company code / company name filter: `2330 / 台積電`
- date range used: concrete detail sample for `spoke_date=20260430`
- whether export/download is available: `not required for v0; detail action target provides deterministic fixture`

## One deterministic result row

- row title / subject: `本公司代子公司 TSMC Global Ltd. 公告取得固定收益證券`
- company code: `2330`
- company name: `台積電`
- filing date / time: `ROC 115/04/30 16:29:38`, Gregorian `2026-04-30 16:29:38 Asia/Taipei`
- announcement type / category: `符合條款 第 20 款`
- detail URL or action target: `https://mopsov.twse.com.tw/mops/web/ajax_t05st01?TYPEK=all&co_id=2330&firstin=1&seq_no=1&skey=2330202604301&spoke_date=20260430&spoke_time=162938&step=2`
- visible announcement id / sequence id: `co_id=2330`, `seq_no=1`, `skey=2330202604301`, `spoke_date=20260430`, `spoke_time=162938`
- any attachment URL: `none observed`

## Detail page capture

- detail URL: `https://mopsov.twse.com.tw/mops/web/ajax_t05st01?TYPEK=all&co_id=2330&firstin=1&seq_no=1&skey=2330202604301&spoke_date=20260430&spoke_time=162938&step=2`
- immutable token in URL or parameters: `co_id=2330`, `spoke_date=20260430`, `spoke_time=162938`, `seq_no=1`; auxiliary `skey=2330202604301`
- public announcement id on detail page: `序號 1`
- company code / name on detail page: `2330 台積電`
- published timestamp on detail page: `發言日期 115/04/30`, `發言時間 16:29:38`
- disclosure body text available directly? `yes`
- any linked attachment URL: `none observed`
- whether detail page alone is sufficient for normalization: `yes for v0`

## Identity decision

- chosen stable external identity field: `MOPS:<co_id>:<spoke_date>:<spoke_time>:<seq_no>`
- chosen stable external identity value: `MOPS:2330:20260430:162938:1`
- why this is better than the other candidates: `visible in deterministic action URL parameters and does not depend on title text; skey is useful but not always present across samples`
- whether this field is visible in both discovery and detail: `yes via URL/action params and detail body sequence/date/time fields`
- whether this field survives corrections / updates: `provisional; corrections/version behavior remains a later hardening item`

## Cursor decision

- chosen cursor key: `latest_spoke_date_time_and_sequence_seen`
- chosen cursor source field: `spoke_date + spoke_time + co_id + seq_no`
- chosen cursor value: `20260430|162938|2330|1`
- why this is stable enough: `uses deterministic action URL parameters rather than title text`
- why title text is not needed: `URL params expose date, time, company code, and sequence`

## Date/time normalization

- source date format: body uses ROC year, e.g. `115/04/30`; detail URL uses Gregorian `spoke_date=20260430`
- source time format: `HH:MM:SS`, e.g. `16:29:38`; URL uses `spoke_time=162938`
- timezone: `Asia/Taipei`
- ROC calendar conversion needed? `yes for body text; URL spoke_date already Gregorian`
- expected `published_at_local`: `2026-04-30T16:29:38+08:00`
- expected `published_at_utc`: `2026-04-30T08:29:38.000000Z`

## Raw-document minimum set

- discovery result payload needed? `yes, represented by one action-target/result-row fixture`
- detail page needed? `yes`
- linked attachment needed? `no for v0`
- minimum raw-document count per item: `2`

## Family boundary check

- chosen event family: `material_information_update`
- adjacent family risk: `the selected sample is an asset/securities acquisition disclosure under a material-information clause, not a broad periodic report`
- reason this item does not belong to a broader mixed bucket: `MOPS material-information detail page exposes a specific subject, clause number, event date, and numbered disclosure body`

## Freeze outcome

- [x] family passes contract-freeze exit criteria
- [ ] family fails contract-freeze exit criteria and should not be the first implementation slice

## Next action

- [x] open the isolated runtime implementation PR for this family
- [ ] promote the backup family and repeat this worksheet there
