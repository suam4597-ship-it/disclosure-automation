# Disclosure API (Phase 1)

Phase 1 첫 마일스톤용 Phoenix API-only 앱이다.

## 목표
- Phoenix 앱 부팅
- Repo/Ecto/Oban 연결
- sec_press_releases 한 개 소스 end-to-end 연결
- digest/source-health API 제공

## 실행
cd apps/backend/disclosure_api
mix deps.get
mix ecto.create
mix ecto.migrate
mix phx.server

## API
- GET /api/health
- GET /api/feed/digest/latest?edition=breaking
- GET /api/feed/digest/:digest_date/:edition
- GET /api/admin/source-health
- GET /api/admin/source-health/:source_key
- POST /api/admin/source-health/:source_key/recheck
- POST /api/admin/sources/sec_press_releases/poll

## sec_press_releases 흐름
- source registry에서 source를 읽음
- 라이브 RSS fetch 시도
- 실패 시 fixture fallback
- raw_documents 저장
- canonical_feed_items 저장
- digest endpoint에서 조회
