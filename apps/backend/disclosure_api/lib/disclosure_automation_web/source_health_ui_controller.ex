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

  def show(conn, %{"source_key" => source_key} = params) do
    case Sources.get_source_health(source_key) do
      {:ok, %{data: source, cursors: cursors}} ->
        conn
        |> put_resp_content_type("text/plain")
        |> text(render_show(source, cursors, params))

      {:error, :not_found} ->
        conn
        |> put_status(:not_found)
        |> put_resp_content_type("text/plain")
        |> text(render_not_found(source_key))
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

  defp render_show(source, cursors, params) do
    ([
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
       "cursor_count=#{length(cursors || [])}"
     ] ++ recheck_action_state(source.source_key, params) ++ legacy_unwired_action_state(params) ++ [
       "back=/admin/source-health"
     ])
    |> Enum.join("\n")
  end

  defp render_not_found(source_key) do
    [
      "Source health detail",
      "state=not_found",
      "source_key=#{safe_text(source_key)}",
      "recheck_action=not_available",
      "back=/admin/source-health"
    ]
    |> Enum.join("\n")
  end

  defp recheck_action_state(source_key, params) do
    if permission_state_requested?(params) do
      permissions = actor_permissions(params)

      if "source_health:recheck" in permissions do
        [
          "recheck_action=enabled",
          "recheck_target=/api/admin/source-health/#{safe_text(source_key)}/recheck",
          "idempotency=required"
        ]
      else
        [
          "recheck_action=disabled",
          "recheck_reason=read_only"
        ]
      end
    else
      ["recheck_action=not_rendered"]
    end
  end

  defp legacy_unwired_action_state(params) do
    if permission_state_requested?(params) do
      []
    else
      [
        "poll_action=not_rendered",
        "audit_ui=not_rendered"
      ]
    end
  end

  defp permission_state_requested?(params), do: Map.has_key?(params, "actor_permissions")

  defp actor_permissions(params) do
    case Map.get(params, "actor_permissions") do
      permissions when is_list(permissions) -> permissions
      permission when is_binary(permission) -> [permission]
      _ -> []
    end
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
