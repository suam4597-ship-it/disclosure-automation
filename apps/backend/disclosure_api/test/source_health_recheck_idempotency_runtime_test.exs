defmodule DisclosureAutomation.SourceHealthRecheckIdempotencyRuntimeTest do
  use DisclosureAutomationWeb.ConnCase, async: false

  alias DisclosureAutomation.Repo
  alias DisclosureAutomation.Sources

  @table "source_health_recheck_idempotency_keys"
  @source_key "source_health_recheck_idem_runtime_fixture"
  @missing_source_key "source_health_recheck_idem_runtime_missing_source"

  setup do
    {:ok, _source} =
      Sources.upsert_source(%{
        "source_key" => @source_key,
        "display_name" => "Source Health Recheck Idempotency Runtime Fixture",
        "source_type" => "api",
        "adapter_key" => "test_adapter",
        "region_code" => "US",
        "discovery_mode" => "fixture",
        "hydrate_mode" => "fixture",
        "default_home_market_region_code" => "US",
        "source_class" => "operator_test",
        "default_source_tier" => "official",
        "base_url" => "https://example.test/source-health-recheck-idem-runtime",
        "healthcheck_url" => "https://example.test/source-health-recheck-idem-runtime/health",
        "parser_key" => "test_parser",
        "poll_cron" => "0 * * * *",
        "coverage_tags" => ["source_health", "recheck", "idempotency_runtime"],
        "active" => true,
        "config" => %{},
        "health_status" => "unknown"
      })

    :ok
  end

  test "same source and idempotency hash returns accepted then reused", %{conn: conn} do
    idempotency_key_hash = "sha256:idempotency-runtime-same-001"

    first_response =
      conn
      |> post("/api/admin/source-health/#{@source_key}/recheck", recheck_actor_payload(idempotency_key_hash))
      |> json_response(202)

    second_response =
      build_conn()
      |> post("/api/admin/source-health/#{@source_key}/recheck", recheck_actor_payload(idempotency_key_hash))
      |> json_response(202)

    assert_bounded_recheck_response(first_response, "accepted")
    assert_bounded_recheck_response(second_response, "reused")
    assert idempotency_record_count(@source_key, idempotency_key_hash) == 1

    refute_raw_audit_material(first_response)
    refute_raw_audit_material(second_response)
  end

  test "different idempotency hashes create separate accepted records", %{conn: conn} do
    first_hash = "sha256:idempotency-runtime-different-001"
    second_hash = "sha256:idempotency-runtime-different-002"

    first_response =
      conn
      |> post("/api/admin/source-health/#{@source_key}/recheck", recheck_actor_payload(first_hash))
      |> json_response(202)

    second_response =
      build_conn()
      |> post("/api/admin/source-health/#{@source_key}/recheck", recheck_actor_payload(second_hash))
      |> json_response(202)

    assert_bounded_recheck_response(first_response, "accepted")
    assert_bounded_recheck_response(second_response, "accepted")
    assert idempotency_record_count(@source_key, first_hash) == 1
    assert idempotency_record_count(@source_key, second_hash) == 1

    refute_raw_audit_material(first_response)
    refute_raw_audit_material(second_response)
  end

  test "missing idempotency hash remains temporarily accepted without storage record", %{conn: conn} do
    response =
      conn
      |> post("/api/admin/source-health/#{@source_key}/recheck", recheck_actor_payload_without_idempotency())
      |> json_response(202)

    assert_bounded_recheck_response(response, "untracked")
    assert idempotency_record_count_for_source(@source_key) == 0
    refute_raw_audit_material(response)
  end

  test "read-only and unknown-source requests do not create idempotency records", %{conn: conn} do
    read_only_hash = "sha256:idempotency-runtime-read-only-001"
    missing_hash = "sha256:idempotency-runtime-missing-001"

    read_only_response =
      conn
      |> post("/api/admin/source-health/#{@source_key}/recheck", read_only_actor_payload(read_only_hash))
      |> json_response(403)

    missing_response =
      build_conn()
      |> post("/api/admin/source-health/#{@missing_source_key}/recheck", recheck_actor_payload(missing_hash))
      |> json_response(404)

    assert read_only_response["error"]["code"] == "forbidden"
    assert missing_response["error"]["code"] == "not_found"
    assert idempotency_record_count(@source_key, read_only_hash) == 0
    assert idempotency_record_count(@missing_source_key, missing_hash) == 0

    refute_raw_audit_material(read_only_response)
    refute_raw_audit_material(missing_response)
  end

  defp assert_bounded_recheck_response(response, idempotency_status) do
    assert is_map(response)
    refute Map.has_key?(response, "error")

    encoded = inspect(response)
    assert encoded =~ @source_key
    assert encoded =~ "health_checks"
    assert encoded =~ idempotency_status
  end

  defp idempotency_record_count(source_key, idempotency_key_hash) do
    {:ok, result} =
      Repo.query(
        """
        select count(*)
        from #{@table}
        where source_key = $1 and idempotency_key_hash = $2
        """,
        [source_key, idempotency_key_hash]
      )

    [[count]] = result.rows
    count
  end

  defp idempotency_record_count_for_source(source_key) do
    {:ok, result} =
      Repo.query(
        """
        select count(*)
        from #{@table}
        where source_key = $1
        """,
        [source_key]
      )

    [[count]] = result.rows
    count
  end

  defp recheck_actor_payload(idempotency_key_hash) do
    %{
      "actor_id_hash" => "sha256:operator-runtime-001",
      "actor_permissions" => ["source_health:recheck"],
      "roles" => ["operator"],
      "request_id_hash" => "sha256:request-runtime-001",
      "idempotency_key_hash" => idempotency_key_hash,
      "reason_redacted" => "REDACTED_SOURCE_HEALTH_REASON",
      "redaction_status" => "passed",
      "created_at" => "2026-05-04T00:00:00Z"
    }
  end

  defp read_only_actor_payload(idempotency_key_hash) do
    recheck_actor_payload(idempotency_key_hash)
    |> Map.put("actor_permissions", ["source_health:read"])
  end

  defp recheck_actor_payload_without_idempotency do
    recheck_actor_payload("sha256:idempotency-runtime-removed")
    |> Map.delete("idempotency_key_hash")
  end

  defp refute_raw_audit_material(response) do
    encoded = inspect(response)

    refute encoded =~ "raw_actor_id"
    refute encoded =~ "raw_request_id"
    refute encoded =~ "raw_idempotency_key"
    refute encoded =~ "unredacted_reason"
    refute encoded =~ "sha256:operator-runtime-001"
    refute encoded =~ "sha256:request-runtime-001"
    refute encoded =~ "sha256:idempotency-runtime"
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
