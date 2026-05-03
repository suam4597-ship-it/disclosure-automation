defmodule DisclosureAutomation.Stage66DuplicateGroupOperatorUiShellRouteTest do
  use DisclosureAutomationWeb.ConnCase, async: false

  import Ecto.Query

  alias DisclosureAutomation.Repo
  alias DisclosureAutomation.Schema.SourceDuplicateGroup
  alias DisclosureAutomation.Schema.SourceDuplicateGroupActionEvent
  alias DisclosureAutomation.Schema.SourceDuplicateGroupMember
  alias DisclosureAutomation.Schema.SourceDuplicateGroupReviewState

  @group_id "duplicate_group:jp.tdnet.4527.20260430.material_information_update"

  test "GET /admin/duplicate-groups returns the Stage 6.6 operator UI shell", %{conn: conn} do
    conn = get(conn, "/admin/duplicate-groups")
    body = html_response(conn, 200)

    assert get_resp_header(conn, "content-type") == ["text/html; charset=utf-8"]
    assert body =~ "Duplicate Group Operator UI"
    assert body =~ "operator-only duplicate group review"
    assert body =~ "advisory-only, non-canonical, bounded, and redacted"
    assert body =~ "data-shell-status=\"stage66-shell-only\""
    assert body =~ "/api/admin/duplicate-groups"
    assert body =~ "/api/admin/duplicate-groups/:group_id"
    assert body =~ "/api/admin/duplicate-groups/:group_id/confirm"
    assert body =~ "/api/admin/duplicate-groups/:group_id/reject"
    assert body =~ "/api/admin/duplicate-groups/:group_id/mark-review"
    assert body =~ "/api/admin/duplicate-groups/:group_id/clear-review-state"
    refute body =~ "action_operation"
    refute body =~ "provider_payload"
    refute body =~ "canonical_payload"
    refute body =~ "full_article_text"
  end

  test "GET /admin/duplicate-groups/:group_id returns a detail shell without reading or writing duplicate group state", %{conn: conn} do
    assert group_count(@group_id) == 0
    assert member_count(@group_id) == 0
    assert action_event_count(@group_id) == 0
    assert review_state_count(@group_id) == 0

    conn = get(conn, "/admin/duplicate-groups/#{@group_id}")
    body = html_response(conn, 200)

    assert body =~ "data-group-id=\"#{@group_id}\""
    assert body =~ "/api/admin/duplicate-groups/duplicate_group%3Ajp.tdnet.4527.20260430.material_information_update"
    assert body =~ "/api/admin/duplicate-groups/duplicate_group%3Ajp.tdnet.4527.20260430.material_information_update/confirm"
    assert body =~ "/api/admin/duplicate-groups/duplicate_group%3Ajp.tdnet.4527.20260430.material_information_update/reject"
    assert body =~ "/api/admin/duplicate-groups/duplicate_group%3Ajp.tdnet.4527.20260430.material_information_update/mark-review"
    assert body =~ "/api/admin/duplicate-groups/duplicate_group%3Ajp.tdnet.4527.20260430.material_information_update/clear-review-state"

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
