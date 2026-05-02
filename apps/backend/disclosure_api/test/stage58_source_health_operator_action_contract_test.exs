defmodule DisclosureAutomation.Stage58SourceHealthOperatorActionContractTest do
  use ExUnit.Case, async: true

  alias DisclosureAutomation.Runtime.Stage58SourceHealthOperatorActionContract

  @valid_attrs %{
    "operation" => "source_health.recheck",
    "source_key" => "stage54_offline_provider_fixture",
    "operator_reason" => "operator requested bounded advisory recheck",
    "idempotency_key" => "stage58-recheck-001",
    "request_id" => "stage58-request-001",
    "expected_current_health_status" => "degraded",
    "expected_current_operational_state" => "active",
    "expected_current_redaction_status" => "passed",
    "operator_note_redacted" => "safe bounded note"
  }

  test "defaults are operator-only, action-permission required, audited, and no-side-effect" do
    assert Stage58SourceHealthOperatorActionContract.defaults() == %{
             action_scope: "operator_only",
             read_only_permission_allowed: false,
             action_permission_required: true,
             operator_reason_required: true,
             idempotency_required: true,
             audit_required: true,
             advisory_only: true,
             public_response_shape_mutation: false,
             trigger_live_fetch: false,
             scheduler_enabled: false,
             network_access: "forbidden",
             action_endpoint_added: false,
             route_added: false,
             ui_added: false,
             source_health_mutation: false,
             canonical_feed_mutation: false,
             provider_canonical_feed_item_creation: false,
             news_only_event_creation: false
           }
  end

  test "validates an operator action envelope with bounded redacted fields" do
    assert {:ok, action} = Stage58SourceHealthOperatorActionContract.validate_action(@valid_attrs)

    assert action.action_scope == "operator_only"
    assert action.read_only_permission_allowed == false
    assert action.action_permission_required == true
    assert action.operator_reason_required == true
    assert action.idempotency_required == true
    assert action.audit_required == true
    assert action.advisory_only == true
    assert action.public_response_shape_mutation == false
    assert action.trigger_live_fetch == false
    assert action.scheduler_enabled == false
    assert action.network_access == "forbidden"
    assert action.action_endpoint_added == false
    assert action.route_added == false
    assert action.ui_added == false
    assert action.source_health_mutation == false
    assert action.canonical_feed_mutation == false
    assert action.provider_canonical_feed_item_creation == false
    assert action.news_only_event_creation == false

    assert action.operation == "source_health.recheck"
    assert action.required_permission == "source_health.recheck"
    assert action.source_key == "stage54_offline_provider_fixture"
    assert action.operator_reason == "operator requested bounded advisory recheck"
    assert action.idempotency_key == "stage58-recheck-001"
    assert action.request_id == "stage58-request-001"
    assert action.expected_current_health_status == "degraded"
    assert action.expected_current_operational_state == "active"
    assert action.expected_current_redaction_status == "passed"
    assert action.operator_note_redacted == "safe bounded note"
  end

  test "accepts each explicit action operation and maps it to its required permission" do
    for operation <- Stage58SourceHealthOperatorActionContract.allowed_operations() do
      assert {:ok, action} =
               Stage58SourceHealthOperatorActionContract.validate_action(%{@valid_attrs | "operation" => operation})

      assert action.operation == operation
      assert action.required_permission == operation
    end
  end

  test "rejects read-only permissions as action operations" do
    for permission <- Stage58SourceHealthOperatorActionContract.read_only_permissions() do
      assert Stage58SourceHealthOperatorActionContract.validate_action(%{@valid_attrs | "operation" => permission}) ==
               {:error, {:read_only_permission_cannot_execute_action, permission}}
    end
  end

  test "rejects unknown action operations" do
    assert Stage58SourceHealthOperatorActionContract.validate_action(%{@valid_attrs | "operation" => "source_health.view"}) ==
             {:error, {:read_only_permission_cannot_execute_action, "source_health.view"}}

    assert Stage58SourceHealthOperatorActionContract.validate_action(%{@valid_attrs | "operation" => "source_health.delete"}) ==
             {:error, {:invalid_stage58_operator_action_operation, "source_health.delete"}}
  end

  test "requires source key, operator reason, idempotency key, and request id" do
    assert Stage58SourceHealthOperatorActionContract.validate_action(Map.delete(@valid_attrs, "source_key")) ==
             {:error, :source_key_required}

    assert Stage58SourceHealthOperatorActionContract.validate_action(Map.delete(@valid_attrs, "operator_reason")) ==
             {:error, :operator_reason_required}

    assert Stage58SourceHealthOperatorActionContract.validate_action(Map.delete(@valid_attrs, "idempotency_key")) ==
             {:error, :idempotency_key_required}

    assert Stage58SourceHealthOperatorActionContract.validate_action(Map.delete(@valid_attrs, "request_id")) ==
             {:error, :request_id_required}
  end

  test "validates optional expected status fields" do
    assert {:ok, action} =
             Stage58SourceHealthOperatorActionContract.validate_action(%{
               @valid_attrs
               | "expected_current_health_status" => "manual_review_required",
                 "expected_current_operational_state" => "redaction_blocked",
                 "expected_current_redaction_status" => "blocked"
             })

    assert action.expected_current_health_status == "manual_review_required"
    assert action.expected_current_operational_state == "redaction_blocked"
    assert action.expected_current_redaction_status == "blocked"

    assert Stage58SourceHealthOperatorActionContract.validate_action(%{
             @valid_attrs
             | "expected_current_health_status" => "canonical_override"
           }) == {:error, {:invalid_expected_current_health_status, "canonical_override"}}

    assert Stage58SourceHealthOperatorActionContract.validate_action(%{
             @valid_attrs
             | "expected_current_operational_state" => "scheduler_enabled"
           }) == {:error, {:invalid_expected_current_operational_state, "scheduler_enabled"}}

    assert Stage58SourceHealthOperatorActionContract.validate_action(%{
             @valid_attrs
             | "expected_current_redaction_status" => "raw_payload_allowed"
           }) == {:error, {:invalid_expected_current_redaction_status, "raw_payload_allowed"}}
  end

  test "rejects public exposure, live fetch, scheduler, mutation, route, and UI opt-ins" do
    assert Stage58SourceHealthOperatorActionContract.validate_action(@valid_attrs, public_exposure: true) ==
             {:error, :public_exposure_not_allowed_in_stage58_operator_actions}

    assert Stage58SourceHealthOperatorActionContract.validate_action(@valid_attrs, trigger_live_fetch: true) ==
             {:error, :live_fetch_not_allowed_in_stage58_operator_actions}

    assert Stage58SourceHealthOperatorActionContract.validate_action(@valid_attrs, scheduler_enabled: true) ==
             {:error, :scheduler_not_allowed_in_stage58_operator_actions}

    assert Stage58SourceHealthOperatorActionContract.validate_action(@valid_attrs, source_health_mutation: true) ==
             {:error, :source_health_mutation_not_allowed_in_stage58_action_contract}

    assert Stage58SourceHealthOperatorActionContract.validate_action(@valid_attrs, canonical_feed_mutation: true) ==
             {:error, :canonical_mutation_not_allowed_in_stage58_operator_actions}

    assert Stage58SourceHealthOperatorActionContract.validate_action(@valid_attrs, action_endpoint_added: true) ==
             {:error, :action_endpoint_not_allowed_in_stage58_action_contract}
  end

  test "rejects credentials, transport metadata, raw provider payloads, full article text, and secret-like values" do
    assert Stage58SourceHealthOperatorActionContract.validate_action(
             Map.put(@valid_attrs, "credentials", %{sensitive_header_name(:subscription_key) => "not-allowed"})
           ) == {:error, {:prohibited_field, "credentials"}}

    assert Stage58SourceHealthOperatorActionContract.validate_action(
             Map.put(@valid_attrs, "requestHeaders", %{sensitive_header_name(:authorization) => "Bearer not-allowed"})
           ) == {:error, {:prohibited_field, "requestHeaders"}}

    assert Stage58SourceHealthOperatorActionContract.validate_action(
             Map.put(@valid_attrs, "responseHeaders", %{sensitive_header_name(:cookie) => "not-allowed"})
           ) == {:error, {:prohibited_field, "responseHeaders"}}

    assert Stage58SourceHealthOperatorActionContract.validate_action(Map.put(@valid_attrs, "rawProviderResponseBody", "not allowed")) ==
             {:error, {:prohibited_field, "rawProviderResponseBody"}}

    assert Stage58SourceHealthOperatorActionContract.validate_action(Map.put(@valid_attrs, "fullArticleText", "not allowed")) ==
             {:error, {:prohibited_field, "fullArticleText"}}

    assert Stage58SourceHealthOperatorActionContract.validate_action(%{
             @valid_attrs
             | "operator_reason" => sensitive_header_prefix(:authorization) <> " Bearer not-allowed"
           }) == {:error, {:prohibited_field, "operator_reason"}}
  end

  test "builds bounded redacted audit envelope without action side effects" do
    assert {:ok, audit} = Stage58SourceHealthOperatorActionContract.audit_envelope(@valid_attrs)

    assert audit.audit_scope == "operator_action_only"
    assert audit.bounded == true
    assert audit.redacted == true
    assert audit.canonical_feed_mutation == false
    assert audit.public_response_shape_mutation == false
    assert audit.operation == "source_health.recheck"
    assert audit.permission == "source_health.recheck"
    assert audit.source_key == "stage54_offline_provider_fixture"
    assert String.starts_with?(audit.request_id_hash, "sha256:")
    assert String.starts_with?(audit.idempotency_key_hash, "sha256:")
    assert audit.operator_reason_redacted == "operator requested bounded advisory recheck"
    assert audit.result_status == "pending"
    assert audit.redaction_status == "unknown"
    assert audit.failure_code_redacted == nil

    refute audit.request_id_hash == "stage58-request-001"
    refute audit.idempotency_key_hash == "stage58-recheck-001"
  end

  test "rejects prohibited fields in audit envelope" do
    assert Stage58SourceHealthOperatorActionContract.audit_envelope(Map.put(@valid_attrs, "canonicalFeedItemPayload", %{})) ==
             {:error, {:prohibited_field, "canonicalFeedItemPayload"}}
  end

  defp sensitive_header_name(:authorization), do: "Author" <> "ization"
  defp sensitive_header_name(:cookie), do: "Coo" <> "kie"
  defp sensitive_header_name(:subscription_key), do: "Subscription" <> "-" <> "Key"

  defp sensitive_header_prefix(:authorization), do: sensitive_header_name(:authorization) <> ":"
end
