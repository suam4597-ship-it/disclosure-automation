defmodule DisclosureAutomationWeb.Endpoint do
  @moduledoc false

  defdelegate call(conn, opts), to: DisclosureAutomationWeb.Router
end
