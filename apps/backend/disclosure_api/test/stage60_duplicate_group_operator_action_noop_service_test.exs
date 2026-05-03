defmodule DisclosureAutomation.Stage60DuplicateGroupOperatorActionNoopServiceTest do
  use ExUnit.Case, async: true

  alias DisclosureAutomation.Runtime.Stage60DuplicateGroupOperatorActionNoopService

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

  @valid_audit_context %{
    "result_status" => "accepted",
    "redaction_status" => "passed",
    "pre_review_state" => "unknown",
    "post_review_state" => "confirmed_by_operator",
    "created_at" => "2026-05-03T03:20:00Z"
  }

  test "defaults are operator-only no-op action service with fake side effects only" do
    assert Stage60DuplicateGroupOperatorActionNoopService.defaults() == %{
             service_scope: "operator_only_duplicate_group_action_noop",
             action_contract_required: true,
             audit_contract_required: true,
             operator_only: true,
             advisory_only: true,
             non_canonical: true,
             bounded: true,
             redacted: true,
             no_op: true,
             fake_side_effects_only: true,
             action_attempt_recorded: true,
             audit_event_built: true,
             accepted: true,
             public_response_shape_mutation: false,
             public_api_duplicate_group_fields: false,
             public_feed_duplicate_group_fields: false,
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
             audit_write_performed: false,
             enqueue_performed: false,
             materializer_triggered: false,
             route_added: false,
             ui_added: false,
             action_endpoint_added: false,
             schema_migration: false
           }
  end

  test "previews confirm duplicate group action with bounded audit event and no side effects" do
    assert {:ok, preview} =
             Stage60DuplicateGroupOperatorActionNoopService.preview_action(@valid_action_attrs, @valid_audit_context)

    assert preview.service_scope == "operator_only_duplicate_group_action_noop"
    assert preview.action_contract_required == true
    assert preview.audit_contract_required == true
    assert preview.operator_only == true
    assert preview.advisory_only == true
    assert preview.non_canonical == true
    assert preview.bounded == true
    assert preview.redacted == true
    assert preview.no_op == true
    assert preview.fake_side_effects_only == true
    assert preview.action_attempt_recorded == true
    assert preview.audit_event_built == true
    assert preview.accepted == true
    assert preview.action_operation == "confirm_duplicate_group"
    assert preview.required_permission == "duplicate_group:confirm"
    assert preview.group_id == @group_id
    assert preview.actor_id_hash == "sha256:operator-001"
    assert preview.request_id_hash == "sha256:request-001"
    assert preview.idempotency_key_hash == "sha256:idempotency-001"
    assert preview.result_status == "accepted"
    assert preview.redaction_status == "passed"

    assert preview.public_response_shape_mutation == false
    assert preview.public_api_duplicate_group_fields == false
    assert preview.public_feed_duplicate_group_fields == false
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
    assert preview.audit_write_performed == false
    assert preview.enqueue_performed == false
    assert preview.materializer_triggered == false
    assert preview.route_added == false
    assert preview.ui_added == false
    assert preview.action_endpoint_added == false
    assert preview.schema_migration == false

    assert preview.action.action_operation == "confirm_duplicate_group"
    assert preview.action.required_permission == "duplicate_group:confirm"
    assert preview.action.operator_reason_redacted == "REDACTED_OPERATOR_CONFIRMED_DUPLICATE_GROUP"

    assert preview.audit_event.action_operation == "confirm_duplicate_group"
    assert preview.audit_event.required_permission == "duplicate_group:confirm"
    assert preview.audit_event.pre_review_state == "unknown"
    assert preview.audit_event.post_review_state == "confirmed_by_operator"
    assert preview.audit_event.created_at == "2026-05-03T03:20:00Z"

    assert preview.action_result == %{
             mode: "stage60_noop_duplicate_group_operator_action",
             group_id: @group_id,
             action_operation: "confirm_duplicate_group",
             required_permission: "duplicate_group:confirm",
             accepted: true,
             no_op: true,
             fake_side_effects_only: true,
             audit_event_built: true,
             audit_write_performed: false,
             db_write: false,
             enqueue_performed: false,
             network_access: "forbidden",
             trigger_live_fetch: false,
             scheduler_enabled: false,
             materializer_triggered: false,
             route_added: false,
             ui_added: false,
             action_endpoint_added: false,
             schema_migration: false,
             public_response_shape_mutation: false,
             public_api_duplicate_group_fields: false,
             public_feed_duplicate_group_fields: false,
             canonical_feed_mutation: false,
             provider_canonical_feed_item_creation: false,
             news_only_event_creation: false,
             official_event_merge: false,
             official_fact_override: false,
             official_citation_override: false,
             result_status: "accepted",
             redaction_status: "passed",
             pre_review_state: "unknown",
             post_review_state: "confirmed_by_operator"
           }
  end

  test "derives default post review state by action operation" do
    cases = [
      {"confirm_duplicate_group", "duplicate_group:confirm", "confirmed_by_operator"},
      {"reject_duplicate_group", "duplicate_group:reject", "rejected_by_operator"},
      {"mark_duplicate_group_needs_review", "duplicate_group:mark_review", "needs_review"},
      {"clear_duplicate_group_review_state", "duplicate_group:clear_review_state", "cleared"}
    ]

    Enum.each(cases, fn {operation, permission, post_review_state} ->
      attrs = %{@valid_action_attrs | "action_operation" => operation, "actor_permissions" => [permission]}
      context = Map.delete(@valid_audit_context, "post_review_state")

      assert {:ok, preview} = Stage60DuplicateGroupOperatorActionNoopService.preview_action(attrs, context)
      assert preview.action_result.post_review_state == post_review_state
      assert preview.audit_event.post_review_state == post_review_state
    end)
  end

  test "propagates action contract permission and hash validation errors" do
    assert Stage60DuplicateGroupOperatorActionNoopService.preview_action(
             %{@valid_action_attrs | "actor_permissions" => ["duplicate_group:read"]},
             @valid_audit_context
           ) == {:error, {:read_only_permission_cannot_execute_action, "duplicate_group:confirm"}}

    assert Stage60DuplicateGroupOperatorActionNoopService.preview_action(
             %{@valid_action_attrs | "actor_id_hash" => "operator-raw"},
             @valid_audit_context
           ) == {:error, {:invalid_hash, :actor_id_hash_required}}
  end

  test "propagates audit contract state validation errors" do
    assert Stage60DuplicateGroupOperatorActionNoopService.preview_action(
             @valid_action_attrs,
             %{@valid_audit_context | "result_status" => "merged"}
           ) == {:error, {:invalid_result_status, "merged"}}

    assert Stage60DuplicateGroupOperatorActionNoopService.preview_action(
             @valid_action_attrs,
             %{@valid_audit_context | "post_review_state" => "canonical_merged"}
           ) == {:error, {:invalid_post_review_state, "canonical_merged"}}
  end

  test "rejects unknown audit context keys" do
    assert Stage60DuplicateGroupOperatorActionNoopService.preview_action(
             @valid_action_attrs,
             Map.put(@valid_audit_context, "rawDiagnosticPayload", "blocked")
           ) == {:error, {:unsupported_stage60_action_noop_context_key, "rawDiagnosticPayload"}}
  end

  test "rejects raw actor request idempotency reason and provider material in audit context" do
    forbidden_contexts = [
      Map.put(@valid_audit_context, "actor_id", "operator-raw"),
      Map.put(@valid_audit_context, "request_id", "request-raw"),
      Map.put(@valid_audit_context, "idempotency_key", "idempotency-raw"),
      Map.put(@valid_audit_context, "operator_reason", "raw reason"),
      Map.put(@valid_audit_context, "request" <> "Headers", %{"redacted" => "blocked"}),
      Map.put(@valid_audit_context, "rawProviderResponseBody", "blocked"),
      Map.put(@valid_audit_context, "fullArticleText", "blocked"),
      Map.put(@valid_audit_context, "canonicalFeedItemPayload", %{})
    ]

    Enum.each(forbidden_contexts, fn context ->
      assert {:error, {:prohibited_field, _path}} =
               Stage60DuplicateGroupOperatorActionNoopService.preview_action(@valid_action_attrs, context)
    end)
  end

  test "rejects public canonical provider scheduler route UI action audit schema materializer and runtime opt-ins" do
    forbidden_opts = [
      :public_exposure,
      :public_response_shape_mutation,
      :public_api_duplicate_group_fields,
      :public_feed_duplicate_group_fields,
      :canonical_feed_mutation,
      :provider_canonical_feed_item_creation,
      :news_only_event_creation,
      :official_event_merge,
      :official_fact_override,
      :official_citation_override,
      :trigger_live_fetch,
      :scheduler_enabled,
      :network_access,
      :db_write,
      :audit_write_performed,
      :audit_write,
      :enqueue_performed,
      :materializer_triggered,
      :route_added,
      :ui_added,
      :action_endpoint_added,
      :schema_migration
    ]

    Enum.each(forbidden_opts, fn opt ->
      assert {:error, _reason} =
               Stage60DuplicateGroupOperatorActionNoopService.preview_action(@valid_action_attrs, @valid_audit_context, [
                 {opt, true}
               ])
    end)
  end
end
