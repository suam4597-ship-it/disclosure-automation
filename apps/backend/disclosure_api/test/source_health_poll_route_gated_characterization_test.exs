defmodule DisclosureAutomation.SourceHealthPollRouteGatedCharacterizationTest do
  use DisclosureAutomationWeb.ConnCase, async: false

  alias DisclosureAutomationWeb.Router

  @missing_source_key "source_health_poll_gated_missing_source"

  test "router keeps poll as the existing bounded API route target" do
    routes = Phoenix.Router.routes(Router)

    assert Enum.any?(routes, fn route ->
             route.verb == :post and
               route.path == "/api/admin/sources/:source_key/poll" and
               route.plug == DisclosureAutomationWeb.AdminSourcePollController and
               route.plug_opts == :create
           end)

    refute Enum.any?(routes, fn route ->
             route.path == "/api/admin/source-health/:source_key/poll"
           end)
  end

  test "poll remains absent from the internal source health UI route surface" do
    routes = Phoenix.Router.routes(Router)
    paths = Enum.map(routes, & &1.path)

    refute "/admin/source-health/:source_key/poll" in paths
    refute "/admin/source-health/:source_key/audit" in paths
    refute "/admin/source-health/audit" in paths
    refute "/admin/sources/:source_key/poll" in paths
  end

  test "poll route remains absent from public source health route surfaces" do
    routes = Phoenix.Router.routes(Router)
    paths = Enum.map(routes, & &1.path)

    refute "/source-health/:source_key/poll" in paths
    refute "/public/source-health/:source_key/poll" in paths
    refute "/api/public/source-health/:source_key/poll" in paths
    refute "/api/source-health/:source_key/poll" in paths
  end

  test "unknown source poll returns bounded not-found JSON", %{conn: conn} do
    response =
      conn
      |> post("/api/admin/sources/#{@missing_source_key}/poll", bounded_operator_payload())
      |> json_response(404)

    assert response == %{
             "error" => %{
               "code" => "not_found",
               "message" => "source not found"
             }
           }

    refute_private_material(response)
  end

  test "unknown source poll response does not expose provider materializer or canonical material", %{conn: conn} do
    response =
      conn
      |> post("/api/admin/sources/#{@missing_source_key}/poll", unsafe_poll_override_payload())
      |> json_response(404)

    assert response["error"]["code"] == "not_found"
    assert response["error"]["message"] == "source not found"

    refute_private_material(response)
    refute_poll_runtime_material(response)
  end

  defp bounded_operator_payload do
    %{
      "actor_id_hash" => "sha256:operator-poll-gated-001",
      "actor_permissions" => ["source_health:read"],
      "request_id_hash" => "sha256:request-poll-gated-001",
      "idempotency_key_hash" => "sha256:idempotency-poll-gated-001",
      "reason_redacted" => "REDACTED_SOURCE_HEALTH_POLL_REASON",
      "redaction_status" => "passed",
      "created_at" => "2026-05-04T00:00:00Z"
    }
  end

  defp unsafe_poll_override_payload do
    bounded_operator_payload()
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
