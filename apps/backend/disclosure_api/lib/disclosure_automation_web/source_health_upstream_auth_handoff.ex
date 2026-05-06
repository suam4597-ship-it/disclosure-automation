defmodule DisclosureAutomationWeb.SourceHealthUpstreamAuthHandoff do
  @moduledoc false

  import Plug.Conn

  @upstream_actor_assign :upstream_actor_id_hash
  @upstream_request_assign :upstream_request_id_hash
  @upstream_session_assign :upstream_session_id_hash
  @upstream_roles_assign :upstream_role_names
  @upstream_permissions_assign :upstream_source_health_permissions

  @source_health_actor_assign :source_health_actor_id_hash
  @source_health_request_assign :source_health_request_id_hash
  @source_health_session_assign :source_health_session_id_hash
  @source_health_roles_assign :source_health_role_names
  @source_health_permissions_assign :source_health_permissions

  def init(opts), do: opts

  def call(conn, _opts) do
    conn
    |> maybe_assign_hash(@source_health_actor_assign, @upstream_actor_assign)
    |> maybe_assign_hash(@source_health_request_assign, @upstream_request_assign)
    |> maybe_assign_hash(@source_health_session_assign, @upstream_session_assign)
    |> maybe_assign_list(@source_health_roles_assign, @upstream_roles_assign)
    |> maybe_assign_list(@source_health_permissions_assign, @upstream_permissions_assign)
  end

  defp maybe_assign_hash(conn, target_key, source_key) do
    case Map.get(conn.assigns, source_key) do
      value when is_binary(value) -> assign(conn, target_key, value)
      _ -> conn
    end
  end

  defp maybe_assign_list(conn, target_key, source_key) do
    case Map.get(conn.assigns, source_key) do
      values when is_list(values) -> assign(conn, target_key, values)
      value when is_binary(value) -> assign(conn, target_key, [value])
      _ -> conn
    end
  end
end
