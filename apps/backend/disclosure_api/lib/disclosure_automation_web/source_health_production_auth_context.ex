defmodule DisclosureAutomationWeb.SourceHealthProductionAuthContext do
  @moduledoc false

  alias DisclosureAutomationWeb.SourceHealthAuthContext

  @production_assign_keys [
    :source_health_actor_id_hash,
    :source_health_request_id_hash,
    :source_health_session_id_hash,
    :source_health_role_names,
    :source_health_permissions
  ]

  def init(opts), do: opts

  def call(conn, _opts) do
    if production_auth_assigns_available?(conn) do
      SourceHealthAuthContext.put_production_source_health_auth_context(conn)
    else
      conn
    end
  end

  defp production_auth_assigns_available?(conn) do
    Enum.any?(@production_assign_keys, &Map.has_key?(conn.assigns, &1))
  end
end
