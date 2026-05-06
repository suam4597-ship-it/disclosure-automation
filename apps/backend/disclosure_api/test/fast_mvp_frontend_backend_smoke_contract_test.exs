defmodule DisclosureAutomation.FastMvpFrontendBackendSmokeContractTest do
  use ExUnit.Case, async: true

  alias DisclosureAutomationWeb.Router

  @web_root Path.expand("../../web", __DIR__)
  @index_html Path.join(@web_root, "index.html")
  @styles_css Path.join(@web_root, "styles.css")
  @script_js Path.join(@web_root, "script.js")

  @forbidden_frontend_fragments [
    "react",
    "vue",
    "next.js",
    "next/",
    "__next",
    "vite",
    "poll_action=enabled",
    "audit_ui=enabled",
    "/public/source-health",
    "/api/public/source-health",
    "/admin/source-health/audit",
    "/admin/source-health/:source_key/audit",
    "/admin/source-health/:source_key/poll",
    "/admin/sources/:source_key/poll"
  ]

  @forbidden_response_fragments [
    "raw_provider_payload",
    "full_article_text",
    "raw_transport_response",
    "sql_details",
    "stack_trace",
    "canonical_payload",
    "private_actor_context",
    "unbounded_diagnostics",
    "raw_actor_id",
    "raw_request_id",
    "raw_idempotency_key",
    "unredacted_reason",
    "provider_credentials",
    "headers",
    "cookies",
    "tokens",
    "audit_event_id"
  ]

  test "existing static frontend shell files are present" do
    assert File.exists?(@index_html)
    assert File.exists?(@styles_css)
    assert File.exists?(@script_js)
  end

  test "existing HTML shell keeps expected Fast MVP sections and placeholders" do
    html = File.read!(@index_html)

    assert html =~ "<title>Disclosure Automation</title>"
    assert html =~ "<link rel=\"stylesheet\" href=\"./styles.css\" />"
    assert html =~ "<script src=\"./script.js\"></script>"
    assert html =~ "class=\"hero\""
    assert html =~ "class=\"container grid\""
    assert html =~ "id=\"latest-digest-card\""
    assert html =~ "id=\"digest-summary\""
    assert html =~ "id=\"digest-items\""
    assert html =~ "id=\"backend-status-card\""
    assert html =~ "id=\"status-text\""
    assert html =~ "id=\"status-details\""
    assert html =~ "id=\"show-status\""
  end

  test "operator link remains minimal and targets source health internal UI" do
    html = File.read!(@index_html)

    assert html =~ "id=\"operator-source-health-link\""
    assert html =~ "href=\"/admin/source-health\""
    assert html =~ "운영자 상태 페이지"

    refute_forbidden_frontend_fragments(html)
  end

  test "frontend script keeps same-origin API smoke calls and safe fallback messages" do
    script = File.read!(@script_js)

    assert script =~ "window.DISCLOSURE_API_BASE_URL"
    assert script =~ "fetchJson(\"/api/health\")"
    assert script =~ "fetchJson(\"/api/feed/digest/latest?edition=breaking\")"
    assert script =~ "백엔드 상태: 확인 불가"
    assert script =~ "최신 digest를 확인할 수 없습니다."
    assert script =~ "API 서버가 아직 연결되지 않았거나"
    assert script =~ "document.getElementById(\"show-status\")"

    refute script =~ "console.log(payload)"
    refute script =~ "JSON.stringify(payload)"
    refute_forbidden_frontend_fragments(script)
  end

  test "frontend digest renderer remains defensive over supported response shapes" do
    script = File.read!(@script_js)

    assert script =~ "payload?.items"
    assert script =~ "payload?.data?.items"
    assert script =~ "payload?.digest?.items"
    assert script =~ "payload?.data"
    assert script =~ "items.slice(0, 5)"
  end

  test "existing CSS shell keeps hero grid card and button primitives without framework imports" do
    css = File.read!(@styles_css)

    assert css =~ ".hero"
    assert css =~ ".container"
    assert css =~ ".grid"
    assert css =~ ".card"
    assert css =~ ".button"
    assert css =~ ".button.primary"
    assert css =~ ".button.secondary"

    refute css =~ "@import"
    refute_forbidden_frontend_fragments(css)
  end

  test "backend smoke routes remain present without adding public source health routes" do
    routes = Phoenix.Router.routes(Router)

    assert route_exists?(routes, :get, "/api/health", DisclosureAutomationWeb.HealthController, :show)
    assert route_exists?(routes, :get, "/api/feed/digest/latest", DisclosureAutomationWeb.FeedDigestController, :latest)
    assert route_exists?(routes, :get, "/admin/source-health", DisclosureAutomationWeb.AdminSourceHealthUiController, :index)
    assert route_exists?(routes, :get, "/admin/source-health/:source_key", DisclosureAutomationWeb.AdminSourceHealthUiController, :show)
    assert route_exists?(routes, :post, "/api/admin/source-health/:source_key/recheck", DisclosureAutomationWeb.AdminSourceHealthController, :recheck)
    assert route_exists?(routes, :post, "/api/admin/sources/:source_key/poll", DisclosureAutomationWeb.AdminSourcePollController, :create)

    paths = Enum.map(routes, & &1.path)
    refute "/public/source-health" in paths
    refute "/api/public/source-health" in paths
    refute "/api/source-health" in paths
    refute "/admin/source-health/:source_key/poll" in paths
    refute "/admin/source-health/:source_key/audit" in paths
  end

  test "bounded source health UI denial copy remains safe for deployment smoke" do
    denial_copy = Enum.join([
      "Source health access denied",
      "state=forbidden",
      "reason=missing_source_health_auth_context"
    ], "\n")

    assert denial_copy =~ "Source health access denied"
    assert denial_copy =~ "state=forbidden"
    assert denial_copy =~ "reason=missing_source_health_auth_context"
    refute_forbidden_response_fragments(denial_copy)
  end

  defp route_exists?(routes, verb, path, plug, plug_opts) do
    Enum.any?(routes, fn route ->
      route.verb == verb and
        route.path == path and
        route.plug == plug and
        route.plug_opts == plug_opts
    end)
  end

  defp refute_forbidden_frontend_fragments(value) do
    value = String.downcase(value)

    for fragment <- @forbidden_frontend_fragments do
      refute String.contains?(value, fragment),
             "expected frontend artifact not to include forbidden fragment #{inspect(fragment)}"
    end
  end

  defp refute_forbidden_response_fragments(value) do
    for fragment <- @forbidden_response_fragments do
      refute String.contains?(value, fragment),
             "expected response copy not to include forbidden fragment #{inspect(fragment)}"
    end
  end
end
