defmodule DisclosureAutomationWeb.ConnCase do
  use ExUnit.CaseTemplate

  using do
    quote do
      use Phoenix.ConnTest

      alias DisclosureAutomation.Repo

      @endpoint DisclosureAutomationWeb.Endpoint
    end
  end

  setup tags do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(DisclosureAutomation.Repo)

    unless tags[:async] do
      Ecto.Adapters.SQL.Sandbox.mode(DisclosureAutomation.Repo, {:shared, self()})
    end

    %{conn: Phoenix.ConnTest.build_conn()}
  end
end
