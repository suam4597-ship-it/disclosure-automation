# Web Frontend

GlobalPulse 공개 대시보드입니다. 빌드 도구 없이 정적 파일만으로 동작하며,
`deploy-pages-phase0.yml` 워크플로우가 GitHub Pages로 배포합니다.

## 파일 구성
- `index.html`: **메인 대시보드** (단일 파일 앱 — Source Health, 지역 필터, SEC 상세 포함)
- `config.js`: 런타임 설정 (apiBaseUrl, configVersion, 지역 라벨/별칭/순서).
  **동작 변경은 코드가 아니라 이 파일에서.** configVersion을 바꾸면
  `globalpulse-public-web-smoke.yml`의 기대값도 같이 바꿔야 한다
- `global-pulse-dashboard.html` + `dashboard.js` + `dashboard.css`: 보조 경량 대시보드
  (digest API 연동 데모, KST 배달 스케줄 계산)
- `global-pulse-dashboard-v2.html`: 대시보드 프로토타입 v2
- `styles.css`, `script.js`: 초기 랜딩용 (메인 index가 대체)
- `vercel.json`: Vercel 배포 대비 설정

## 시간 규칙
- 모든 시각은 UTC로 받고, 표시 변환은 화면에서 Intl + IANA 타임존으로 수행
- 오프셋(+09:00) 하드코딩 금지 — 서머타임에 깨짐 (data_model_blueprint 2장)

## 로컬에서 보기
```
python3 -m http.server -d apps/web 8000
# http://localhost:8000/            (메인)
# http://localhost:8000/global-pulse-dashboard.html  (보조)
# 다른 백엔드 지정: ...?apiBase=http://localhost:4000
```
