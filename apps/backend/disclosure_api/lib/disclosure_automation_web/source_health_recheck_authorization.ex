defmodule DisclosureAutomationWeb.SourceHealthRecheckAuthorization do
  @moduledoc false

  import Plug.Conn
  import Phoenix.Controller, only: [json: 2]

  alias DisclosureAutomation.Sources
  alias DisclosureAutomationWeb.SourceHealthAuthContext
  alias DisclosureAutomationWeb.SourceHealthJSON

  @recheck_permission "source_health:recheck"

  def init(opts), do: opts

  def call(%Plug.Conn{params: %{"source_key" => source_key}} = conn, _opts) do
    case Sources.get_source_by_key(source_key) do
      {:ok, _source} ->
        authorize_recheck(conn)

      {:error, :not_found} ->
        Sources.record_source_health_recheck_audit(source_key, auth_params(conn), "not_found", "none")

        conn
        |> put_status(:not_found)
        |> json(SourceHealthJSON.error(%{code: "not_found", message: "source not found"}))
        |> halt()
    end
  end

  def call(conn, _opts), do: authorize_recheck(conn)

  defp authorize_recheck(%Plug.Conn{params: %{"source_key" => source_key}} = conn) do
    if recheck_allowed?(conn) do
      conn
    else
      Sources.record_source_health_recheck_audit(source_key, auth_params(conn), "forbidden", "none")

      conn
      |> put_status(:forbidden)
      |> json(SourceHealthJSON.error(%{code: "forbidden", message: "source health recheck not allowed"}))
      |> halt()
    end
  end

  defp authorize_recheck(conn) do
    if recheck_allowed?(conn) do
      conn
    else
      conn
      |> put_status(:forbidden)
      |> json(SourceHealthJSON.error(%{code: "forbidden", message: "source health recheck not allowed"}))
      |> halt()
    end
  end

  defp recheck_allowed?(conn) do
    conn
    |> SourceHealthAuthContext.permissions_for_authorization(conn.params)
    |> Enum.member?(@recheck_permission)
  end

  defp auth_params(conn), do: SourceHealthAuthContext.auth_param_map_for_request(conn)
end
