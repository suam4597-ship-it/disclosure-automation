defmodule DisclosureAutomationWeb.SourceHealthPollAuthorization do
  @moduledoc false

  import Plug.Conn
  import Phoenix.Controller, only: [json: 2]

  alias DisclosureAutomation.SourceHealthPollRuntime
  alias DisclosureAutomation.Sources
  alias DisclosureAutomationWeb.SourceHealthAuthContext
  alias DisclosureAutomationWeb.SourceHealthJSON

  @poll_permission "source_health:poll"

  def init(opts), do: opts

  def call(%Plug.Conn{params: %{"source_key" => source_key}} = conn, _opts) do
    case Sources.get_source_by_key(source_key) do
      {:ok, _source} ->
        authorize_poll(conn)

      {:error, :not_found} ->
        SourceHealthPollRuntime.record_poll_audit(source_key, auth_params(conn), "not_found", "none", "none")

        conn
        |> put_status(:not_found)
        |> json(SourceHealthJSON.error(%{code: "not_found", message: "source not found"}))
        |> halt()
    end
  end

  def call(conn, _opts), do: authorize_poll(conn)

  defp authorize_poll(%Plug.Conn{params: %{"source_key" => source_key}} = conn) do
    if poll_allowed?(conn) do
      conn
    else
      SourceHealthPollRuntime.record_poll_audit(source_key, auth_params(conn), "forbidden", "none", "none")

      conn
      |> put_status(:forbidden)
      |> json(SourceHealthJSON.error(%{code: "forbidden", message: "source poll not allowed"}))
      |> halt()
    end
  end

  defp authorize_poll(conn) do
    if poll_allowed?(conn) do
      conn
    else
      conn
      |> put_status(:forbidden)
      |> json(SourceHealthJSON.error(%{code: "forbidden", message: "source poll not allowed"}))
      |> halt()
    end
  end

  defp poll_allowed?(conn) do
    if SourceHealthAuthContext.source_health_auth_context_available?(conn) do
      conn
      |> SourceHealthAuthContext.fetch_source_health_auth_context()
      |> SourceHealthAuthContext.has_permission?(@poll_permission)
    else
      poll_allowed_from_params?(conn.params)
    end
  end

  defp poll_allowed_from_params?(%{"actor_permissions" => permissions}) when is_list(permissions),
    do: @poll_permission in permissions

  defp poll_allowed_from_params?(_params), do: false

  defp auth_params(conn) do
    if SourceHealthAuthContext.source_health_auth_context_available?(conn) do
      conn
      |> SourceHealthAuthContext.fetch_source_health_auth_context()
      |> SourceHealthAuthContext.to_param_map()
    else
      conn.params
    end
  end
end
