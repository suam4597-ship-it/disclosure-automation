defmodule DisclosureAutomation.SourceHealthRouteTargetTest do
  use DisclosureAutomationWeb.ConnCase, async: false

  @missing_source_key "source_health_contract_missing_source"

  test "GET /api/admin/source-health dispatches to the existing bounded JSON route target", %{conn: conn} do
    response =
      conn
      |> get("/api/admin/source-health")
      |> json_response(200)

    assert is_list(response["data"])
    assert Map.has_key?(response, "page")
    assert Map.has_key?(response, "page_size")
    assert Map.has_key?(response, "total_entries")

    refute_private_material(response)
  end

  test "GET /api/admin/source-health/:source_key returns bounded not-found JSON for an unknown source", %{conn: conn} do
    response =
      conn
      |> get("/api/admin/source-health/#{@missing_source_key}")
      |> json_response(404)

    assert response["error"]["code"] == "not_found"
    assert response["error"]["message"] == "source not found"

    refute_private_material(response)
  end

  test "POST /api/admin/source-health/:source_key/recheck returns bounded not-found JSON for an unknown source", %{conn: conn} do
    response =
      conn
      |> post("/api/admin/source-health/#{@missing_source_key}/recheck", bounded_operator_payload())
      |> json_response(404)

    assert response["error"]["code"] == "not_found"
    assert response["error"]["message"] == "source not found"

    refute_private_material(response)
  end

  test "POST /api/admin/sources/:source_key/poll returns bounded not-found JSON for an unknown source", %{conn: conn} do
    response =
      conn
      |> post("/api/admin/sources/#{@missing_source_key}/poll", bounded_operator_payload())
      |> json_response(404)

    assert response["error"]["code"] == "not_found"
    assert response["error"]["message"] == "source not found"

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
