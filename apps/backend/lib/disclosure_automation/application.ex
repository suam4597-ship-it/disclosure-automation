defmodule DisclosureAutomation.Application do
  @moduledoc false

  use Application

  @impl Application
  def start(_type, _args) do
    children = [
      {DisclosureAutomation.Store, []}
    ]

    {:ok, supervisor} =
      Supervisor.start_link(children, strategy: :one_for_one, name: DisclosureAutomation.Supervisor)

    :ok = DisclosureAutomation.Bootstrap.bootstrap()
    {:ok, supervisor}
  end
end
