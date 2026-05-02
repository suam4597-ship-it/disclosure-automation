defmodule DisclosureAutomation.Stage59DuplicateGroupProjectionContractTest do
  use ExUnit.Case, async: true

  alias DisclosureAutomation.Runtime.Stage59DuplicateGroupProjectionContract

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

  test "defaults are internal operator projection only and preserve public/canonical guardrails" do
    assert Stage59DuplicateGroupProjectionContract.defaults() == %{
             projection_scope: "internal_operator_duplicate_group_projection_only",
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

  test "projects a valid duplicate group into bounded redacted operator fields" do
    assert {:ok, projection} = Stage59DuplicateGroupProjectionContract.project(@valid_group_attrs)

    assert projection.projection_scope == "internal_operator_duplicate_group_projection_only"
    assert projection.bounded == true
    assert projection.redacted == true
    assert projection.advisory_only == true
    assert projection.operator_only == true
    assert projection.non_canonical == true
    assert projection.public_response_shape_mutation == false
    assert projection.public_api_duplicate_group_fields == false
    assert projection.public_feed_duplicate_group_fields == false
    assert projection.item_overlays_shape_mutation == false
    assert projection.news_overlays_shape_mutation == false
    assert projection.materializer_output_mutation == false
    assert projection.canonical_feed_mutation == false
    assert projection.provider_canonical_feed_item_creation == false
    assert projection.news_only_event_creation == false
    assert projection.official_event_merge == false
    assert projection.official_fact_override == false
    assert projection.official_citation_override == false
    assert projection.trigger_live_fetch == false
    assert projection.scheduler_enabled == false
    assert projection.network_access == "forbidden"
    assert projection.db_write == false
    assert projection.route_added == false
    assert projection.ui_added == false
    assert projection.action_endpoint_added == false
    assert projection.schema_migration == false

    assert projection.group_id == "duplicate_group:jp.tdnet.4527.20260430.material_information_update"
    assert projection.confidence == "likely"
    assert projection.member_count == 2
    assert projection.has_official_tdnet_event == true
    assert projection.has_provider_overlay == true
    assert projection.source_keys == ["jp_tdnet_timely_disclosure", "stage5_news_overlay_fixture"]
    assert projection.match_reasons == ["same_official_event_id", "same_disclosure_date", "same_provider_citation_target"]

    assert projection.fields.group_id == projection.group_id
    assert projection.fields.confidence == "likely"
    assert projection.fields.member_count == 2
    assert projection.fields.has_official_tdnet_event == true
    assert projection.fields.has_provider_overlay == true
    assert projection.fields.source_keys == projection.source_keys
    assert projection.fields.match_reasons == projection.match_reasons

    assert [official, overlay] = projection.fields.members
    assert official == %{
             member_id: "member:official:jp_tdnet",
             member_kind: "official_tdnet_event",
             source_key: "jp_tdnet_timely_disclosure",
             provider: "TDnet",
             external_id_hash: "sha256:official-001",
             official_event_id: @official_event_id,
             overlay_id: nil,
             confidence: "likely",
             match_reasons: ["same_official_event_id", "same_disclosure_date"],
             redaction_status: "passed"
           }

    assert overlay == %{
             member_id: "member:overlay:reuters",
             member_kind: "news_overlay_attachment",
             source_key: "stage5_news_overlay_fixture",
             provider: "Reuters",
             external_id_hash: "sha256:reuters-001",
             official_event_id: @official_event_id,
             overlay_id: @overlay_id,
             confidence: "candidate",
             match_reasons: ["same_official_event_id", "same_provider_citation_target"],
             redaction_status: "passed"
           }
  end

  test "allowed projection field lists are explicit" do
    assert Stage59DuplicateGroupProjectionContract.allowed_group_fields() == [
             "group_id",
             "confidence",
             "member_count",
             "has_official_tdnet_event",
             "has_provider_overlay",
             "match_reasons",
             "source_keys",
             "members"
           ]

    assert Stage59DuplicateGroupProjectionContract.allowed_member_fields() == [
             "member_id",
             "member_kind",
             "source_key",
             "provider",
             "external_id_hash",
             "official_event_id",
             "overlay_id",
             "confidence",
             "match_reasons",
             "redaction_status"
           ]
  end

  test "rejects non-projectable raw external id and timestamps" do
    assert Stage59DuplicateGroupProjectionContract.project(
             put_in(@valid_group_attrs, ["members", Access.at(1), "external_id"], "raw-external-id")
           ) == {:error, {:prohibited_field, "members[1].external_id"}}

    assert Stage59DuplicateGroupProjectionContract.project(
             put_in(@valid_group_attrs, ["members", Access.at(1), "created_at"], "2026-05-02T14:30:00Z")
           ) == {:error, {:non_projectable_member_field, :created_at}}

    assert Stage59DuplicateGroupProjectionContract.project(
             put_in(@valid_group_attrs, ["members", Access.at(1), "updated_at"], "2026-05-02T14:30:01Z")
           ) == {:error, {:non_projectable_member_field, :updated_at}}
  end

  test "propagates duplicate group contract validation failures" do
    assert Stage59DuplicateGroupProjectionContract.project(%{@valid_group_attrs | "members" => []}) ==
             {:error, :duplicate_group_requires_at_least_two_members}

    assert Stage59DuplicateGroupProjectionContract.project(%{@valid_group_attrs | "confidence" => "canonical"}) ==
             {:error, {:invalid_confidence, "canonical"}}

    assert Stage59DuplicateGroupProjectionContract.project(
             put_in(@valid_group_attrs, ["members", Access.at(1), "member_kind"], "canonical_feed_item")
           ) == {:error, {{:invalid_member_kind, 1}, "canonical_feed_item"}}

    assert Stage59DuplicateGroupProjectionContract.project(
             put_in(@valid_group_attrs, ["members", Access.at(1), "match_reasons"], ["full_text_similarity_payload"])
           ) == {:error, {{:invalid_match_reason, 1}, "full_text_similarity_payload"}}
  end

  test "rejects public projection, public response shape mutation, and public duplicate group fields" do
    assert Stage59DuplicateGroupProjectionContract.project(@valid_group_attrs, public_exposure: true) ==
             {:error, :public_exposure_not_allowed_in_stage59_duplicate_group_projection}

    assert Stage59DuplicateGroupProjectionContract.project(@valid_group_attrs, public_response_shape_mutation: true) ==
             {:error, :public_response_shape_mutation_not_allowed_in_stage59_duplicate_group_projection}

    assert Stage59DuplicateGroupProjectionContract.project(@valid_group_attrs, public_api_duplicate_group_fields: true) ==
             {:error, :public_response_shape_mutation_not_allowed_in_stage59_duplicate_group_projection}

    assert Stage59DuplicateGroupProjectionContract.project(@valid_group_attrs, item_overlays_shape_mutation: true) ==
             {:error, :public_response_shape_mutation_not_allowed_in_stage59_duplicate_group_projection}
  end

  test "rejects canonical mutation, official merge, live fetch, scheduler, DB, route, UI, and schema opt-ins" do
    assert Stage59DuplicateGroupProjectionContract.project(@valid_group_attrs, canonical_feed_mutation: true) ==
             {:error, :canonical_mutation_not_allowed_in_stage59_duplicate_group_projection}

    assert Stage59DuplicateGroupProjectionContract.project(@valid_group_attrs, provider_canonical_feed_item_creation: true) ==
             {:error, :canonical_mutation_not_allowed_in_stage59_duplicate_group_projection}

    assert Stage59DuplicateGroupProjectionContract.project(@valid_group_attrs, official_event_merge: true) ==
             {:error, :canonical_mutation_not_allowed_in_stage59_duplicate_group_projection}

    assert Stage59DuplicateGroupProjectionContract.project(@valid_group_attrs, trigger_live_fetch: true) ==
             {:error, :live_fetch_not_allowed_in_stage59_duplicate_group_projection}

    assert Stage59DuplicateGroupProjectionContract.project(@valid_group_attrs, scheduler_enabled: true) ==
             {:error, :scheduler_not_allowed_in_stage59_duplicate_group_projection}

    assert Stage59DuplicateGroupProjectionContract.project(@valid_group_attrs, db_write: true) ==
             {:error, :runtime_side_effect_not_allowed_in_stage59_duplicate_group_projection}

    assert Stage59DuplicateGroupProjectionContract.project(@valid_group_attrs, route_added: true) ==
             {:error, :route_ui_action_or_schema_not_allowed_in_stage59_duplicate_group_projection}

    assert Stage59DuplicateGroupProjectionContract.project(@valid_group_attrs, schema_migration: true) ==
             {:error, :route_ui_action_or_schema_not_allowed_in_stage59_duplicate_group_projection}
  end

  test "rejects credentials, transport metadata, raw payloads, full article text, canonical payloads, and secret-like values" do
    assert Stage59DuplicateGroupProjectionContract.project(
             Map.put(@valid_group_attrs, "credentials", %{sensitive_header_name(:subscription_key) => "not-allowed"})
           ) == {:error, {:prohibited_field, "credentials"}}

    assert Stage59DuplicateGroupProjectionContract.project(
             put_in(@valid_group_attrs, ["members", Access.at(1), "requestHeaders"], %{
               sensitive_header_name(:authorization) => "Bearer not-allowed"
             })
           ) == {:error, {:prohibited_field, "members[1].requestHeaders"}}

    assert Stage59DuplicateGroupProjectionContract.project(
             put_in(@valid_group_attrs, ["members", Access.at(1), "rawProviderResponseBody"], "not allowed")
           ) == {:error, {:prohibited_field, "members[1].rawProviderResponseBody"}}

    assert Stage59DuplicateGroupProjectionContract.project(
             put_in(@valid_group_attrs, ["members", Access.at(1), "fullArticleText"], "not allowed")
           ) == {:error, {:prohibited_field, "members[1].fullArticleText"}}

    assert Stage59DuplicateGroupProjectionContract.project(
             put_in(@valid_group_attrs, ["members", Access.at(1), "canonicalFeedItemPayload"], %{})
           ) == {:error, {:prohibited_field, "members[1].canonicalFeedItemPayload"}}

    assert Stage59DuplicateGroupProjectionContract.project(%{
             @valid_group_attrs
             | "group_id" => sensitive_header_prefix(:authorization) <> " Bearer not-allowed"
           }) == {:error, {:prohibited_field, "group_id"}}
  end

  defp sensitive_header_name(:authorization), do: "Author" <> "ization"
  defp sensitive_header_name(:subscription_key), do: "Subscription" <> "-" <> "Key"

  defp sensitive_header_prefix(:authorization), do: sensitive_header_name(:authorization) <> ":"
end
