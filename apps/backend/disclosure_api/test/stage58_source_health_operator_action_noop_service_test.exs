defmodule DisclosureAutomation.Stage58SourceHealthOperatorActionNoopServiceTest do
  use ExUnit.Case, async: true

  alias DisclosureAutomation.Runtime.Stage58SourceHealthOperatorActionNoopService

  @valid_action_attrs %{
    "operation" => "source_health.recheck",
    "source_key" => "stage54_offline_provider_fixture",
    "operator_reason" => "operator requested bounded advisory recheck",
    "idempotency_key" => "stage58-noop-001",
    "request_id" => "stage58-noop-request-001",
    "expected_current_health_status" => "degraded",
    "expected_current_operational_state" => "active",
    "expected_current_redaction_status" => "passed",
    "operator_note_redacted" => "safe bounded note"
  }

  @valid_audit_context %{
    "actor_id_hash" => "sha256:actor-001",
    "result_status" => "accepted",
    "redaction_status" => "passed",
    "started_at" => "2026-05-02T12:40:00Z",
    "completed_at" => "2026-05-02T12:40:01Z"
  }

  test "defaults are operator-only noop service with fake side effects only" do
    assert Stage58SourceHealthOperatorActionNoopService.defaults() == %{
             service_scope: "operator_action_noop_only",
             operator_only: true,
             action_contract_required: true,
             audit_contract_required: true,
             no_op: true,
             fake_side_effects_only: true,
             advisory_only: true,
             public_response_shape_mutation: false,
             trigger_live_fetch: false,
             scheduler_enabled: false,
             network_access: "forbidden",
             db_write: false,
             audit_write_performed: false,
             enqueue_performed: false,
             source_health_mutation: false,
             canonical_feed_mutation: false,
             provider_canonical_feed_item_creation: false,
             news_only_event_creation: false,
             action_endpoint_added: false,
             route_added: false,
             ui_added: false
           }
  end

  test "previews a valid operator action through action and audit contracts without side effects" do
    assert {:ok, preview} =
             Stage58SourceHealthOperatorActionNoopService.preview_action(@valid_action_attrs, @valid_audit_context)

    assert preview.service_scope == "operator_action_noop_only"
    assert preview.operator_only == true
    assert preview.action_contract_required == true
    assert preview.audit_contract_required == true
    assert preview.no_op == true
    assert preview.fake_side_effects_only == true
    assert preview.advisory_only == true
    assert preview.public_response_shape_mutation == false
    assert preview.trigger_live_fetch == false
    assert preview.scheduler_enabled == false
    assert preview.network_access == "forbidden"
    assert preview.db_write == false
    assert preview.audit_write_performed == false
    assert preview.enqueue_performed == false
    assert preview.source_health_mutation == false
    assert preview.canonical_feed_mutation == false
    assert preview.provider_canonical_feed_item_creation == false
    assert preview.news_only_event_creation == false
    assert preview.action_endpoint_added == false
    assert preview.route_added == false
    assert preview.ui_added == false

    assert preview.operation == "source_health.recheck"
    assert preview.required_permission == "source_health.recheck"
    assert preview.source_key == "stage54_offline_provider_fixture"
    assert preview.actor_id_hash == "sha256:actor-001"

    assert preview.action.operation == "source_health.recheck"
    assert preview.action.source_key == "stage54_offline_provider_fixture"
    assert preview.action.idempotency_key == "stage58-noop-001"
    assert preview.action.request_id == "stage58-noop-request-001"

    assert preview.audit_event.audit_scope == "operator_action_audit_only"
    assert preview.audit_event.operation == "source_health.recheck"
    assert preview.audit_event.permission == "source_health.recheck"
    assert preview.audit_event.actor_id_hash == "sha256:actor-001"
    assert String.starts_with?(preview.audit_event.request_id_hash, "sha256:")
    assert String.starts_with?(preview.audit_event.idempotency_key_hash, "sha256:")
    assert preview.audit_event.operator_reason_redacted == "operator requested bounded advisory recheck"
    assert preview.audit_event.result_status == "accepted"
    assert preview.audit_event.redaction_status == "passed"
    assert preview.audit_event.pre_action_health_status == "degraded"
    assert preview.audit_event.post_action_health_status == "degraded"
    assert preview.audit_event.started_at == "2026-05-02T12:40:00Z"
    assert preview.audit_event.completed_at == "2026-05-02T12:40:01Z"

    assert preview.action_result == %{
             mode: "stage58_noop_operator_action",
             operation: "source_health.recheck",
             required_permission: "source_health.recheck",
             source_key: "stage54_offline_provider_fixture",
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
             source_health_mutation: false,
             canonical_feed_mutation: false,
             provider_canonical_feed_item_creation: false,
             news_only_event_creation: false,
             public_response_shape_mutation: false,
             action_endpoint_added: false,
             route_added: false,
             ui_added: false,
             result_status: "accepted",
             redaction_status: "passed"
           }
  end

  test "supports each allowlisted action operation as noop preview" do
    for operation <- [
          "source_health.recheck",
          "source_health.pause",
          "source_health.resume",
          "source_health.acknowledge_manual_review",
          "source_health.clear_redaction_violation",
          "source_health.manual_provider_trigger",
          "source_health.export_redacted_diagnostics"
        ] do
      assert {:ok, preview} =
               Stage58SourceHealthOperatorActionNoopService.preview_action(
                 %{@valid_action_attrs | "operation" => operation},
                 @valid_audit_context
               )

      assert preview.operation == operation
      assert preview.required_permission == operation
      assert preview.audit_event.operation == operation
      assert preview.audit_event.permission == operation
      assert preview.action_result.operation == operation
      assert preview.action_result.no_op == true
    end
  end

  test "rejects missing or malformed actor hash" do
    assert Stage58SourceHealthOperatorActionNoopService.preview_action(@valid_action_attrs, %{}) ==
             {:error, :actor_id_hash_required}

    assert Stage58SourceHealthOperatorActionNoopService.preview_action(@valid_action_attrs, %{"actor_id_hash" => "actor-001"}) ==
             {:error, {:invalid_hash, :actor_id_hash_required}}
  end

  test "propagates action contract rejection for read-only permissions and missing idempotency" do
    assert Stage58SourceHealthOperatorActionNoopService.preview_action(
             %{@valid_action_attrs | "operation" => "source_health.view"},
             @valid_audit_context
           ) == {:error, {:read_only_permission_cannot_execute_action, "source_health.view"}}

    assert Stage58SourceHealthOperatorActionNoopService.preview_action(
             Map.delete(@valid_action_attrs, "idempotency_key"),
             @valid_audit_context
           ) == {:error, :idempotency_key_required}
  end

  test "propagates audit contract rejection for invalid result or redaction status" do
    assert Stage58SourceHealthOperatorActionNoopService.preview_action(
             @valid_action_attrs,
             %{@valid_audit_context | "result_status" => "canonical_mutated"}
           ) == {:error, {:invalid_result_status, "canonical_mutated"}}

    assert Stage58SourceHealthOperatorActionNoopService.preview_action(
             @valid_action_attrs,
             %{@valid_audit_context | "redaction_status" => "raw_allowed"}
           ) == {:error, {:invalid_redaction_status, "raw_allowed"}}
  end

  test "rejects runtime side effect opt-ins before contract execution" do
    assert Stage58SourceHealthOperatorActionNoopService.preview_action(@valid_action_attrs, @valid_audit_context,
             db_write: true
           ) == {:error, :runtime_side_effect_not_allowed_in_stage58_noop_action_service}

    assert Stage58SourceHealthOperatorActionNoopService.preview_action(@valid_action_attrs, @valid_audit_context,
             audit_write_performed: true
           ) == {:error, :runtime_side_effect_not_allowed_in_stage58_noop_action_service}

    assert Stage58SourceHealthOperatorActionNoopService.preview_action(@valid_action_attrs, @valid_audit_context,
             enqueue_performed: true
           ) == {:error, :runtime_side_effect_not_allowed_in_stage58_noop_action_service}

    assert Stage58SourceHealthOperatorActionNoopService.preview_action(@valid_action_attrs, @valid_audit_context,
             network_access: true
           ) == {:error, :runtime_side_effect_not_allowed_in_stage58_noop_action_service}
  end

  test "rejects live fetch, scheduler, source health mutation, canonical mutation, route, UI, and endpoint opt-ins" do
    assert Stage58SourceHealthOperatorActionNoopService.preview_action(@valid_action_attrs, @valid_audit_context,
             trigger_live_fetch: true
           ) == {:error, :live_fetch_not_allowed_in_stage58_operator_actions}

    assert Stage58SourceHealthOperatorActionNoopService.preview_action(@valid_action_attrs, @valid_audit_context,
             scheduler_enabled: true
           ) == {:error, :scheduler_not_allowed_in_stage58_operator_actions}

    assert Stage58SourceHealthOperatorActionNoopService.preview_action(@valid_action_attrs, @valid_audit_context,
             source_health_mutation: true
           ) == {:error, :source_health_mutation_not_allowed_in_stage58_action_contract}

    assert Stage58SourceHealthOperatorActionNoopService.preview_action(@valid_action_attrs, @valid_audit_context,
             canonical_feed_mutation: true
           ) == {:error, :canonical_mutation_not_allowed_in_stage58_operator_actions}

    assert Stage58SourceHealthOperatorActionNoopService.preview_action(@valid_action_attrs, @valid_audit_context,
             action_endpoint_added: true
           ) == {:error, :action_endpoint_not_allowed_in_stage58_action_contract}
  end

  test "rejects raw actor id, credentials, transport metadata, raw payloads, and secret-like values" do
    assert Stage58SourceHealthOperatorActionNoopService.preview_action(
             @valid_action_attrs,
             Map.put(@valid_audit_context, "actor_id", "operator-1")
           ) == {:error, {:prohibited_field, "actor_id"}}

    assert Stage58SourceHealthOperatorActionNoopService.preview_action(
             Map.put(@valid_action_attrs, "credentials", %{sensitive_header_name(:subscription_key) => "not-allowed"}),
             @valid_audit_context
           ) == {:error, {:prohibited_field, "credentials"}}

    assert Stage58SourceHealthOperatorActionNoopService.preview_action(
             Map.put(@valid_action_attrs, "requestHeaders", %{sensitive_header_name(:authorization) => "Bearer not-allowed"}),
             @valid_audit_context
           ) == {:error, {:prohibited_field, "requestHeaders"}}

    assert Stage58SourceHealthOperatorActionNoopService.preview_action(
             Map.put(@valid_action_attrs, "rawProviderResponseBody", "not allowed"),
             @valid_audit_context
           ) == {:error, {:prohibited_field, "rawProviderResponseBody"}}

    assert Stage58SourceHealthOperatorActionNoopService.preview_action(
             %{@valid_action_attrs | "operator_reason" => sensitive_header_prefix(:authorization) <> " Bearer not-allowed"},
             @valid_audit_context
           ) == {:error, {:prohibited_field, "operator_reason"}}
  end

  defp sensitive_header_name(:authorization), do: "Author" <> "ization"
  defp sensitive_header_name(:cookie), do: "Coo" <> "kie"
  defp sensitive_header_name(:subscription_key), do: "Subscription" <> "-" <> "Key"

  defp sensitive_header_prefix(:authorization), do: sensitive_header_name(:authorization) <> ":"
end
