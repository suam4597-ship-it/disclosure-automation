# Backend Workspace

백엔드 구현(Elixir/Rust 권장) 자체는 별도 배포(`globalpulse-backend-staging.fly.dev`)에
있고, 이 디렉터리는 그 구현이 따라야 할 **계약과 참조 자료**를 보관합니다.

## 파일 구성
| 경로 | 내용 |
|---|---|
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

## 백엔드 저장소에서 해야 할 정렬 작업
1. `openapi.yml` 계약에 응답 형태 맞추기 (UTC 시각, 복수 카테고리, duplicates_removed)
2. DB를 `schema/0001` 구조로 마이그레이션 (특히 event_evidence의 match_method/confidence)
3. `dedup/pipeline.py`의 동작을 기준으로 병합 로직 구현, 3단계는 다국어 임베딩 연결
4. 시드(`schema/0002`) 투입 후 수집 파이프라인의 issuer 해소 활성화

## 권장 기술
- Elixir / Phoenix / Oban
- Rust sidecar workers
- PostgreSQL
- Object Storage
