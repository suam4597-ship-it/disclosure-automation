defmodule DisclosureAutomationWeb.AdminSourcePollController do
  @moduledoc false

  use DisclosureAutomationWeb, :controller

  @mode "source_poll_route_target_placeholder"
  @view_scope "internal_admin_source_poll"

  def create(conn, %{"source_key" => source_key}) do
    json(conn, %{
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
      source_key: source_key,
      operation: "poll_source",
      required_permission: "source:poll",
      authorized: false,
      accepted: false,
      result_status: "route_target_placeholder",
      request_id_hash: nil,
      idempotency_key_hash: nil,
      failure_code: nil,
      redaction_status: "passed",
      public_response_shape_mutation: false,
      canonical_feed_mutation: false,
      trigger_live_fetch: false,
      scheduler_enabled: false,
      materializer_triggered: false,
      network_access: "forbidden"
    })
  end
end
