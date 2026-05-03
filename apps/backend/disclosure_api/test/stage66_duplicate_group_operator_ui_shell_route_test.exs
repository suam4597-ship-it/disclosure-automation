defmodule DisclosureAutomation.Stage66DuplicateGroupOperatorUiShellRouteTest do
  use DisclosureAutomationWeb.ConnCase, async: false

  import Ecto.Query

  alias DisclosureAutomation.Repo
  alias DisclosureAutomation.Schema.SourceDuplicateGroup
  alias DisclosureAutomation.Schema.SourceDuplicateGroupActionEvent
  alias DisclosureAutomation.Schema.SourceDuplicateGroupMember
  alias DisclosureAutomation.Schema.SourceDuplicateGroupReviewState

  @group_id "duplicate_group:jp.tdnet.4527.20260430.material_information_update"

  test "GET /admin/duplicate-groups returns the Stage 6.7 operator list screen states", %{conn: conn} do
    conn = get(conn, "/admin/duplicate-groups")
    body = html_response(conn, 200)

    assert get_resp_header(conn, "content-type") == ["text/html; charset=utf-8"]
    assert body =~ "Duplicate Groups"
    assert body =~ "operator-only, advisory-only, non-canonical, bounded, and redacted"
    assert body =~ "id=\"duplicate-group-operator-list-screen\""
    assert body =~ "id=\"duplicate-group-list-filters\""
    assert body =~ "data-filter-scope=\"bounded-list-filters\""
    assert body =~ "data-list-api-route=\"/api/admin/duplicate-groups\""
    assert body =~ "data-detail-route-template=\"/admin/duplicate-groups/:group_id\""
    assert body =~ "data-excludes=\"action_event_summary\""
    assert body =~ "Loading duplicate groups."
    assert body =~ "No duplicate groups found."
    assert body =~ "Unable to load duplicate groups."
    refute body =~ "/api/admin/duplicate-groups/:group_id/confirm"
    refute body =~ "/api/admin/duplicate-groups/:group_id/reject"
    refute body =~ "/api/admin/duplicate-groups/:group_id/mark-review"
    refute body =~ "/api/admin/duplicate-groups/:group_id/clear-review-state"
    refute body =~ "provider_payload"
    refute body =~ "canonical_payload"
    refute body =~ "full_article_text"
    refute body =~ "stack trace"
  end

  test "GET /admin/duplicate-groups/:group_id returns accessible permission-aware action controls and preserves action flow", %{conn: conn} do
    assert group_count(@group_id) == 0
    assert member_count(@group_id) == 0
    assert action_event_count(@group_id) == 0
    assert review_state_count(@group_id) == 0

    conn = get(conn, "/admin/duplicate-groups/#{@group_id}")
    body = html_response(conn, 200)

    assert body =~ "Skip to action controls"
    assert body =~ "href=\"#duplicate-group-action-controls\""
    assert body =~ "aria-labelledby=\"duplicate-group-detail-title\""
    assert body =~ "id=\"duplicate-group-detail-title\""
    assert body =~ "aria-label=\"Duplicate group operator navigation\""
    assert body =~ "role=\"status\""
    assert body =~ "role=\"alert\""
    assert body =~ "aria-labelledby=\"duplicate-group-action-controls-title\""
    assert body =~ "id=\"duplicate-group-action-controls-title\""
    assert body =~ "aria-describedby=\"duplicate-group-action-controls-description duplicate-group-action-permission-state\""
    assert body =~ "<fieldset><legend>Operator action metadata</legend>"
    assert body =~ "<fieldset><legend>Duplicate group actions</legend>"
    assert body =~ "<caption>Duplicate group members</caption>"
    assert body =~ "<caption>Latest duplicate group operator actions</caption>"
    assert body =~ "aria-describedby=\"duplicate-group-action-confirmation-description\""
    assert body =~ "id=\"duplicate-group-action-confirmation-description\""
    assert body =~ "aria-describedby=\"duplicate-group-action-permission-state\""
    assert body =~ "data-action-result=\"bounded\" aria-live=\"polite\""

    assert body =~ "Duplicate Group Detail"
    assert body =~ "id=\"duplicate-group-operator-detail-screen\""
    assert body =~ "data-group-id=\"#{@group_id}\""
    assert body =~ "data-detail-api-route=\"/api/admin/duplicate-groups/duplicate_group%3Ajp.tdnet.4527.20260430.material_information_update\""
    assert body =~ "Permission-aware button state is advisory only; backend authorization remains authoritative."
    assert body =~ "data-permission-aware=\"advisory-only\""
    assert body =~ "id=\"duplicate-group-action-permission-state\""
    assert body =~ "data-permission-state=\"unknown\""
    assert body =~ "Permission state pending operator input."
    assert body =~ "Read-only permission does not authorize actions."
    assert body =~ "Action permission missing."
    assert body =~ "Action permissions available. Backend authorization remains authoritative."
    assert body =~ "actionPermissionList = ['duplicate_group:confirm', 'duplicate_group:reject', 'duplicate_group:mark_review', 'duplicate_group:clear_review_state']"
    assert body =~ "data-required-permission=\"duplicate_group:confirm\""
    assert body =~ "data-required-permission=\"duplicate_group:reject\""
    assert body =~ "data-required-permission=\"duplicate_group:mark_review\""
    assert body =~ "data-required-permission=\"duplicate_group:clear_review_state\""
    assert body =~ "data-disabled-reason"
    assert body =~ "action_permission_missing"
    assert body =~ "button.disabled = actionPending || !allowed"
    assert body =~ "permissionsInput.addEventListener('input', setPermissionState)"
    assert body =~ "setPermissionState();"

    assert body =~ "id=\"duplicate-group-action-confirmation-modal\""
    assert body =~ "data-confirmation-state=\"closed\""
    assert body =~ "Confirm operator action"
    assert body =~ "id=\"duplicate-group-action-confirm-submit\""
    assert body =~ "id=\"duplicate-group-action-confirm-cancel\""
    assert body =~ "data-operation-override=\"forbidden\""
    assert body =~ "data-action-control=\"confirm\""
    assert body =~ "data-action-control=\"reject\""
    assert body =~ "data-action-control=\"mark-review\""
    assert body =~ "data-action-control=\"clear-review-state\""
    assert body =~ "/api/admin/duplicate-groups/duplicate_group%3Ajp.tdnet.4527.20260430.material_information_update/confirm"
    assert body =~ "/api/admin/duplicate-groups/duplicate_group%3Ajp.tdnet.4527.20260430.material_information_update/reject"
    assert body =~ "/api/admin/duplicate-groups/duplicate_group%3Ajp.tdnet.4527.20260430.material_information_update/mark-review"
    assert body =~ "/api/admin/duplicate-groups/duplicate_group%3Ajp.tdnet.4527.20260430.material_information_update/clear-review-state"

    assert body =~ "function loadDetail()"
    assert body =~ "fetch(detailRoute, { headers: { 'accept': 'application/json' } })"
    assert body =~ "function openConfirmation(button)"
    assert body =~ "pendingActionButton = button"
    assert body =~ "confirmationModal.setAttribute('data-confirmation-state', 'open')"
    assert body =~ "function submitAction(button)"
    assert body =~ "fetch(button.getAttribute('data-action-route'), { method: 'POST'"
    assert body =~ "body: JSON.stringify(actionPayload(button))"
    assert body =~ "return loadDetail();"
    assert body =~ "boundedActionResult(result)"
    assert body =~ "confirmationSubmit.addEventListener('click'"
    assert body =~ "confirmationCancel.addEventListener('click'"

    refute body =~ "name=\"action_operation\""
    refute body =~ "action_operation: stringValue"
    refute body =~ "raw_actor_id"
    refute body =~ "raw_request_id"
    refute body =~ "raw_idempotency_key"
    refute body =~ "provider_payload"
    refute body =~ "canonical_payload"
    refute body =~ "full_article_text"
    refute body =~ "stack trace"

    assert group_count(@group_id) == 0
    assert member_count(@group_id) == 0
    assert action_event_count(@group_id) == 0
    assert review_state_count(@group_id) == 0
  end

  test "shell routes do not replace the locked JSON duplicate group read route", %{conn: conn} do
    response =
      conn
      |> get("/api/admin/duplicate-groups?limit=10")
      |> json_response(200)

    assert response["mode"] == "stage59_internal_duplicate_group_list_projection"
    assert response["route_added"] == true
    assert response["ui_added"] == false
    assert response["action_endpoint_added"] == false
    assert response["materializer_triggered"] == false
    assert response["public_response_shape_mutation"] == false
    assert response["public_api_duplicate_group_fields"] == false
    assert response["public_feed_duplicate_group_fields"] == false
    assert response["canonical_feed_mutation"] == false
    assert response["trigger_live_fetch"] == false
    assert response["scheduler_enabled"] == false
    assert response["network_access"] == "forbidden"
  end

  test "shell routes are outside the API namespace", %{conn: conn} do
    conn = get(conn, "/api/admin/duplicate-groups")

    assert get_resp_header(conn, "content-type") == ["application/json; charset=utf-8"]
    assert json_response(conn, 200)["mode"] == "stage59_internal_duplicate_group_list_projection"
  end

  defp group_count(group_id) do
    SourceDuplicateGroup
    |> where([group], group.group_id == ^group_id)
    |> Repo.aggregate(:count)
  end

  defp member_count(group_id) do
    SourceDuplicateGroupMember
    |> where([member], member.group_id == ^group_id)
    |> Repo.aggregate(:count)
  end

  defp action_event_count(group_id) do
    SourceDuplicateGroupActionEvent
    |> where([event], event.group_id == ^group_id)
    |> Repo.aggregate(:count)
  end

  defp review_state_count(group_id) do
    SourceDuplicateGroupReviewState
    |> where([state], state.group_id == ^group_id)
    |> Repo.aggregate(:count)
  end
end
