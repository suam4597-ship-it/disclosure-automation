ExUnit.start()

Code.require_file("support/conn_case.ex", __DIR__)

Ecto.Adapters.SQL.Sandbox.mode(DisclosureAutomation.Repo, :manual)
