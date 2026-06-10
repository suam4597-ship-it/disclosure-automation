# Blueprint Documents

이 폴더는 프로젝트 설계 문서를 보관하는 공간입니다.

## 문서
- [`investment_news_blueprint_v2.md`](./investment_news_blueprint_v2.md) — **제품 설계서 v2.**
  제품 목표, 사용자 문제, Phase 0 기반 작업 정의 (phase0-foundation 원본)
- [`data_model_blueprint.md`](./data_model_blueprint.md) — **데이터 모델 설계서.**
  4층 데이터 모델(원본→정리→사건→전달), 회사 명함첩(Issuer), 이중 시간 규칙,
  3단계 중복 제거, 수집처 명단 운영 방식

## 관련 파일
- 백엔드 구현: [`apps/backend/disclosure_api/`](../../apps/backend/disclosure_api/)
- 목표 스키마 초안: [`apps/backend/schema/0001_core_schema.sql`](../../apps/backend/schema/0001_core_schema.sql)
- API 계약: [`apps/backend/openapi.yml`](../../apps/backend/openapi.yml)
- 수집처 명단: [`config/sources.yml`](../../config/sources.yml)

## 다음 작업
1. disclosure_api(Ecto 스키마)를 데이터 모델 설계서와 비교해 정렬 격차 목록화
2. Issuer 명함첩 시드를 백엔드 마이그레이션으로 이식
3. 의미 기반(3단계) dedup을 백엔드 병합 로직에 도입
