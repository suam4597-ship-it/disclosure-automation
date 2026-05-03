defmodule DisclosureAutomation.Stage66DuplicateGroupOperatorUiIntegrationTest do
  use DisclosureAutomationWeb.ConnCase, async: false

  import Ecto.Query

  alias DisclosureAutomation.Repo
  alias DisclosureAutomation.Runtime.Stage59DuplicateGroupInternalMaterializer
  alias DisclosureAutomation.Schema.SourceDuplicateGroupActionEvent
  alias DisclosureAutomation.Schema.SourceDuplicateGroupReviewState

  @official_event_id "jp.tdnet.4527.20260430.material_information_update.material_information_update.140120260430515474"
  @overlay_id "news_overlay:jp.tdnet.4527.20260430.material_information_update.material_information_update.140120260430515474:ba9e08fb9a92ac57"
  @group_id "duplicate_group:jp.tdnet.4527.20260430.material_information_update"

  @confirm_payload %{
    "actor_id_hash" => "sha256:operator-001",
    "actor_permissions" => ["duplicate_group:confirm"],
    "roles" => ["operator"],
    "request_id_hash" => "sha256:ui-request-001",
    "idempotency_key_hash" => "sha256:ui-idempotency-001",
    "operator_reason_redacted" => "REDACTED_OPERATOR_CONFIRMED_DUPLICATE_GROUP",
    "result_status" => "completed",
    "redaction_status" => "passed",
    "pre_review_state" => "unknown",
    "post_review_state" => "confirmed_by_operator",
    "created_at" => "2026-05-03T14:10:00Z"
  }

  test "operator UI list and detail screens depend only on locked JSON APIs", %{conn: conn} do
    materialize_fixture_group!()

    list_body =
      conn
      |> get("/admin/duplicate-groups")
      |> html_response(200)

    assert list_body =~ "data-list-api-route=\"/api/admin/duplicate-groups\""
    assert list_body =~ "fetch(buildUrl(), { headers: { 'accept': 'application/json' } })"
    assert list_body =~ "data-excludes=\"action_event_summary\""
    assert list_body =~ "data-detail-route-template=\"/admin/duplicate-groups/:group_id\""
    refute list_body =~ "/api/admin/duplicate-groups/:group_id/confirm"
    refute list_body =~ "/api/admin/duplicate-groups/:group_id/reject"
    refute list_body =~ "/api/admin/duplicate-groups/:group_id/mark-review"
    refute list_body =~ "/api/admin/duplicate-groups/:group_id/clear-review-state"

    detail_body =
      conn
      |> recycle()
      |> get("/admin/duplicate-groups/#{@group_id}")
      |> html_response(200)

    assert detail_body =~ "data-detail-api-route=\"/api/admin/duplicate-groups/duplicate_group%3Ajp.tdnet.4527.20260430.material_information_update\""
    assert detail_body =~ "data-summary-source=\"show-response-only\""
    assert detail_body =~ "data-summary-limit=\"latest-five-from-show-response\""
    assert detail_body =~ "data-action-controls=\"enabled\""
    assert detail_body =~ "data-operation-override=\"forbidden\""
    assert detail_body =~ "data-action-control=\"confirm\""
    assert detail_body =~ "data-action-control=\"reject\""
    assert detail_body =~ "data-action-control=\"mark-review\""
    assert detail_body =~ "data-action-control=\"clear-review-state\""
    refute detail_body =~ "name=\"action_operation\""
    refute detail_body =~ "action_operation:"
    refute detail_body =~ "raw_actor_id"
    refute detail_body =~ "raw_request_id"
    refute detail_body =~ "raw_idempotency_key"
    refute detail_body =~ "provider_payload"
    refute detail_body =~ "canonical_payload"
    refute detail_body =~ "full_article_text"
  end

  test "operator UI action control flow matches locked action route and refreshed detail projection", %{conn: conn} do
    materialize_fixture_group!()

    assert action_event_count(@group_id) == 0
    assert review_state_count(@group_id) == 0

    action_response =
      conn
      |> post("/api/admin/duplicate-groups/#{@group_id}/confirm", @confirm_payload)
      |> json_response(200)

    assert action_response["action_operation"] == "confirm_duplicate_group"
    assert action_response["required_permission"] == "duplicate_group:confirm"
    assert action_response["review_state"] == "confirmed_by_operator"
    assert action_response["authorized"] == true
    assert action_response["public_response_shape_mutation"] == false
    assert action_response["canonical_feed_mutation"] == false
    assert action_response["trigger_live_fetch"] == false
    assert action_response["scheduler_enabled"] == false
    assert action_response["materializer_triggered"] == false
    assert action_response["action_event_inserted"] == true

    refreshed_detail =
      conn
      |> recycle()
      |> get("/api/admin/duplicate-groups/#{@group_id}")
      |> json_response(200)

    item = refreshed_detail["item"]
    assert item["review_state_summary"]["review_state"] == "confirmed_by_operator"
    assert item["review_state_summary"]["last_action_operation"] == "confirm_duplicate_group"
    assert item["review_state_summary"]["last_action_request_id_hash"] == "sha256:ui-request-001"
    assert item["review_state_summary"]["last_action_idempotency_key_hash"] == "sha256:ui-idempotency-001"
    assert item["review_state_summary"]["reviewed_by_actor_id_hash"] == "sha256:operator-001"
    assert item["review_state_summary"]["review_reason_redacted"] == "REDACTED_OPERATOR_CONFIRMED_DUPLICATE_GROUP"

    assert [event] = item["action_event_summary"]
    assert event["action_operation"] == "confirm_duplicate_group"
    assert event["required_permission"] == "duplicate_group:confirm"
    assert event["actor_id_hash"] == "sha256:operator-001"
    assert event["request_id_hash"] == "sha256:ui-request-001"
    assert event["idempotency_key_hash"] == "sha256:ui-idempotency-001"
    refute Map.has_key?(event, "operator_reason_redacted")
    refute Map.has_key?(event, "raw_actor_id")
    refute Map.has_key?(event, "raw_request_id")
    refute Map.has_key?(event, "raw_idempotency_key")
    refute Map.has_key?(event, "canonical_payload")

    assert action_event_count(@group_id) == 1
    assert review_state_count(@group_id) == 1
  end

  test "operator UI action controls preserve route-derived operation despite body override attempt", %{conn: conn} do
    payload = Map.put(@confirm_payload, "action_operation", "reject_duplicate_group")

    response =
      conn
      |> post("/api/admin/duplicate-groups/#{@group_id}/confirm", payload)
      |> json_response(200)

    assert response["action_operation"] == "confirm_duplicate_group"
    assert response["required_permission"] == "duplicate_group:confirm"
    assert response["review_state"] == "confirmed_by_operator"
  end

  test "operator UI action controls reject read-only permission without writes", %{conn: conn} do
    payload = %{@confirm_payload | "actor_permissions" => ["duplicate_group:read"]}

    response =
      conn
      |> post("/api/admin/duplicate-groups/#{@group_id}/confirm", payload)
      |> json_response(403)

    assert response["error"] =~ "read_only_permission"
    assert action_event_count(@group_id) == 0
    assert review_state_count(@group_id) == 0
  end

  test "operator UI pages do not mutate duplicate group review/action state by rendering", %{conn: conn} do
    materialize_fixture_group!()

    assert action_event_count(@group_id) == 0
    assert review_state_count(@group_id) == 0

    conn
    |> get("/admin/duplicate-groups")
    |> html_response(200)

    conn
    |> recycle()
    |> get("/admin/duplicate-groups/#{@group_id}")
    |> html_response(200)

    assert action_event_count(@group_id) == 0
    assert review_state_count(@group_id) == 0
  end

  defp materialize_fixture_group! do
    assert {:ok, _result} = Stage59DuplicateGroupInternalMaterializer.materialize_group(valid_group_attrs())
  end

  defp valid_group_attrs do
    %{
      "group_id" => @group_id,
      "confidence" => "likely",
      "members" => [
        %{
          "member_id" => "member:official:jp_tdnet",
          "member_kind" => "official_tdnet_event",
          "source_key" => "jp_tdnet_timely_disclosure",
          "provider" => "TDnet",
          "external_id_hash" => "sha256:official-001",
          "official_event_id" => @official_event_id,
          "confidence" => "likely",
          "match_reasons" => ["same_official_event_id", "same_disclosure_date"],
          "redaction_status" => "passed"
        },
        %{
          "member_id" => "member:overlay:reuters",
          "member_kind" => "news_overlay_attachment",
          "source_key" => "stage5_news_overlay_fixture",
          "provider" => "Reuters",
          "external_id_hash" => "sha256:reuters-001",
          "official_event_id" => @official_event_id,
          "overlay_id" => @overlay_id,
          "confidence" => "candidate",
          "match_reasons" => ["same_official_event_id", "same_provider_citation_target"],
          "redaction_status" => "passed"
        }
      ]
    }
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
