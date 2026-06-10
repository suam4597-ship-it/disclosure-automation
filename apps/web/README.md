# Web Frontend

GlobalPulse 웹 프론트엔드입니다. 빌드 도구 없이 정적 파일만으로 동작합니다.

## 파일 구성
- `index.html`: 랜딩 페이지 (대시보드·설계서 링크)
- `global-pulse-dashboard.html`: 대시보드 본체 (마크업 셸만, 데이터 없음)
- `dashboard.css`: 대시보드 스타일
- `dashboard.js`: 렌더러 — 백엔드 digest API를 호출해 화면을 그림
- `config.js`: 런타임 설정 (apiBase, 지역·타임존, 카테고리). **동작 변경은 코드가 아니라 이 파일에서**
- `styles.css`, `script.js`: 랜딩 페이지용

## 데이터 흐름
1. `config.js`의 `apiBase`로 `GET /api/feed/digest/latest?edition=breaking` 호출
2. 응답 `items[]`를 지역별로 묶어 렌더, 카테고리 탭·중복 제거 수는 데이터에서 계산
3. 백엔드 연결 실패 시 **"샘플 데이터" 표시와 함께** 폴백 렌더

## 시간 규칙
- 모든 시각은 UTC로 받고, KST 변환·배달 스케줄 계산은 화면에서 Intl + IANA 타임존으로 수행
- 오프셋(+09:00) 하드코딩 금지 — 서머타임에 깨짐 (설계서 2장 참조)

## 로컬에서 보기
```
python3 -m http.server -d apps/web 8000
# http://localhost:8000/global-pulse-dashboard.html
# 다른 백엔드 지정: ...?apiBase=http://localhost:4000
```
