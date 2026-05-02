defmodule DisclosureAutomation.Stage59DuplicateGroupInternalMaterializerTest do
  use DisclosureAutomationWeb.ConnCase, async: false

  import Ecto.Query

  alias DisclosureAutomation.Repo
  alias DisclosureAutomation.Runtime.Stage59DuplicateGroupInternalMaterializer
  alias DisclosureAutomation.Schema.SourceDuplicateGroup
  alias DisclosureAutomation.Schema.SourceDuplicateGroupMember

  @official_event_id "jp.tdnet.4527.20260430.material_information_update.material_information_update.140120260430515474"
  @overlay_id "news_overlay:jp.tdnet.4527.20260430.material_information_update.material_information_update.140120260430515474:ba9e08fb9a92ac57"
  @group_id "duplicate_group:jp.tdnet.4527.20260430.material_information_update"

  test "materializes bounded duplicate group metadata using existing fixture source keys" do
    assert {:ok, result} = Stage59DuplicateGroupInternalMaterializer.materialize_group(valid_group_attrs())

    assert result.mode == "stage59_internal_duplicate_group_materialized"
    assert result.group_id == @group_id
    assert result.members_seen == 2
    assert result.groups_upserted == 1
    assert result.members_upserted == 2
    assert result.public_response_shape_mutation == false
    assert result.public_api_duplicate_group_fields == false
    assert result.public_feed_duplicate_group_fields == false
    assert result.item_overlays_shape_mutation == false
    assert result.news_overlays_shape_mutation == false
    assert result.materializer_output_mutation == false
    assert result.canonical_feed_mutation == false
    assert result.provider_canonical_feed_item_creation == false
    assert result.news_only_event_creation == false
    assert result.official_event_merge == false
    assert result.official_fact_override == false
    assert result.official_citation_override == false
    assert result.network_access == "forbidden"
    assert result.trigger_live_fetch == false
    assert result.scheduler_enabled == false
    assert result.route_added == false
    assert result.ui_added == false
    assert result.action_endpoint_added == false

    assert group_count(@group_id) == 1
    assert member_count(@group_id) == 2

    group = Repo.one!(from group in SourceDuplicateGroup, where: group.group_id == ^@group_id)
    assert group.confidence == "likely"
    assert group.member_count == 2
    assert group.source_keys == %{"items" => ["jp_tdnet_timely_disclosure", "stage5_news_overlay_fixture"]}
    assert group.match_reasons == %{"items" => ["same_official_event_id", "same_disclosure_date", "same_provider_citation_target"]}
    assert group.has_official_tdnet_event == true
    assert group.has_provider_overlay == true
    assert group.redaction_status == "passed"

    official_member = member_by_id("member:official:jp_tdnet")
    assert official_member.group_id == @group_id
    assert official_member.member_kind == "official_tdnet_event"
    assert official_member.source_key == "jp_tdnet_timely_disclosure"
    assert official_member.provider == "TDnet"
    assert official_member.external_id_hash == "sha256:official-001"
    assert official_member.official_event_id == @official_event_id
    assert official_member.confidence == "likely"
    assert official_member.match_reasons == %{"items" => ["same_official_event_id", "same_disclosure_date"]}
    assert official_member.redaction_status == "passed"

    overlay_member = member_by_id("member:overlay:reuters")
    assert overlay_member.group_id == @group_id
    assert overlay_member.member_kind == "news_overlay_attachment"
    assert overlay_member.source_key == "stage5_news_overlay_fixture"
    assert overlay_member.provider == "Reuters"
    assert overlay_member.external_id_hash == "sha256:reuters-001"
    assert overlay_member.official_event_id == @official_event_id
    assert overlay_member.overlay_id == @overlay_id
    assert overlay_member.confidence == "candidate"
    assert overlay_member.match_reasons == %{"items" => ["same_official_event_id", "same_provider_citation_target"]}
    assert overlay_member.redaction_status == "passed"
  end

  test "rerunning the same duplicate group is idempotent" do
    assert {:ok, first_result} = Stage59DuplicateGroupInternalMaterializer.materialize_group(valid_group_attrs())
    assert group_count(@group_id) == 1
    assert member_count(@group_id) == 2

    assert {:ok, second_result} = Stage59DuplicateGroupInternalMaterializer.materialize_group(valid_group_attrs())

    assert first_result == second_result
    assert group_count(@group_id) == 1
    assert member_count(@group_id) == 2
  end

  test "rejects unknown source keys before writing duplicate group rows" do
    attrs = put_in(valid_group_attrs(), ["members", Access.at(1), "source_key"], "unreviewed_live_provider")

    assert Stage59DuplicateGroupInternalMaterializer.materialize_group(attrs) ==
             {:error, {:source_key_not_allowed_in_stage59_noop_service, "unreviewed_live_provider"}}

    assert group_count(@group_id) == 0
    assert member_count(@group_id) == 0
  end

  test "rejects forbidden payload, transport, full text, and canonical fields before writing rows" do
    forbidden_attrs = [
      Map.put(valid_group_attrs(), "cred" <> "entials", %{"redacted" => "blocked"}),
      Map.put(valid_group_attrs(), "canonicalFeedItemPayload", %{}),
      put_in(valid_group_attrs(), ["members", Access.at(1), "request" <> "Headers"], %{"redacted" => "blocked"}),
      put_in(valid_group_attrs(), ["members", Access.at(1), "rawProviderResponseBody"], "blocked"),
      put_in(valid_group_attrs(), ["members", Access.at(1), "fullArticleText"], "blocked"),
      put_in(valid_group_attrs(), ["members", Access.at(1), "canonicalFeedItemPayload"], %{})
    ]

    Enum.each(forbidden_attrs, fn attrs ->
      assert {:error, _reason} = Stage59DuplicateGroupInternalMaterializer.materialize_group(attrs)
      assert group_count(@group_id) == 0
      assert member_count(@group_id) == 0
    end)
  end

  test "rejects public and canonical opt-ins before writing rows" do
    forbidden_opts = [
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
      :official_citation_override
    ]

    Enum.each(forbidden_opts, fn opt ->
      assert {:error, _reason} = Stage59DuplicateGroupInternalMaterializer.materialize_group(valid_group_attrs(), [{opt, true}])
      assert group_count(@group_id) == 0
      assert member_count(@group_id) == 0
    end)
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

  defp member_by_id(member_id) do
    Repo.one!(from member in SourceDuplicateGroupMember, where: member.member_id == ^member_id)
  end
end
