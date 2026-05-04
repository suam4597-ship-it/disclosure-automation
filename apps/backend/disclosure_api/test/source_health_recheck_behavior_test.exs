defmodule DisclosureAutomation.SourceHealthRecheckBehaviorTest do
  use DisclosureAutomationWeb.ConnCase, async: false

  @missing_source_key "source_health_recheck_behavior_missing_source"

  test "POST /api/admin/source-health/:source_key/recheck keeps request body operation overrides bounded", %{conn: conn} do
    response =
      conn
      |> post("/api/admin/source-health/#{@missing_source_key}/recheck", unsafe_operation_override_payload())
      |> json_response(404)

    assert response == %{
             "error" => %{
               "code" => "not_found",
               "message" => "source not found"
             }
           }

    refute_accepted_job_response(response)
    refute_private_material(response)
  end

  test "POST /api/admin/source-health/:source_key/recheck keeps read-only actor payload from accepted unknown-source work", %{conn: conn} do
    response =
      conn
      |> post("/api/admin/source-health/#{@missing_source_key}/recheck", read_only_actor_payload())
      |> json_response(404)

    assert response["error"]["code"] == "not_found"
    assert response["error"]["message"] == "source not found"

    refute_accepted_job_response(response)
    refute_private_material(response)
  end

  test "POST /api/admin/source-health/:source_key/recheck error response shape stays public and bounded", %{conn: conn} do
    response =
      conn
      |> post("/api/admin/source-health/#{@missing_source_key}/recheck", bounded_operator_payload())
      |> json_response(404)

    assert Map.keys(response) == ["error"]
    assert Map.keys(response["error"]) == ["code", "message"]
    assert response["error"]["code"] == "not_found"
    assert response["error"]["message"] == "source not found"

    refute_accepted_job_response(response)
    refute_private_material(response)
  end

  defp unsafe_operation_override_payload do
    bounded_operator_payload()
    |> Map.merge(%{
      "operation" => "poll",
      "action_operation" => "materialize",
      "route_operation" => "canonicalize",
      "action" => "provider_fetch",
      "use_live_fetch" => true,
      "inline_feed" => true
    })
  end

  defp read_only_actor_payload do
    bounded_operator_payload()
    |> Map.merge(%{
      "actor_permissions" => ["source_health:read"],
      "operation" => "recheck",
      "action_operation" => "recheck"
    })
  end

  defp bounded_operator_payload do
    %{
      "actor_id_hash" => "sha256:operator-001",
      "actor_permissions" => ["source_health:recheck"],
      "roles" => ["operator"],
      "request_id_hash" => "sha256:request-001",
      "idempotency_key_hash" => "sha256:idempotency-001",
      "reason_redacted" => "REDACTED_SOURCE_HEALTH_REASON",
      "redaction_status" => "passed",
      "created_at" => "2026-05-04T00:00:00Z"
    }
  end

  defp refute_accepted_job_response(response) do
    refute Map.has_key?(response, "job_id")
    refute Map.has_key?(response, "queue")
    refute Map.has_key?(response, "args")
    refute Map.has_key?(response, "worker")
    refute Map.has_key?(response, "accepted")
    refute Map.has_key?(response, "scheduled_at")
  end

  defp refute_private_material(response) do
    encoded = inspect(response)

    refute encoded =~ "raw_provider_payload"
    refute encoded =~ "full_article_text"
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
