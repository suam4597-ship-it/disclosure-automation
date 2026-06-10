# disclosure_api ↔ 목표 데이터 모델 격차 분석

> 현재 백엔드(`apps/backend/disclosure_api`, Ecto/PostgreSQL)와
> 목표 설계([`data_model_blueprint.md`](./data_model_blueprint.md),
> [`0001_core_schema.sql`](../../apps/backend/schema/0001_core_schema.sql))의 비교.
> 정렬은 비파괴(non-breaking) 단계로 진행한다.

## 현재 구조 요약 (마이그레이션 4개 기준)

| 테이블 | 역할 | 비고 |
|---|---|---|
| `source_registry` | 수집처 명단 + 건강 추적 | parser_key, poll_cron, health_status, last_success/failure — **목표 설계보다 풍부** |
| `delivery_windows` | 지역·채널별 배달 창 | IANA timezone + 현지 시각 — 설계 원칙과 일치 ✅ |
| `ingestion_runs` | 폴 1회 단위 감사 로그 | records_seen/inserted/updated/rejected, checksum — **목표 설계에 없던 좋은 추가** |
| `raw_documents` | 원본 1층 | (source, external_id) + (source, content_hash) 이중 유니크 = 멱등성 ✅, fetched_at/published_at 분리 = 이중 시간 ✅ |
| `canonical_feed_items` | 3·4층 겸용 | story_key 유니크 업서트, tickers/regions/sectors 배열, edition+digest_date |
| `domain_events`(+dispatches) | 이벤트 소싱 버스 | 목표 설계 외 추가 자산 |

## 격차 (목표 대비 빠진 것)

### G1. 사건↔증거 분리 없음 — 교차 소스 중복 제거 불가 (최우선)
- `canonical_feed_items.story_key = edition-날짜-slug(소스의 external_id/url/title)`,
  `duplicate_group_key = source_key-slug(...)` — 둘 다 **소스 자체 ID에서 파생**.
- 결과: 같은 사건을 Reuters와 TDnet이 각각 보도하면 **story_key가 달라 두 행으로 남는다.**
  현재 dedup은 "같은 소스의 재수집 멱등 처리"일 뿐, 설계의 1~3단계 체 중 1단계의 부분집합.
- 병합 근거(match_method/confidence) 기록 칸이 없어 오병합 추적·복구 불가.
- **해소**: `canonical_item_evidence` (item ↔ raw_document N:M + match_method/confidence/is_primary)
  → 마이그레이션 `20260610000100` 으로 추가됨. 파이프라인이 업서트 시 evidence를 기록한다.
  교차 소스 병합(2·3단계 체)은 이 테이블 위에서 후속 구현.

### G2. 회사 명함첩(Issuer) 없음
- `tickers`가 문자열 배열 — "2330"과 "TSM"이 같은 회사임을 모른다.
  `Canonicalizer`의 entity_profile이 소스별 부착만 수행.
- **해소**: `issuers` + `issuer_identifiers` 테이블 + `canonical_feed_items.issuer_id`(nullable FK)
  → 마이그레이션 `20260610000100`, 시드 10곳 `20260610000200`.
  파이프라인의 issuer 해소(티커→issuer_id 매핑)는 후속 구현.

### G3. 2층(정리본) 독립성 부족
- 파싱 결과(title/raw_text/language)가 `raw_documents`에 합쳐져 있고 문서별 parser
  버전 기록이 없다 (parser_key는 소스 단위).
- **판정**: 당장 분리하지 않는다. 원문이 `payload`(map)로 보존되어 재처리 가능성은
  충족. 문서별 `parser_version` 컬럼 추가만 후속 검토.

### G4. 원문 본문의 DB 보관
- `raw_text`/`payload`가 DB에 저장 (설계는 object storage + 경로).
- **판정**: 현재 캐너리 캡(25건/폴) 규모에서는 문제없음. 프로덕션 승격 전 결정 항목으로
  이슈 #561 계열에서 다룬다.

## 의도적 차이 (격차 아님)

| 항목 | 목표 초안 | 백엔드 | 판정 |
|---|---|---|---|
| PK | bigint identity | uuid | 백엔드 관례 유지 (신규 테이블도 uuid) |
| content_hash | bytea | hex string | 동등, 유지 |
| 카테고리 | category 테이블 N:M | metadata.category + sectors[] | 후속: G1·G2 정착 후 재평가 |
| digest 테이블 | digest/digest_item | edition+digest_date 컬럼 | 기능 동등, 유지 |

## 정렬 로드맵

1. ✅ **(이번 PR)** issuers / issuer_identifiers / canonical_item_evidence 테이블 + 시드,
   업서트 시 evidence(exact_hash, 1.000) 자동 기록 — 기존 동작 변화 없음
2. ⬜ 티커→issuer 해소: canonicalize 시 `issuer_identifiers` 조회로 `issuer_id` 채움
3. ⬜ 교차 소스 병합 2단계(MinHash+LSH): `apps/backend/dedup/pipeline.py` 동작 기준으로
   Elixir 이식, 블로킹 키 = issuer_id + published_at 48h 윈도
4. ⬜ digest API에 `duplicates_removed`(evidence 수 - 1)·`issuer` 노출
   (openapi.yml 계약 — 단, 이슈 #565 가드레일 "digest JSON 응답 형태 변경 금지"가
   해제된 뒤에만, 운영자 승인 필요)
5. ⬜ 3단계(의미 기반) — 다국어 임베딩 도입 결정 후
