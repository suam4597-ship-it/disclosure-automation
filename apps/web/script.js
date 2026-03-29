document.getElementById("show-status")?.addEventListener("click", () => {
  const target = document.getElementById("status-text");
  if (target) {
    target.textContent = "기본 웹 스캐폴딩이 Git 저장소에 반영되었습니다. 이제 네 HTML을 여기에 넣고 Vercel 또는 Cloudflare Pages로 배포하면 됩니다.";
  }
});
