defmodule DisclosureAutomation.Stage59DuplicateGroupNoopServiceTest do
  use ExUnit.Case, async: true

  alias DisclosureAutomation.Runtime.Stage59DuplicateGroupNoopService

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

  test "defaults are internal no-op service with fake existing fixtures only" do
    assert Stage59DuplicateGroupNoopService.defaults() == %{
             service_scope: "internal_duplicate_group_noop_only",
             bounded: true,
             redacted: true,
             advisory_only: true,
             operator_only: true,
             non_canonical: true,
             no_op: true,
             fake_existing_fixtures_only: true,
             duplicate_group_contract_required: true,
             duplicate_group_projection_required: true,
             grouping_materialized: false,
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

  test "previews a duplicate group using projection contract with no side effects" do
    assert {:ok, preview} = Stage59DuplicateGroupNoopService.preview_group(@valid_group_attrs)

    assert preview.service_scope == "internal_duplicate_group_noop_only"
    assert preview.bounded == true
    assert preview.redacted == true
    assert preview.advisory_only == true
    assert preview.operator_only == true
    assert preview.non_canonical == true
    assert preview.no_op == true
    assert preview.fake_existing_fixtures_only == true
    assert preview.duplicate_group_contract_required == true
    assert preview.duplicate_group_projection_required == true
    assert preview.grouping_materialized == false
    assert preview.public_response_shape_mutation == false
    assert preview.public_api_duplicate_group_fields == false
    assert preview.public_feed_duplicate_group_fields == false
    assert preview.item_overlays_shape_mutation == false
    assert preview.news_overlays_shape_mutation == false
    assert preview.materializer_output_mutation == false
    assert preview.canonical_feed_mutation == false
    assert preview.provider_canonical_feed_item_creation == false
    assert preview.news_only_event_creation == false
    assert preview.official_event_merge == false
    assert preview.official_fact_override == false
    assert preview.official_citation_override == false
    assert preview.trigger_live_fetch == false
    assert preview.scheduler_enabled == false
    assert preview.network_access == "forbidden"
    assert preview.db_write == false
    assert preview.route_added == false
    assert preview.ui_added == false
    assert preview.action_endpoint_added == false
    assert preview.schema_migration == false

    assert preview.group_id == "duplicate_group:jp.tdnet.4527.20260430.material_information_update"
    assert preview.confidence == "likely"
    assert preview.member_count == 2
    assert preview.source_keys == ["jp_tdnet_timely_disclosure", "stage5_news_overlay_fixture"]
    assert preview.match_reasons == ["same_official_event_id", "same_disclosure_date", "same_provider_citation_target"]

    assert preview.projection.projection_scope == "internal_operator_duplicate_group_projection_only"
    assert preview.projection.fields.members |> length() == 2

    assert preview.preview_result == %{
             mode: "stage59_noop_duplicate_group_preview",
             group_id: "duplicate_group:jp.tdnet.4527.20260430.material_information_update",
             confidence: "likely",
             member_count: 2,
             source_keys: ["jp_tdnet_timely_disclosure", "stage5_news_overlay_fixture"],
             match_reasons: ["same_official_event_id", "same_disclosure_date", "same_provider_citation_target"],
             no_op: true,
             fake_existing_fixtures_only: true,
             grouping_materialized: false,
             db_write: false,
             network_access: "forbidden",
             trigger_live_fetch: false,
             scheduler_enabled: false,
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
             route_added: false,
             ui_added: false,
             action_endpoint_added: false,
             schema_migration: false
           }
  end

  test "allows locked TDnet and Stage 5 overlay fixture source keys" do
    assert Stage59DuplicateGroupNoopService.allowed_source_keys() == [
             "jp_tdnet_timely_disclosure",
             "stage5_news_overlay_fixture",
             "stage53_news_overlay_fixture"
           ]

    group_attrs =
      put_in(@valid_group_attrs, ["members", Access.at(1), "source_key"], "stage53_news_overlay_fixture")

    assert {:ok, preview} = Stage59DuplicateGroupNoopService.preview_group(group_attrs)
    assert preview.source_keys == ["jp_tdnet_timely_disclosure", "stage53_news_overlay_fixture"]
  end

  test "rejects unknown source keys outside locked fixture set" do
    group_attrs = put_in(@valid_group_attrs, ["members", Access.at(1), "source_key"], "unreviewed_live_provider")

    assert Stage59DuplicateGroupNoopService.preview_group(group_attrs) ==
             {:error, {:source_key_not_allowed_in_stage59_noop_service, "unreviewed_live_provider"}}
  end

  test "propagates projection contract validation errors" do
    assert Stage59DuplicateGroupNoopService.preview_group(%{@valid_group_attrs | "members" => []}) ==
             {:error, :duplicate_group_requires_at_least_two_members}

    assert Stage59DuplicateGroupNoopService.preview_group(%{@valid_group_attrs | "confidence" => "canonical"}) ==
             {:error, {:invalid_confidence, "canonical"}}

    assert Stage59DuplicateGroupNoopService.preview_group(
             put_in(@valid_group_attrs, ["members", Access.at(1), "external_id"], "raw-external-id")
           ) == {:error, {:prohibited_field, "members[1].external_id"}}
  end

  test "rejects public response-shape, duplicate group field, and materializer opt-ins" do
    assert Stage59DuplicateGroupNoopService.preview_group(@valid_group_attrs, public_exposure: true) ==
             {:error, :public_exposure_not_allowed_in_stage59_noop_service}

    assert Stage59DuplicateGroupNoopService.preview_group(@valid_group_attrs, public_response_shape_mutation: true) ==
             {:error, :public_response_shape_mutation_not_allowed_in_stage59_noop_service}

    assert Stage59DuplicateGroupNoopService.preview_group(@valid_group_attrs, public_api_duplicate_group_fields: true) ==
             {:error, :public_response_shape_mutation_not_allowed_in_stage59_noop_service}

    assert Stage59DuplicateGroupNoopService.preview_group(@valid_group_attrs, item_overlays_shape_mutation: true) ==
             {:error, :public_response_shape_mutation_not_allowed_in_stage59_noop_service}

    assert Stage59DuplicateGroupNoopService.preview_group(@valid_group_attrs, materializer_output_mutation: true) ==
             {:error, :public_response_shape_mutation_not_allowed_in_stage59_noop_service}
  end

  test "rejects canonical mutation, official merge, live fetch, scheduler, DB, route, UI, and schema opt-ins" do
    assert Stage59DuplicateGroupNoopService.preview_group(@valid_group_attrs, canonical_feed_mutation: true) ==
             {:error, :canonical_mutation_not_allowed_in_stage59_noop_service}

    assert Stage59DuplicateGroupNoopService.preview_group(@valid_group_attrs, provider_canonical_feed_item_creation: true) ==
             {:error, :canonical_mutation_not_allowed_in_stage59_noop_service}

    assert Stage59DuplicateGroupNoopService.preview_group(@valid_group_attrs, official_event_merge: true) ==
             {:error, :canonical_mutation_not_allowed_in_stage59_noop_service}

    assert Stage59DuplicateGroupNoopService.preview_group(@valid_group_attrs, trigger_live_fetch: true) ==
             {:error, :live_fetch_not_allowed_in_stage59_noop_service}

    assert Stage59DuplicateGroupNoopService.preview_group(@valid_group_attrs, scheduler_enabled: true) ==
             {:error, :scheduler_not_allowed_in_stage59_noop_service}

    assert Stage59DuplicateGroupNoopService.preview_group(@valid_group_attrs, db_write: true) ==
             {:error, :runtime_side_effect_not_allowed_in_stage59_noop_service}

    assert Stage59DuplicateGroupNoopService.preview_group(@valid_group_attrs, route_added: true) ==
             {:error, :route_ui_action_or_schema_not_allowed_in_stage59_noop_service}

    assert Stage59DuplicateGroupNoopService.preview_group(@valid_group_attrs, schema_migration: true) ==
             {:error, :route_ui_action_or_schema_not_allowed_in_stage59_noop_service}
  end

  test "rejects credentials, transport metadata, raw payloads, full article text, canonical payloads, and secret-like values" do
    assert Stage59DuplicateGroupNoopService.preview_group(
             Map.put(@valid_group_attrs, "credentials", %{sensitive_header_name(:subscription_key) => "not-allowed"})
           ) == {:error, {:prohibited_field, "credentials"}}

    assert Stage59DuplicateGroupNoopService.preview_group(
             put_in(@valid_group_attrs, ["members", Access.at(1), "requestHeaders"], %{
               sensitive_header_name(:authorization) => "Bearer not-allowed"
             })
           ) == {:error, {:prohibited_field, "members[1].requestHeaders"}}

    assert Stage59DuplicateGroupNoopService.preview_group(
             put_in(@valid_group_attrs, ["members", Access.at(1), "rawProviderResponseBody"], "not allowed")
           ) == {:error, {:prohibited_field, "members[1].rawProviderResponseBody"}}

    assert Stage59DuplicateGroupNoopService.preview_group(
             put_in(@valid_group_attrs, ["members", Access.at(1), "fullArticleText"], "not allowed")
           ) == {:error, {:prohibited_field, "members[1].fullArticleText"}}

    assert Stage59DuplicateGroupNoopService.preview_group(
             put_in(@valid_group_attrs, ["members", Access.at(1), "canonicalFeedItemPayload"], %{})
           ) == {:error, {:prohibited_field, "members[1].canonicalFeedItemPayload"}}

    assert Stage59DuplicateGroupNoopService.preview_group(%{
             @valid_group_attrs
             | "group_id" => sensitive_header_prefix(:authorization) <> " Bearer not-allowed"
           }) == {:error, {:prohibited_field, "group_id"}}
  end

  defp sensitive_header_name(:authorization), do: "Author" <> "ization"
  defp sensitive_header_name(:subscription_key), do: "Subscription" <> "-" <> "Key"

  defp sensitive_header_prefix(:authorization), do: sensitive_header_name(:authorization) <> ":"
end
