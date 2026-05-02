defmodule DisclosureAutomation.Stage59DuplicateGroupInternalReadProjectionTest do
  use DisclosureAutomationWeb.ConnCase, async: false

  import Ecto.Query

  alias DisclosureAutomation.Repo
  alias DisclosureAutomation.Runtime.Stage59DuplicateGroupInternalMaterializer
  alias DisclosureAutomation.Runtime.Stage59DuplicateGroupInternalReadProjection
  alias DisclosureAutomation.Schema.SourceDuplicateGroup
  alias DisclosureAutomation.Schema.SourceDuplicateGroupMember

  @official_event_id "jp.tdnet.4527.20260430.material_information_update.material_information_update.140120260430515474"
  @overlay_id "news_overlay:jp.tdnet.4527.20260430.material_information_update.material_information_update.140120260430515474:ba9e08fb9a92ac57"
  @group_id "duplicate_group:jp.tdnet.4527.20260430.material_information_update"

  test "lists bounded operator-only duplicate group projections from persisted rows" do
    materialize_fixture_group!()

    assert {:ok, page} = Stage59DuplicateGroupInternalReadProjection.list(%{"limit" => "10"})

    assert page.mode == "stage59_internal_duplicate_group_list_projection"
    assert page.view_scope == "operator_only_duplicate_group_review"
    assert page.read_only == true
    assert page.advisory_only == true
    assert page.bounded == true
    assert page.redacted == true
    assert page.operator_only == true
    assert page.non_canonical == true
    assert page.public_response_shape_mutation == false
    assert page.public_api_duplicate_group_fields == false
    assert page.public_feed_duplicate_group_fields == false
    assert page.item_overlays_shape_mutation == false
    assert page.news_overlays_shape_mutation == false
    assert page.materializer_output_mutation == false
    assert page.canonical_feed_mutation == false
    assert page.provider_canonical_feed_item_creation == false
    assert page.news_only_event_creation == false
    assert page.official_event_merge == false
    assert page.official_fact_override == false
    assert page.official_citation_override == false
    assert page.trigger_live_fetch == false
    assert page.scheduler_enabled == false
    assert page.network_access == "forbidden"
    assert page.route_added == false
    assert page.ui_added == false
    assert page.action_endpoint_added == false
    assert page.materializer_triggered == false
    assert page.item_count == 1
    assert page.limit == 10

    assert [item] = page.items
    assert item.group_id == @group_id
    assert item.confidence == "likely"
    assert item.source_keys == ["jp_tdnet_timely_disclosure", "stage5_news_overlay_fixture"]
    assert item.match_reasons == ["same_official_event_id", "same_disclosure_date", "same_provider_citation_target"]
    assert item.member_count == 2
    assert item.has_official_tdnet_event == true
    assert item.has_provider_overlay == true
    assert item.redaction_status == "passed"
    assert length(item.members) == 2

    assert Enum.all?(item.members, &Map.has_key?(&1, :member_id))
    refute Map.has_key?(item, :canonical_feed_item_payload)
    refute Enum.any?(item.members, &Map.has_key?(&1, :external_id))
  end

  test "shows one duplicate group with bounded members" do
    materialize_fixture_group!()

    assert {:ok, show} = Stage59DuplicateGroupInternalReadProjection.get(@group_id)

    assert show.mode == "stage59_internal_duplicate_group_show_projection"
    assert show.read_only == true
    assert show.canonical_feed_mutation == false
    assert show.materializer_triggered == false

    item = show.item
    assert item.group_id == @group_id
    assert item.member_count == 2

    assert [official_member, overlay_member] = item.members
    assert official_member.member_id == "member:official:jp_tdnet"
    assert official_member.member_kind == "official_tdnet_event"
    assert official_member.source_key == "jp_tdnet_timely_disclosure"
    assert official_member.provider == "TDnet"
    assert official_member.external_id_hash == "sha256:official-001"
    assert official_member.official_event_id == @official_event_id
    assert official_member.overlay_id == nil
    assert official_member.confidence == "likely"
    assert official_member.match_reasons == ["same_official_event_id", "same_disclosure_date"]
    assert official_member.redaction_status == "passed"

    assert overlay_member.member_id == "member:overlay:reuters"
    assert overlay_member.member_kind == "news_overlay_attachment"
    assert overlay_member.source_key == "stage5_news_overlay_fixture"
    assert overlay_member.provider == "Reuters"
    assert overlay_member.external_id_hash == "sha256:reuters-001"
    assert overlay_member.official_event_id == @official_event_id
    assert overlay_member.overlay_id == @overlay_id
    assert overlay_member.confidence == "candidate"
    assert overlay_member.match_reasons == ["same_official_event_id", "same_provider_citation_target"]
    assert overlay_member.redaction_status == "passed"
  end

  test "supports bounded allowlisted list filters" do
    materialize_fixture_group!()

    assert {:ok, page} =
             Stage59DuplicateGroupInternalReadProjection.list(%{
               "confidence" => "likely",
               "source_key" => "stage5_news_overlay_fixture",
               "member_kind" => "news_overlay_attachment",
               "redaction_status" => "passed",
               "limit" => 5
             })

    assert page.item_count == 1
    assert page.filters == %{
             confidence: "likely",
             source_key: "stage5_news_overlay_fixture",
             member_kind: "news_overlay_attachment",
             redaction_status: "passed",
             limit: 5
           }

    assert {:ok, empty_page} = Stage59DuplicateGroupInternalReadProjection.list(%{"source_key" => "stage53_news_overlay_fixture"})
    assert empty_page.item_count == 0
    assert empty_page.items == []
  end

  test "rejects unsupported or unbounded filters" do
    assert Stage59DuplicateGroupInternalReadProjection.list(%{"rawProviderResponseBody" => "blocked"}) ==
             {:error, {:unsupported_duplicate_group_filter, "rawProviderResponseBody"}}

    assert Stage59DuplicateGroupInternalReadProjection.list(%{"confidence" => "canonical"}) ==
             {:error, {:invalid_duplicate_group_filter, :confidence, "canonical"}}

    assert Stage59DuplicateGroupInternalReadProjection.list(%{"member_kind" => "canonical_feed_item"}) ==
             {:error, {:invalid_duplicate_group_filter, :member_kind, "canonical_feed_item"}}

    assert Stage59DuplicateGroupInternalReadProjection.list(%{"limit" => "101"}) ==
             {:error, {:invalid_duplicate_group_limit, 101}}
  end

  test "read projection rejects public, canonical, route, action, scheduler, live fetch, and materializer opt-ins" do
    forbidden_opts = [
      :public_exposure,
      :public_response_shape_mutation,
      :public_api_duplicate_group_fields,
      :public_feed_duplicate_group_fields,
      :item_overlays_shape_mutation,
      :news_overlays_shape_mutation,
      :materializer_output_mutation,
      :canonical_feed_mutation,
      :provider_canonical_feed_item_creation,
      :news_only_event_creation,
      :official_event_merge,
      :official_fact_override,
      :official_citation_override,
      :trigger_live_fetch,
      :scheduler_enabled,
      :network_access,
      :route_added,
      :ui_added,
      :action_endpoint_added,
      :materializer_triggered
    ]

    Enum.each(forbidden_opts, fn opt ->
      assert {:error, _reason} = Stage59DuplicateGroupInternalReadProjection.list(%{}, [{opt, true}])
      assert {:error, _reason} = Stage59DuplicateGroupInternalReadProjection.get(@group_id, [{opt, true}])
    end)
  end

  test "read projection does not write rows or trigger materialization" do
    assert group_count(@group_id) == 0
    assert member_count(@group_id) == 0

    assert {:ok, page} = Stage59DuplicateGroupInternalReadProjection.list(%{})
    assert page.items == []
    assert page.materializer_triggered == false

    assert Stage59DuplicateGroupInternalReadProjection.get(@group_id) == {:error, :duplicate_group_not_found}
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
