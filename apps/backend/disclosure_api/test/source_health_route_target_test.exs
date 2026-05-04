defmodule DisclosureAutomation.SourceHealthRouteTargetTest do
  use DisclosureAutomationWeb.ConnCase, async: false

  @source_key "jp_tdnet_timely_disclosure"

  test "GET /api/admin/source-health returns a bounded placeholder JSON response", %{conn: conn} do
    response =
      conn
      |> get("/api/admin/source-health")
      |> json_response(200)

    assert response["mode"] == "source_health_route_target_placeholder"
    assert response["view_scope"] == "internal_admin_source_health"
    assert response["operator_only"] == true
    assert response["advisory_only"] == true
    assert response["non_canonical"] == true
    assert response["bounded"] == true
    assert response["redacted"] == true
    assert response["route_added"] == true
    assert response["ui_added"] == false
    assert response["action_endpoint_added"] == true
    assert response["item_count"] == 0
    assert response["items"] == []

    assert_safe_flags(response)
    refute_private_material(response)
  end

  test "GET /api/admin/source-health/:source_key returns a bounded placeholder JSON response", %{conn: conn} do
    response =
      conn
      |> get("/api/admin/source-health/#{@source_key}")
      |> json_response(200)

    assert response["mode"] == "source_health_route_target_placeholder"
    assert response["source_key"] == @source_key
    assert response["item"]["source_key"] == @source_key
    assert response["item"]["status"] == "unknown"
    assert response["item"]["freshness_status"] == "unknown"
    assert response["item"]["redaction_status"] == "passed"
    assert response["item"]["last_success_at"] == nil
    assert response["item"]["last_failure_at"] == nil
    assert response["item"]["last_checked_at"] == nil
    assert response["item"]["last_error_code"] == nil
    assert response["item"]["retry_after"] == nil

    assert_safe_flags(response)
    refute_private_material(response)
  end

  test "POST /api/admin/source-health/:source_key/recheck returns a bounded placeholder JSON response", %{conn: conn} do
    response =
      conn
      |> post("/api/admin/source-health/#{@source_key}/recheck", bounded_operator_payload())
      |> json_response(200)

    assert response["mode"] == "source_health_route_target_placeholder"
    assert response["source_key"] == @source_key
    assert response["operation"] == "recheck_source_health"
    assert response["required_permission"] == "source_health:recheck"
    assert response["authorized"] == false
    assert response["accepted"] == false
    assert response["result_status"] == "route_target_placeholder"
    assert response["request_id_hash"] == nil
    assert response["idempotency_key_hash"] == nil
    assert response["failure_code"] == nil

    assert_safe_flags(response)
    refute_private_material(response)
  end

  test "POST /api/admin/sources/:source_key/poll returns a bounded placeholder JSON response", %{conn: conn} do
    response =
      conn
      |> post("/api/admin/sources/#{@source_key}/poll", bounded_operator_payload())
      |> json_response(200)

    assert response["mode"] == "source_poll_route_target_placeholder"
    assert response["view_scope"] == "internal_admin_source_poll"
    assert response["source_key"] == @source_key
    assert response["operation"] == "poll_source"
    assert response["required_permission"] == "source:poll"
    assert response["authorized"] == false
    assert response["accepted"] == false
    assert response["result_status"] == "route_target_placeholder"
    assert response["request_id_hash"] == nil
    assert response["idempotency_key_hash"] == nil
    assert response["failure_code"] == nil

    assert_safe_flags(response)
    refute_private_material(response)
  end

  defp bounded_operator_payload do
    %{
      "actor_id_hash" => "sha256:operator-001",
      "actor_permissions" => ["source_health:read"],
      "roles" => ["operator"],
      "request_id_hash" => "sha256:request-001",
      "idempotency_key_hash" => "sha256:idempotency-001",
      "reason_redacted" => "REDACTED_SOURCE_HEALTH_REASON",
      "redaction_status" => "passed",
      "created_at" => "2026-05-04T00:00:00Z",
      "operation" => "body_override_must_not_win",
      "action_operation" => "body_override_must_not_win"
    }
  end

  defp assert_safe_flags(response) do
    assert response["redaction_status"] == "passed"
    assert response["public_response_shape_mutation"] == false
    assert response["canonical_feed_mutation"] == false
    assert response["trigger_live_fetch"] == false
    assert response["scheduler_enabled"] == false
    assert response["materializer_triggered"] == false
    assert response["network_access"] == "forbidden"
  end

  defp refute_private_material(response) do
    encoded = inspect(response)

    refute encoded =~ "raw_provider_payload"
    refute encoded =~ "full_article_text"
    refute encoded =~ "headers"
    refute encoded =~ "cookies"
    refute encoded =~ "secrets"
    refute encoded =~ "api_keys"
    refute encoded =~ "raw_transport_response"
    refute encoded =~ "sql_details"
    refute encoded =~ "stack_trace"
    refute encoded =~ "canonical_payload"
    refute encoded =~ "private_actor_context"
    refute encoded =~ "unbounded_diagnostics"
    refute encoded =~ "raw_actor_id"
    refute encoded =~ "raw_request_id"
    refute encoded =~ "raw_idempotency_key"
    refute encoded =~ "unredacted_reason"
  end
end
