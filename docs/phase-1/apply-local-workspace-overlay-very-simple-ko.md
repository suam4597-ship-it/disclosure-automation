# zip 덮어씌우기 아주 쉽게 하기

이 문서는 zip 파일을 레포 위에 덮어씌우는 가장 쉬운 방법입니다.

## 준비
- GitHub에서 레포를 받아 둔다
- zip 파일을 받아 둔다
- zip 파일을 폴더에 압축 해제한다

예시:
- 레포 폴더: `C:\Users\내이름\Documents\disclosure-automation`
- 압축 푼 폴더: `C:\Users\내이름\Downloads\sec-zip`

## PowerShell에서 하기

레포 폴더로 간다.

```powershell
cd "C:\Users\내이름\Documents\disclosure-automation"
```

이제 아래를 실행한다.

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\apply_sec_thin_slice_overlay.ps1 -ExtractedRoot "C:\Users\내이름\Downloads\sec-zip"
```

이 스크립트는 zip 안에 있는 `apps/backend/disclosure_api` 내용을 레포의 같은 자리로 복사한다.

## 그다음 바로 할 것

```powershell
cd "C:\Users\내이름\Documents\disclosure-automation\apps\backend\disclosure_api"
mix format
mix deps.get
mix ecto.create
mix ecto.migrate
mix compile
```

## 성공 기준
- 복사 에러가 없다
- `mix compile` 에러가 없다

## 실패하면 보내줄 것
- overlay 스크립트 에러 글
- `mix compile` 마지막 에러 글
