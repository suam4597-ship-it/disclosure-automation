defmodule DisclosureAutomation.SourceHealthRecheckPositiveCharacterizationTest do
  use DisclosureAutomationWeb.ConnCase, async: false

  alias DisclosureAutomation.Sources

  @source_key "source_health_recheck_positive_fixture"

  setup do
    {:ok, _source} =
      Sources.upsert_source(%{
        "source_key" => @source_key,
        "display_name" => "Source Health Recheck Positive Fixture",
        "source_type" => "api",
        "adapter_key" => "test_adapter",
        "region_code" => "US",
        "discovery_mode" => "fixture",
        "hydrate_mode" => "fixture",
        "default_home_market_region_code" => "US",
        "source_class" => "operator_test",
        "default_source_tier" => "official",
        "base_url" => "https://example.test/source-health-recheck-positive",
        "healthcheck_url" => "https://example.test/source-health-recheck-positive/health",
        "parser_key" => "test_parser",
        "poll_cron" => "0 * * * *",
        "coverage_tags" => ["source_health", "recheck", "positive_characterization"],
        "active" => true,
        "config" => %{},
        "health_status" => "unknown"
      })

    :ok
  end

  test "authorized recheck currently returns an accepted bounded response for an existing source", %{conn: conn} do
    response =
      conn
      |> post("/api/admin/source-health/#{@source_key}/recheck", recheck_actor_payload())
      |> json_response(202)

    assert is_map(response)
    refute Map.has_key?(response, "error")

    encoded = inspect(response)
    assert encoded =~ @source_key
    assert encoded =~ "health_checks"

    refute_private_material(response)
  end

  test "authorized recheck body override does not alter the bounded job characterization", %{conn: conn} do
    response =
      conn
      |> post("/api/admin/source-health/#{@source_key}/recheck", recheck_actor_override_payload())
      |> json_response(202)

    encoded = inspect(response)

    assert encoded =~ @source_key
    assert encoded =~ "health_checks"
    refute encoded =~ "materialize"
    refute encoded =~ "canonicalize"
    refute encoded =~ "provider_fetch"
    refute encoded =~ "inline_feed"
    refute encoded =~ "use_live_fetch"

    refute_private_material(response)
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
      "queue" => "materializer",
      "worker" => "canonical_mutation"
    })
  end

  defp recheck_actor_payload do
    %{
      "actor_id_hash" => "sha256:operator-001",
      "actor_permissions" => ["source_health:recheck"],
      "roles" => ["operator"],
      "request_id_hash" => "sha256:request-positive-001",
      "idempotency_key_hash" => "sha256:idempotency-positive-001",
      "reason_redacted" => "REDACTED_SOURCE_HEALTH_REASON",
      "redaction_status" => "passed",
      "created_at" => "2026-05-04T00:00:00Z"
    }
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
