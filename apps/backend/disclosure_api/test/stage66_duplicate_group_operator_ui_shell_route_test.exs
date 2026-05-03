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
    assert body =~ "name=\"confidence\""
    assert body =~ "name=\"source_key\""
    assert body =~ "name=\"member_kind\""
    assert body =~ "name=\"redaction_status\""
    assert body =~ "name=\"limit\""
    assert body =~ "id=\"duplicate-group-list-table\""
    assert body =~ "group_id"
    assert body =~ "confidence"
    assert body =~ "review_state_summary.review_state"
    assert body =~ "review_state_summary.last_action_operation"
    assert body =~ "review_state_summary.reviewed_at"
    assert body =~ "member_count"
    assert body =~ "source_keys"
    assert body =~ "redaction_status"
    assert body =~ "data-list-api-route=\"/api/admin/duplicate-groups\""
    assert body =~ "data-detail-route-template=\"/admin/duplicate-groups/:group_id\""
    assert body =~ "data-excludes=\"action_event_summary\""
    assert body =~ "id=\"duplicate-group-list-loading-state\""
    assert body =~ "Loading duplicate groups."
    assert body =~ "id=\"duplicate-group-list-empty-state\""
    assert body =~ "No duplicate groups found."
    assert body =~ "id=\"duplicate-group-list-error-state\""
    assert body =~ "data-error-category=\"unable_to_load_duplicate_groups\""
    assert body =~ "Unable to load duplicate groups."
    assert body =~ "setListState('loading', 'Loading duplicate groups.')"
    assert body =~ "setListState('loaded', 'Loaded '"
    assert body =~ "setListState('empty', 'No duplicate groups found.')"
    assert body =~ "setListState('error', 'Unable to load duplicate groups.')"
    assert body =~ "fetch(buildUrl(), { headers: { 'accept': 'application/json' } })"
    refute body =~ "/api/admin/duplicate-groups/:group_id/confirm"
    refute body =~ "/api/admin/duplicate-groups/:group_id/reject"
    refute body =~ "/api/admin/duplicate-groups/:group_id/mark-review"
    refute body =~ "/api/admin/duplicate-groups/:group_id/clear-review-state"
    refute body =~ "provider_payload"
    refute body =~ "canonical_payload"
    refute body =~ "full_article_text"
    refute body =~ "stack trace"
  end

  test "GET /admin/duplicate-groups/:group_id returns a detail screen with bounded states and action controls", %{conn: conn} do
    assert group_count(@group_id) == 0
    assert member_count(@group_id) == 0
    assert action_event_count(@group_id) == 0
    assert review_state_count(@group_id) == 0

    conn = get(conn, "/admin/duplicate-groups/#{@group_id}")
    body = html_response(conn, 200)

    assert body =~ "Duplicate Group Detail"
    assert body =~ "id=\"duplicate-group-operator-detail-screen\""
    assert body =~ "data-group-id=\"#{@group_id}\""
    assert body =~ "data-detail-api-route=\"/api/admin/duplicate-groups/duplicate_group%3Ajp.tdnet.4527.20260430.material_information_update\""
    assert body =~ "Detail data is loaded only from the locked internal JSON API."
    assert body =~ "id=\"duplicate-group-summary\""
    assert body =~ "id=\"duplicate-group-review-state\""
    assert body =~ "id=\"duplicate-group-review-state-empty\""
    assert body =~ "No review state recorded yet."
    assert body =~ "id=\"duplicate-group-members\""
    assert body =~ "id=\"duplicate-group-members-empty\""
    assert body =~ "No members found."
    assert body =~ "id=\"duplicate-group-action-event-summary\""
    assert body =~ "id=\"duplicate-group-action-event-empty\""
    assert body =~ "No latest actions found."
    assert body =~ "data-summary-limit=\"latest-five-from-show-response\""
    assert body =~ "data-summary-source=\"show-response-only\""
    assert body =~ "id=\"duplicate-group-action-controls\""
    assert body =~ "data-action-controls=\"enabled\""
    assert body =~ "data-operation-override=\"forbidden\""
    assert body =~ "id=\"duplicate-group-detail-loading-state\""
    assert body =~ "Loading duplicate group detail."
    assert body =~ "id=\"duplicate-group-detail-error-state\""
    assert body =~ "data-error-category=\"unable_to_load_duplicate_group_detail\""
    assert body =~ "Unable to load duplicate group detail."
    assert body =~ "id=\"duplicate-group-action-loading-state\""
    assert body =~ "Submitting action."
    assert body =~ "id=\"duplicate-group-action-error-state\""
    assert body =~ "data-error-category=\"unable_to_submit_action\""
    assert body =~ "Unable to submit action."
    assert body =~ "id=\"duplicate-group-action-success-state\""
    assert body =~ "Action submitted and detail refreshed."
    assert body =~ "fetch(detailRoute, { headers: { 'accept': 'application/json' } })"
    assert body =~ "item.action_event_summary || []"
    assert body =~ "review_state_summary.review_state"
    assert body =~ "review_state_summary.last_action_operation"
    assert body =~ "review_state_summary.reviewed_at"
    assert body =~ "review_state_summary.reviewed_by_actor_id_hash"
    assert body =~ "member_id"
    assert body =~ "member_kind"
    assert body =~ "external_id_hash"
    assert body =~ "action_operation"
    assert body =~ "required_permission"
    assert body =~ "actor_id_hash"
    assert body =~ "request_id_hash"
    assert body =~ "idempotency_key_hash"
    assert body =~ "operator_reason_redacted"
    assert body =~ "result_status"
    assert body =~ "pre_review_state"
    assert body =~ "post_review_state"
    assert body =~ "failure_code"
    assert body =~ "inserted_at"

    assert body =~ "data-action-control=\"confirm\""
    assert body =~ "data-action-control=\"reject\""
    assert body =~ "data-action-control=\"mark-review\""
    assert body =~ "data-action-control=\"clear-review-state\""
    assert body =~ "Confirm duplicate group"
    assert body =~ "Reject duplicate group"
    assert body =~ "Mark needs review"
    assert body =~ "Clear review state"
    assert body =~ "/api/admin/duplicate-groups/duplicate_group%3Ajp.tdnet.4527.20260430.material_information_update/confirm"
    assert body =~ "/api/admin/duplicate-groups/duplicate_group%3Ajp.tdnet.4527.20260430.material_information_update/reject"
    assert body =~ "/api/admin/duplicate-groups/duplicate_group%3Ajp.tdnet.4527.20260430.material_information_update/mark-review"
    assert body =~ "/api/admin/duplicate-groups/duplicate_group%3Ajp.tdnet.4527.20260430.material_information_update/clear-review-state"
    assert body =~ "fetch(button.getAttribute('data-action-route'),"
    assert body =~ "body: JSON.stringify(actionPayload(button))"
    assert body =~ "return loadDetail();"
    assert body =~ "setPending(true)"
    assert body =~ "setPending(false)"
    assert body =~ "boundedActionResult(result)"
    assert body =~ "setActionState('loading', 'Submitting action.')"
    assert body =~ "setActionState('refreshing', 'Action submitted. Refreshing detail.')"
    assert body =~ "setActionState('success', 'Action submitted and detail refreshed.')"
    assert body =~ "setActionState('error', 'Unable to submit action.')"

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
