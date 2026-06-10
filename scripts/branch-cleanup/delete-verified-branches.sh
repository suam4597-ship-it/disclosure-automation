#!/usr/bin/env bash
# main에 내용이 전부 포함된 것이 검증된 원격 브랜치를 삭제한다.
#
# 검증 방법 (2026-06-10):
#   1) git branch -r --merged origin/main  (커밋 도달성)
#   2) git merge-tree --write-tree origin/main <branch> 결과 트리가
#      main 트리와 동일 (squash 병합된 브랜치의 내용 포함 검증)
# 두 기준 중 하나라도 통과한 58개만 목록에 있다.
#
# 사용법:
#   ./delete-verified-branches.sh           # 미리보기 (삭제 안 함)
#   ./delete-verified-branches.sh --delete  # 실제 삭제
set -euo pipefail

cd "$(git rev-parse --show-toplevel)"
list="scripts/branch-cleanup/verified-safe-to-delete.txt"
mode="${1:---dry-run}"

while read -r branch; do
  [ -z "${branch}" ] && continue
  if [ "${mode}" = "--delete" ]; then
    git push origin --delete "${branch}" && echo "deleted ${branch}"
  else
    echo "would delete ${branch}"
  fi
done < "${list}"

if [ "${mode}" != "--delete" ]; then
  echo
  echo "실제 삭제: $0 --delete"
fi
