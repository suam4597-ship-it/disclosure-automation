# GlobalPulse 상세 설계서 v2 — 데이터 모델 중심

> 미국·유럽·일본·대만·중국·인도·홍콩 등의 공식 공시와 주요 외신을 수집해,
> **중복 없이 정리된 "사건(event) 중심" 피드**로 전달하는 시스템의 설계 문서입니다.
>
> 이 문서는 백엔드가 따라야 할 데이터 모델의 단일 기준(single source of truth)입니다.
> 실제 테이블 정의 초안은 [`apps/backend/schema/0001_core_schema.sql`](../../apps/backend/schema/0001_core_schema.sql),
> 수집처 명단은 [`config/sources.yml`](../../config/sources.yml)을 참고하세요.

---

## 0. 한눈에 보는 전체 흐름

```
수집처(거래소·감독기관·언론)
        │  주기적으로 긁어옴 (config/sources.yml 명단 기준)
        ▼
[1층 원본]  RawDocument        ← 긁어온 원문 그대로, 절대 수정·삭제 금지
        │  파싱·정리
        ▼
[2층 정리]  NormalizedItem     ← 기사/공시 1건 = 1행 (제목·본문·발행시각·회사)
        │  중복 거르기 (3단계 체)
        ▼
[3층 사건]  CanonicalEvent     ← "사건 1개 = 1행", 여러 기사가 한 사건에 매달림
        │  지역·시간대별 묶음
        ▼
[4층 전달]  Digest             ← 사용자에게 보내는 최종 피드 패킷
```

각 층 사이를 넘어갈 때마다 품질 검사를 합니다. 검사를 끝에서 한 번만 하지 않습니다.

---

## 1. 1층 — 원본 보관소 (RawDocument)

긁어온 HTML/XML/JSON/PDF를 **받은 그대로** 저장합니다.

| 필드 | 설명 |
|---|---|
| `id` | 내부 고유 번호 |
| `source_key` | 어느 수집처에서 왔는가 (`config/sources.yml`의 key) |
| `idempotency_key` | **이중 저장 방지용 지문.** `source_key + 원천 고유ID` 또는 콘텐츠 해시. 같은 지문이 이미 있으면 저장하지 않음 |
| `content_hash` | 본문 SHA-256 해시 (완전 중복 판별 1단계에 사용) |
| `storage_ref` | 원문 파일이 저장된 object storage 경로 |
| `http_status`, `fetch_mode` | 수집 당시 HTTP 상태, live/fixture 구분 |
| `fetched_at` | **우리가 가져온 시각** (UTC) — transaction time |

규칙:

- **불변(immutable).** 한 번 쓰면 수정·삭제하지 않는다. 파싱 로직에 버그가 있어도
  원본만 있으면 2층 이후를 전부 재생성할 수 있다 (영수증 보관 원칙).
- 본문 파일은 DB가 아니라 S3 호환 object storage에 두고 DB에는 경로만 저장.
- `records_seen`(본 건수) / `records_inserted`(실제 새로 저장한 건수)를 폴마다 기록.
  같은 폴을 두 번 돌려도 inserted가 늘면 안 된다 (멱등성). 이 계약은 이미
  `globalpulse-live-staging-poll` 워크플로우가 검증하고 있다.

---

## 2. 2층 — 정리된 기사 (NormalizedItem)

원본 1건을 파싱해 표준 형태로 만든 것. **기사/공시 1건 = 1행.**

| 필드 | 설명 |
|---|---|
| `raw_document_id` | 어느 원본에서 왔는가 (계보·역추적용, 필수 FK) |
| `source_key` | 수집처 |
| `title`, `summary`, `body_text` | 정리된 텍스트 |
| `language` | 원문 언어 (`en`, `ja`, `zh-Hant`, `ko`, …) |
| `issuer_id` | 어느 회사 이야기인가 (3장 Issuer 참조, 미해소 시 NULL) |
| `published_at_utc` | **발행 시각, 반드시 UTC** — valid time |
| `source_timezone` | 원천의 IANA 타임존 (`Asia/Taipei`, `Europe/Copenhagen` 등) |
| `ingested_at` | 우리 파이프라인이 처리한 시각 (UTC) — transaction time |
| `parser_key`, `schema_version` | 어떤 파서의 몇 번째 버전으로 정리했는가 |

### 시간 규칙 (이중 시간, bitemporal)

시각은 항상 **두 가지를 따로** 기록한다:

1. **사건이 실제 일어난/발행된 시각** (`published_at_utc`) — "세상의 시간"
2. **우리가 수집·처리한 시각** (`fetched_at`, `ingested_at`) — "우리 장부의 시간"

둘이 다를 수 있다(어제 공시를 오늘 새벽에 수집). 늦게 도착한 데이터를 올바른
날짜의 다이제스트에 넣으려면 둘 다 필요하다.

