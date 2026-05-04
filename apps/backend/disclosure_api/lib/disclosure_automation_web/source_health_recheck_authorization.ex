defmodule DisclosureAutomationWeb.SourceHealthRecheckAuthorization do
  @moduledoc false

  import Plug.Conn
  import Phoenix.Controller, only: [json: 2]

  alias DisclosureAutomation.Sources
  alias DisclosureAutomationWeb.SourceHealthJSON

  @recheck_permission "source_health:recheck"

  def init(opts), do: opts

  def call(%Plug.Conn{params: %{"source_key" => source_key}} = conn, _opts) do
    case Sources.get_source_by_key(source_key) do
      {:ok, _source} ->
        authorize_recheck(conn)

      {:error, :not_found} ->
        conn
        |> put_status(:not_found)
        |> json(SourceHealthJSON.error(%{code: "not_found", message: "source not found"}))
        |> halt()
    end
  end

  def call(conn, _opts), do: authorize_recheck(conn)

  defp authorize_recheck(conn) do
    if recheck_allowed?(conn.params) do
      conn
    else
      conn
      |> put_status(:forbidden)
      |> json(SourceHealthJSON.error(%{code: "forbidden", message: "source health recheck not allowed"}))
      |> halt()
    end
  end

  defp recheck_allowed?(%{"actor_permissions" => permissions}) when is_list(permissions),
    do: @recheck_permission in permissions

  defp recheck_allowed?(_params), do: false
end
