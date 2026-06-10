# disclosure-automation (GlobalPulse)

해외 공시·실적·M&A·산업 변화를 수집해 **중복 없이 정리된 사건(event) 중심 피드**로
전달하는 프로젝트입니다.

## 구조
| 경로 | 내용 |
|---|---|
| `docs/blueprint/` | 상세 설계서 v2 (데이터 모델의 단일 기준) |
| `config/sources.yml` | 수집처 명단 — 새 거래소 추가는 여기 한 줄 |
| `apps/web/` | 대시보드 프론트엔드 (digest API 연동) |
| `apps/backend/schema/` | PostgreSQL 핵심 스키마 초안 |
| `.github/workflows/` | 스테이징 폴링·공개 웹 스모크 검증 |

백엔드 구현은 별도 배포(`globalpulse-backend-staging.fly.dev`)이며,
이 저장소의 워크플로우가 폴 계약·다이제스트 계약을 주기적으로 검증합니다.

시작 안내: [`docs/START_HERE.md`](./docs/START_HERE.md)
