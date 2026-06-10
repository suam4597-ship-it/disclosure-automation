# Blueprint Documents

이 폴더는 프로젝트 설계 문서를 보관하는 공간입니다.

## 문서
- [`investment_news_blueprint_v2.md`](./investment_news_blueprint_v2.md) — 상세 설계서 v2.
  4층 데이터 모델(원본→정리→사건→전달), 회사 명함첩(Issuer), 이중 시간 규칙,
  3단계 중복 제거, 수집처 명단 운영 방식을 정의한 **단일 기준 문서**

## 관련 파일
- 테이블 정의 초안: [`apps/backend/schema/0001_core_schema.sql`](../../apps/backend/schema/0001_core_schema.sql)
- 수집처 명단: [`config/sources.yml`](../../config/sources.yml)

## 다음 작업
1. 백엔드(fly.dev) 구현을 설계서 스키마에 정렬
2. Issuer 명함첩 시드 데이터(LEI/ISIN 매핑) 구축
3. 의미 기반(3단계) dedup 도입
