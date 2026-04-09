# 로컬 테스트 아주 쉽게 하기

이 문서는 초등학생도 따라할 수 있게 아주 쉽게 쓴 설명입니다.

## 1. 준비물

컴퓨터에 아래 3개가 있어야 해요.
- Git
- PostgreSQL
- Erlang / Elixir

없으면 먼저 설치해야 해요.

## 2. 폴더 열기

PowerShell을 열고, 프로젝트 폴더로 가요.

```powershell
cd "C:\Users\<내이름>\Documents\disclosure-automation\apps\backend\disclosure_api"
```

`<내이름>`은 자기 컴퓨터 이름으로 바꾸면 돼요.

## 3. 진짜 있는지 확인하기

아래 2개를 쳐요.

```powershell
mix --version
elixir --version
```

둘 다 글자가 나오면 성공이에요.

## 4. 코드 준비하기

아래를 한 줄씩 차례대로 쳐요.

```powershell
mix format
mix deps.get
mix ecto.create
mix ecto.migrate
mix compile
```

### 여기서 뜻
- `mix format` : 코드 모양 예쁘게 정리
- `mix deps.get` : 필요한 부품 받기
- `mix ecto.create` : 데이터 저장 창고 만들기
- `mix ecto.migrate` : 저장 창고 칸 만들기
- `mix compile` : 코드가 말이 되는지 검사

## 5. 서버 켜기

아래를 쳐요.

```powershell
mix phx.server
```

성공하면 서버가 켜져요.

## 6. 새 창 하나 더 열기

PowerShell을 하나 더 열어요.
그리고 같은 폴더로 다시 가요.

```powershell
cd "C:\Users\<내이름>\Documents\disclosure-automation\apps\backend\disclosure_api"
```

## 7. 잘 켜졌는지 확인

아래를 쳐요.

```powershell
Invoke-RestMethod -Uri "http://localhost:4000/api/health"
```

`ok` 비슷한 글자가 나오면 성공이에요.

## 8. SEC 테스트 해보기

아래를 차례대로 쳐요.

```powershell
Invoke-RestMethod -Method POST -Uri "http://localhost:4000/api/admin/sources/sec_current_forms/poll?edition=breaking&use_live_fetch=false&inline_feed=true"
Invoke-RestMethod -Uri "http://localhost:4000/api/feed/hero"
Invoke-RestMethod -Uri "http://localhost:4000/api/feed/region/us"
Invoke-RestMethod -Uri "http://localhost:4000/api/admin/source-health/sec_current_forms"
Invoke-RestMethod -Uri "http://localhost:4000/api/feed/digest/latest?edition=breaking"
```

## 9. 무엇이 나오면 좋을까?

이런 느낌이면 좋아요.
- 에러가 안 난다
- `us` 같은 지역 코드가 보인다
- 시간 값이 보인다
- digest 나 hero 같은 결과가 비어 있지 않다

## 10. 실패하면 무엇을 보내주면 될까?

실패해도 괜찮아요.
아래 3개만 복사해서 보내주면 다음 작업을 이어갈 수 있어요.

1. `mix compile`에서 나온 마지막 에러 글
2. `/api/health` 결과
3. SEC 테스트 명령 중 처음 실패한 것의 결과

## 11. 제일 쉬운 성공 기준

여기까지 되면 성공이에요.
- `mix compile` 성공
- `mix phx.server` 성공
- `/api/health` 성공
- SEC poll 한 번 성공

그다음부터는 내가 나머지 디버깅을 더 이어서 볼 수 있어요.
