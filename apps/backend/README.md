# Backend Workspace

백엔드 구현은 [`disclosure_api/`](./disclosure_api/) (Phoenix/Elixir, Fly.io 스테이징 배포 본체)이고,
그 외 파일들은 구현이 따라야 할 **계약과 참조 자료**입니다.

## 파일 구성
| 경로 | 내용 |
|---|---|
| `disclosure_api/` | Phoenix/Elixir 백엔드 구현 (마이그레이션·소스 어댑터·운영 문서 포함) |
| `openapi.yml` | API 계약 명세 — health/poll/digest 엔드포인트와 응답 형태의 단일 기준 |
| `schema/0001_core_schema.sql` | 핵심 PostgreSQL 스키마 (4층 모델, Issuer, 이중 시간, 사건↔증거 N:M) |
| `schema/0002_issuer_seed.sql` | 회사 명함첩 시드 10곳 (GLEIF 검증 LEI) |
| `dedup/` | 3단계 중복 제거 참조 구현 (Python, 표준 라이브러리만) + 테스트 |

전부 `GlobalPulse CI` 워크플로우에서 자동 검증됩니다
(dedup 테스트, 명단·계약 정합성, PostgreSQL 16 스키마 적용).

## dedup 테스트 실행
```
cd apps/backend/dedup
python3 -m unittest discover -s tests -t . -v
```

## disclosure_api 정렬 작업
격차 분석: [`docs/blueprint/schema_gap_analysis.md`](../../docs/blueprint/schema_gap_analysis.md)

1. ✅ 격차 목록화 + issuers/issuer_identifiers/canonical_item_evidence 테이블·시드 추가,
   업서트 시 evidence(exact_hash) 자동 기록 (마이그레이션 20260610000100/000200)
2. ⬜ 티커→issuer 해소로 `canonical_feed_items.issuer_id` 채우기
3. ⬜ 교차 소스 병합(MinHash+LSH) — `dedup/pipeline.py` 동작 기준으로 이식
4. ⬜ digest 응답에 duplicates_removed·issuer 노출 (이슈 #565 가드레일 해제 후, 운영자 승인 필요)

## 권장 기술
- Elixir / Phoenix / Oban
- Rust sidecar workers
- PostgreSQL
- Object Storage
