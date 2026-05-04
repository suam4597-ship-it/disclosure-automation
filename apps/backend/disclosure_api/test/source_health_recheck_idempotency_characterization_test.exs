defmodule DisclosureAutomation.SourceHealthRecheckIdempotencyCharacterizationTest do
  use DisclosureAutomationWeb.ConnCase, async: false

  alias DisclosureAutomation.Sources

  @source_key "source_health_recheck_idem_fixture"

  setup do
    {:ok, _source} =
      Sources.upsert_source(%{
        "source_key" => @source_key,
        "display_name" => "Source Health Recheck Idempotency Fixture",
        "source_type" => "api",
        "adapter_key" => "test_adapter",
        "region_code" => "US",
        "discovery_mode" => "fixture",
        "hydrate_mode" => "fixture",
        "default_home_market_region_code" => "US",
        "source_class" => "operator_test",
        "default_source_tier" => "official",
        "base_url" => "https://example.test/source-health-recheck-idem",
        "healthcheck_url" => "https://example.test/source-health-recheck-idem/health",
        "parser_key" => "test_parser",
        "poll_cron" => "0 * * * *",
        "coverage_tags" => ["source_health", "recheck", "idempotency_characterization"],
        "active" => true,
        "config" => %{},
        "health_status" => "unknown"
      })

    :ok
  end

  test "repeated authorized recheck with the same idempotency hash remains bounded", %{conn: conn} do
    payload = recheck_actor_payload("sha256:idempotency-same-001")

    first_response =
      conn
      |> post("/api/admin/source-health/#{@source_key}/recheck", payload)
      |> json_response(202)

    second_response =
      build_conn()
      |> post("/api/admin/source-health/#{@source_key}/recheck", payload)
      |> json_response(202)

    assert_bounded_recheck_response(first_response)
    assert_bounded_recheck_response(second_response)
    refute_raw_audit_material(first_response)
    refute_raw_audit_material(second_response)
  end

  test "repeated authorized recheck with different idempotency hashes remains bounded", %{conn: conn} do
    first_response =
      conn
      |> post("/api/admin/source-health/#{@source_key}/recheck", recheck_actor_payload("sha256:idempotency-different-001"))
      |> json_response(202)

    second_response =
      build_conn()
      |> post("/api/admin/source-health/#{@source_key}/recheck", recheck_actor_payload("sha256:idempotency-different-002"))
      |> json_response(202)

    assert_bounded_recheck_response(first_response)
    assert_bounded_recheck_response(second_response)
    refute_raw_audit_material(first_response)
    refute_raw_audit_material(second_response)
  end

  test "authorized recheck without idempotency hash remains bounded under current behavior", %{conn: conn} do
    response =
      conn
      |> post("/api/admin/source-health/#{@source_key}/recheck", recheck_actor_payload_without_idempotency())
      |> json_response(202)

    assert_bounded_recheck_response(response)
    refute_raw_audit_material(response)
  end

  defp assert_bounded_recheck_response(response) do
    assert is_map(response)
    refute Map.has_key?(response, "error")

    encoded = inspect(response)
    assert encoded =~ @source_key
    assert encoded =~ "health_checks"
  end

  defp recheck_actor_payload(idempotency_key_hash) do
    %{
      "actor_id_hash" => "sha256:operator-001",
      "actor_permissions" => ["source_health:recheck"],
      "roles" => ["operator"],
      "request_id_hash" => "sha256:request-idem-001",
      "idempotency_key_hash" => idempotency_key_hash,
      "reason_redacted" => "REDACTED_SOURCE_HEALTH_REASON",
      "redaction_status" => "passed",
      "created_at" => "2026-05-04T00:00:00Z"
    }
  end

  defp recheck_actor_payload_without_idempotency do
    recheck_actor_payload("sha256:idempotency-removed")
    |> Map.delete("idempotency_key_hash")
  end

  defp refute_raw_audit_material(response) do
    encoded = inspect(response)

    refute encoded =~ "raw_actor_id"
    refute encoded =~ "raw_request_id"
    refute encoded =~ "raw_idempotency_key"
    refute encoded =~ "unredacted_reason"
    refute encoded =~ "sha256:operator-001"
    refute encoded =~ "sha256:request-idem-001"
    refute encoded =~ "sha256:idempotency"
    refute encoded =~ "REDACTED_SOURCE_HEALTH_REASON"
    refute encoded =~ "raw_provider_payload"
    refute encoded =~ "full_article_text"
    refute encoded =~ "raw_transport_response"
    refute encoded =~ "sql_details"
    refute encoded =~ "stack_trace"
    refute encoded =~ "canonical_payload"
    refute encoded =~ "private_actor_context"
    refute encoded =~ "unbounded_diagnostics"
  end
end
