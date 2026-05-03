defmodule DisclosureAutomation.Stage62DuplicateGroupActionRouteTest do
  use DisclosureAutomationWeb.ConnCase, async: false

  import Ecto.Query

  alias DisclosureAutomation.Repo
  alias DisclosureAutomation.Schema.SourceDuplicateGroupActionEvent
  alias DisclosureAutomation.Schema.SourceDuplicateGroupReviewState

  @group_id "duplicate_group:jp.tdnet.4527.20260430.material_information_update"

  @valid_payload %{
    "actor_id_hash" => "sha256:operator-001",
    "actor_permissions" => ["duplicate_group:confirm"],
    "roles" => ["operator"],
    "request_id_hash" => "sha256:request-001",
    "idempotency_key_hash" => "sha256:idempotency-001",
    "operator_reason_redacted" => "REDACTED_OPERATOR_CONFIRMED_DUPLICATE_GROUP",
    "result_status" => "completed",
    "redaction_status" => "passed",
    "pre_review_state" => "unknown",
    "post_review_state" => "confirmed_by_operator",
    "created_at" => "2026-05-03T08:10:00Z"
  }

  test "POST /api/admin/duplicate-groups/:group_id/confirm records bounded action state", %{conn: conn} do
    response =
      conn
      |> post("/api/admin/duplicate-groups/#{@group_id}/confirm", @valid_payload)
      |> json_response(200)

    assert response["mode"] == "stage61_duplicate_group_action_state_recorded"
    assert response["group_id"] == @group_id
    assert response["action_operation"] == "confirm_duplicate_group"
    assert response["required_permission"] == "duplicate_group:confirm"
    assert response["actor_id_hash"] == "sha256:operator-001"
    assert response["request_id_hash"] == "sha256:request-001"
    assert response["idempotency_key_hash"] == "sha256:idempotency-001"
    assert response["result_status"] == "completed"
    assert response["redaction_status"] == "passed"
    assert response["pre_review_state"] == "unknown"
    assert response["post_review_state"] == "confirmed_by_operator"
    assert response["action_event_inserted"] == true
    assert response["review_state"] == "confirmed_by_operator"
    assert response["authorized"] == true
    assert response["authorization_result"] == "allowed_noop_preview"
    assert response["public_response_shape_mutation"] == false
    assert response["public_api_duplicate_group_fields"] == false
    assert response["public_feed_duplicate_group_fields"] == false
    assert response["canonical_feed_mutation"] == false
    assert response["provider_canonical_feed_item_creation"] == false
    assert response["news_only_event_creation"] == false
    assert response["official_event_merge"] == false
    assert response["official_fact_override"] == false
    assert response["official_citation_override"] == false
    assert response["trigger_live_fetch"] == false
    assert response["scheduler_enabled"] == false
    assert response["network_access"] == "forbidden"
    assert response["enqueue_performed"] == false
    assert response["materializer_triggered"] == false
    assert response["route_added"] == true
    assert response["ui_added"] == false
    assert response["action_endpoint_added"] == true
    assert response["schema_migration"] == false

    assert event_count(@group_id) == 1
    assert review_state_count(@group_id) == 1

    event = Repo.one!(from event in SourceDuplicateGroupActionEvent, where: event.group_id == ^@group_id)
    assert event.action_operation == "confirm_duplicate_group"
    assert event.required_permission == "duplicate_group:confirm"
    assert event.actor_id_hash == "sha256:operator-001"
    assert event.request_id_hash == "sha256:request-001"
    assert event.idempotency_key_hash == "sha256:idempotency-001"
    assert event.operator_reason_redacted == "REDACTED_OPERATOR_CONFIRMED_DUPLICATE_GROUP"

    state = Repo.one!(from state in SourceDuplicateGroupReviewState, where: state.group_id == ^@group_id)
    assert state.review_state == "confirmed_by_operator"
    assert state.last_action_operation == "confirm_duplicate_group"
    assert state.last_action_request_id_hash == "sha256:request-001"
    assert state.last_action_idempotency_key_hash == "sha256:idempotency-001"
    assert state.reviewed_by_actor_id_hash == "sha256:operator-001"
  end

  test "POST action route is idempotent for same identity", %{conn: conn} do
    first_response =
      conn
      |> post("/api/admin/duplicate-groups/#{@group_id}/confirm", @valid_payload)
      |> json_response(200)

    second_response =
      conn
      |> recycle()
      |> post("/api/admin/duplicate-groups/#{@group_id}/confirm", @valid_payload)
      |> json_response(200)

    assert first_response["action_event_inserted"] == true
    assert second_response["action_event_inserted"] == false
    assert second_response["action_event_id"] == first_response["action_event_id"]
    assert second_response["review_state_id"] == first_response["review_state_id"]
    assert event_count(@group_id) == 1
    assert review_state_count(@group_id) == 1
  end

  test "POST action routes map to locked operations", %{conn: conn} do
    cases = [
      {"reject", "reject_duplicate_group", "duplicate_group:reject", "rejected_by_operator"},
      {"mark-review", "mark_duplicate_group_needs_review", "duplicate_group:mark_review", "needs_review"},
      {"clear-review-state", "clear_duplicate_group_review_state", "duplicate_group:clear_review_state", "cleared"}
    ]

    Enum.with_index(cases, 1)
    |> Enum.each(fn {{route, operation, permission, state}, index} ->
      payload = %{
        @valid_payload
        | "actor_permissions" => [permission],
          "request_id_hash" => "sha256:request-#{index + 10}",
          "idempotency_key_hash" => "sha256:idempotency-#{index + 10}",
          "operator_reason_redacted" => "REDACTED_OPERATOR_ACTION_#{index}",
          "post_review_state" => state
      }

      response =
        conn
        |> recycle()
        |> post("/api/admin/duplicate-groups/#{@group_id}/#{route}", payload)
        |> json_response(200)

      assert response["action_operation"] == operation
      assert response["required_permission"] == permission
      assert response["review_state"] == state
    end)

    assert event_count(@group_id) == 3
    assert review_state_count(@group_id) == 1
  end

  test "request body cannot override route-derived operation", %{conn: conn} do
    payload = Map.put(@valid_payload, "action_operation", "reject_duplicate_group")

    response =
      conn
      |> post("/api/admin/duplicate-groups/#{@group_id}/confirm", payload)
      |> json_response(200)

    assert response["action_operation"] == "confirm_duplicate_group"
    assert response["required_permission"] == "duplicate_group:confirm"
    assert event_count(@group_id) == 1
  end

  test "read-only permission is rejected and writes no rows", %{conn: conn} do
    payload = %{@valid_payload | "actor_permissions" => ["duplicate_group:read"]}

    response =
      conn
      |> post("/api/admin/duplicate-groups/#{@group_id}/confirm", payload)
      |> json_response(403)

    assert response["error"] =~ "read_only_permission"
    assert event_count(@group_id) == 0
    assert review_state_count(@group_id) == 0
  end

  test "invalid payload is bounded 400 and writes no rows", %{conn: conn} do
    payload = %{@valid_payload | "actor_id_hash" => "operator-raw"}

    response =
      conn
      |> post("/api/admin/duplicate-groups/#{@group_id}/confirm", payload)
      |> json_response(400)

    assert response["error"] =~ "invalid_hash"
    assert event_count(@group_id) == 0
    assert review_state_count(@group_id) == 0
  end

  defp event_count(group_id) do
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
