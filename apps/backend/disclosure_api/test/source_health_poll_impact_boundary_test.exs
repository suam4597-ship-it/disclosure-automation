defmodule DisclosureAutomation.SourceHealthPollImpactBoundaryTest do
  use DisclosureAutomationWeb.ConnCase, async: false

  alias DisclosureAutomation.Repo
  alias DisclosureAutomation.SourceHealthPollRuntime
  alias DisclosureAutomation.Sources
  alias DisclosureAutomationWeb.Router

  @source_key "source_health_poll_impact_boundary_fixture"
  @missing_source_key "source_health_poll_impact_boundary_missing"
  @rate_limit_table "source_health_poll_rate_limits"

  setup do
    {:ok, _source} =
      Sources.upsert_source(%{
        "source_key" => @source_key,
        "display_name" => "Source Health Poll Impact Boundary Fixture",
        "source_type" => "api",
        "adapter_key" => "test_adapter",
        "region_code" => "US",
        "discovery_mode" => "fixture",
        "hydrate_mode" => "fixture",
        "default_home_market_region_code" => "US",
        "source_class" => "operator_test",
        "default_source_tier" => "official",
        "base_url" => "https://example.test/source-health-poll-impact-boundary",
        "healthcheck_url" => "https://example.test/source-health-poll-impact-boundary/health",
        "parser_key" => "test_parser",
        "poll_cron" => "0 * * * *",
        "coverage_tags" => ["source_health", "poll", "impact_boundary"],
        "active" => true,
        "config" => %{},
        "health_status" => "unknown"
      })

    :ok
  end

  test "accepted poll gate response stays bounded before downstream execution" do
    assert {:ok, response} = SourceHealthPollRuntime.prepare_poll(@source_key, poll_actor_payload("accepted"))

    assert response == %{
             "source_key" => @source_key,
             "poll_status" => "accepted",
             "idempotency_status" => "accepted",
             "rate_limit_status" => "allowed"
           }

    refute_downstream_controls(response)
    refute_private_material(response)
  end

  test "reused poll response does not expose downstream controls", %{conn: conn} do
    assert {:ok, %{"poll_status" => "accepted"}} =
             SourceHealthPollRuntime.prepare_poll(@source_key, poll_actor_payload("reused"))

    response =
      conn
      |> post("/api/admin/sources/#{@source_key}/poll", poll_actor_payload("reused"))
      |> json_response(202)

    assert response["poll_status"] == "reused"
    assert response["idempotency_status"] == "reused"
    assert response["rate_limit_status"] == "allowed"
    refute_downstream_controls(response)
    refute_private_material(response)
  end

  test "body override cannot select downstream behavior on missing-key path", %{conn: conn} do
    response =
      conn
      |> post("/api/admin/sources/#{@source_key}/poll", unsafe_override_payload_without_idempotency())
      |> json_response(409)

    assert response["error"]["code"] == "missing_idempotency_key"
    assert response["error"]["message"] == "poll idempotency key required"
    refute_downstream_controls(response)
    refute_private_material(response)
  end

  test "body override cannot select downstream behavior on rate-limited path", %{conn: conn} do
    prefill_rate_limit!("source_key", @source_key, 5)

    response =
      conn
      |> post("/api/admin/sources/#{@source_key}/poll", unsafe_override_payload("rate-limited"))
      |> json_response(429)

    assert response["error"]["code"] == "rate_limited"
    assert response["error"]["rate_limit_status"] == "rate_limited_source"
    refute_downstream_controls(response)
    refute_private_material(response)
  end

  test "unknown-source poll remains bounded and does not expose downstream controls", %{conn: conn} do
    response =
      conn
      |> post("/api/admin/sources/#{@missing_source_key}/poll", unsafe_override_payload("missing"))
      |> json_response(404)

    assert response["error"]["code"] == "not_found"
    assert response["error"]["message"] == "source not found"
    refute_downstream_controls(response)
    refute_private_material(response)
  end

  test "internal source health UI still does not expose poll controls", %{conn: conn} do
    list_response =
      conn
      |> get("/admin/source-health")
      |> response(200)

    assert list_response =~ "poll_action=not_rendered"
    refute list_response =~ "poll_action=enabled"
    refute list_response =~ "poll_source"
    refute list_response =~ "provider_fetch"
    refute list_response =~ "materialize"
    refute list_response =~ "canonicalize"
    refute list_response =~ "inline_feed"
    refute list_response =~ "use_live_fetch"

    detail_response =
      build_conn()
      |> get("/admin/source-health/#{@source_key}?actor_permissions=source_health:poll")
      |> response(200)

    refute detail_response =~ "poll_action=enabled"
    refute detail_response =~ "poll_source"
    refute detail_response =~ "provider_fetch"
    refute detail_response =~ "materialize"
    refute detail_response =~ "canonicalize"
    refute detail_response =~ "inline_feed"
    refute detail_response =~ "use_live_fetch"
  end

  test "router exposes no internal or public source health poll UI surfaces" do
    routes = Phoenix.Router.routes(Router)
    paths = Enum.map(routes, & &1.path)

    refute "/admin/source-health/:source_key/poll" in paths
    refute "/admin/source-health/:source_key/audit" in paths
    refute "/admin/source-health/audit" in paths
    refute "/source-health/:source_key/poll" in paths
    refute "/public/source-health/:source_key/poll" in paths
    refute "/api/public/source-health/:source_key/poll" in paths
    refute "/api/source-health/:source_key/poll" in paths
  end

  test "public API and feed route inventory remains separate from source health poll" do
    routes = Phoenix.Router.routes(Router)

    assert route_exists?(routes, :get, "/api/events/:event_id", DisclosureAutomationWeb.EventController, :show)
    assert route_exists?(routes, :get, "/api/events/:event_id/news-overlay", DisclosureAutomationWeb.EventNewsOverlayController, :show)
    assert route_exists?(routes, :get, "/api/feed/digest/latest", DisclosureAutomationWeb.FeedDigestController, :latest)
    assert route_exists?(routes, :get, "/api/feed/digest/:digest_date/:edition", DisclosureAutomationWeb.FeedDigestController, :show)
    assert route_exists?(routes, :get, "/api/feed/hero", DisclosureAutomationWeb.FeedController, :hero)
    assert route_exists?(routes, :get, "/api/feed/region/:region_code", DisclosureAutomationWeb.FeedController, :region)

    refute route_exists?(routes, :post, "/api/feed/poll", DisclosureAutomationWeb.AdminSourcePollController, :create)
    refute route_exists?(routes, :post, "/api/events/:event_id/poll", DisclosureAutomationWeb.AdminSourcePollController, :create)
  end

  defp route_exists?(routes, verb, path, plug, plug_opts) do
    Enum.any?(routes, fn route ->
      route.verb == verb and route.path == path and route.plug == plug and route.plug_opts == plug_opts
    end)
  end

  defp poll_actor_payload(idempotency_suffix) do
    %{
      "actor_id_hash" => "sha256:operator-poll-impact-boundary-001",
      "actor_permissions" => ["source_health:poll"],
      "request_id_hash" => "sha256:request-poll-impact-boundary-#{idempotency_suffix}",
      "idempotency_key_hash" => "sha256:idempotency-poll-impact-boundary-#{idempotency_suffix}",
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
    |> Map.merge(unsafe_override_controls())
  end

  defp unsafe_override_payload_without_idempotency do
    poll_actor_payload_without_idempotency()
    |> Map.merge(unsafe_override_controls())
  end

  defp unsafe_override_controls do
    %{
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
      "use_live_fetch" => true,
      "canonical_mutation" => true,
      "canonical_payload" => %{"unsafe" => true}
    }
  end

  defp prefill_rate_limit!(scope, scope_key, request_count) do
    now = DateTime.utc_now() |> DateTime.truncate(:second)

    windows = [
      DateTime.add(now, -1, :second),
      now,
      DateTime.add(now, 1, :second)
    ]

    rows =
      Enum.map(windows, fn window_start_at ->
        %{
          id: Ecto.UUID.generate() |> Ecto.UUID.dump!(),
          scope: scope,
          scope_key: scope_key,
          source_key: @source_key,
          actor_id_hash: "sha256:operator-poll-impact-boundary-001",
          status: "allowed",
          request_count: request_count,
          limit_count: request_count,
          window_start_at: window_start_at,
          window_expires_at: DateTime.add(window_start_at, 60, :second),
          metadata: %{},
          inserted_at: now,
          updated_at: now
        }
      end)

    Repo.insert_all(@rate_limit_table, rows)
  end

  defp refute_downstream_controls(response) do
    encoded = inspect(response)

    refute encoded =~ "provider_fetch"
    refute encoded =~ "materialize"
    refute encoded =~ "canonicalize"
    refute encoded =~ "inline_feed"
    refute encoded =~ "use_live_fetch"
    refute encoded =~ "canonical_mutation"
    refute encoded =~ "canonical_payload"
  end

  defp refute_private_material(response) do
    encoded = inspect(response)

    refute encoded =~ "raw_provider_payload"
    refute encoded =~ "full_article_text"
    refute encoded =~ "raw_transport_response"
    refute encoded =~ "sql_details"
    refute encoded =~ "stack_trace"
    refute encoded =~ "private_actor_context"
    refute encoded =~ "unbounded_diagnostics"
    refute encoded =~ "raw_actor_id"
    refute encoded =~ "raw_request_id"
    refute encoded =~ "raw_idempotency_key"
    refute encoded =~ "unredacted_reason"
    refute encoded =~ "provider_credentials"
    refute encoded =~ "headers"
    refute encoded =~ "cookies"
    refute encoded =~ "tokens"
    refute encoded =~ "audit_event_id"
  end
end
