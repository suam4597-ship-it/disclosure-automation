defmodule DisclosureAutomationWeb.Router do
  @moduledoc false

  @feed_digest_latest_path "/api/feed/digest/latest"
  @admin_source_health_path "/api/admin/source-health"
  @admin_source_health_recheck_suffix "recheck"

  alias DisclosureAutomationWeb.AdminSourceHealthController
  alias DisclosureAutomationWeb.FeedDigestController
  alias Phoenix.Controller
  alias Plug.Conn

  def call(%Conn{method: "GET", request_path: @feed_digest_latest_path, params: params} = conn, _opts),
    do: FeedDigestController.latest(conn, params)

  def call(%Conn{method: "GET", request_path: path, params: params} = conn, _opts) do
    case String.split(path, "/", trim: true) do
      ["api", "feed", "digest", digest_date, edition] ->
        FeedDigestController.show(conn, Map.merge(params, %{"digest_date" => digest_date, "edition" => edition}))

      ["api", "admin", "source-health"] ->
        AdminSourceHealthController.index(conn, params)

      ["api", "admin", "source-health", source_key] ->
        AdminSourceHealthController.show(conn, Map.merge(params, %{"source_key" => source_key}))

      _ ->
        conn
        |> Conn.put_status(:not_found)
        |> Controller.json(%{error: %{code: "not_found", message: "route not found"}})
    end
  end

  def call(%Conn{method: "POST", request_path: path, params: params} = conn, _opts) do
    case String.split(path, "/", trim: true) do
      ["api", "admin", "source-health", source_key, "recheck"] ->
        AdminSourceHealthController.recheck(conn, Map.merge(params, %{"source_key" => source_key}))

      _ ->
        conn
        |> Conn.put_status(:not_found)
        |> Controller.json(%{error: %{code: "not_found", message: "route not found"}})
    end
  end
end