저장 규칙:

- **저장은 항상 UTC.** 오프셋(`+09:00`)이 아니라 IANA 존 이름(`Asia/Seoul`)을
  별도 컬럼에 보존한다. 미국·유럽은 서머타임으로 오프셋이 1년에 두 번 바뀌므로
  오프셋 하드코딩은 금지.
- KST 변환, "3시간 전" 표시, 지역별 배달 시각 계산은 전부 **화면(프론트엔드)에서만** 한다.

---

## 3. 회사 명함첩 (Issuer)

같은 회사가 수집처마다 다른 이름으로 등장한다:
TSMC = 台積電 = `2330.TW`(대만) = `TSM`(미국 ADR). 컴퓨터는 이것들이 같은 회사인지 모른다.

그래서 **회사 1곳 = 명함 1장**을 만들고 모든 별명을 매달아 둔다.

```
Issuer (회사 1곳)
  ├─ canonical_name      대표 이름
  ├─ lei                 국제 표준 법인 식별자(LEI) — 회사용 주민번호. 교차 매칭의 앵커
  └─ IssuerIdentifier[]  (종류, 값) 목록
       ├─ (ticker,  "2330",  exchange=TWSE)
       ├─ (ticker,  "TSM",   exchange=NYSE)
       ├─ (isin,    "TW0002330008")
       └─ (alias,   "台積電", lang=zh-Hant)
```

- 식별자는 자체 발급 ID보다 **표준 식별자(LEI/ISIN)를 우선** 사용한다.
- `NormalizedItem.issuer_id`와 `CanonicalEvent.issuer_id`가 이 명함을 가리키면
  "이 회사 관련 소식 전부"를 나라·언어·수집처 횡단으로 모을 수 있다.
  이것이 이 서비스의 핵심 가치다.

---

## 4. 3층 — 사건 (CanonicalEvent)과 증거 (EventEvidence)

**사건은 하나, 기사는 여러 개.** "Broadcom이 VMware 인수"라는 사건 1개를
Reuters·FT·Nikkei가 각각 보도한다. 그래서 사건과 기사를 분리하고 **다대다(N:M)**로 잇는다.

```
CanonicalEvent (사건 1개)
  ├─ headline, summary        대표 제목·요약 (증거 중 가장 정보가 많은 것에서 채움)
  ├─ issuer_id                관련 회사
  ├─ region                   asia_pacific | greater_china | korea | eu_* | americas …
  ├─ occurred_at_utc          사건 발생/최초 발행 시각 (UTC)
  ├─ first_seen_at            우리가 처음 인지한 시각 (UTC)
  └─ primary_evidence_id      대표로 보여줄 기사 1건

EventEvidence (사건 ↔ 기사 연결 1건)
  ├─ canonical_event_id  ─┐
  ├─ normalized_item_id  ─┴─ N:M 연결
  ├─ match_method             exact_hash | minhash_lsh | semantic  (어느 체에 걸렸나)
  ├─ confidence               0.0 ~ 1.0
  └─ is_primary               대표 기사 여부
```

파생 규칙:

- 화면의 "중복 N건 제거" 숫자는 **저장값이 아니라 계산값**이다:
  `중복 제거 수 = Σ(사건별 evidence 수 − 1)`.
- "각 스토리는 primary source 아래 한 번만 표시"는 `is_primary=true`인 증거를
  렌더하는 것으로 구현된다.
- 잘못 병합된 사건을 발견하면 `match_method`·`confidence`로 원인을 추적하고
  evidence 연결만 끊어 복구한다 (원본·기사 데이터는 건드리지 않음).

### 4-1. 중복 거르기 3단계 (싼 체부터 차례로)

| 단계 | 방법 | 잡는 것 | 비용 |
|---|---|---|---|
| 1 | **정확 일치**: 본문 정규화 후 SHA-256 비교 (`content_hash`) | 동일 기사 재전송, 같은 글 재수집 | 매우 쌈 |
| 2 | **근사 중복**: MinHash + LSH로 자카드 유사도 높은 쌍을 같은 버킷에 | 통신사 전재, 살짝 고친 베껴 쓴 기사 | 중간 |
| 3 | **의미 기반**: 문장 임베딩 + 최근접 이웃 검색 | 영어 Reuters와 일본어 Nikkei가 같은 TSMC 실적을 다룬 경우 | 비쌈 |

- 1단계는 RawDocument 삽입 시점에, 2·3단계는 NormalizedItem → CanonicalEvent
  병합 시점에 수행한다.
- 전수 비교(O(N²))를 피하기 위해 **블로킹 키**(예: `issuer_id + 발행일`)로 비교
  후보를 먼저 좁힌다.
- 어느 단계에서 왜 합쳐졌는지는 `EventEvidence.match_method / confidence`에 남긴다.
- 다국어 환경이므로 3단계는 다국어 임베딩 모델을 사용한다.

