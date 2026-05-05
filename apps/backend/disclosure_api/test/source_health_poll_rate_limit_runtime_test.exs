defmodule DisclosureAutomation.SourceHealthPollRateLimitRuntimeTest do
  use DisclosureAutomationWeb.ConnCase, async: false

  alias DisclosureAutomation.Repo
  alias DisclosureAutomation.SourceHealthPollRuntime
  alias DisclosureAutomation.Sources

  @source_key "source_health_poll_rate_limit_runtime_fixture"
  @other_source_key "source_health_poll_rate_limit_runtime_other"
  @missing_source_key "source_health_poll_rate_limit_runtime_missing"
  @poll_rate_limit_table "source_health_poll_rate_limits"

  setup do
    upsert_source!(@source_key, "Source Health Poll Rate Limit Runtime Fixture")
    upsert_source!(@other_source_key, "Source Health Poll Rate Limit Runtime Other Fixture")
    :ok
  end

  test "first accepted poll records global source and actor counters" do
    assert {:ok, %{"poll_status" => "accepted"}} =
             SourceHealthPollRuntime.prepare_poll(@source_key, poll_actor_payload("001"))

    assert rate_limit_count("global", "global") == 1
    assert rate_limit_count("source_key", @source_key) == 1
    assert rate_limit_count("actor_id_hash", "sha256:operator-poll-rate-runtime-001") == 1

    refute_private_material(rate_limit_record("source_key", @source_key))
  end

  test "reused idempotency request does not increment rate counters", %{conn: conn} do
    assert {:ok, %{"poll_status" => "accepted"}} =
             SourceHealthPollRuntime.prepare_poll(@source_key, poll_actor_payload("002"))

    before_counts = rate_limit_counts(@source_key, "sha256:operator-poll-rate-runtime-001")

    response =
      conn
      |> post("/api/admin/sources/#{@source_key}/poll", poll_actor_payload("002"))
      |> json_response(202)

    assert response["poll_status"] == "reused"
    assert response["idempotency_status"] == "reused"
    assert response["rate_limit_status"] == "allowed"
    assert rate_limit_counts(@source_key, "sha256:operator-poll-rate-runtime-001") == before_counts
    refute_private_material(response)
  end

  test "missing key request does not increment rate counters", %{conn: conn} do
    before_counts = rate_limit_counts(@source_key, "sha256:operator-poll-rate-runtime-001")

    response =
      conn
      |> post("/api/admin/sources/#{@source_key}/poll", poll_actor_payload_without_idempotency())
      |> json_response(409)

    assert response["error"]["code"] == "missing_idempotency_key"
    assert rate_limit_counts(@source_key, "sha256:operator-poll-rate-runtime-001") == before_counts
    refute_private_material(response)
  end

  test "unknown source request does not increment rate counters", %{conn: conn} do
    before_global = rate_limit_count("global", "global")

    response =
      conn
      |> post("/api/admin/sources/#{@missing_source_key}/poll", poll_actor_payload("003"))
      |> json_response(404)

    assert response["error"]["code"] == "not_found"
    assert rate_limit_count("global", "global") == before_global
    refute_private_material(response)
  end

  test "source key limit exceeded returns bounded 429", %{conn: conn} do
    prefill_rate_limit!("source_key", @source_key, 5)

    response =
      conn
      |> post("/api/admin/sources/#{@source_key}/poll", poll_actor_payload("004"))
      |> json_response(429)

    assert response == %{
             "error" => %{
               "code" => "rate_limited",
               "message" => "source poll rate limited",
               "rate_limit_status" => "rate_limited_source"
             }
           }

    refute_private_material(response)
    refute_poll_runtime_material(response)
  end

  test "actor limit exceeded returns bounded 429", %{conn: conn} do
    prefill_rate_limit!("actor_id_hash", "sha256:operator-poll-rate-runtime-001", 10)

    response =
      conn
      |> post("/api/admin/sources/#{@source_key}/poll", poll_actor_payload("005"))
      |> json_response(429)

    assert response["error"]["code"] == "rate_limited"
    assert response["error"]["message"] == "source poll rate limited"
    assert response["error"]["rate_limit_status"] == "rate_limited_actor"
    refute_private_material(response)
    refute_poll_runtime_material(response)
  end

  test "global limit exceeded takes priority over source and actor limits", %{conn: conn} do
    prefill_rate_limit!("global", "global", 100)
    prefill_rate_limit!("source_key", @source_key, 5)
    prefill_rate_limit!("actor_id_hash", "sha256:operator-poll-rate-runtime-001", 10)

    response =
      conn
      |> post("/api/admin/sources/#{@source_key}/poll", poll_actor_payload("006"))
      |> json_response(429)

    assert response["error"]["rate_limit_status"] == "rate_limited_global"
    refute_private_material(response)
  end

  test "body override cannot alter rate-limit decision", %{conn: conn} do
    prefill_rate_limit!("source_key", @source_key, 5)

    response =
      conn
      |> post("/api/admin/sources/#{@source_key}/poll", unsafe_override_payload("007"))
      |> json_response(429)

    assert response["error"]["code"] == "rate_limited"
    assert response["error"]["rate_limit_status"] == "rate_limited_source"
    refute_private_material(response)
    refute_poll_runtime_material(response)
  end

  defp upsert_source!(source_key, display_name) do
    {:ok, _source} =
      Sources.upsert_source(%{
        "source_key" => source_key,
        "display_name" => display_name,
        "source_type" => "api",
        "adapter_key" => "test_adapter",
        "region_code" => "US",
        "discovery_mode" => "fixture",
        "hydrate_mode" => "fixture",
        "default_home_market_region_code" => "US",
        "source_class" => "operator_test",
        "default_source_tier" => "official",
        "base_url" => "https://example.test/#{source_key}",
        "healthcheck_url" => "https://example.test/#{source_key}/health",
        "parser_key" => "test_parser",
        "poll_cron" => "0 * * * *",
        "coverage_tags" => ["source_health", "poll", "rate_limit_runtime"],
        "active" => true,
        "config" => %{},
        "health_status" => "unknown"
      })
  end

  defp poll_actor_payload(idempotency_suffix) do
    %{
      "actor_id_hash" => "sha256:operator-poll-rate-runtime-001",
      "actor_permissions" => ["source_health:poll"],
      "request_id_hash" => "sha256:request-poll-rate-runtime-#{idempotency_suffix}",
      "idempotency_key_hash" => "sha256:idempotency-poll-rate-runtime-#{idempotency_suffix}",
      "reason_redacted" => "REDACTED_SOURCE_HEALTH_POLL_REASON",
      "redaction_status" => "passed",
      "created_at" => "2026-05-04T00:00:00Z"
    }
  end

  defp poll_actor_payload_without_idempotency do
    poll_actor_payload("missing")
    |> Map.delete("idempotency_key_hash")
  end

  defp unsafe_override_payload(idempotency_suffix) do
    poll_actor_payload(idempotency_suffix)
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

  defp prefill_rate_limit!(scope, scope_key, request_count) do
    now = DateTime.utc_now() |> DateTime.truncate(:second)
    window_expires_at = DateTime.add(now, 60, :second)

    Repo.insert_all(@poll_rate_limit_table, [
      %{
        id: Ecto.UUID.generate() |> Ecto.UUID.dump!(),
        scope: scope,
        scope_key: scope_key,
        source_key: if(scope == "source_key", do: scope_key, else: @source_key),
        actor_id_hash: if(scope == "actor_id_hash", do: scope_key, else: "sha256:operator-poll-rate-runtime-001"),
        status: "allowed",
        request_count: request_count,
        limit_count: request_count,
        window_start_at: now,
        window_expires_at: window_expires_at,
        metadata: %{},
        inserted_at: now,
        updated_at: now
      }
    ])
  end

  defp rate_limit_counts(source_key, actor_id_hash) do
    %{
      global: rate_limit_count("global", "global"),
      source: rate_limit_count("source_key", source_key),
      actor: rate_limit_count("actor_id_hash", actor_id_hash)
    }
  end

  defp rate_limit_count(scope, scope_key) do
    {:ok, result} =
      Repo.query(
        """
        select coalesce(sum(request_count), 0)
        from #{@poll_rate_limit_table}
        where scope = $1 and scope_key = $2
        """,
        [scope, scope_key]
      )

    [[count]] = result.rows
    count
  end

  defp rate_limit_record(scope, scope_key) do
    {:ok, result} =
      Repo.query(
        """
        select scope, scope_key, source_key, actor_id_hash, status, request_count, limit_count
        from #{@poll_rate_limit_table}
        where scope = $1 and scope_key = $2
        order by inserted_at desc
        limit 1
        """,
        [scope, scope_key]
      )

    [row] = result.rows

    result.columns
    |> Enum.zip(row)
    |> Map.new()
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
