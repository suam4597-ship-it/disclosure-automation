document.getElementById("show-status")?.addEventListener("click", () => {
  const target = document.getElementById("status-text");
  if (target) {
    target.textContent = "Phase 0 foundation 자산, OpenAPI, fixture, reference runtime/helper, 그리고 index 페이지 업데이트가 PR 브랜치에 반영되었습니다. 다음 단계는 Phoenix API-only 앱 통합입니다.";
  }
});
