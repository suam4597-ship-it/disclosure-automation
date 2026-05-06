defmodule DisclosureAutomationWeb.SourceHealthUpstreamAuthProviderAdapter do
  @moduledoc false

  import Plug.Conn

  @app_auth_assign :source_health_app_auth

  def init(opts), do: opts

  def call(conn, _opts) do
    case Map.get(conn.assigns, @app_auth_assign) do
      %{} = app_auth -> put_upstream_assigns(conn, app_auth)
      _ -> conn
    end
  end

  defp put_upstream_assigns(conn, app_auth) do
    conn
    |> maybe_assign(:upstream_actor_id_hash, Map.get(app_auth, :actor_id_hash))
    |> maybe_assign(:upstream_request_id_hash, Map.get(app_auth, :request_id_hash))
    |> maybe_assign(:upstream_session_id_hash, Map.get(app_auth, :session_id_hash))
    |> maybe_assign_list(:upstream_role_names, Map.get(app_auth, :role_names))
    |> maybe_assign_list(:upstream_source_health_permissions, Map.get(app_auth, :source_health_permissions))
  end

  defp maybe_assign(conn, key, value) when is_binary(value), do: assign(conn, key, value)
  defp maybe_assign(conn, _key, _value), do: conn

  defp maybe_assign_list(conn, key, values) when is_list(values), do: assign(conn, key, values)
  defp maybe_assign_list(conn, key, value) when is_binary(value), do: assign(conn, key, [value])
  defp maybe_assign_list(conn, _key, _value), do: conn
end
