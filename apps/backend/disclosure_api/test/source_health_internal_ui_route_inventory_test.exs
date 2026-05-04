defmodule DisclosureAutomation.SourceHealthInternalUiRouteInventoryTest do
  use ExUnit.Case, async: true

  alias DisclosureAutomationWeb.Router

  @approved_source_health_ui_routes [
    {:get, "/admin/source-health", DisclosureAutomationWeb.AdminSourceHealthUiController, :index},
    {:get, "/admin/source-health/:source_key", DisclosureAutomationWeb.AdminSourceHealthUiController, :show}
  ]

  test "router exposes the locked internal source health UI routes" do
    routes = Phoenix.Router.routes(Router)

    for {verb, path, plug, plug_opts} <- @approved_source_health_ui_routes do
      assert Enum.any?(routes, fn route ->
               route.verb == verb and
                 route.path == path and
                 route.plug == plug and
                 route.plug_opts == plug_opts
             end), "expected #{inspect(verb)} #{path} to route to #{inspect(plug)}.#{plug_opts}"
    end
  end

  test "source health UI routes remain internal browser routes only" do
    routes = Phoenix.Router.routes(Router)
    paths = Enum.map(routes, & &1.path)

    assert "/admin/source-health" in paths
    assert "/admin/source-health/:source_key" in paths

    refute "/source-health" in paths
    refute "/public/source-health" in paths
    refute "/api/public/source-health" in paths
    refute "/api/source-health" in paths
  end

  test "source health UI route inventory does not expose poll or audit UI routes" do
    routes = Phoenix.Router.routes(Router)
    paths = Enum.map(routes, & &1.path)

    refute "/admin/source-health/:source_key/poll" in paths
    refute "/admin/source-health/:source_key/audit" in paths
    refute "/admin/source-health/audit" in paths
    refute "/admin/sources/:source_key/poll" in paths
  end

  test "source health UI routes are separate from bounded API routes" do
    routes = Phoenix.Router.routes(Router)

    assert Enum.any?(routes, fn route ->
             route.verb == :get and
               route.path == "/api/admin/source-health" and
               route.plug == DisclosureAutomationWeb.AdminSourceHealthController and
               route.plug_opts == :index
           end)

    assert Enum.any?(routes, fn route ->
             route.verb == :get and
               route.path == "/admin/source-health" and
               route.plug == DisclosureAutomationWeb.AdminSourceHealthUiController and
               route.plug_opts == :index
           end)
  end
end
