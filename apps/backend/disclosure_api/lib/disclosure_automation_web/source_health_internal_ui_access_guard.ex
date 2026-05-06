defmodule DisclosureAutomationWeb.SourceHealthInternalUiAccessGuard do
  @moduledoc false

  import Plug.Conn
  import Phoenix.Controller, only: [text: 2]

  alias DisclosureAutomationWeb.SourceHealthAuthContext

  @read_permission "source_health:read"

  def init(opts), do: opts

  def call(conn, _opts) do
    cond do
      not SourceHealthAuthContext.source_health_auth_context_available?(conn) ->
        deny(conn, "missing_source_health_auth_context")

      @read_permission in SourceHealthAuthContext.permissions_for_authorization(conn, conn.params) ->
        conn

      true ->
        deny(conn, "missing_source_health_read_permission")
    end
  end

  defp deny(conn, reason) do
    conn
    |> put_status(:forbidden)
    |> put_resp_content_type("text/plain")
    |> text([
      "Source health access denied",
      "state=forbidden",
      "reason=#{reason}"
    ] |> Enum.join("\n"))
    |> halt()
  end
end
