defmodule DisclosureAutomation.Stage59CrossSourceDuplicateGroupContractTest do
  use ExUnit.Case, async: true

  alias DisclosureAutomation.Runtime.Stage59CrossSourceDuplicateGroupContract

  @official_event_id "jp.tdnet.4527.20260430.material_information_update.material_information_update.140120260430515474"
  @overlay_id "news_overlay:jp.tdnet.4527.20260430.material_information_update.material_information_update.140120260430515474:ba9e08fb9a92ac57"

  @valid_group_attrs %{
    "group_id" => "duplicate_group:jp.tdnet.4527.20260430.material_information_update",
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
        "redaction_status" => "passed",
        "created_at" => "2026-05-02T14:10:00Z"
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
        "redaction_status" => "passed",
        "created_at" => "2026-05-02T14:10:01Z"
      }
    ]
  }

  test "defaults are internal operator advisory only and no-side-effect" do
    assert Stage59CrossSourceDuplicateGroupContract.defaults() == %{
             duplicate_group_scope: "internal_operator_advisory_only",
             bounded: true,
             redacted: true,
             advisory_only: true,
             operator_only: true,
             non_canonical: true,
             public_response_shape_mutation: false,
             public_api_duplicate_group_fields: false,
             public_feed_duplicate_group_fields: false,
             item_overlays_shape_mutation: false,
             news_overlays_shape_mutation: false,
             materializer_output_mutation: false,
             canonical_feed_mutation: false,
             provider_canonical_feed_item_creation: false,
             news_only_event_creation: false,
             official_event_merge: false,
             official_fact_override: false,
             official_citation_override: false,
             trigger_live_fetch: false,
             scheduler_enabled: false,
             network_access: "forbidden",
             db_write: false,
             route_added: false,
             ui_added: false,
             action_endpoint_added: false,
             schema_migration: false
           }
  end

  test "validates a bounded advisory duplicate group" do
    assert {:ok, group} = Stage59CrossSourceDuplicateGroupContract.validate_group(@valid_group_attrs)

    assert group.duplicate_group_scope == "internal_operator_advisory_only"
    assert group.bounded == true
    assert group.redacted == true
    assert group.advisory_only == true
    assert group.operator_only == true
    assert group.non_canonical == true
    assert group.public_response_shape_mutation == false
    assert group.public_api_duplicate_group_fields == false
    assert group.public_feed_duplicate_group_fields == false
    assert group.item_overlays_shape_mutation == false
    assert group.news_overlays_shape_mutation == false
    assert group.materializer_output_mutation == false
    assert group.canonical_feed_mutation == false
    assert group.provider_canonical_feed_item_creation == false
    assert group.news_only_event_creation == false
    assert group.official_event_merge == false
    assert group.official_fact_override == false
    assert group.official_citation_override == false
    assert group.trigger_live_fetch == false
    assert group.scheduler_enabled == false
    assert group.network_access == "forbidden"
    assert group.db_write == false
    assert group.route_added == false
    assert group.ui_added == false
    assert group.action_endpoint_added == false
    assert group.schema_migration == false

    assert group.group_id == "duplicate_group:jp.tdnet.4527.20260430.material_information_update"
    assert group.confidence == "likely"
    assert group.member_count == 2
    assert group.has_official_tdnet_event == true
    assert group.has_provider_overlay == true
    assert group.source_keys == ["jp_tdnet_timely_disclosure", "stage5_news_overlay_fixture"]
    assert group.match_reasons == ["same_official_event_id", "same_disclosure_date", "same_provider_citation_target"]

    assert [official, overlay] = group.members
    assert official.member_kind == "official_tdnet_event"
    assert official.canonical_feed_mutation == false
    assert official.official_fact_override == false
    assert overlay.member_kind == "news_overlay_attachment"
    assert overlay.overlay_id == @overlay_id
    assert overlay.provider_canonical_feed_item_creation == false
  end

  test "accepts all allowlisted member kinds, confidence states, match reasons, and redaction statuses" do
    for member_kind <- Stage59CrossSourceDuplicateGroupContract.allowed_member_kinds() do
      group_attrs = put_in(@valid_group_attrs, ["members", Access.at(1), "member_kind"], member_kind)
      assert {:ok, group} = Stage59CrossSourceDuplicateGroupContract.validate_group(group_attrs)
      assert Enum.at(group.members, 1).member_kind == member_kind
    end

    for confidence <- Stage59CrossSourceDuplicateGroupContract.allowed_confidence_states() do
      group_attrs = %{@valid_group_attrs | "confidence" => confidence}
      assert {:ok, group} = Stage59CrossSourceDuplicateGroupContract.validate_group(group_attrs)
      assert group.confidence == confidence
    end

    for reason <- Stage59CrossSourceDuplicateGroupContract.allowed_match_reasons() do
      group_attrs = put_in(@valid_group_attrs, ["members", Access.at(1), "match_reasons"], [reason])
      assert {:ok, group} = Stage59CrossSourceDuplicateGroupContract.validate_group(group_attrs)
      assert reason in Enum.at(group.members, 1).match_reasons
    end

    for status <- Stage59CrossSourceDuplicateGroupContract.allowed_redaction_statuses() do
      group_attrs = put_in(@valid_group_attrs, ["members", Access.at(1), "redaction_status"], status)
      assert {:ok, group} = Stage59CrossSourceDuplicateGroupContract.validate_group(group_attrs)
      assert Enum.at(group.members, 1).redaction_status == status
    end
  end

  test "requires at least two members and required group fields" do
    assert Stage59CrossSourceDuplicateGroupContract.validate_group(Map.delete(@valid_group_attrs, "group_id")) ==
             {:error, :group_id_required}

    assert Stage59CrossSourceDuplicateGroupContract.validate_group(Map.delete(@valid_group_attrs, "confidence")) ==
             {:error, :invalid_confidence}

    assert Stage59CrossSourceDuplicateGroupContract.validate_group(%{@valid_group_attrs | "members" => []}) ==
             {:error, :duplicate_group_requires_at_least_two_members}

    assert Stage59CrossSourceDuplicateGroupContract.validate_group(Map.delete(@valid_group_attrs, "members")) ==
             {:error, :duplicate_group_members_required}
  end

  test "rejects invalid member kind, confidence, redaction status, and match reason" do
    assert Stage59CrossSourceDuplicateGroupContract.validate_group(%{@valid_group_attrs | "confidence" => "canonical"}) ==
             {:error, {:invalid_confidence, "canonical"}}

    assert Stage59CrossSourceDuplicateGroupContract.validate_group(
             put_in(@valid_group_attrs, ["members", Access.at(1), "member_kind"], "canonical_feed_item")
           ) == {:error, {{:invalid_member_kind, 1}, "canonical_feed_item"}}

    assert Stage59CrossSourceDuplicateGroupContract.validate_group(
             put_in(@valid_group_attrs, ["members", Access.at(1), "confidence"], "merged")
           ) == {:error, {{:invalid_member_confidence, 1}, "merged"}}

    assert Stage59CrossSourceDuplicateGroupContract.validate_group(
             put_in(@valid_group_attrs, ["members", Access.at(1), "redaction_status"], "raw_allowed")
           ) == {:error, {{:invalid_member_redaction_status, 1}, "raw_allowed"}}

    assert Stage59CrossSourceDuplicateGroupContract.validate_group(
             put_in(@valid_group_attrs, ["members", Access.at(1), "match_reasons"], ["full_text_similarity_payload"])
           ) == {:error, {{:invalid_match_reason, 1}, "full_text_similarity_payload"}}
  end

  test "requires each member to have at least one bounded reference" do
    member_without_reference =
      @valid_group_attrs
      |> get_in(["members", Access.at(1)])
      |> Map.drop(["external_id", "external_id_hash", "official_event_id", "overlay_id"])

    group_attrs = put_in(@valid_group_attrs, ["members", Access.at(1)], member_without_reference)

    assert Stage59CrossSourceDuplicateGroupContract.validate_group(group_attrs) ==
             {:error, {:member_reference_required, 1}}
  end

  test "rejects public exposure, response shape mutation, and public duplicate group fields" do
    assert Stage59CrossSourceDuplicateGroupContract.validate_group(@valid_group_attrs, public_exposure: true) ==
             {:error, :public_exposure_not_allowed_in_stage59_duplicate_group_contract}

    assert Stage59CrossSourceDuplicateGroupContract.validate_group(@valid_group_attrs, public_response_shape_mutation: true) ==
             {:error, :public_response_shape_mutation_not_allowed_in_stage59_duplicate_group_contract}

    assert Stage59CrossSourceDuplicateGroupContract.validate_group(@valid_group_attrs, public_api_duplicate_group_fields: true) ==
             {:error, :public_response_shape_mutation_not_allowed_in_stage59_duplicate_group_contract}

    assert Stage59CrossSourceDuplicateGroupContract.validate_group(@valid_group_attrs, item_overlays_shape_mutation: true) ==
             {:error, :public_response_shape_mutation_not_allowed_in_stage59_duplicate_group_contract}
  end

  test "rejects canonical mutation, official merge, live fetch, scheduler, DB, route, UI, and schema opt-ins" do
    assert Stage59CrossSourceDuplicateGroupContract.validate_group(@valid_group_attrs, canonical_feed_mutation: true) ==
             {:error, :canonical_mutation_not_allowed_in_stage59_duplicate_group_contract}

    assert Stage59CrossSourceDuplicateGroupContract.validate_group(@valid_group_attrs, provider_canonical_feed_item_creation: true) ==
             {:error, :canonical_mutation_not_allowed_in_stage59_duplicate_group_contract}

    assert Stage59CrossSourceDuplicateGroupContract.validate_group(@valid_group_attrs, official_event_merge: true) ==
             {:error, :canonical_mutation_not_allowed_in_stage59_duplicate_group_contract}

    assert Stage59CrossSourceDuplicateGroupContract.validate_group(@valid_group_attrs, trigger_live_fetch: true) ==
             {:error, :live_fetch_not_allowed_in_stage59_duplicate_group_contract}

    assert Stage59CrossSourceDuplicateGroupContract.validate_group(@valid_group_attrs, scheduler_enabled: true) ==
             {:error, :scheduler_not_allowed_in_stage59_duplicate_group_contract}

    assert Stage59CrossSourceDuplicateGroupContract.validate_group(@valid_group_attrs, db_write: true) ==
             {:error, :runtime_side_effect_not_allowed_in_stage59_duplicate_group_contract}

    assert Stage59CrossSourceDuplicateGroupContract.validate_group(@valid_group_attrs, route_added: true) ==
             {:error, :route_ui_action_or_schema_not_allowed_in_stage59_duplicate_group_contract}

    assert Stage59CrossSourceDuplicateGroupContract.validate_group(@valid_group_attrs, schema_migration: true) ==
             {:error, :route_ui_action_or_schema_not_allowed_in_stage59_duplicate_group_contract}
  end

  test "rejects credentials, transport metadata, raw payloads, full article text, canonical payloads, and secret-like values" do
    assert Stage59CrossSourceDuplicateGroupContract.validate_group(
             Map.put(@valid_group_attrs, "credentials", %{sensitive_header_name(:subscription_key) => "not-allowed"})
           ) == {:error, {:prohibited_field, "credentials"}}

    assert Stage59CrossSourceDuplicateGroupContract.validate_group(
             put_in(@valid_group_attrs, ["members", Access.at(1), "requestHeaders"], %{
               sensitive_header_name(:authorization) => "Bearer not-allowed"
             })
           ) == {:error, {:prohibited_field, "members[1].requestHeaders"}}

    assert Stage59CrossSourceDuplicateGroupContract.validate_group(
             put_in(@valid_group_attrs, ["members", Access.at(1), "rawProviderResponseBody"], "not allowed")
           ) == {:error, {:prohibited_field, "members[1].rawProviderResponseBody"}}

    assert Stage59CrossSourceDuplicateGroupContract.validate_group(
             put_in(@valid_group_attrs, ["members", Access.at(1), "fullArticleText"], "not allowed")
           ) == {:error, {:prohibited_field, "members[1].fullArticleText"}}

    assert Stage59CrossSourceDuplicateGroupContract.validate_group(
             put_in(@valid_group_attrs, ["members", Access.at(1), "canonicalFeedItemPayload"], %{})
           ) == {:error, {:prohibited_field, "members[1].canonicalFeedItemPayload"}}

    assert Stage59CrossSourceDuplicateGroupContract.validate_group(%{
             @valid_group_attrs
             | "group_id" => sensitive_header_prefix(:authorization) <> " Bearer not-allowed"
           }) == {:error, {:prohibited_field, "group_id"}}
  end

  test "rejects malformed external id hash" do
    assert Stage59CrossSourceDuplicateGroupContract.validate_group(
             put_in(@valid_group_attrs, ["members", Access.at(1), "external_id_hash"], "not-a-hash")
           ) == {:error, {:invalid_hash, :external_id_hash}}
  end

  defp sensitive_header_name(:authorization), do: "Author" <> "ization"
  defp sensitive_header_name(:subscription_key), do: "Subscription" <> "-" <> "Key"

  defp sensitive_header_prefix(:authorization), do: sensitive_header_name(:authorization) <> ":"
end
