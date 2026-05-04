defmodule DisclosureAutomation.SourceHealthRecheckAuthorizationTest do
  use DisclosureAutomationWeb.ConnCase, async: false

  alias DisclosureAutomation.Sources

  @source_key "source_health_recheck_auth_fixture"
  @missing_source_key "source_health_recheck_auth_missing_source"

  setup do
    {:ok, _source} =
      Sources.upsert_source(%{
        "source_key" => @source_key,
        "display_name" => "Source Health Recheck Auth Fixture",
        "source_type" => "api",
        "adapter_key" => "test_adapter",
        "region_code" => "US",
        "discovery_mode" => "fixture",
        "hydrate_mode" => "fixture",
        "default_home_market_region_code" => "US",
        "source_class" => "operator_test",
        "default_source_tier" => "official",
        "base_url" => "https://example.test/source-health-recheck-auth",
        "healthcheck_url" => "https://example.test/source-health-recheck-auth/health",
        "parser_key" => "test_parser",
        "poll_cron" => "0 * * * *",
        "coverage_tags" => ["source_health", "recheck", "authorization"],
        "active" => true,
        "config" => %{},
        "health_status" => "unknown"
      })

    :ok
  end

  test "read-only actor cannot trigger recheck for an existing source", %{conn: conn} do
    response =
      conn
      |> post("/api/admin/source-health/#{@source_key}/recheck", read_only_actor_payload())
      |> json_response(403)

    assert response == %{
             "error" => %{
               "code" => "forbidden",
               "message" => "source health recheck not allowed"
             }
           }

    refute_accepted_job_response(response)
    refute_private_material(response)
  end

  test "request body operation override cannot bypass read-only recheck denial", %{conn: conn} do
    response =
      conn
      |> post("/api/admin/source-health/#{@source_key}/recheck", read_only_override_payload())
      |> json_response(403)

    assert response["error"]["code"] == "forbidden"
    assert response["error"]["message"] == "source health recheck not allowed"

    refute_accepted_job_response(response)
    refute_private_material(response)
  end

  test "unknown source still returns bounded 404 before authorization denial", %{conn: conn} do
    response =
      conn
      |> post("/api/admin/source-health/#{@missing_source_key}/recheck", read_only_actor_payload())
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

  defp read_only_override_payload do
    read_only_actor_payload()
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
    %{
      "actor_id_hash" => "sha256:operator-001",
      "actor_permissions" => ["source_health:read"],
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
