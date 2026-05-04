defmodule DisclosureAutomationWeb.AdminSourceHealthController do
  @moduledoc false

  use DisclosureAutomationWeb, :controller

  @mode "source_health_route_target_placeholder"
  @view_scope "internal_admin_source_health"

  def index(conn, _params) do
    json(conn, Map.merge(base_response(), %{item_count: 0, items: []}))
  end

  def show(conn, %{"source_key" => source_key}) do
    json(
      conn,
      Map.merge(base_response(), %{
        source_key: source_key,
        item: %{
          source_key: source_key,
          status: "unknown",
          last_success_at: nil,
          last_failure_at: nil,
          last_checked_at: nil,
          last_error_code: nil,
          retry_after: nil,
          freshness_status: "unknown",
          redaction_status: "passed"
        }
      })
    )
  end

  def recheck(conn, %{"source_key" => source_key}) do
    json(
      conn,
      Map.merge(base_response(), %{
        source_key: source_key,
        operation: "recheck_source_health",
        required_permission: "source_health:recheck",
        authorized: false,
        accepted: false,
        result_status: "route_target_placeholder",
        request_id_hash: nil,
        idempotency_key_hash: nil,
        failure_code: nil
      })
    )
  end

  defp base_response do
    %{
      view_scope: @view_scope,
      operator_only: true,
      advisory_only: true,
      non_canonical: true,
      bounded: true,
      redacted: true,
      mode: @mode,
      route_added: true,
      ui_added: false,
      action_endpoint_added: true,
      redaction_status: "passed",
      public_response_shape_mutation: false,
      canonical_feed_mutation: false,
      trigger_live_fetch: false,
      scheduler_enabled: false,
      materializer_triggered: false,
      network_access: "forbidden"
    }
  end
end
