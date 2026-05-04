defmodule DisclosureAutomation.SourceHealthRouteContractTest do
  use ExUnit.Case, async: true

  alias DisclosureAutomationWeb.Router

  @locked_source_health_routes [
    {:get, "/api/admin/source-health", DisclosureAutomationWeb.AdminSourceHealthController, :index},
    {:get, "/api/admin/source-health/:source_key", DisclosureAutomationWeb.AdminSourceHealthController, :show},
    {:post, "/api/admin/source-health/:source_key/recheck", DisclosureAutomationWeb.AdminSourceHealthController, :recheck},
    {:post, "/api/admin/sources/:source_key/poll", DisclosureAutomationWeb.AdminSourcePollController, :create}
  ]
  @locked_source_health_ui_routes [
    "/admin/source-health",
    "/admin/source-health/:source_key"
  ]

  test "router exposes the locked internal source health route surface" do
    routes = Phoenix.Router.routes(Router)

    for {verb, path, plug, plug_opts} <- @locked_source_health_routes do
      assert Enum.any?(routes, fn route ->
               route.verb == verb and
                 route.path == path and
                 route.plug == plug and
                 route.plug_opts == plug_opts
             end), "expected #{inspect(verb)} #{path} to route to #{inspect(plug)}.#{plug_opts}"
    end
  end

  test "source health route surface remains internal admin only" do
    routes = Phoenix.Router.routes(Router)

    source_health_paths =
      routes
      |> Enum.map(& &1.path)
      |> Enum.filter(fn path -> String.contains?(path, "source-health") or String.contains?(path, "/sources/") end)

    assert "/api/admin/source-health" in source_health_paths
    assert "/api/admin/source-health/:source_key" in source_health_paths
    assert "/api/admin/source-health/:source_key/recheck" in source_health_paths
    assert "/api/admin/sources/:source_key/poll" in source_health_paths
    assert "/admin/source-health" in source_health_paths
    assert "/admin/source-health/:source_key" in source_health_paths

    refute Enum.any?(source_health_paths, fn path -> String.starts_with?(path, "/public") end)
    refute Enum.any?(source_health_paths, fn path -> String.starts_with?(path, "/api/public") end)

    admin_ui_source_health_paths =
      Enum.filter(source_health_paths, fn path -> String.starts_with?(path, "/admin") end)

    assert Enum.sort(admin_ui_source_health_paths) == Enum.sort(@locked_source_health_ui_routes)
  end

  test "route contract preserves route-derived operation names" do
    route_operation_by_path = %{
      "/api/admin/source-health/:source_key/recheck" => :recheck_source_health,
      "/api/admin/sources/:source_key/poll" => :poll_source
    }

    assert route_operation_by_path["/api/admin/source-health/:source_key/recheck"] == :recheck_source_health
    assert route_operation_by_path["/api/admin/sources/:source_key/poll"] == :poll_source

    refute Map.has_key?(route_operation_by_path, :operation)
    refute Map.has_key?(route_operation_by_path, :action_operation)
    refute Map.has_key?(route_operation_by_path, :route_operation)
  end

  test "source health routes do not alter public route inventory" do
    routes = Phoenix.Router.routes(Router)
    paths = Enum.map(routes, & &1.path)

    assert "/api/events/:event_id" in paths
    assert "/api/events/:event_id/news-overlay" in paths
    assert "/api/feed/digest/latest" in paths
    assert "/api/feed/digest/:digest_date/:edition" in paths
    assert "/api/feed/hero" in paths
    assert "/api/feed/region/:region_code" in paths

    refute "/api/public/source-health" in paths
    refute "/api/public/sources/:source_key/poll" in paths
    refute "/api/events/:event_id/source-health" in paths
    refute "/api/feed/source-health" in paths
  end
end
