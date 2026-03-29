# START HERE

이 프로젝트는 GitHub를 중심으로 브라우저에서 작업을 이어가도록 구성했습니다.

## 가장 쉬운 시작 방법
1. GitHub 저장소를 엽니다.
2. `.` 키를 눌러 github.dev 편집기를 엽니다.
3. 또는 `Code > Codespaces > Create codespace on main`으로 클라우드 개발환경을 생성합니다.
4. `apps/web/index.html`부터 열어 프론트엔드를 수정합니다.
5. 네가 따로 만든 HTML/CSS/JS가 있다면 `apps/web/` 아래에 넣고 교체합니다.

## 배포 순서
1. 프론트엔드부터 Vercel 또는 Cloudflare Pages에 배포
2. 백엔드는 나중에 Railway 또는 Fly.io로 분리 배포
3. 환경변수와 비밀값은 Git에 올리지 않고 배포 플랫폼에만 등록
