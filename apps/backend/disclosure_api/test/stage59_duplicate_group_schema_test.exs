defmodule DisclosureAutomation.Stage59DuplicateGroupSchemaTest do
  use ExUnit.Case, async: true

  alias DisclosureAutomation.Schema.SourceDuplicateGroup
  alias DisclosureAutomation.Schema.SourceDuplicateGroupMember

  @official_event_id "jp.tdnet.4527.20260430.material_information_update.material_information_update.140120260430515474"
  @overlay_id "news_overlay:jp.tdnet.4527.20260430.material_information_update.material_information_update.140120260430515474:ba9e08fb9a92ac57"

  @valid_group_attrs %{
    "group_id" => "duplicate_group:jp.tdnet.4527.20260430.material_information_update",
    "confidence" => "likely",
    "source_keys" => %{"items" => ["jp_tdnet_timely_disclosure", "stage5_news_overlay_fixture"]},
    "match_reasons" => %{"items" => ["same_official_event_id", "same_disclosure_date"]},
    "member_count" => 2,
    "has_official_tdnet_event" => true,
    "has_provider_overlay" => true,
    "redaction_status" => "passed"
  }

  @valid_member_attrs %{
    "group_id" => "duplicate_group:jp.tdnet.4527.20260430.material_information_update",
    "member_id" => "member:overlay:reuters",
    "member_kind" => "news_overlay_attachment",
    "source_key" => "stage5_news_overlay_fixture",
    "provider" => "Reuters",
    "external_id_hash" => "sha256:reuters-001",
    "official_event_id" => @official_event_id,
    "overlay_id" => @overlay_id,
    "confidence" => "candidate",
    "match_reasons" => %{"items" => ["same_official_event_id", "same_provider_citation_target"]},
    "redaction_status" => "passed"
  }

  test "source duplicate group changeset accepts bounded advisory metadata" do
    changeset = SourceDuplicateGroup.changeset(%SourceDuplicateGroup{}, @valid_group_attrs)

    assert changeset.valid?
    assert Ecto.Changeset.get_change(changeset, :group_id) == @valid_group_attrs["group_id"]
    assert Ecto.Changeset.get_change(changeset, :confidence) == "likely"
    assert Ecto.Changeset.get_change(changeset, :member_count) == 2
    assert Ecto.Changeset.get_change(changeset, :source_keys) == %{
             "items" => ["jp_tdnet_timely_disclosure", "stage5_news_overlay_fixture"]
           }
    assert Ecto.Changeset.get_change(changeset, :match_reasons) == %{
             "items" => ["same_official_event_id", "same_disclosure_date"]
           }
  end

  test "source duplicate group changeset enforces allowlists and bounded member count" do
    assert SourceDuplicateGroup.changeset(%SourceDuplicateGroup{}, %{@valid_group_attrs | "confidence" => "canonical"}).valid? == false
    assert SourceDuplicateGroup.changeset(%SourceDuplicateGroup{}, %{@valid_group_attrs | "redaction_status" => "raw_allowed"}).valid? == false
    assert SourceDuplicateGroup.changeset(%SourceDuplicateGroup{}, %{@valid_group_attrs | "member_count" => 1}).valid? == false

    assert SourceDuplicateGroup.changeset(%SourceDuplicateGroup{}, %{
             @valid_group_attrs
             | "match_reasons" => %{"items" => ["full_text_similarity_payload"]}
           }).valid? == false
  end

  test "source duplicate group changeset rejects forbidden raw or secret-like fields" do
    assert SourceDuplicateGroup.changeset(
             %SourceDuplicateGroup{},
             Map.put(@valid_group_attrs, "rawProviderResponseBody", "not allowed")
           ).valid? == false

    assert SourceDuplicateGroup.changeset(
             %SourceDuplicateGroup{},
             Map.put(@valid_group_attrs, "canonicalFeedItemPayload", %{})
           ).valid? == false

    assert SourceDuplicateGroup.changeset(%SourceDuplicateGroup{}, %{
             @valid_group_attrs
             | "group_id" => sensitive_header_prefix(:authorization) <> " Bearer not-allowed"
           }).valid? == false
  end

  test "source duplicate group member changeset accepts bounded member metadata" do
    changeset = SourceDuplicateGroupMember.changeset(%SourceDuplicateGroupMember{}, @valid_member_attrs)

    assert changeset.valid?
    assert Ecto.Changeset.get_change(changeset, :group_id) == @valid_member_attrs["group_id"]
    assert Ecto.Changeset.get_change(changeset, :member_id) == "member:overlay:reuters"
    assert Ecto.Changeset.get_change(changeset, :member_kind) == "news_overlay_attachment"
    assert Ecto.Changeset.get_change(changeset, :external_id_hash) == "sha256:reuters-001"
    assert Ecto.Changeset.get_change(changeset, :official_event_id) == @official_event_id
    assert Ecto.Changeset.get_change(changeset, :overlay_id) == @overlay_id
  end

  test "source duplicate group member changeset enforces allowlists and references" do
    assert SourceDuplicateGroupMember.changeset(%SourceDuplicateGroupMember{}, %{
             @valid_member_attrs
             | "member_kind" => "canonical_feed_item"
           }).valid? == false

    assert SourceDuplicateGroupMember.changeset(%SourceDuplicateGroupMember{}, %{
             @valid_member_attrs
             | "confidence" => "merged"
           }).valid? == false

    assert SourceDuplicateGroupMember.changeset(%SourceDuplicateGroupMember{}, %{
             @valid_member_attrs
             | "redaction_status" => "raw_allowed"
           }).valid? == false

    assert SourceDuplicateGroupMember.changeset(%SourceDuplicateGroupMember{}, %{
             @valid_member_attrs
             | "match_reasons" => %{"items" => ["full_text_similarity_payload"]}
           }).valid? == false

    missing_reference_attrs = Map.drop(@valid_member_attrs, ["external_id_hash", "official_event_id", "overlay_id"])
    assert SourceDuplicateGroupMember.changeset(%SourceDuplicateGroupMember{}, missing_reference_attrs).valid? == false
  end

  test "source duplicate group member changeset requires hash-shaped external id hash" do
    assert SourceDuplicateGroupMember.changeset(%SourceDuplicateGroupMember{}, %{
             @valid_member_attrs
             | "external_id_hash" => "reuters-001"
           }).valid? == false
  end

  test "source duplicate group member changeset rejects forbidden raw or secret-like fields" do
    assert SourceDuplicateGroupMember.changeset(
             %SourceDuplicateGroupMember{},
             Map.put(@valid_member_attrs, "credentials", %{sensitive_header_name(:subscription_key) => "not-allowed"})
           ).valid? == false

    assert SourceDuplicateGroupMember.changeset(
             %SourceDuplicateGroupMember{},
             Map.put(@valid_member_attrs, "requestHeaders", %{sensitive_header_name(:authorization) => "Bearer not-allowed"})
           ).valid? == false

    assert SourceDuplicateGroupMember.changeset(
             %SourceDuplicateGroupMember{},
             Map.put(@valid_member_attrs, "fullArticleText", "not allowed")
           ).valid? == false

    assert SourceDuplicateGroupMember.changeset(%SourceDuplicateGroupMember{}, %{
             @valid_member_attrs
             | "member_id" => sensitive_header_prefix(:authorization) <> " Bearer not-allowed"
           }).valid? == false
  end

  test "schema allowlists match Stage 5.9 contract values" do
    assert "official_tdnet_event" in SourceDuplicateGroupMember.member_kinds()
    assert "news_overlay_attachment" in SourceDuplicateGroupMember.member_kinds()
    assert "candidate" in SourceDuplicateGroup.confidence_states()
    assert "confirmed_by_operator" in SourceDuplicateGroup.confidence_states()
    assert "same_official_event_id" in SourceDuplicateGroup.match_reasons()
    assert "same_provider_citation_target" in SourceDuplicateGroupMember.match_reasons()
    assert "passed" in SourceDuplicateGroup.redaction_statuses()
    assert "blocked" in SourceDuplicateGroupMember.redaction_statuses()
  end

  defp sensitive_header_name(:authorization), do: "Author" <> "ization"
  defp sensitive_header_name(:subscription_key), do: "Subscription" <> "-" <> "Key"

  defp sensitive_header_prefix(:authorization), do: sensitive_header_name(:authorization) <> ":"
end
