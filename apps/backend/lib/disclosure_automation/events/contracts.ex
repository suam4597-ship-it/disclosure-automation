defmodule DisclosureAutomation.Events.Contracts do
  @moduledoc """
  Consumer defaults for reference domain events.
  """

  @defaults %{
    "digest.edition_generated" => ["dashboard_projector", "notification_router"],
    "source.health_recomputed" => ["ops_audit_log"]
  }

  def default_consumers_for(event_name) when is_binary(event_name) do
    Map.get(@defaults, event_name, [])
  end
end
