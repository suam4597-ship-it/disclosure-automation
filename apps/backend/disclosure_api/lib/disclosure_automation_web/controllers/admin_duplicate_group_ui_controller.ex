defmodule DisclosureAutomationWeb.AdminDuplicateGroupUiController do
  @moduledoc false

  use Phoenix.Controller, formats: [:html]

  import Plug.Conn

  @list_api_route "/api/admin/duplicate-groups"
  @detail_api_route_template "/api/admin/duplicate-groups/:group_id"

  def index(conn, _params), do: send_html(conn, list_screen_html())
  def show(conn, %{"group_id" => group_id}), do: send_html(conn, detail_screen_html(group_id))

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
              <li>Action controls remain deferred to a later Stage 6.6 PR.</li>
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

  defp detail_screen_html(group_id) do
    group_id_attribute = group_id_attribute(group_id)
    detail_api_route = detail_route_for(group_id)

    """
    <!doctype html>
    <html lang=\"en\">
      <head>
        <meta charset=\"utf-8\">
        <meta name=\"viewport\" content=\"width=device-width, initial-scale=1\">
        <title>Duplicate Group Detail</title>
      </head>
      <body data-view-scope=\"operator_only_duplicate_group_review\"#{group_id_attribute} data-list-route=\"/admin/duplicate-groups\" data-detail-api-route=\"#{detail_api_route}\">
        <main id=\"duplicate-group-operator-detail-screen\">
          <p><a href=\"/admin/duplicate-groups\">Back to duplicate groups</a></p>
          <h1>Duplicate Group Detail</h1>
          <p>This internal detail screen is operator-only, advisory-only, non-canonical, bounded, and redacted.</p>

          <section id=\"duplicate-group-detail-guardrails\">
            <h2>Guardrails</h2>
            <ul>
              <li>Detail data is loaded only from the locked internal JSON API.</li>
              <li>Action event summary rendering is bounded to the locked show response.</li>
              <li>Action controls and POST submissions remain deferred to a later Stage 6.6 PR.</li>
            </ul>
          </section>

          <section id=\"duplicate-group-detail-api-routes\">
            <h2>Locked API Routes</h2>
            <dl>
              <dt>Detail</dt><dd data-api-route=\"detail\">#{detail_api_route}</dd>
            </dl>
          </section>

          <p id=\"duplicate-group-detail-status\" data-detail-status=\"ready\">Ready to load duplicate group detail.</p>

          <section id=\"duplicate-group-summary\">
            <h2>Group</h2>
            <dl>
              <dt>group_id</dt><dd data-detail-field=\"group_id\"></dd>
              <dt>confidence</dt><dd data-detail-field=\"confidence\"></dd>
              <dt>source_keys</dt><dd data-detail-field=\"source_keys\"></dd>
              <dt>match_reasons</dt><dd data-detail-field=\"match_reasons\"></dd>
              <dt>member_count</dt><dd data-detail-field=\"member_count\"></dd>
              <dt>has_official_tdnet_event</dt><dd data-detail-field=\"has_official_tdnet_event\"></dd>
              <dt>has_provider_overlay</dt><dd data-detail-field=\"has_provider_overlay\"></dd>
              <dt>redaction_status</dt><dd data-detail-field=\"redaction_status\"></dd>
            </dl>
          </section>

          <section id=\"duplicate-group-review-state\">
            <h2>Review State</h2>
            <dl>
              <dt>review_state_summary.review_state</dt><dd data-review-state-field=\"review_state\"></dd>
              <dt>review_state_summary.last_action_operation</dt><dd data-review-state-field=\"last_action_operation\"></dd>
              <dt>review_state_summary.reviewed_at</dt><dd data-review-state-field=\"reviewed_at\"></dd>
              <dt>review_state_summary.reviewed_by_actor_id_hash</dt><dd data-review-state-field=\"reviewed_by_actor_id_hash\"></dd>
              <dt>review_state_summary.redaction_status</dt><dd data-review-state-field=\"redaction_status\"></dd>
            </dl>
          </section>

          <section id=\"duplicate-group-members\">
            <h2>Members</h2>
            <table>
              <thead>
                <tr>
                  <th scope=\"col\">member_id</th>
                  <th scope=\"col\">member_kind</th>
                  <th scope=\"col\">source_key</th>
                  <th scope=\"col\">provider</th>
                  <th scope=\"col\">external_id_hash</th>
                  <th scope=\"col\">official_event_id</th>
                  <th scope=\"col\">overlay_id</th>
                  <th scope=\"col\">confidence</th>
                  <th scope=\"col\">match_reasons</th>
                  <th scope=\"col\">redaction_status</th>
                </tr>
              </thead>
              <tbody id=\"duplicate-group-member-rows\">
                <tr><td colspan=\"10\">No members loaded yet.</td></tr>
              </tbody>
            </table>
          </section>

          <section id=\"duplicate-group-action-event-summary\" data-summary-limit=\"latest-five-from-show-response\">
            <h2>Latest Actions</h2>
            <table>
              <thead>
                <tr>
                  <th scope=\"col\">action_operation</th>
                  <th scope=\"col\">required_permission</th>
                  <th scope=\"col\">actor_id_hash</th>
                  <th scope=\"col\">request_id_hash</th>
                  <th scope=\"col\">idempotency_key_hash</th>
                  <th scope=\"col\">result_status</th>
                  <th scope=\"col\">pre_review_state</th>
                  <th scope=\"col\">post_review_state</th>
                  <th scope=\"col\">failure_code</th>
                  <th scope=\"col\">redaction_status</th>
                  <th scope=\"col\">inserted_at</th>
                </tr>
              </thead>
              <tbody id=\"duplicate-group-action-event-rows\" data-summary-source=\"show-response-only\">
                <tr><td colspan=\"11\">No latest actions loaded yet.</td></tr>
              </tbody>
            </table>
          </section>

          <section id=\"duplicate-group-action-controls-placeholder\" data-action-controls=\"deferred\">
            <h2>Action Controls</h2>
            <p>Action controls are deferred to a later Stage 6.6 PR.</p>
          </section>
        </main>
        <script>
          (function () {
            var status = document.getElementById('duplicate-group-detail-status');
            var detailRoute = document.body.getAttribute('data-detail-api-route');
            var memberRows = document.getElementById('duplicate-group-member-rows');
            var actionRows = document.getElementById('duplicate-group-action-event-rows');

            function text(value) {
              if (value === null || value === undefined || value === '') { return ''; }
              if (Array.isArray(value)) { return value.join(', '); }
              return String(value);
            }

            function setField(selector, key, value) {
              var element = document.querySelector(selector + '[data-detail-field=\"' + key + '\"]');
              if (element) { element.textContent = text(value); }
            }

            function setReviewState(summary, key) {
              var element = document.querySelector('[data-review-state-field=\"' + key + '\"]');
              if (element) { element.textContent = text((summary || {})[key]); }
            }

            function appendCells(row, values) {
              values.forEach(function (value) {
                var cell = document.createElement('td');
                cell.textContent = text(value);
                row.appendChild(cell);
              });
            }

            function renderMembers(members) {
              memberRows.textContent = '';
              if (!members || members.length === 0) {
                var emptyRow = document.createElement('tr');
                var emptyCell = document.createElement('td');
                emptyCell.colSpan = 10;
                emptyCell.textContent = 'No members found.';
                emptyRow.appendChild(emptyCell);
                memberRows.appendChild(emptyRow);
                return;
              }

              members.forEach(function (member) {
                var row = document.createElement('tr');
                appendCells(row, [
                  member.member_id,
                  member.member_kind,
                  member.source_key,
                  member.provider,
                  member.external_id_hash,
                  member.official_event_id,
                  member.overlay_id,
                  member.confidence,
                  member.match_reasons || [],
                  member.redaction_status
                ]);
                memberRows.appendChild(row);
              });
            }

            function renderActions(events) {
              actionRows.textContent = '';
              if (!events || events.length === 0) {
                var emptyRow = document.createElement('tr');
                var emptyCell = document.createElement('td');
                emptyCell.colSpan = 11;
                emptyCell.textContent = 'No latest actions found.';
                emptyRow.appendChild(emptyCell);
                actionRows.appendChild(emptyRow);
                return;
              }

              events.forEach(function (event) {
                var row = document.createElement('tr');
                appendCells(row, [
                  event.action_operation,
                  event.required_permission,
                  event.actor_id_hash,
                  event.request_id_hash,
                  event.idempotency_key_hash,
                  event.result_status,
                  event.pre_review_state,
                  event.post_review_state,
                  event.failure_code,
                  event.redaction_status,
                  event.inserted_at
                ]);
                actionRows.appendChild(row);
              });
            }

            function renderDetail(page) {
              var item = page.item || {};
              setField('[data-detail-field]', 'group_id', item.group_id);
              setField('[data-detail-field]', 'confidence', item.confidence);
              setField('[data-detail-field]', 'source_keys', item.source_keys || []);
              setField('[data-detail-field]', 'match_reasons', item.match_reasons || []);
              setField('[data-detail-field]', 'member_count', item.member_count);
              setField('[data-detail-field]', 'has_official_tdnet_event', item.has_official_tdnet_event);
              setField('[data-detail-field]', 'has_provider_overlay', item.has_provider_overlay);
              setField('[data-detail-field]', 'redaction_status', item.redaction_status);

              ['review_state', 'last_action_operation', 'reviewed_at', 'reviewed_by_actor_id_hash', 'redaction_status'].forEach(function (key) {
                setReviewState(item.review_state_summary || {}, key);
              });

              renderMembers(item.members || []);
              renderActions(item.action_event_summary || []);
            }

            function loadDetail() {
              status.textContent = 'Loading duplicate group detail.';
              return fetch(detailRoute, { headers: { 'accept': 'application/json' } })
                .then(function (response) { return response.json(); })
                .then(function (page) {
                  renderDetail(page);
                  status.textContent = 'Loaded duplicate group detail.';
                })
                .catch(function () {
                  status.textContent = 'Unable to load duplicate group detail.';
                });
            }

            loadDetail();
          }());
        </script>
      </body>
    </html>
    """
  end

  defp group_id_attribute(nil), do: ""
  defp group_id_attribute(group_id), do: " data-group-id=\"#{escape_html(group_id)}\""

  defp detail_route_for(nil), do: @detail_api_route_template
  defp detail_route_for(group_id), do: replace_group_id(@detail_api_route_template, group_id)

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