### 4-2. 카테고리 분류 (복수 태그)

한 사건이 "실적이면서 동시에 공급 부족"일 수 있으므로 단일 선택이 아니라 **복수 태그**다.

```
Category: earnings | ma_capital_flow | supply_demand | tech_innovation | shortage_surge
EventCategory (사건 ↔ 카테고리 N:M)
  ├─ taxonomy_version    분류 기준 몇 번째 버전인가 (기준은 진화한다)
  ├─ classifier          rule | ml | human  (누가/무엇이 분류했나)
  └─ confidence
```

---

## 5. 4층 — 전달 패킷 (Digest)

사용자에게 실제로 보내는 묶음. 3층의 읽기 전용 투영(projection)이다.

```
Digest
  ├─ edition          breaking | daily | …
  ├─ region           대상 지역 (null이면 전체)
  ├─ generated_at     생성 시각 (UTC)
  └─ DigestItem[]     (digest_id, canonical_event_id, rank)
```

- API: `GET /api/feed/digest/latest?edition=breaking`
  응답 계약: `{ edition, items[], metadata: { fallback_to_fixture: false, … } }`
- 공개 응답에 인증·세션·내부 필드(`authorization`, `token`, `raw_provider` 등)가
  새어 나가면 안 된다 — `globalpulse-public-web-smoke` 워크플로우가 검증 중.
- 지역별 배달 시각은 사용자 설정(지역 로컬 타임) + IANA 타임존으로 계산하고,
  KST 환산은 표시 시점에 한다. 오프셋 하드코딩 금지 (2장 시간 규칙과 동일).

---

## 6. 수집처 명단 (Source Registry)

수집처는 코드가 아니라 **명단 파일(`config/sources.yml`)**로 관리한다.
새 거래소 추가 = 코드 수정이 아니라 **표에 한 줄 추가**.

| 필드 | 설명 |
|---|---|
| `key` | 고유 키 (예: `hkex_latest_listed_company_information`) |
| `name` | 사람이 읽는 이름 |
| `region` | 지역 분류 |
| `timezone` | IANA 타임존 |
| `fetch.type` | rss / html / api / pdf |
| `fetch.parser` | 사용할 파서 키 + `schema_version` |
| `status` | `disabled → fixture → canary → production` 승격 단계 |
| `records_seen_cap` | 캐너리 단계의 1회 수집 상한 (현재 25) |

운영 중 그룹(스케줄)은 같은 파일의 `groups:` 절에 정의하며,
`globalpulse-live-staging-poll` 워크플로우가 이 파일을 읽어 폴 대상을 결정한다.

---

## 7. 품질·운영 계약 (이미 워크플로우에 구현된 것 포함)

| 검사 | 위치 | 내용 |
|---|---|---|
| 폴 계약 | live-staging-poll | `fetch.mode=live`, `fixture_fallback≠true`, `records_inserted ≤ records_seen ≤ cap(25)` |
| 다이제스트 계약 | live-staging-poll, public-web-smoke | `fallback_to_fixture=false`, items 비어있지 않음 |
| 공개 셸 계약 | public-web-smoke | Pages에 `config.js`·`apiBase` 마커 존재, 비밀값 누출 없음 |
| 멱등성 | (백엔드) | 동일 `idempotency_key` 재삽입 금지 |
| 계보 | (백엔드) | 모든 사건 → 기사 → 원본 역추적 가능 |

---

## 8. 단계별 로드맵

1. ✅ 설계서를 저장소에 반영 (이 문서)
2. ✅ 수집처 명단을 `config/sources.yml`로 추출, 워크플로우가 이를 읽도록 리팩터
3. ✅ 핵심 스키마 초안(`apps/backend/schema/0001_core_schema.sql`) — Issuer·이중 시간 포함
4. ✅ 사건/증거 N:M + 3단계 dedup 명세 (이 문서 4장 + 스키마)
5. ✅ 프론트엔드를 실제 digest API에 연결 (`apps/web/`)
6. 🔶 백엔드 정렬 — API 계약 명세 완료(`apps/backend/openapi.yml`).
   백엔드 구현(`apps/backend/disclosure_api/`, phase0-foundation에서 병합됨)의
   Ecto 스키마를 이 설계와 비교·정렬하는 작업이 다음 단계
7. ✅ Issuer 명함첩 시드 데이터 구축 (`apps/backend/schema/0002_issuer_seed.sql`,
   GLEIF 검증 LEI 9건 + 미검증 NULL 사례 1건)
8. ✅ 3단계 dedup 참조 구현 (`apps/backend/dedup/`, 테스트 8건 + CI) —
   실서비스 임베딩 모델 연결은 백엔드 반영 시점에
9. ⬜ disclosure_api의 Ecto 스키마 격차 분석 및 dedup 참조 구현 이식
