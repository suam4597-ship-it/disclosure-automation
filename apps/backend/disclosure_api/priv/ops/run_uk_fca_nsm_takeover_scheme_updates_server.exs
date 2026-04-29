alias DisclosureAutomation.Ops.UKFCANSMTakeoverSchemeUpdatesSource

Application.put_env(
  :disclosure_automation,
  :source_registry_path,
  UKFCANSMTakeoverSchemeUpdatesSource.sample_path()
)

endpoint_config =
  Application.get_env(:disclosure_automation, DisclosureAutomationWeb.Endpoint, [])
  |> Keyword.put(:server, true)

Application.put_env(
  :disclosure_automation,
  DisclosureAutomationWeb.Endpoint,
  endpoint_config
)

{:ok, _started} = Application.ensure_all_started(:disclosure_automation)

IO.puts("UK FCA NSM takeover/scheme isolated dev server started on http://127.0.0.1:4000")
IO.puts("source_registry_path override: #{UKFCANSMTakeoverSchemeUpdatesSource.sample_path()}")

Process.sleep(:infinity)
