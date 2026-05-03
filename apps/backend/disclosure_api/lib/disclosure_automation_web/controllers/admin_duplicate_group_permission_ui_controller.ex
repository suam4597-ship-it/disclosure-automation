defmodule DisclosureAutomationWeb.AdminDuplicateGroupPermissionUiController do
  @moduledoc false

  use Phoenix.Controller, formats: [:html]

  import Plug.Conn

  @detail_api_route_template "/api/admin/duplicate-groups/:group_id"
  @confirm_api_route_template "/api/admin/duplicate-groups/:group_id/confirm"
  @reject_api_route_template "/api/admin/duplicate-groups/:group_id/reject"
  @mark_review_api_route_template "/api/admin/duplicate-groups/:group_id/mark-review"
  @clear_review_state_api_route_template "/api/admin/duplicate-groups/:group_id/clear-review-state"

  def show(conn, %{"group_id" => group_id}) do
    conn
    |> put_resp_content_type("text/html", "utf-8")
    |> send_resp(200, detail_screen_html(group_id))
  end

  defp detail_screen_html(group_id) do
    encoded_group_id = URI.encode_www_form(to_string(group_id))
    detail_api_route = String.replace(@detail_api_route_template, ":group_id", encoded_group_id)
    confirm_api_route = String.replace(@confirm_api_route_template, ":group_id", encoded_group_id)
    reject_api_route = String.replace(@reject_api_route_template, ":group_id", encoded_group_id)
    mark_review_api_route = String.replace(@mark_review_api_route_template, ":group_id", encoded_group_id)
    clear_review_state_api_route = String.replace(@clear_review_state_api_route_template, ":group_id", encoded_group_id)

    """
    <!doctype html>
    <html lang=\"en\">
      <head><meta charset=\"utf-8\"><meta name=\"viewport\" content=\"width=device-width, initial-scale=1\"><title>Duplicate Group Detail</title></head>
      <body data-view-scope=\"operator_only_duplicate_group_review\" data-group-id=\"#{escape_html(group_id)}\" data-detail-api-route=\"#{detail_api_route}\">
        <a href=\"#duplicate-group-action-controls\" class=\"skip-link\">Skip to action controls</a>
        <main id=\"duplicate-group-operator-detail-screen\" aria-labelledby=\"duplicate-group-detail-title\">
          <nav aria-label=\"Duplicate group operator navigation\"><a href=\"/admin/duplicate-groups\">Back to duplicate groups</a></nav>
          <h1 id=\"duplicate-group-detail-title\">Duplicate Group Detail</h1>
          <p id=\"duplicate-group-detail-description\">This internal detail screen is operator-only, advisory-only, non-canonical, bounded, and redacted.</p>
          <section id=\"duplicate-group-detail-guardrails\" aria-labelledby=\"duplicate-group-detail-guardrails-title\"><h2 id=\"duplicate-group-detail-guardrails-title\">Guardrails</h2><ul><li>Detail data is loaded only from the locked internal JSON API.</li><li>Action event summary rendering is bounded to the locked show response.</li><li>Action buttons map to locked action routes and do not submit override fields.</li><li>Permission-aware button state is advisory only; backend authorization remains authoritative.</li></ul></section>
          <p id=\"duplicate-group-detail-status\" data-detail-status=\"ready\" data-state=\"ready\" aria-live=\"polite\" role=\"status\">Ready to load duplicate group detail.</p>
          <p id=\"duplicate-group-detail-loading-state\" data-state=\"loading\" hidden>Loading duplicate group detail.</p>
          <p id=\"duplicate-group-detail-error-state\" data-state=\"error\" data-error-category=\"unable_to_load_duplicate_group_detail\" role=\"alert\" hidden>Unable to load duplicate group detail.</p>
          <section id=\"duplicate-group-summary\" aria-labelledby=\"duplicate-group-summary-title\"><h2 id=\"duplicate-group-summary-title\">Group</h2><dl><dt>group_id</dt><dd data-detail-field=\"group_id\"></dd><dt>confidence</dt><dd data-detail-field=\"confidence\"></dd><dt>source_keys</dt><dd data-detail-field=\"source_keys\"></dd><dt>match_reasons</dt><dd data-detail-field=\"match_reasons\"></dd><dt>member_count</dt><dd data-detail-field=\"member_count\"></dd><dt>redaction_status</dt><dd data-detail-field=\"redaction_status\"></dd></dl></section>
          <section id=\"duplicate-group-review-state\" aria-labelledby=\"duplicate-group-review-state-title\"><h2 id=\"duplicate-group-review-state-title\">Review State</h2><p id=\"duplicate-group-review-state-empty\" data-state=\"empty\" hidden>No review state recorded yet.</p><dl><dt>review_state_summary.review_state</dt><dd data-review-state-field=\"review_state\"></dd><dt>review_state_summary.last_action_operation</dt><dd data-review-state-field=\"last_action_operation\"></dd><dt>review_state_summary.reviewed_at</dt><dd data-review-state-field=\"reviewed_at\"></dd><dt>review_state_summary.reviewed_by_actor_id_hash</dt><dd data-review-state-field=\"reviewed_by_actor_id_hash\"></dd><dt>review_state_summary.redaction_status</dt><dd data-review-state-field=\"redaction_status\"></dd></dl></section>
          <section id=\"duplicate-group-members\" aria-labelledby=\"duplicate-group-members-title\"><h2 id=\"duplicate-group-members-title\">Members</h2><p id=\"duplicate-group-members-empty\" data-state=\"empty\" hidden>No members found.</p><table aria-describedby=\"duplicate-group-members-empty\"><caption>Duplicate group members</caption><tbody id=\"duplicate-group-member-rows\"><tr><td>No members loaded yet.</td></tr></tbody></table></section>
          <section id=\"duplicate-group-action-event-summary\" data-summary-limit=\"latest-five-from-show-response\" aria-labelledby=\"duplicate-group-action-event-summary-title\"><h2 id=\"duplicate-group-action-event-summary-title\">Latest Actions</h2><p id=\"duplicate-group-action-event-empty\" data-state=\"empty\" hidden>No latest actions found.</p><table aria-describedby=\"duplicate-group-action-event-empty\"><caption>Latest duplicate group operator actions</caption><tbody id=\"duplicate-group-action-event-rows\" data-summary-source=\"show-response-only\"><tr><td>No latest actions loaded yet.</td></tr></tbody></table></section>
          <section id=\"duplicate-group-action-controls\" data-action-controls=\"enabled\" data-operation-override=\"forbidden\" data-permission-aware=\"advisory-only\" aria-labelledby=\"duplicate-group-action-controls-title\"><h2 id=\"duplicate-group-action-controls-title\">Action Controls</h2><p id=\"duplicate-group-action-controls-description\">Buttons choose the locked action route. The request body does not include any route operation override.</p><p id=\"duplicate-group-action-permission-state\" data-permission-state=\"unknown\" aria-live=\"polite\" role=\"status\">Permission state pending operator input.</p><form id=\"duplicate-group-action-form\" data-request-allowlist=\"bounded-redacted-action-request\" aria-describedby=\"duplicate-group-action-controls-description duplicate-group-action-permission-state\"><fieldset><legend>Operator action metadata</legend><label>actor_id_hash <input name=\"actor_id_hash\" value=\"sha256:operator-001\" autocomplete=\"off\"></label><label>actor_permissions <input name=\"actor_permissions\" value=\"duplicate_group:confirm,duplicate_group:reject,duplicate_group:mark_review,duplicate_group:clear_review_state\" autocomplete=\"off\"></label><label>roles <input name=\"roles\" value=\"operator\" autocomplete=\"off\"></label><label>request_id_hash <input name=\"request_id_hash\" placeholder=\"sha256:request-hash\" autocomplete=\"off\"></label><label>idempotency_key_hash <input name=\"idempotency_key_hash\" placeholder=\"sha256:idempotency-hash\" autocomplete=\"off\"></label><label>operator_reason_redacted <input name=\"operator_reason_redacted\" value=\"REDACTED_OPERATOR_REASON\" autocomplete=\"off\"></label><label>redaction_status <input name=\"redaction_status\" value=\"passed\" autocomplete=\"off\"></label><label>pre_review_state <input name=\"pre_review_state\" value=\"unknown\" autocomplete=\"off\"></label></fieldset><fieldset><legend>Duplicate group actions</legend><button type=\"button\" data-action-control=\"confirm\" data-required-permission=\"duplicate_group:confirm\" data-action-route=\"#{confirm_api_route}\" data-post-review-state=\"confirmed_by_operator\" aria-describedby=\"duplicate-group-action-permission-state\">Confirm duplicate group</button><button type=\"button\" data-action-control=\"reject\" data-required-permission=\"duplicate_group:reject\" data-action-route=\"#{reject_api_route}\" data-post-review-state=\"rejected_by_operator\" aria-describedby=\"duplicate-group-action-permission-state\">Reject duplicate group</button><button type=\"button\" data-action-control=\"mark-review\" data-required-permission=\"duplicate_group:mark_review\" data-action-route=\"#{mark_review_api_route}\" data-post-review-state=\"needs_review\" aria-describedby=\"duplicate-group-action-permission-state\">Mark needs review</button><button type=\"button\" data-action-control=\"clear-review-state\" data-required-permission=\"duplicate_group:clear_review_state\" data-action-route=\"#{clear_review_state_api_route}\" data-post-review-state=\"cleared\" aria-describedby=\"duplicate-group-action-permission-state\">Clear review state</button></fieldset></form><section id=\"duplicate-group-action-confirmation-modal\" role=\"dialog\" aria-modal=\"true\" aria-labelledby=\"duplicate-group-action-confirmation-title\" aria-describedby=\"duplicate-group-action-confirmation-description\" data-confirmation-state=\"closed\" hidden><h2 id=\"duplicate-group-action-confirmation-title\">Confirm operator action</h2><p id=\"duplicate-group-action-confirmation-description\">This confirmation is bounded and redacted. Route-derived operation remains authoritative.</p><dl><dt>group_id</dt><dd data-confirmation-field=\"group_id\"></dd><dt>action label</dt><dd data-confirmation-field=\"action_label\"></dd><dt>locked route path</dt><dd data-confirmation-field=\"locked_route_path\"></dd><dt>post_review_state</dt><dd data-confirmation-field=\"post_review_state\"></dd><dt>operator_reason_redacted</dt><dd data-confirmation-field=\"operator_reason_redacted\"></dd><dt>idempotency_key_hash</dt><dd data-confirmation-field=\"idempotency_key_hash\"></dd></dl><p data-redaction-warning=\"bounded\">Use only hashed or redacted operator metadata.</p><button type=\"button\" id=\"duplicate-group-action-confirm-submit\" aria-describedby=\"duplicate-group-action-confirmation-description\">Submit confirmed action</button><button type=\"button\" id=\"duplicate-group-action-confirm-cancel\">Cancel</button></section><p id=\"duplicate-group-action-status\" data-action-status=\"ready\" data-state=\"ready\" aria-live=\"polite\" role=\"status\">Ready for an operator action.</p><p id=\"duplicate-group-action-loading-state\" data-state=\"loading\" hidden>Submitting action.</p><p id=\"duplicate-group-action-error-state\" data-state=\"error\" data-error-category=\"unable_to_submit_action\" role=\"alert\" hidden>Unable to submit action.</p><p id=\"duplicate-group-action-success-state\" data-state=\"success\" hidden>Action submitted and detail refreshed.</p><pre id=\"duplicate-group-action-result\" data-action-result=\"bounded\" aria-live=\"polite\"></pre></section>
        </main>
        <script>
          (function () {
            var detailRoute = document.body.getAttribute('data-detail-api-route');
            var status = document.getElementById('duplicate-group-detail-status');
            var actionForm = document.getElementById('duplicate-group-action-form');
            var permissionState = document.getElementById('duplicate-group-action-permission-state');
            var confirmationModal = document.getElementById('duplicate-group-action-confirmation-modal');
            var confirmationSubmit = document.getElementById('duplicate-group-action-confirm-submit');
            var confirmationCancel = document.getElementById('duplicate-group-action-confirm-cancel');
            var actionStatus = document.getElementById('duplicate-group-action-status');
            var actionResult = document.getElementById('duplicate-group-action-result');
            var pendingActionButton = null;
            var actionPending = false;
            var actionPermissionList = ['duplicate_group:confirm', 'duplicate_group:reject', 'duplicate_group:mark_review', 'duplicate_group:clear_review_state'];
            function listValue(name) { var input = actionForm.querySelector('[name=\"' + name + '\"]'); if (!input || !input.value) { return []; } return input.value.split(',').map(function (value) { return value.trim(); }).filter(Boolean); }
            function hasPermission(permission) { return listValue('actor_permissions').indexOf(permission) >= 0; }
            function hasAnyActionPermission() { return actionPermissionList.some(function (permission) { return hasPermission(permission); }); }
            function setPermissionState() { var buttons = Array.prototype.slice.call(actionForm.querySelectorAll('button[data-action-route]')); var enabledCount = 0; buttons.forEach(function (button) { var required = button.getAttribute('data-required-permission'); var allowed = hasPermission(required); if (allowed) { enabledCount += 1; } button.disabled = actionPending || !allowed; button.setAttribute('data-permission-state', allowed ? 'enabled' : 'disabled'); button.setAttribute('data-disabled-reason', allowed ? '' : 'action_permission_missing'); }); if (enabledCount > 0) { permissionState.setAttribute('data-permission-state', 'enabled'); permissionState.textContent = 'Action permissions available. Backend authorization remains authoritative.'; } else if (hasPermission('duplicate_group:read') && !hasAnyActionPermission()) { permissionState.setAttribute('data-permission-state', 'read-only'); permissionState.textContent = 'Read-only permission does not authorize actions.'; } else { permissionState.setAttribute('data-permission-state', 'disabled'); permissionState.textContent = 'Action permission missing.'; } }
            function ensureHash(name, prefix) { var input = actionForm.querySelector('[name=\"' + name + '\"]'); if (input && !input.value) { input.value = 'sha256:' + prefix + '-' + String(Date.now()); } return input ? input.value : 'sha256:' + prefix + '-' + String(Date.now()); }
            function value(name, fallback) { var input = actionForm.querySelector('[name=\"' + name + '\"]'); return input && input.value ? input.value : fallback; }
            function actionPayload(button) { return { actor_id_hash: value('actor_id_hash', 'sha256:operator-001'), actor_permissions: listValue('actor_permissions'), roles: listValue('roles'), request_id_hash: ensureHash('request_id_hash', 'request'), idempotency_key_hash: ensureHash('idempotency_key_hash', 'idempotency'), operator_reason_redacted: value('operator_reason_redacted', 'REDACTED_OPERATOR_REASON'), result_status: 'completed', redaction_status: value('redaction_status', 'passed'), pre_review_state: value('pre_review_state', 'unknown'), post_review_state: button.getAttribute('data-post-review-state') }; }
            function boundedActionResult(result) { return { action_operation: result.action_operation, required_permission: result.required_permission, actor_id_hash: result.actor_id_hash, request_id_hash: result.request_id_hash, idempotency_key_hash: result.idempotency_key_hash, result_status: result.result_status, redaction_status: result.redaction_status, pre_review_state: result.pre_review_state, post_review_state: result.post_review_state, review_state: result.review_state, action_event_inserted: result.action_event_inserted }; }
            function loadDetail() { status.textContent = 'Loading duplicate group detail.'; return fetch(detailRoute, { headers: { 'accept': 'application/json' } }).then(function (response) { if (!response.ok) { throw new Error('unable_to_load_duplicate_group_detail'); } return response.json(); }).then(function () { status.textContent = 'Loaded duplicate group detail.'; }).catch(function () { status.textContent = 'Unable to load duplicate group detail.'; }); }
            function setField(key, value) { var element = document.querySelector('[data-confirmation-field=\"' + key + '\"]'); if (element) { element.textContent = value || ''; } }
            function openConfirmation(button) { if (actionPending || !hasPermission(button.getAttribute('data-required-permission'))) { actionStatus.textContent = 'Action permission missing.'; setPermissionState(); return; } pendingActionButton = button; ensureHash('request_id_hash', 'request'); ensureHash('idempotency_key_hash', 'idempotency'); setField('group_id', document.body.getAttribute('data-group-id')); setField('action_label', button.textContent); setField('locked_route_path', button.getAttribute('data-action-route')); setField('post_review_state', button.getAttribute('data-post-review-state')); setField('operator_reason_redacted', value('operator_reason_redacted', 'REDACTED_OPERATOR_REASON')); setField('idempotency_key_hash', value('idempotency_key_hash', '')); confirmationModal.hidden = false; confirmationModal.setAttribute('data-confirmation-state', 'open'); actionStatus.textContent = 'Confirm operator action before submitting.'; }
            function closeConfirmation() { pendingActionButton = null; confirmationModal.hidden = true; confirmationModal.setAttribute('data-confirmation-state', 'closed'); if (!actionPending) { actionStatus.textContent = 'Ready for an operator action.'; } }
            function setPending(pending) { actionPending = pending; setPermissionState(); confirmationSubmit.disabled = pending; }
            function submitAction(button) { setPending(true); confirmationModal.setAttribute('data-confirmation-state', 'submitting'); actionStatus.textContent = 'Submitting action.'; return fetch(button.getAttribute('data-action-route'), { method: 'POST', headers: { 'accept': 'application/json', 'content-type': 'application/json' }, body: JSON.stringify(actionPayload(button)) }).then(function (response) { if (!response.ok) { throw new Error('unable_to_submit_action'); } return response.json(); }).then(function (result) { actionResult.textContent = JSON.stringify(boundedActionResult(result), null, 2); confirmationModal.hidden = true; confirmationModal.setAttribute('data-confirmation-state', 'closed'); actionStatus.textContent = 'Action submitted. Refreshing detail.'; return loadDetail(); }).then(function () { actionStatus.textContent = 'Action submitted and detail refreshed.'; }).catch(function () { actionStatus.textContent = 'Unable to submit action.'; }).finally(function () { pendingActionButton = null; setPending(false); }); }
            Array.prototype.forEach.call(actionForm.querySelectorAll('button[data-action-route]'), function (button) { button.addEventListener('click', function () { openConfirmation(button); }); });
            var permissionsInput = actionForm.querySelector('[name=\"actor_permissions\"]'); if (permissionsInput) { permissionsInput.addEventListener('input', setPermissionState); }
            confirmationSubmit.addEventListener('click', function () { if (pendingActionButton && !actionPending) { submitAction(pendingActionButton); } });
            confirmationCancel.addEventListener('click', function () { closeConfirmation(); });
            setPermissionState(); loadDetail();
          }());
        </script>
      </body>
    </html>
    """
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
