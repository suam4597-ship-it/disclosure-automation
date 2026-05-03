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
    group_id_attribute = " data-group-id=\"#{escape_html(group_id)}\""
    detail_api_route = route_for(@detail_api_route_template, group_id)
    confirm_api_route = route_for(@confirm_api_route_template, group_id)
    reject_api_route = route_for(@reject_api_route_template, group_id)
    mark_review_api_route = route_for(@mark_review_api_route_template, group_id)
    clear_review_state_api_route = route_for(@clear_review_state_api_route_template, group_id)

    """
    <!doctype html>
    <html lang=\"en\">
      <head><meta charset=\"utf-8\"><meta name=\"viewport\" content=\"width=device-width, initial-scale=1\"><title>Duplicate Group Detail</title></head>
      <body data-view-scope=\"operator_only_duplicate_group_review\"#{group_id_attribute} data-detail-api-route=\"#{detail_api_route}\">
        <main id=\"duplicate-group-operator-detail-screen\">
          <p><a href=\"/admin/duplicate-groups\">Back to duplicate groups</a></p>
          <h1>Duplicate Group Detail</h1>
          <p>This internal detail screen is operator-only, advisory-only, non-canonical, bounded, and redacted.</p>
          <section id=\"duplicate-group-detail-guardrails\"><h2>Guardrails</h2><ul><li>Detail data is loaded only from the locked internal JSON API.</li><li>Action event summary rendering is bounded to the locked show response.</li><li>Action buttons map to locked action routes and do not submit override fields.</li><li>Permission-aware button state is advisory only; backend authorization remains authoritative.</li></ul></section>
          <p id=\"duplicate-group-detail-status\" data-detail-status=\"ready\" data-state=\"ready\" aria-live=\"polite\">Ready to load duplicate group detail.</p>
          <p id=\"duplicate-group-detail-loading-state\" data-state=\"loading\" hidden>Loading duplicate group detail.</p>
          <p id=\"duplicate-group-detail-error-state\" data-state=\"error\" data-error-category=\"unable_to_load_duplicate_group_detail\" hidden>Unable to load duplicate group detail.</p>
          <section id=\"duplicate-group-summary\"><h2>Group</h2><dl><dt>group_id</dt><dd data-detail-field=\"group_id\"></dd><dt>confidence</dt><dd data-detail-field=\"confidence\"></dd><dt>source_keys</dt><dd data-detail-field=\"source_keys\"></dd><dt>match_reasons</dt><dd data-detail-field=\"match_reasons\"></dd><dt>member_count</dt><dd data-detail-field=\"member_count\"></dd><dt>redaction_status</dt><dd data-detail-field=\"redaction_status\"></dd></dl></section>
          <section id=\"duplicate-group-review-state\"><h2>Review State</h2><p id=\"duplicate-group-review-state-empty\" data-state=\"empty\" hidden>No review state recorded yet.</p><dl><dt>review_state_summary.review_state</dt><dd data-review-state-field=\"review_state\"></dd><dt>review_state_summary.last_action_operation</dt><dd data-review-state-field=\"last_action_operation\"></dd><dt>review_state_summary.reviewed_at</dt><dd data-review-state-field=\"reviewed_at\"></dd><dt>review_state_summary.reviewed_by_actor_id_hash</dt><dd data-review-state-field=\"reviewed_by_actor_id_hash\"></dd><dt>review_state_summary.redaction_status</dt><dd data-review-state-field=\"redaction_status\"></dd></dl></section>
          <section id=\"duplicate-group-members\"><h2>Members</h2><p id=\"duplicate-group-members-empty\" data-state=\"empty\" hidden>No members found.</p><table><tbody id=\"duplicate-group-member-rows\"><tr><td>No members loaded yet.</td></tr></tbody></table></section>
          <section id=\"duplicate-group-action-event-summary\" data-summary-limit=\"latest-five-from-show-response\"><h2>Latest Actions</h2><p id=\"duplicate-group-action-event-empty\" data-state=\"empty\" hidden>No latest actions found.</p><table><tbody id=\"duplicate-group-action-event-rows\" data-summary-source=\"show-response-only\"><tr><td>No latest actions loaded yet.</td></tr></tbody></table></section>
          <section id=\"duplicate-group-action-controls\" data-action-controls=\"enabled\" data-operation-override=\"forbidden\" data-permission-aware=\"advisory-only\">
            <h2>Action Controls</h2>
            <p>Buttons choose the locked action route. The request body does not include any route operation override.</p>
            <p id=\"duplicate-group-action-permission-state\" data-permission-state=\"unknown\" aria-live=\"polite\">Permission state pending operator input.</p>
            <form id=\"duplicate-group-action-form\" data-request-allowlist=\"bounded-redacted-action-request\">
              <label>actor_id_hash <input name=\"actor_id_hash\" value=\"sha256:operator-001\" autocomplete=\"off\"></label>
              <label>actor_permissions <input name=\"actor_permissions\" value=\"duplicate_group:confirm,duplicate_group:reject,duplicate_group:mark_review,duplicate_group:clear_review_state\" autocomplete=\"off\"></label>
              <label>roles <input name=\"roles\" value=\"operator\" autocomplete=\"off\"></label>
              <label>request_id_hash <input name=\"request_id_hash\" placeholder=\"sha256:request-hash\" autocomplete=\"off\"></label>
              <label>idempotency_key_hash <input name=\"idempotency_key_hash\" placeholder=\"sha256:idempotency-hash\" autocomplete=\"off\"></label>
              <label>operator_reason_redacted <input name=\"operator_reason_redacted\" value=\"REDACTED_OPERATOR_REASON\" autocomplete=\"off\"></label>
              <label>redaction_status <input name=\"redaction_status\" value=\"passed\" autocomplete=\"off\"></label>
              <label>pre_review_state <input name=\"pre_review_state\" value=\"unknown\" autocomplete=\"off\"></label>
              <button type=\"button\" data-action-control=\"confirm\" data-required-permission=\"duplicate_group:confirm\" data-action-route=\"#{confirm_api_route}\" data-post-review-state=\"confirmed_by_operator\">Confirm duplicate group</button>
              <button type=\"button\" data-action-control=\"reject\" data-required-permission=\"duplicate_group:reject\" data-action-route=\"#{reject_api_route}\" data-post-review-state=\"rejected_by_operator\">Reject duplicate group</button>
              <button type=\"button\" data-action-control=\"mark-review\" data-required-permission=\"duplicate_group:mark_review\" data-action-route=\"#{mark_review_api_route}\" data-post-review-state=\"needs_review\">Mark needs review</button>
              <button type=\"button\" data-action-control=\"clear-review-state\" data-required-permission=\"duplicate_group:clear_review_state\" data-action-route=\"#{clear_review_state_api_route}\" data-post-review-state=\"cleared\">Clear review state</button>
            </form>
            <section id=\"duplicate-group-action-confirmation-modal\" role=\"dialog\" aria-modal=\"true\" aria-labelledby=\"duplicate-group-action-confirmation-title\" data-confirmation-state=\"closed\" hidden><h2 id=\"duplicate-group-action-confirmation-title\">Confirm operator action</h2><p>This confirmation is bounded and redacted. Route-derived operation remains authoritative.</p><dl><dt>group_id</dt><dd data-confirmation-field=\"group_id\"></dd><dt>action label</dt><dd data-confirmation-field=\"action_label\"></dd><dt>locked route path</dt><dd data-confirmation-field=\"locked_route_path\"></dd><dt>post_review_state</dt><dd data-confirmation-field=\"post_review_state\"></dd><dt>operator_reason_redacted</dt><dd data-confirmation-field=\"operator_reason_redacted\"></dd><dt>idempotency_key_hash</dt><dd data-confirmation-field=\"idempotency_key_hash\"></dd></dl><p data-redaction-warning=\"bounded\">Use only hashed or redacted operator metadata. Do not paste raw identifiers or unredacted reasons.</p><button type=\"button\" id=\"duplicate-group-action-confirm-submit\">Submit confirmed action</button><button type=\"button\" id=\"duplicate-group-action-confirm-cancel\">Cancel</button></section>
            <p id=\"duplicate-group-action-status\" data-action-status=\"ready\" data-state=\"ready\" aria-live=\"polite\">Ready for an operator action.</p>
            <p id=\"duplicate-group-action-loading-state\" data-state=\"loading\" hidden>Submitting action.</p><p id=\"duplicate-group-action-error-state\" data-state=\"error\" data-error-category=\"unable_to_submit_action\" hidden>Unable to submit action.</p><p id=\"duplicate-group-action-success-state\" data-state=\"success\" hidden>Action submitted and detail refreshed.</p><pre id=\"duplicate-group-action-result\" data-action-result=\"bounded\"></pre>
          </section>
        </main>
        <script>(function () { var actionForm = document.getElementById('duplicate-group-action-form'); var permissionState = document.getElementById('duplicate-group-action-permission-state'); var confirmationSubmit = document.getElementById('duplicate-group-action-confirm-submit'); var actionPending = false; var actionPermissionList = ['duplicate_group:confirm', 'duplicate_group:reject', 'duplicate_group:mark_review', 'duplicate_group:clear_review_state']; function listValue(name) { var input = actionForm.querySelector('[name=\"' + name + '\"]'); if (!input || !input.value) { return []; } return input.value.split(',').map(function (value) { return value.trim(); }).filter(Boolean); } function hasPermission(permission) { return listValue('actor_permissions').indexOf(permission) >= 0; } function hasAnyActionPermission() { return actionPermissionList.some(function (permission) { return hasPermission(permission); }); } function updatePermissionButtonStates() { var buttons = Array.prototype.slice.call(actionForm.querySelectorAll('button[data-action-route]')); var enabledCount = 0; buttons.forEach(function (button) { var required = button.getAttribute('data-required-permission'); var allowed = hasPermission(required); if (allowed) { enabledCount += 1; } button.disabled = actionPending || !allowed; button.setAttribute('data-permission-state', allowed ? 'enabled' : 'disabled'); button.setAttribute('data-disabled-reason', allowed ? '' : 'action_permission_missing'); button.title = allowed ? '' : 'Action permission missing: ' + required; }); if (enabledCount > 0) { permissionState.setAttribute('data-permission-state', 'enabled'); permissionState.textContent = 'Action permissions available. Backend authorization remains authoritative.'; } else if (hasPermission('duplicate_group:read') && !hasAnyActionPermission()) { permissionState.setAttribute('data-permission-state', 'read-only'); permissionState.textContent = 'Read-only permission does not authorize actions.'; } else { permissionState.setAttribute('data-permission-state', 'disabled'); permissionState.textContent = 'Action permission missing.'; } } function setPending(pending) { actionPending = pending; updatePermissionButtonStates(); confirmationSubmit.disabled = pending; } Array.prototype.forEach.call(actionForm.querySelectorAll('button[data-action-route]'), function (button) { button.addEventListener('click', function () { if (!hasPermission(button.getAttribute('data-required-permission'))) { updatePermissionButtonStates(); } }); }); var permissionsInput = actionForm.querySelector('[name=\"actor_permissions\"]'); if (permissionsInput) { permissionsInput.addEventListener('input', updatePermissionButtonStates); } setPending(false); }());</script>
      </body>
    </html>
    """
  end

  defp route_for(template, group_id), do: String.replace(template, ":group_id", URI.encode_www_form(to_string(group_id)))

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
