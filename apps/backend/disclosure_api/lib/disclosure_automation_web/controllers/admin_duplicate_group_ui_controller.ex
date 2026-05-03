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

  def index(conn, _params), do: send_html(conn, list_screen_html())
  def show(conn, %{"group_id" => group_id}), do: send_html(conn, detail_shell_html(group_id))

  defp send_html(conn, html) do
    conn
    |> put_resp_content_type("text/html", "utf-8")
    |> send_resp(200, html)
  end

  defp list_screen_html do
    """
    <!doctype html>
    <html lang=\"en\">
      <head>
        <meta charset=\"utf-8\">
        <meta name=\"viewport\" content=\"width=device-width, initial-scale=1\">
        <title>Duplicate Groups</title>
      </head>
      <body data-view-scope=\"operator_only_duplicate_group_review\" data-list-api-route=\"#{@list_api_route}\" data-detail-route-template=\"/admin/duplicate-groups/:group_id\">
        <main id=\"duplicate-group-operator-list-screen\">
          <h1>Duplicate Groups</h1>
          <p>This internal list screen is operator-only, advisory-only, non-canonical, bounded, and redacted.</p>

          <section id=\"duplicate-group-list-guardrails\">
            <h2>Guardrails</h2>
            <ul>
              <li>List data is loaded only from the locked internal JSON API.</li>
              <li>The list screen does not fetch or render action event history.</li>
              <li>Detail and action controls remain deferred to later Stage 6.6 PRs.</li>
            </ul>
          </section>

          <section id=\"duplicate-group-list-api-routes\">
            <h2>Locked API Routes</h2>
            <dl>
              <dt>List</dt><dd data-api-route=\"list\">#{@list_api_route}</dd>
              <dt>Detail template</dt><dd data-api-route=\"detail-template\">#{@detail_api_route_template}</dd>
            </dl>
          </section>

          <form id=\"duplicate-group-list-filters\" data-filter-scope=\"bounded-list-filters\">
            <label>Confidence <input name=\"confidence\" autocomplete=\"off\"></label>
            <label>Source key <input name=\"source_key\" autocomplete=\"off\"></label>
            <label>Member kind <input name=\"member_kind\" autocomplete=\"off\"></label>
            <label>Redaction status <input name=\"redaction_status\" autocomplete=\"off\"></label>
            <label>Limit <input name=\"limit\" type=\"number\" min=\"1\" max=\"100\" value=\"50\"></label>
            <button type=\"submit\">Apply filters</button>
          </form>

          <p id=\"duplicate-group-list-status\" data-list-status=\"ready\">Ready to load duplicate groups.</p>

          <table id=\"duplicate-group-list-table\">
            <thead>
              <tr>
                <th scope=\"col\">group_id</th>
                <th scope=\"col\">confidence</th>
                <th scope=\"col\">review_state_summary.review_state</th>
                <th scope=\"col\">review_state_summary.last_action_operation</th>
                <th scope=\"col\">review_state_summary.reviewed_at</th>
                <th scope=\"col\">member_count</th>
                <th scope=\"col\">source_keys</th>
                <th scope=\"col\">redaction_status</th>
              </tr>
            </thead>
            <tbody id=\"duplicate-group-list-rows\" data-excludes=\"action_event_summary\">
              <tr><td colspan=\"8\">No duplicate groups loaded yet.</td></tr>
            </tbody>
          </table>
        </main>
        <script>
          (function () {
            var form = document.getElementById('duplicate-group-list-filters');
            var rows = document.getElementById('duplicate-group-list-rows');
            var status = document.getElementById('duplicate-group-list-status');
            var listRoute = document.body.getAttribute('data-list-api-route');
            var detailTemplate = document.body.getAttribute('data-detail-route-template');

            function text(value) {
              if (value === null || value === undefined || value === '') { return ''; }
              return String(value);
            }

            function reviewState(item, key) {
              return text((item.review_state_summary || {})[key]);
            }

            function detailHref(groupId) {
              return detailTemplate.replace(':group_id', encodeURIComponent(groupId));
            }

            function renderItems(items) {
              rows.textContent = '';
              if (!items || items.length === 0) {
                var emptyRow = document.createElement('tr');
                var emptyCell = document.createElement('td');
                emptyCell.colSpan = 8;
                emptyCell.textContent = 'No duplicate groups found.';
                emptyRow.appendChild(emptyCell);
                rows.appendChild(emptyRow);
                return;
              }

              items.forEach(function (item) {
                var tr = document.createElement('tr');
                var values = [
                  item.group_id,
                  item.confidence,
                  reviewState(item, 'review_state'),
                  reviewState(item, 'last_action_operation'),
                  reviewState(item, 'reviewed_at'),
                  item.member_count,
                  (item.source_keys || []).join(', '),
                  item.redaction_status
                ];

                values.forEach(function (value, index) {
                  var td = document.createElement('td');
                  if (index === 0 && value) {
                    var link = document.createElement('a');
                    link.href = detailHref(value);
                    link.textContent = value;
                    td.appendChild(link);
                  } else {
                    td.textContent = text(value);
                  }
                  tr.appendChild(td);
                });

                rows.appendChild(tr);
              });
            }

            function buildUrl() {
              var params = new URLSearchParams();
              Array.prototype.forEach.call(new FormData(form).entries(), function (entry) {
                if (entry[1]) { params.set(entry[0], entry[1]); }
              });
              var query = params.toString();
              return query ? listRoute + '?' + query : listRoute;
            }

            function loadList() {
              status.textContent = 'Loading duplicate groups.';
              return fetch(buildUrl(), { headers: { 'accept': 'application/json' } })
                .then(function (response) { return response.json(); })
                .then(function (page) {
                  renderItems(page.items || []);
                  status.textContent = 'Loaded ' + text(page.item_count || 0) + ' duplicate groups.';
                })
                .catch(function () {
                  rows.textContent = '';
                  status.textContent = 'Unable to load duplicate groups.';
                });
            }

            form.addEventListener('submit', function (event) {
              event.preventDefault();
              loadList();
            });
          }());
        </script>
      </body>
    </html>
    """
  end

  defp detail_shell_html(group_id) do
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
        <title>Duplicate Group Detail</title>
      </head>
      <body data-view-scope=\"operator_only_duplicate_group_review\"#{group_id_attribute}>
        <main id=\"duplicate-group-operator-ui-shell\">
          <h1>Duplicate Group Detail</h1>
          <p>This internal detail shell is operator-only, advisory-only, non-canonical, bounded, and redacted.</p>
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
          <p data-shell-status=\"stage66-detail-deferred\">Stage 6.6 detail shell only. Detail data rendering and action controls are deferred.</p>
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
