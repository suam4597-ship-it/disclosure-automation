alias DisclosureAutomation.Ops.Stage5NewsOverlayFixtureSource
alias DisclosureAutomation.Runtime.Stage5NewsOverlayRawStaging

Application.put_env(:disclosure_automation, :source_registry_path, Stage5NewsOverlayFixtureSource.sample_path())

{:ok, _started} = Application.ensure_all_started(:disclosure_automation)

case Stage5NewsOverlayRawStaging.stage_once() do
  {:ok, result} ->
    IO.puts("Stage 5 news overlay raw staging completed")
    IO.inspect(result, label: "result")

  {:error, reason} ->
    IO.puts("Stage 5 news overlay raw staging failed")
    IO.inspect(reason, label: "reason")
    System.halt(1)
end
