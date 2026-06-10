defmodule DisclosureAutomation.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      DisclosureAutomation.Repo,
      {Oban, Application.fetch_env!(:disclosure_automation, Oban)},
      DisclosureAutomationWeb.Endpoint
    ]

    opts = [strategy: :one_for_one, name: DisclosureAutomation.Supervisor]
    {:ok, supervisor} = Supervisor.start_link(children, opts)

    :ok = DisclosureAutomation.Bootstrap.bootstrap()

    {:ok, supervisor}
  end

  @impl true
  def config_change(changed, _new, removed) do
    DisclosureAutomationWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
