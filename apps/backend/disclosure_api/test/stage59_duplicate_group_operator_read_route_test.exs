defmodule DisclosureAutomation.Stage59DuplicateGroupOperatorReadRouteTest do
  use DisclosureAutomationWeb.ConnCase, async: false

  import Ecto.Query

  alias DisclosureAutomation.Repo
  alias DisclosureAutomation.Runtime.Stage59DuplicateGroupInternalMaterializer
  alias DisclosureAutomation.Schema.SourceDuplicateGroup
  alias DisclosureAutomation.Schema.SourceDuplicateGroupMember

  @official_event_id "jp.tdnet.4527.20260430.material_information_update.material_information_update.140120260430515474"
  @overlay_id "news_overlay:jp.tdnet.4527.20260430.material_information_update.material_information_update.140120260430515474:ba9e08fb9a92ac57"
  @group_id "duplicate_group:jp.tdnet.4527.20260430.material_information_update"

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

    page =
      conn
      |> get("/api/admin/duplicate-groups")
      |> json_response(200)

    assert page["items"] == []
    assert page["materializer_triggered"] == false

    assert group_count(@group_id) == 0
    assert member_count(@group_id) == 0
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
end
