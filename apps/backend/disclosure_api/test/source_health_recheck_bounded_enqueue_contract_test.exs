defmodule DisclosureAutomation.SourceHealthRecheckBoundedEnqueueContractTest do
  use DisclosureAutomationWeb.ConnCase, async: false

  alias DisclosureAutomation.Sources

  @source_key "source_health_recheck_enqueue_contract_fixture"
  @missing_source_key "source_health_recheck_enqueue_contract_missing_source"

  setup do
    {:ok, _source} =
      Sources.upsert_source(%{
        "source_key" => @source_key,
        "display_name" => "Source Health Recheck Enqueue Contract Fixture",
        "source_type" => "api",
        "adapter_key" => "test_adapter",
        "region_code" => "US",
        "discovery_mode" => "fixture",
        "hydrate_mode" => "fixture",
        "default_home_market_region_code" => "US",
        "source_class" => "operator_test",
        "default_source_tier" => "official",
        "base_url" => "https://example.test/source-health-recheck-enqueue-contract",
        "healthcheck_url" => "https://example.test/source-health-recheck-enqueue-contract/health",
        "parser_key" => "test_parser",
        "poll_cron" => "0 * * * *",
        "coverage_tags" => ["source_health", "recheck", "bounded_enqueue_contract"],
        "active" => true,
        "config" => %{},
        "health_status" => "unknown"
      })

    :ok
  end

  test "authorized recheck preserves the bounded enqueue response contract", %{conn: conn} do
    response =
      conn
      |> post("/api/admin/source-health/#{@source_key}/recheck", recheck_actor_payload())
      |> json_response(202)

    assert is_map(response)
    refute Map.has_key?(response, "error")

    encoded = inspect(response)
    assert encoded =~ @source_key
    assert encoded =~ "health_checks"

    refute_operator_override_material(response)
    refute_private_material(response)
  end

  test "request body operation override does not change bounded enqueue response", %{conn: conn} do
    response =
      conn
      |> post("/api/admin/source-health/#{@source_key}/recheck", recheck_actor_override_payload())
      |> json_response(202)

    encoded = inspect(response)
    assert encoded =~ @source_key
    assert encoded =~ "health_checks"

    refute_operator_override_material(response)
    refute_private_material(response)
  end

  test "bounded enqueue contract keeps existing denial and not-found boundaries", %{conn: conn} do
    read_only_response =
      conn
      |> post("/api/admin/source-health/#{@source_key}/recheck", read_only_actor_payload())
      |> json_response(403)

    assert read_only_response == %{
             "error" => %{
               "code" => "forbidden",
               "message" => "source health recheck not allowed"
             }
           }

    missing_response =
      build_conn()
      |> post("/api/admin/source-health/#{@missing_source_key}/recheck", recheck_actor_payload())
      |> json_response(404)

    assert missing_response == %{
             "error" => %{
               "code" => "not_found",
               "message" => "source not found"
             }
           }

    refute_private_material(read_only_response)
    refute_private_material(missing_response)
  end

  defp recheck_actor_override_payload do
    recheck_actor_payload()
    |> Map.merge(%{
      "operation" => "poll",
      "action_operation" => "materialize",
      "route_operation" => "canonicalize",
      "action" => "provider_fetch",
      "use_live_fetch" => true,
      "inline_feed" => true,
      "queue" => "operator_override_queue",
      "worker" => "operator_override_worker",
      "payload" => %{"operator_override_payload" => true}
    })
  end

  defp recheck_actor_payload do
    %{
      "actor_id_hash" => "sha256:operator-001",
      "actor_permissions" => ["source_health:recheck"],
      "roles" => ["operator"],
      "request_id_hash" => "sha256:request-enqueue-contract-001",
      "idempotency_key_hash" => "sha256:idempotency-enqueue-contract-001",
      "reason_redacted" => "REDACTED_SOURCE_HEALTH_REASON",
      "redaction_status" => "passed",
      "created_at" => "2026-05-04T00:00:00Z"
    }
  end

  defp read_only_actor_payload do
    recheck_actor_payload()
    |> Map.put("actor_permissions", ["source_health:read"])
  end

  defp refute_operator_override_material(response) do
    encoded = inspect(response)

    refute encoded =~ "materialize"
    refute encoded =~ "canonicalize"
    refute encoded =~ "provider_fetch"
    refute encoded =~ "inline_feed"
    refute encoded =~ "use_live_fetch"
    refute encoded =~ "operator_override_queue"
    refute encoded =~ "operator_override_worker"
    refute encoded =~ "operator_override_payload"
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
