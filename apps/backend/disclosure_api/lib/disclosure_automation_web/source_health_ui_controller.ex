defmodule DisclosureAutomationWeb.AdminSourceHealthUiController do
  @moduledoc false

  use DisclosureAutomationWeb, :controller

  alias DisclosureAutomation.Sources

  def index(conn, params) do
    {:ok, page} = Sources.list_source_health(params)

    conn
    |> put_resp_content_type("text/plain")
    |> text(render_index(page))
  end

  def show(conn, %{"source_key" => source_key}) do
    case Sources.get_source_health(source_key) do
      {:ok, %{data: source, cursors: cursors}} ->
        conn
        |> put_resp_content_type("text/plain")
        |> text(render_show(source, cursors))

      {:error, :not_found} ->
        conn
        |> put_status(:not_found)
        |> put_resp_content_type("text/plain")
        |> text("Source health detail\nstate=not_found\nsource_key=#{safe_text(source_key)}\nback=/admin/source-health")
    end
  end

  defp render_index(page) do
    rows = Enum.map(page.data, &render_source_row/1)

    ([
       "Source health",
       "page=#{page.page}",
       "page_size=#{page.page_size}",
       "total_entries=#{page.total_entries}",
       "fields=source_key,display_name,source_type,region_code,health_status,last_success_at,last_failure_at,active",
       "recheck_action=not_rendered",
       "poll_action=not_rendered",
       "audit_ui=not_rendered"
     ] ++ rows)
    |> Enum.join("\n")
  end

  defp render_show(source, cursors) do
    [
      "Source health detail",
      "state=found",
      "source_key=#{safe_text(source.source_key)}",
      "display_name=#{safe_text(source.display_name)}",
      "source_type=#{safe_text(source.source_type)}",
      "region_code=#{safe_text(source.region_code)}",
      "health_status=#{safe_text(source.health_status)}",
      "last_success_at=#{safe_datetime(source.last_success_at)}",
      "last_failure_at=#{safe_datetime(source.last_failure_at)}",
      "active=#{source.active}",
      "cursor_count=#{length(cursors || [])}",
      "recheck_action=not_rendered",
      "poll_action=not_rendered",
      "audit_ui=not_rendered",
      "back=/admin/source-health"
    ]
    |> Enum.join("\n")
  end

  defp render_source_row(source) do
    [
      "source",
      "source_key=#{safe_text(source.source_key)}",
      "display_name=#{safe_text(source.display_name)}",
      "source_type=#{safe_text(source.source_type)}",
      "region_code=#{safe_text(source.region_code)}",
      "health_status=#{safe_text(source.health_status)}",
      "last_success_at=#{safe_datetime(source.last_success_at)}",
      "last_failure_at=#{safe_datetime(source.last_failure_at)}",
      "active=#{source.active}"
    ]
    |> Enum.join(" ")
  end

  defp safe_datetime(nil), do: ""
  defp safe_datetime(%DateTime{} = value), do: DateTime.to_iso8601(value)
  defp safe_datetime(value), do: safe_text(value)

  defp safe_text(nil), do: ""

  defp safe_text(value) do
    value
    |> to_string()
    |> String.replace(~r/[\r\n\t]/, " ")
  end
end
