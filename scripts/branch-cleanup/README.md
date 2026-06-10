# 브랜치 청소

2026-06-10 기준 원격 브랜치 631개 분류 결과.

| 분류 | 수 | 조치 |
|---|---|---|
| main에 내용 전부 포함 (이중 검증) | 58 | `verified-safe-to-delete.txt` — 스크립트로 삭제 |
| main에 없는 내용 보유 | 1 | 보존 (`chatgpt-globalpulse-sec-body-handoff-v1` 계열 — 수동 검토) |
| 자동 판별 불가 (옛 main 기준이라 병합 시뮬레이션 충돌) | ~570 | 아래 참고 |

## 사용법
```bash
./scripts/branch-cleanup/delete-verified-branches.sh           # 미리보기
./scripts/branch-cleanup/delete-verified-branches.sh --delete  # 삭제
```
(Claude 원격 세션은 지정 작업 브랜치 외 푸시가 차단되어 직접 삭제 불가 —
저장소 쓰기 권한이 있는 로컬에서 실행)

## 판별 불가 ~570개에 대하여
대부분 2026-03~05월의 chatgpt-*/codex-* 작업 브랜치로, PR을 통해 squash 병합되었거나
폐기된 것으로 보이나, 옛 main을 기준으로 만들어져 현재 main과의 병합 시뮬레이션이
충돌해 **자동으로 안전을 증명할 수 없다**. 선택지:

1. **보수적(권장)**: 그대로 두고, GitHub 설정에서
   "Automatically delete head branches"를 켜서 앞으로의 누적만 방지
2. **일괄 정리**: 어차피 전부 PR로 처리된 이력이므로 GitHub UI의
   Branches → Stale 탭에서 일괄 삭제 (삭제해도 PR에 커밋 기록은 남음)
