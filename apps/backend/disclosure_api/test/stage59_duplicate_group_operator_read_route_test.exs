defmodule DisclosureAutomation.Stage59DuplicateGroupOperatorReadRouteTest do
  use DisclosureAutomationWeb.ConnCase, async: false

  import Ecto.Query

  alias DisclosureAutomation.Repo
  alias DisclosureAutomation.Runtime.Stage59DuplicateGroupInternalMaterializer
  alias DisclosureAutomation.Runtime.Stage61DuplicateGroupActionStateWriter
  alias DisclosureAutomation.Schema.SourceDuplicateGroup
  alias DisclosureAutomation.Schema.SourceDuplicateGroupActionEvent
  alias DisclosureAutomation.Schema.SourceDuplicateGroupMember
  alias DisclosureAutomation.Schema.SourceDuplicateGroupReviewState

  @official_event_id "jp.tdnet.4527.20260430.material_information_update.material_information_update.140120260430515474"
  @overlay_id "news_overlay:jp.tdnet.4527.20260430.material_information_update.material_information_update.140120260430515474:ba9e08fb9a92ac57"
  @group_id "duplicate_group:jp.tdnet.4527.20260430.material_information_update"

  @valid_action_attrs %{
    "group_id" => @group_id,
    "action_operation" => "confirm_duplicate_group",
    "actor_permissions" => ["duplicate_group:confirm"],
    "actor_id_hash" => "sha256:operator-001",
    "request_id_hash" => "sha256:request-001",
    "idempotency_key_hash" => "sha256:idempotency-001",
    "operator_reason_redacted" => "REDACTED_OPERATOR_CONFIRMED_DUPLICATE_GROUP",
    "redaction_status" => "passed"
  }

  @valid_actor_context %{
    "authenticated" => true,
    "roles" => ["operator"],
    "permissions" => ["duplicate_group:confirm"],
    "actor_id_hash" => "sha256:operator-001",
    "result_status" => "completed",
    "redaction_status" => "passed",
    "pre_review_state" => "unknown",
    "post_review_state" => "confirmed_by_operator",
    "created_at" => "2026-05-03T07:30:00Z"
  }

  test "GET /api/admin/duplicate-groups returns bounded operator-only duplicate groups", %{conn: conn} do
    materialize_fixture_group!()

    response =
      conn
      |> get("/api/admin/duplicate-groups?limit=10")
      |> json_response(200)

    assert response["mode"] == "stage59_internal_duplicate_group_list_projection"
    assert response["view_scope"] == "operator_only_duplicate_group_review"
    assert response["read_only"] == true
    assert response["advisory_only"] == true
    assert response["operator_only"] == true
    assert response["non_canonical"] == true
    assert response["bounded"] == true
    assert response["redacted"] == true
    assert response["item_count"] == 1
    assert response["limit"] == 10
    assert response["route_added"] == true
    assert response["ui_added"] == false
    assert response["action_endpoint_added"] == false
    assert response["materializer_triggered"] == false
    assert response["public_response_shape_mutation"] == false
    assert response["public_api_duplicate_group_fields"] == false
    assert response["public_feed_duplicate_group_fields"] == false
    assert response["item_overlays_shape_mutation"] == false
    assert response["news_overlays_shape_mutation"] == false
    assert response["materializer_output_mutation"] == false
    assert response["canonical_feed_mutation"] == false
    assert response["provider_canonical_feed_item_creation"] == false
    assert response["news_only_event_creation"] == false
    assert response["official_event_merge"] == false
    assert response["official_fact_override"] == false
    assert response["official_citation_override"] == false
    assert response["trigger_live_fetch"] == false
    assert response["scheduler_enabled"] == false
    assert response["network_access"] == "forbidden"

    assert [item] = response["items"]
    assert item["group_id"] == @group_id
    assert item["confidence"] == "likely"
    assert item["source_keys"] == ["jp_tdnet_timely_disclosure", "stage5_news_overlay_fixture"]
    assert item["match_reasons"] == ["same_official_event_id", "same_disclosure_date", "same_provider_citation_target"]
    assert item["member_count"] == 2
    assert item["has_official_tdnet_event"] == true
    assert item["has_provider_overlay"] == true
    assert item["redaction_status"] == "passed"
    assert item["review_state_summary"] == empty_review_state_summary_json()
    refute Map.has_key?(item, "action_event_summary")
    assert length(item["members"]) == 2
    refute Map.has_key?(item, "canonical_feed_item_payload")
    refute Map.has_key?(item, "raw_provider_response_body")
  end

  test "GET /api/admin/duplicate-groups/:group_id returns one bounded duplicate group", %{conn: conn} do
    materialize_fixture_group!()

    response =
      conn
      |> get("/api/admin/duplicate-groups/#{@group_id}")
      |> json_response(200)

    assert response["mode"] == "stage59_internal_duplicate_group_show_projection"
    assert response["read_only"] == true
    assert response["route_added"] == true
    assert response["action_endpoint_added"] == false
    assert response["materializer_triggered"] == false
    assert response["canonical_feed_mutation"] == false

    item = response["item"]
    assert item["group_id"] == @group_id
    assert item["member_count"] == 2
    assert item["review_state_summary"] == empty_review_state_summary_json()
    assert item["action_event_summary"] == []

    assert [official_member, overlay_member] = item["members"]
    assert official_member["member_id"] == "member:official:jp_tdnet"
    assert official_member["member_kind"] == "official_tdnet_event"
    assert official_member["source_key"] == "jp_tdnet_timely_disclosure"
    assert official_member["provider"] == "TDnet"
    assert official_member["external_id_hash"] == "sha256:official-001"
    assert official_member["official_event_id"] == @official_event_id
    assert official_member["overlay_id"] == nil
    assert official_member["confidence"] == "likely"
    assert official_member["match_reasons"] == ["same_official_event_id", "same_disclosure_date"]
    assert official_member["redaction_status"] == "passed"

    assert overlay_member["member_id"] == "member:overlay:reuters"
    assert overlay_member["member_kind"] == "news_overlay_attachment"
    assert overlay_member["source_key"] == "stage5_news_overlay_fixture"
    assert overlay_member["provider"] == "Reuters"
    assert overlay_member["external_id_hash"] == "sha256:reuters-001"
    assert overlay_member["official_event_id"] == @official_event_id
    assert overlay_member["overlay_id"] == @overlay_id
    assert overlay_member["confidence"] == "candidate"
    assert overlay_member["match_reasons"] == ["same_official_event_id", "same_provider_citation_target"]
    assert overlay_member["redaction_status"] == "passed"
    refute Map.has_key?(overlay_member, "external_id")
    refute Map.has_key?(overlay_member, "full_article_text")
  end

  test "admin read routes expose bounded review state and action event response metadata", %{conn: conn} do
    materialize_fixture_group!()
    record_confirm_action!()

    list_response =
      conn
      |> get("/api/admin/duplicate-groups?limit=10")
      |> json_response(200)

    assert [list_item] = list_response["items"]
    assert list_item["review_state_summary"]["review_state"] == "confirmed_by_operator"
    assert list_item["review_state_summary"]["last_action_operation"] == "confirm_duplicate_group"
    assert list_item["review_state_summary"]["last_action_request_id_hash"] == "sha256:request-001"
    assert list_item["review_state_summary"]["last_action_idempotency_key_hash"] == "sha256:idempotency-001"
    assert list_item["review_state_summary"]["reviewed_by_actor_id_hash"] == "sha256:operator-001"
    assert list_item["review_state_summary"]["review_reason_redacted"] == "REDACTED_OPERATOR_CONFIRMED_DUPLICATE_GROUP"
    assert list_item["review_state_summary"]["redaction_status"] == "passed"
    assert is_binary(list_item["review_state_summary"]["reviewed_at"])
    refute Map.has_key?(list_item, "action_event_summary")

    show_response =
      conn
      |> recycle()
      |> get("/api/admin/duplicate-groups/#{@group_id}")
      |> json_response(200)

    item = show_response["item"]
    assert item["review_state_summary"] == list_item["review_state_summary"]

    assert [event] = item["action_event_summary"]
    assert event["action_operation"] == "confirm_duplicate_group"
    assert event["required_permission"] == "duplicate_group:confirm"
    assert event["actor_id_hash"] == "sha256:operator-001"
    assert event["request_id_hash"] == "sha256:request-001"
    assert event["idempotency_key_hash"] == "sha256:idempotency-001"
    assert event["result_status"] == "completed"
    assert event["pre_review_state"] == "unknown"
    assert event["post_review_state"] == "confirmed_by_operator"
    assert event["failure_code"] == nil
    assert event["redaction_status"] == "passed"
    assert is_binary(event["inserted_at"])

    refute Map.has_key?(event, "operator_reason_redacted")
    refute Map.has_key?(event, "raw_actor_id")
    refute Map.has_key?(event, "raw_request_id")
    refute Map.has_key?(event, "raw_idempotency_key")
    refute Map.has_key?(event, "canonical_payload")
    refute Map.has_key?(item, "canonical_feed_item_payload")
    refute Map.has_key?(item, "raw_provider_response_body")
  end

  test "GET /api/admin/duplicate-groups supports bounded filters", %{conn: conn} do
    materialize_fixture_group!()

    response =
      conn
      |> get("/api/admin/duplicate-groups?confidence=likely&source_key=stage5_news_overlay_fixture&member_kind=news_overlay_attachment&redaction_status=passed&limit=5")
      |> json_response(200)

    assert response["item_count"] == 1
    assert response["filters"] == %{
             "confidence" => "likely",
             "source_key" => "stage5_news_overlay_fixture",
             "member_kind" => "news_overlay_attachment",
             "redaction_status" => "passed",
             "limit" => 5
           }

    empty_response =
      conn
      |> recycle()
      |> get("/api/admin/duplicate-groups?source_key=stage53_news_overlay_fixture")
      |> json_response(200)

    assert empty_response["item_count"] == 0
    assert empty_response["items"] == []
  end

  test "GET /api/admin/duplicate-groups rejects unsupported filters", %{conn: conn} do
    response =
      conn
      |> get("/api/admin/duplicate-groups?unboundedDiagnosticPayload=blocked")
      |> json_response(400)

    assert response["error"] =~ "unsupported_duplicate_group_filter"
  end

  test "GET /api/admin/duplicate-groups/:group_id returns 404 for missing group", %{conn: conn} do
    response =
      conn
      |> get("/api/admin/duplicate-groups/duplicate_group:missing")
      |> json_response(404)

    assert response == %{"error" => "duplicate_group_not_found"}
  end

  test "read routes do not create rows or trigger materialization", %{conn: conn} do
    assert group_count(@group_id) == 0
    assert member_count(@group_id) == 0
    assert action_event_count(@group_id) == 0
    assert review_state_count(@group_id) == 0

    page =
      conn
      |> get("/api/admin/duplicate-groups")
      |> json_response(200)

    assert page["items"] == []
    assert page["materializer_triggered"] == false

    assert group_count(@group_id) == 0
    assert member_count(@group_id) == 0
    assert action_event_count(@group_id) == 0
    assert review_state_count(@group_id) == 0
  end

  defp materialize_fixture_group! do
    assert {:ok, _result} = Stage59DuplicateGroupInternalMaterializer.materialize_group(valid_group_attrs())
  end

  defp record_confirm_action! do
    assert {:ok, result} = Stage61DuplicateGroupActionStateWriter.record_action(@valid_action_attrs, @valid_actor_context)
    assert result.action_event_inserted == true
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

  defp empty_review_state_summary_json do
    %{
      "review_state" => nil,
      "last_action_operation" => nil,
      "last_action_request_id_hash" => nil,
      "last_action_idempotency_key_hash" => nil,
      "reviewed_by_actor_id_hash" => nil,
      "reviewed_at" => nil,
      "review_reason_redacted" => nil,
      "redaction_status" => nil
    }
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
