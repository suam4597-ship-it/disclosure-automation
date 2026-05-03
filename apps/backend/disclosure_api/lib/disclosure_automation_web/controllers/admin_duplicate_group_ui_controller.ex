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
              <li>Action controls are available only on the detail screen.</li>
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
              <li>Action buttons map to locked action routes and do not submit override fields.</li>
            </ul>
          </section>

          <section id=\"duplicate-group-detail-api-routes\">
            <h2>Locked API Routes</h2>
            <dl>
              <dt>Detail</dt><dd data-api-route=\"detail\">#{detail_api_route}</dd>
              <dt>Confirm</dt><dd data-api-route=\"confirm\">#{confirm_api_route}</dd>
              <dt>Reject</dt><dd data-api-route=\"reject\">#{reject_api_route}</dd>
              <dt>Mark needs review</dt><dd data-api-route=\"mark-review\">#{mark_review_api_route}</dd>
              <dt>Clear review state</dt><dd data-api-route=\"clear-review-state\">#{clear_review_state_api_route}</dd>
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

          <section id=\"duplicate-group-action-controls\" data-action-controls=\"enabled\" data-operation-override=\"forbidden\">
            <h2>Action Controls</h2>
            <p>Buttons choose the locked action route. The request body does not include any route operation override.</p>
            <form id=\"duplicate-group-action-form\" data-request-allowlist=\"bounded-redacted-action-request\">
              <label>actor_id_hash <input name=\"actor_id_hash\" value=\"sha256:operator-001\" autocomplete=\"off\"></label>
              <label>actor_permissions <input name=\"actor_permissions\" value=\"duplicate_group:confirm,duplicate_group:reject,duplicate_group:mark_review,duplicate_group:clear_review_state\" autocomplete=\"off\"></label>
              <label>roles <input name=\"roles\" value=\"operator\" autocomplete=\"off\"></label>
              <label>request_id_hash <input name=\"request_id_hash\" placeholder=\"sha256:request-hash\" autocomplete=\"off\"></label>
              <label>idempotency_key_hash <input name=\"idempotency_key_hash\" placeholder=\"sha256:idempotency-hash\" autocomplete=\"off\"></label>
              <label>operator_reason_redacted <input name=\"operator_reason_redacted\" value=\"REDACTED_OPERATOR_REASON\" autocomplete=\"off\"></label>
              <label>redaction_status <input name=\"redaction_status\" value=\"passed\" autocomplete=\"off\"></label>
              <label>pre_review_state <input name=\"pre_review_state\" value=\"unknown\" autocomplete=\"off\"></label>
              <button type=\"button\" data-action-control=\"confirm\" data-action-route=\"#{confirm_api_route}\" data-post-review-state=\"confirmed_by_operator\">Confirm duplicate group</button>
              <button type=\"button\" data-action-control=\"reject\" data-action-route=\"#{reject_api_route}\" data-post-review-state=\"rejected_by_operator\">Reject duplicate group</button>
              <button type=\"button\" data-action-control=\"mark-review\" data-action-route=\"#{mark_review_api_route}\" data-post-review-state=\"needs_review\">Mark needs review</button>
              <button type=\"button\" data-action-control=\"clear-review-state\" data-action-route=\"#{clear_review_state_api_route}\" data-post-review-state=\"cleared\">Clear review state</button>
            </form>
            <p id=\"duplicate-group-action-status\" data-action-status=\"ready\">Ready for an operator action.</p>
            <pre id=\"duplicate-group-action-result\" data-action-result=\"bounded\"></pre>
          </section>
        </main>
        <script>
          (function () {
            var status = document.getElementById('duplicate-group-detail-status');
            var detailRoute = document.body.getAttribute('data-detail-api-route');
            var memberRows = document.getElementById('duplicate-group-member-rows');
            var actionRows = document.getElementById('duplicate-group-action-event-rows');
            var actionForm = document.getElementById('duplicate-group-action-form');
            var actionStatus = document.getElementById('duplicate-group-action-status');
            var actionResult = document.getElementById('duplicate-group-action-result');

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

              var currentState = (item.review_state_summary || {}).review_state || 'unknown';
              var preReviewState = actionForm.querySelector('[name=\"pre_review_state\"]');
              if (preReviewState) { preReviewState.value = currentState; }

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

            function listValue(name) {
              var input = actionForm.querySelector('[name=\"' + name + '\"]');
              if (!input || !input.value) { return []; }
              return input.value.split(',').map(function (value) { return value.trim(); }).filter(Boolean);
            }

            function stringValue(name, fallback) {
              var input = actionForm.querySelector('[name=\"' + name + '\"]');
              if (!input || !input.value) { return fallback; }
              return input.value;
            }

            function generatedHash(prefix) {
              return 'sha256:' + prefix + '-' + String(Date.now());
            }

            function actionPayload(button) {
              return {
                actor_id_hash: stringValue('actor_id_hash', 'sha256:operator-001'),
                actor_permissions: listValue('actor_permissions'),
                roles: listValue('roles'),
                request_id_hash: stringValue('request_id_hash', generatedHash('request')),
                idempotency_key_hash: stringValue('idempotency_key_hash', generatedHash('idempotency')),
                operator_reason_redacted: stringValue('operator_reason_redacted', 'REDACTED_OPERATOR_REASON'),
                result_status: 'completed',
                redaction_status: stringValue('redaction_status', 'passed'),
                pre_review_state: stringValue('pre_review_state', 'unknown'),
                post_review_state: button.getAttribute('data-post-review-state')
              };
            }

            function setPending(pending) {
              Array.prototype.forEach.call(actionForm.querySelectorAll('button[data-action-route]'), function (button) {
                button.disabled = pending;
              });
            }

            function submitAction(button) {
              setPending(true);
              actionStatus.textContent = 'Submitting action.';
              return fetch(button.getAttribute('data-action-route'), {
                method: 'POST',
                headers: { 'accept': 'application/json', 'content-type': 'application/json' },
                body: JSON.stringify(actionPayload(button))
              })
                .then(function (response) { return response.json(); })
                .then(function (result) {
                  actionResult.textContent = JSON.stringify(result, null, 2);
                  actionStatus.textContent = 'Action submitted. Refreshing detail.';
                  return loadDetail();
                })
                .then(function () {
                  actionStatus.textContent = 'Action submitted and detail refreshed.';
                })
                .catch(function () {
                  actionStatus.textContent = 'Unable to submit action.';
                })
                .finally(function () {
                  setPending(false);
                });
            }

            Array.prototype.forEach.call(actionForm.querySelectorAll('button[data-action-route]'), function (button) {
              button.addEventListener('click', function () { submitAction(button); });
            });

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
