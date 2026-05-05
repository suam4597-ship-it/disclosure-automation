defmodule DisclosureAutomation.SourceHealthPollAuthorizationContractTest do
  use DisclosureAutomationWeb.ConnCase, async: false

  alias DisclosureAutomation.Sources

  @source_key "source_health_poll_authorization_fixture"
  @missing_source_key "source_health_poll_authorization_missing"

  setup do
    {:ok, _source} =
      Sources.upsert_source(%{
        "source_key" => @source_key,
        "display_name" => "Source Health Poll Authorization Fixture",
        "source_type" => "api",
        "adapter_key" => "test_adapter",
        "region_code" => "US",
        "discovery_mode" => "fixture",
        "hydrate_mode" => "fixture",
        "default_home_market_region_code" => "US",
        "source_class" => "operator_test",
        "default_source_tier" => "official",
        "base_url" => "https://example.test/source-health-poll-authorization",
        "healthcheck_url" => "https://example.test/source-health-poll-authorization/health",
        "parser_key" => "test_parser",
        "poll_cron" => "0 * * * *",
        "coverage_tags" => ["source_health", "poll", "authorization"],
        "active" => true,
        "config" => %{},
        "health_status" => "unknown"
      })

    :ok
  end

  test "read-only actor cannot poll an existing source", %{conn: conn} do
    response =
      conn
      |> post("/api/admin/sources/#{@source_key}/poll", read_only_payload())
      |> json_response(403)

    assert_forbidden_poll_response(response)
    refute_poll_result_response(response)
    refute_private_material(response)
  end

  test "recheck-only actor cannot poll an existing source", %{conn: conn} do
    response =
      conn
      |> post("/api/admin/sources/#{@source_key}/poll", recheck_only_payload())
      |> json_response(403)

    assert_forbidden_poll_response(response)
    refute_poll_result_response(response)
    refute_private_material(response)
  end

  test "missing actor permission cannot poll an existing source", %{conn: conn} do
    response =
      conn
      |> post("/api/admin/sources/#{@source_key}/poll", missing_permission_payload())
      |> json_response(403)

    assert_forbidden_poll_response(response)
    refute_poll_result_response(response)
    refute_private_material(response)
  end

  test "request body override cannot bypass poll authorization", %{conn: conn} do
    response =
      conn
      |> post("/api/admin/sources/#{@source_key}/poll", unsafe_override_payload())
      |> json_response(403)

    assert_forbidden_poll_response(response)
    refute_poll_result_response(response)
    refute_private_material(response)
    refute_poll_runtime_material(response)
  end

  test "unknown source remains bounded not found", %{conn: conn} do
    response =
      conn
      |> post("/api/admin/sources/#{@missing_source_key}/poll", poll_actor_payload())
      |> json_response(404)

    assert response == %{
             "error" => %{
               "code" => "not_found",
               "message" => "source not found"
             }
           }

    refute_poll_result_response(response)
    refute_private_material(response)
  end

  test "forbidden poll response does not expose raw private canonical material", %{conn: conn} do
    response =
      conn
      |> post("/api/admin/sources/#{@source_key}/poll", unsafe_override_payload())
      |> json_response(403)

    assert_forbidden_poll_response(response)
    refute_private_material(response)
  end

  defp assert_forbidden_poll_response(response) do
    assert response == %{
             "error" => %{
               "code" => "forbidden",
               "message" => "source poll not allowed"
             }
           }
  end

  defp read_only_payload do
    bounded_operator_payload(["source_health:read"])
  end

  defp recheck_only_payload do
    bounded_operator_payload(["source_health:recheck"])
  end

  defp poll_actor_payload do
    bounded_operator_payload(["source_health:poll"])
  end

  defp missing_permission_payload do
    bounded_operator_payload([])
  end

  defp unsafe_override_payload do
    read_only_payload()
    |> Map.merge(%{
      "operation" => "poll",
      "action_operation" => "provider_fetch",
      "route_operation" => "canonicalize",
      "action" => "materialize",
      "queue" => "provider_fetch",
      "worker" => "canonical_mutation",
      "payload" => %{"use_live_fetch" => true},
      "provider_fetch" => true,
      "materialize" => true,
      "canonicalize" => true,
      "inline_feed" => true,
      "use_live_fetch" => true
    })
  end

  defp bounded_operator_payload(actor_permissions) do
    %{
      "actor_id_hash" => "sha256:operator-poll-auth-001",
      "actor_permissions" => actor_permissions,
      "request_id_hash" => "sha256:request-poll-auth-001",
      "idempotency_key_hash" => "sha256:idempotency-poll-auth-001",
      "reason_redacted" => "REDACTED_SOURCE_HEALTH_POLL_REASON",
      "redaction_status" => "passed",
      "created_at" => "2026-05-04T00:00:00Z"
    }
  end

  defp refute_poll_result_response(response) do
    refute Map.has_key?(response, "job_id")
    refute Map.has_key?(response, "queue")
    refute Map.has_key?(response, "args")
    refute Map.has_key?(response, "worker")
    refute Map.has_key?(response, "accepted")
    refute Map.has_key?(response, "scheduled_at")
    refute Map.has_key?(response, "items")
    refute Map.has_key?(response, "events")
    refute Map.has_key?(response, "feed")
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
    refute encoded =~ "audit_event"
    refute encoded =~ "audit_event_id"
  end

  defp refute_poll_runtime_material(response) do
    encoded = inspect(response)

    refute encoded =~ "provider_fetch"
    refute encoded =~ "materialize"
    refute encoded =~ "canonicalize"
    refute encoded =~ "inline_feed"
    refute encoded =~ "use_live_fetch"
    refute encoded =~ "canonical_mutation"
  end
end
