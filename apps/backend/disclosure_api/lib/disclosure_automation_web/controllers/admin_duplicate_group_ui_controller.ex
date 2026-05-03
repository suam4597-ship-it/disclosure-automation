defmodule DisclosureAutomationWeb.AdminDuplicateGroupUiController do
  @moduledoc false

  use Phoenix.Controller, formats: [:html]

  import Plug.Conn

  @list_api_route "/api/admin/duplicate-groups"
  @detail_api_route_template "/api/admin/duplicate-groups/:group_id"
  @confirm_api_route_template "/api/admin/duplicate-groups/:group_id/confirm"
  @reject_api_route_template "/api/admin/duplicate-groups/:group_id/reject"
  @mark_review_api_route_template "/api/admin/duplicate-groups/:group_id/mark-review"
  @clear_review_state_api_route_template "/api/admin/duplicate-groups/:group_id/clear-review-state"

  def index(conn, _params), do: send_shell(conn, nil)
  def show(conn, %{"group_id" => group_id}), do: send_shell(conn, group_id)

  defp send_shell(conn, group_id) do
    conn
    |> put_resp_content_type("text/html", "utf-8")
    |> send_resp(200, shell_html(group_id))
  end

  defp shell_html(group_id) do
    group_id_attribute = group_id_attribute(group_id)
    detail_api_route = detail_route_for(group_id)
    confirm_api_route = action_route_for(@confirm_api_route_template, group_id)
    reject_api_route = action_route_for(@reject_api_route_template, group_id)
    mark_review_api_route = action_route_for(@mark_review_api_route_template, group_id)
    clear_review_state_api_route = action_route_for(@clear_review_state_api_route_template, group_id)

    """
    <!doctype html>
    <html lang=\"en\">
      <head>
        <meta charset=\"utf-8\">
        <meta name=\"viewport\" content=\"width=device-width, initial-scale=1\">
        <title>Duplicate Group Operator UI</title>
      </head>
      <body data-view-scope=\"operator_only_duplicate_group_review\"#{group_id_attribute}>
        <main id=\"duplicate-group-operator-ui-shell\">
          <h1>Duplicate Group Operator UI</h1>
          <p>This internal shell is for operator-only duplicate group review.</p>
          <p>This shell is advisory-only, non-canonical, bounded, and redacted.</p>
          <section id=\"duplicate-group-api-routes\">
            <h2>Locked API Routes</h2>
            <dl>
              <dt>List</dt><dd data-api-route=\"list\">#{@list_api_route}</dd>
              <dt>Detail</dt><dd data-api-route=\"detail\">#{detail_api_route}</dd>
              <dt>Confirm</dt><dd data-api-route=\"confirm\">#{confirm_api_route}</dd>
              <dt>Reject</dt><dd data-api-route=\"reject\">#{reject_api_route}</dd>
              <dt>Mark needs review</dt><dd data-api-route=\"mark-review\">#{mark_review_api_route}</dd>
              <dt>Clear review state</dt><dd data-api-route=\"clear-review-state\">#{clear_review_state_api_route}</dd>
            </dl>
          </section>
          <p data-shell-status=\"stage66-shell-only\">Stage 6.6 shell route only. List, detail, and action controls are deferred.</p>
        </main>
      </body>
    </html>
    """
  end

  defp group_id_attribute(nil), do: ""
  defp group_id_attribute(group_id), do: " data-group-id=\"#{escape_html(group_id)}\""

  defp detail_route_for(nil), do: @detail_api_route_template
  defp detail_route_for(group_id), do: replace_group_id(@detail_api_route_template, group_id)

  defp action_route_for(template, nil), do: template
  defp action_route_for(template, group_id), do: replace_group_id(template, group_id)

  defp replace_group_id(template, group_id) do
    String.replace(template, ":group_id", URI.encode_www_form(to_string(group_id)))
  end

  defp escape_html(value) do
    value
    |> to_string()
    |> String.replace("&", "&amp;")
    |> String.replace("\"", "&quot;")
    |> String.replace("'", "&#39;")
    |> String.replace("<", "&lt;")
    |> String.replace(">", "&gt;")
  end
end
