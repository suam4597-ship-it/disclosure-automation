# Phase 1 Codespaces Backend Runbook

목표: GitHub Codespaces 안에서 Phoenix API-only 백엔드 뼈대를 생성하고, Phase 0 스키마와 OpenAPI 자산을 실제 Phoenix 앱에 연결한다.

## 1. Codespace 준비
- repo root에 `.devcontainer/devcontainer.json`을 둔다.
- Codespaces를 새로 만들거나 rebuild 한다.
- postCreate가 끝나면 `mix`, `elixir`, `phx.new`가 준비된다.

## 2. Phoenix API-only 앱 생성
```bash
bash apps/backend/scripts/bootstrap_phoenix_api.sh
```

생성 대상:
- `apps/backend/disclosure_api`

생성 전략:
- module: `DisclosureAutomation`
- OTP app: `disclosure_automation`
- database: `postgres`
- HTML/assets 제외

## 3. Phase 0 자산 주입
```bash
bash apps/backend/scripts/copy_phase0_assets.sh
```

이 단계에서 다음이 Phoenix 앱 쪽으로 복사된다.
- `priv/repo/migrations/*.exs`
- `priv/openapi/*.yaml`
- `priv/config_samples/*.yaml`
- `priv/fixtures/*.json`

## 4. 수동 패치 3개
1) `mix.exs`
- deps에 `{:oban, "~> 2.19"}` 추가

2) `config/config.exs`
- Oban config 추가

3) `lib/disclosure_automation/application.ex`
- supervision tree에 `{Oban, Application.fetch_env!(:disclosure_automation, Oban)}` 추가

## 5. 기본 API 파일 추가
다음 템플릿을 Phoenix app에 복사한다.
- `apps/backend/templates/disclosure_automation/lib/disclosure_automation/feed.ex`
- `apps/backend/templates/disclosure_automation/lib/disclosure_automation_web/controllers/health_controller.ex`
- `apps/backend/templates/disclosure_automation/lib/disclosure_automation_web/controllers/feed_controller.ex`

그리고 `apps/backend/templates/disclosure_automation/router_notes.md`를 참고해 router에 route를 추가한다.

## 6. 실행
```bash
cd apps/backend/disclosure_api
mix deps.get
mix ecto.create
mix ecto.migrate
mix phx.server
```

Codespaces에서는 4000 포트를 열면 된다.

## 7. 프론트 연결 전 최소 완료 기준
- `/api/health` 응답
- `/api/feed/daily`에서 fixture JSON 응답
- DB migration 4개 + Oban jobs table 적용 완료
- OpenAPI spec 파일이 Phoenix app `priv/openapi` 아래 존재
