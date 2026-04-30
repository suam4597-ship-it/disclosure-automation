alias DisclosureAutomation.Ops.CNCNInfoOwnershipChangeSource

Application.put_env(:disclosure_automation, :source_registry_path, CNCNInfoOwnershipChangeSource.sample_path())

endpoint_config =
  Application.get_env(:disclosure_automation, DisclosureAutomationWeb.Endpoint, [])
  |> Keyword.put(:server, true)

Application.put_env(:disclosure_automation, DisclosureAutomationWeb.Endpoint, endpoint_config)

{:ok, _started} = Application.ensure_all_started(:disclosure_automation)

IO.puts("CNInfo ownership-change isolated dev server started on http://127.0.0.1:4000")
IO.puts("source_registry_path override: " <> CNCNInfoOwnershipChangeSource.sample_path())

Process.sleep(:infinity)
