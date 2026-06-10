# disclosure-automation (GlobalPulse)

해외 공시·실적·M&A·산업 변화를 수집해 **중복 없이 정리된 사건(event) 중심 피드**로
전달하는 프로젝트입니다.

## 구조
| 경로 | 내용 |
|---|---|
| `apps/backend/disclosure_api/` | Phoenix/Elixir 백엔드 (Fly.io 스테이징 배포 본체) |
| `apps/web/` | 공개 대시보드 프론트엔드 (GitHub Pages 배포) |
| `docs/blueprint/` | 설계 문서 (제품 설계서 + 데이터 모델 설계서) |
| `config/sources.yml` | 수집처 명단 레지스트리 |
| `apps/backend/schema/` | 목표 데이터 모델 PostgreSQL 스키마 초안 |
| `apps/backend/dedup/` | 3단계 중복 제거 참조 구현 + 테스트 |
| `apps/backend/openapi.yml` | 백엔드 API 계약 명세 |
| `.github/workflows/` | 배포·스테이징 폴링·스모크·CI 검증 |

- 스테이징 백엔드: `https://globalpulse-backend-staging.fly.dev`
- 공개 Pages: `https://suam4597-ship-it.github.io/disclosure-automation/`

## GlobalPulse Handoff

If you are continuing GlobalPulse work from a different local machine, start here:

```text
GLOBALPULSE_HANDOFF.md
```

The canonical detailed handoff lives at:

```text
apps/backend/disclosure_api/docs/globalpulse_remote_handoff_guide.md
```

시작 안내: [`docs/START_HERE.md`](./docs/START_HERE.md)
