# Infrastructure

이 디렉터리는 배포와 운영 관련 문서를 보관합니다.

## 추천 초기 배포 흐름
- 프론트엔드: Vercel 또는 Cloudflare Pages
- 백엔드: Railway로 시작, 추후 Fly.io 검토
- DB: PostgreSQL
- 파일 저장: S3 호환 object storage

## 운영 주의사항
- 비밀값은 Git에 올리지 않기
- 환경변수는 배포 플랫폼에서 관리
- 리전/시간대/DST를 하드코딩하지 않기
