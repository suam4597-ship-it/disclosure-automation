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
1. ✅ 정렬 격차 분석: [`schema_gap_analysis.md`](./schema_gap_analysis.md)
2. ✅ Issuer 명함첩·증거 테이블을 백엔드 마이그레이션으로 이식 (20260610000100/000200)
3. ⬜ 티커→issuer 해소, 교차 소스 병합(2·3단계)을 백엔드에 도입
