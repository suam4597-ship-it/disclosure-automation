defmodule DisclosureAutomation.SourceHealthPollIdempotencyRuntimeTest do
  use DisclosureAutomationWeb.ConnCase, async: false

  alias DisclosureAutomation.Repo
  alias DisclosureAutomation.SourceHealthPollRuntime
  alias DisclosureAutomation.Sources

  @source_key "source_health_poll_idempotency_runtime_fixture"
  @missing_source_key "source_health_poll_idempotency_runtime_missing"
  @poll_idempotency_table "source_health_poll_idempotency_keys"

  setup do
    {:ok, _source} =
      Sources.upsert_source(%{
        "source_key" => @source_key,
        "display_name" => "Source Health Poll Idempotency Runtime Fixture",
        "source_type" => "api",
        "adapter_key" => "test_adapter",
        "region_code" => "US",
        "discovery_mode" => "fixture",
        "hydrate_mode" => "fixture",
        "default_home_market_region_code" => "US",
        "source_class" => "operator_test",
        "default_source_tier" => "official",
        "base_url" => "https://example.test/source-health-poll-idempotency-runtime",
        "healthcheck_url" => "https://example.test/source-health-poll-idempotency-runtime/health",
        "parser_key" => "test_parser",
        "poll_cron" => "0 * * * *",
        "coverage_tags" => ["source_health", "poll", "idempotency_runtime"],
        "active" => true,
        "config" => %{},
        "health_status" => "unknown"
      })

    :ok
  end

  test "missing idempotency key returns bounded conflict before poll execution", %{conn: conn} do
    response =
      conn
      |> post("/api/admin/sources/#{@source_key}/poll", poll_actor_payload_without_idempotency())
      |> json_response(409)

    assert response == %{
             "error" => %{
               "code" => "missing_idempotency_key",
               "message" => "poll idempotency key required"
             }
           }

    assert poll_idempotency_record_count(@source_key) == 0
    refute_poll_result_response(response)
    refute_private_material(response)
  end

  test "empty idempotency key returns bounded conflict before poll execution", %{conn: conn} do
    response =
      conn
      |> post("/api/admin/sources/#{@source_key}/poll", poll_actor_payload(""))
      |> json_response(409)

    assert response["error"]["code"] == "missing_idempotency_key"
    assert response["error"]["message"] == "poll idempotency key required"
    assert poll_idempotency_record_count(@source_key) == 0
    refute_poll_result_response(response)
    refute_private_material(response)
  end

  test "first authorized poll idempotency preparation creates accepted bounded record" do
    assert {:ok,
            %{
              "source_key" => @source_key,
              "poll_status" => "accepted",
              "idempotency_status" => "accepted",
              "rate_limit_status" => "allowed"
            }} = SourceHealthPollRuntime.prepare_poll(@source_key, poll_actor_payload())

    assert poll_idempotency_record_count(@source_key) == 1

    record = poll_idempotency_record(@source_key)
    assert record["source_key"] == @source_key
    assert record["idempotency_key_hash"] == "sha256:idempotency-poll-runtime-001"
    assert record["request_id_hash"] == "sha256:request-poll-runtime-001"
    assert record["actor_id_hash"] == "sha256:operator-poll-runtime-001"
    assert record["status"] == "accepted"
    assert record["rate_limit_status"] == "allowed"

    refute_private_material(record)
  end

  test "repeated authorized poll with same idempotency key returns reused without poll execution", %{conn: conn} do
    assert {:ok, %{"poll_status" => "accepted"}} =
             SourceHealthPollRuntime.prepare_poll(@source_key, poll_actor_payload())

    response =
      conn
      |> post("/api/admin/sources/#{@source_key}/poll", poll_actor_payload())
      |> json_response(202)

    assert response == %{
             "source_key" => @source_key,
             "poll_status" => "reused",
             "idempotency_status" => "reused",
             "rate_limit_status" => "allowed"
           }

    assert poll_idempotency_record_count(@source_key) == 1
    refute_poll_result_response(response)
    refute_private_material(response)
  end

  test "body override cannot alter missing idempotency denial", %{conn: conn} do
    response =
      conn
      |> post("/api/admin/sources/#{@source_key}/poll", unsafe_override_payload_without_idempotency())
      |> json_response(409)

    assert response["error"]["code"] == "missing_idempotency_key"
    assert response["error"]["message"] == "poll idempotency key required"
    assert poll_idempotency_record_count(@source_key) == 0
    refute_private_material(response)
    refute_poll_runtime_material(response)
  end

  test "unknown source creates no idempotency record and returns bounded not found", %{conn: conn} do
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

    assert poll_idempotency_record_count(@missing_source_key) == 0
    refute_poll_result_response(response)
    refute_private_material(response)
  end

  defp poll_actor_payload(idempotency_key_hash \\ "sha256:idempotency-poll-runtime-001") do
    %{
      "actor_id_hash" => "sha256:operator-poll-runtime-001",
      "actor_permissions" => ["source_health:poll"],
      "request_id_hash" => "sha256:request-poll-runtime-001",
      "idempotency_key_hash" => idempotency_key_hash,
      "reason_redacted" => "REDACTED_SOURCE_HEALTH_POLL_REASON",
      "redaction_status" => "passed",
      "created_at" => "2026-05-04T00:00:00Z"
    }
  end

  defp poll_actor_payload_without_idempotency do
    poll_actor_payload()
    |> Map.delete("idempotency_key_hash")
  end

  defp unsafe_override_payload_without_idempotency do
    poll_actor_payload_without_idempotency()
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

  defp poll_idempotency_record_count(source_key) do
    {:ok, result} =
      Repo.query(
        "select count(*) from #{@poll_idempotency_table} where source_key = $1",
        [source_key]
      )

    [[count]] = result.rows
    count
  end

  defp poll_idempotency_record(source_key) do
    {:ok, result} =
      Repo.query(
        """
        select source_key, idempotency_key_hash, request_id_hash, actor_id_hash, status, rate_limit_status
        from #{@poll_idempotency_table}
        where source_key = $1
        """,
        [source_key]
      )

    [row] = result.rows

    result.columns
    |> Enum.zip(row)
    |> Map.new()
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
