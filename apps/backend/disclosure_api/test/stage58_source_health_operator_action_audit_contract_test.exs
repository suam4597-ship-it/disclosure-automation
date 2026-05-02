defmodule DisclosureAutomation.Stage58SourceHealthOperatorActionAuditContractTest do
  use ExUnit.Case, async: true

  alias DisclosureAutomation.Runtime.Stage58SourceHealthOperatorActionAuditContract

  @valid_attrs %{
    "operation" => "source_health.recheck",
    "permission" => "source_health.recheck",
    "source_key" => "stage54_offline_provider_fixture",
    "actor_id_hash" => "sha256:actor-001",
    "request_id_hash" => "sha256:request-001",
    "idempotency_key_hash" => "sha256:idempotency-001",
    "operator_reason_redacted" => "operator requested bounded advisory recheck",
    "result_status" => "accepted",
    "redaction_status" => "passed",
    "pre_action_health_status" => "degraded",
    "post_action_health_status" => "healthy",
    "pre_action_operational_state" => "active",
    "post_action_operational_state" => "active",
    "failure_code_redacted" => nil,
    "started_at" => "2026-05-02T12:00:00Z",
    "completed_at" => "2026-05-02T12:00:01Z"
  }

  test "defaults are bounded, redacted, operator-only, and no-side-effect" do
    assert Stage58SourceHealthOperatorActionAuditContract.defaults() == %{
             audit_scope: "operator_action_audit_only",
             bounded: true,
             redacted: true,
             action_attempt_recorded: true,
             operator_only: true,
             advisory_only: true,
             public_response_shape_mutation: false,
             trigger_live_fetch: false,
             scheduler_enabled: false,
             network_access: "forbidden",
             audit_write_performed: false,
             source_health_mutation: false,
             canonical_feed_mutation: false,
             provider_canonical_feed_item_creation: false,
             news_only_event_creation: false,
             action_endpoint_added: false,
             route_added: false,
             ui_added: false
           }
  end

  test "validates a bounded redacted action audit event" do
    assert {:ok, audit} = Stage58SourceHealthOperatorActionAuditContract.validate_event(@valid_attrs)

    assert audit.audit_scope == "operator_action_audit_only"
    assert audit.bounded == true
    assert audit.redacted == true
    assert audit.action_attempt_recorded == true
    assert audit.operator_only == true
    assert audit.advisory_only == true
    assert audit.public_response_shape_mutation == false
    assert audit.trigger_live_fetch == false
    assert audit.scheduler_enabled == false
    assert audit.network_access == "forbidden"
    assert audit.audit_write_performed == false
    assert audit.source_health_mutation == false
    assert audit.canonical_feed_mutation == false
    assert audit.provider_canonical_feed_item_creation == false
    assert audit.news_only_event_creation == false
    assert audit.action_endpoint_added == false
    assert audit.route_added == false
    assert audit.ui_added == false

    assert audit.operation == "source_health.recheck"
    assert audit.permission == "source_health.recheck"
    assert audit.source_key == "stage54_offline_provider_fixture"
    assert audit.actor_id_hash == "sha256:actor-001"
    assert audit.request_id_hash == "sha256:request-001"
    assert audit.idempotency_key_hash == "sha256:idempotency-001"
    assert audit.operator_reason_redacted == "operator requested bounded advisory recheck"
    assert audit.result_status == "accepted"
    assert audit.redaction_status == "passed"
    assert audit.pre_action_health_status == "degraded"
    assert audit.post_action_health_status == "healthy"
    assert audit.pre_action_operational_state == "active"
    assert audit.post_action_operational_state == "active"
    assert audit.failure_code_redacted == nil
    assert audit.started_at == "2026-05-02T12:00:00Z"
    assert audit.completed_at == "2026-05-02T12:00:01Z"
  end

  test "accepts each action operation when permission matches" do
    for operation <- Stage58SourceHealthOperatorActionAuditContract.allowed_operations() do
      assert {:ok, audit} =
               Stage58SourceHealthOperatorActionAuditContract.validate_event(%{
                 @valid_attrs
                 | "operation" => operation,
                   "permission" => operation
               })

      assert audit.operation == operation
      assert audit.permission == operation
    end
  end

  test "rejects read-only permissions as operations or authorizing permissions" do
    assert Stage58SourceHealthOperatorActionAuditContract.validate_event(%{
             @valid_attrs
             | "operation" => "source_health.view",
               "permission" => "source_health.view"
           }) == {:error, {:read_only_permission_cannot_be_audited_as_action, "source_health.view"}}

    assert Stage58SourceHealthOperatorActionAuditContract.validate_event(%{
             @valid_attrs
             | "permission" => "source_health.detail"
           }) ==
             {:error,
              {:read_only_permission_cannot_authorize_action_audit, "source_health.detail", "source_health.recheck"}}
  end

  test "rejects permission mismatch and unknown operations" do
    assert Stage58SourceHealthOperatorActionAuditContract.validate_event(%{
             @valid_attrs
             | "permission" => "source_health.pause"
           }) == {:error, {:permission_mismatch, "source_health.pause", "source_health.recheck"}}

    assert Stage58SourceHealthOperatorActionAuditContract.validate_event(%{
             @valid_attrs
             | "operation" => "source_health.delete",
               "permission" => "source_health.delete"
           }) == {:error, {:invalid_stage58_operator_action_operation, "source_health.delete"}}
  end

  test "requires hashes and redacted reason" do
    assert Stage58SourceHealthOperatorActionAuditContract.validate_event(Map.delete(@valid_attrs, "actor_id_hash")) ==
             {:error, :actor_id_hash_required}

    assert Stage58SourceHealthOperatorActionAuditContract.validate_event(Map.delete(@valid_attrs, "request_id_hash")) ==
             {:error, :request_id_hash_required}

    assert Stage58SourceHealthOperatorActionAuditContract.validate_event(Map.delete(@valid_attrs, "idempotency_key_hash")) ==
             {:error, :idempotency_key_hash_required}

    assert Stage58SourceHealthOperatorActionAuditContract.validate_event(Map.delete(@valid_attrs, "operator_reason_redacted")) ==
             {:error, :operator_reason_redacted_required}

    assert Stage58SourceHealthOperatorActionAuditContract.validate_event(%{@valid_attrs | "actor_id_hash" => "actor-001"}) ==
             {:error, {:invalid_hash, :actor_id_hash_required}}
  end

  test "validates result, redaction, health, and operational states" do
    for status <- Stage58SourceHealthOperatorActionAuditContract.allowed_result_statuses() do
      assert {:ok, audit} = Stage58SourceHealthOperatorActionAuditContract.validate_event(%{@valid_attrs | "result_status" => status})
      assert audit.result_status == status
    end

    for status <- Stage58SourceHealthOperatorActionAuditContract.allowed_redaction_statuses() do
      assert {:ok, audit} = Stage58SourceHealthOperatorActionAuditContract.validate_event(%{@valid_attrs | "redaction_status" => status})
      assert audit.redaction_status == status
    end

    assert Stage58SourceHealthOperatorActionAuditContract.validate_event(%{@valid_attrs | "result_status" => "canonical_mutated"}) ==
             {:error, {:invalid_result_status, "canonical_mutated"}}

    assert Stage58SourceHealthOperatorActionAuditContract.validate_event(%{@valid_attrs | "redaction_status" => "raw_allowed"}) ==
             {:error, {:invalid_redaction_status, "raw_allowed"}}

    assert Stage58SourceHealthOperatorActionAuditContract.validate_event(%{@valid_attrs | "pre_action_health_status" => "live_fetching"}) ==
             {:error, {:invalid_pre_action_health_status, "live_fetching"}}

    assert Stage58SourceHealthOperatorActionAuditContract.validate_event(%{@valid_attrs | "post_action_operational_state" => "scheduler_enabled"}) ==
             {:error, {:invalid_post_action_operational_state, "scheduler_enabled"}}
  end

  test "rejects runtime side effect opt-ins" do
    assert Stage58SourceHealthOperatorActionAuditContract.validate_event(@valid_attrs, public_exposure: true) ==
             {:error, :public_exposure_not_allowed_in_stage58_action_audit_contract}

    assert Stage58SourceHealthOperatorActionAuditContract.validate_event(@valid_attrs, trigger_live_fetch: true) ==
             {:error, :live_fetch_not_allowed_in_stage58_action_audit_contract}

    assert Stage58SourceHealthOperatorActionAuditContract.validate_event(@valid_attrs, scheduler_enabled: true) ==
             {:error, :scheduler_not_allowed_in_stage58_action_audit_contract}

    assert Stage58SourceHealthOperatorActionAuditContract.validate_event(@valid_attrs, db_write: true) ==
             {:error, :runtime_side_effect_not_allowed_in_stage58_action_audit_contract}

    assert Stage58SourceHealthOperatorActionAuditContract.validate_event(@valid_attrs, audit_write_performed: true) ==
             {:error, :runtime_side_effect_not_allowed_in_stage58_action_audit_contract}

    assert Stage58SourceHealthOperatorActionAuditContract.validate_event(@valid_attrs, source_health_mutation: true) ==
             {:error, :source_health_mutation_not_allowed_in_stage58_action_audit_contract}

    assert Stage58SourceHealthOperatorActionAuditContract.validate_event(@valid_attrs, canonical_feed_mutation: true) ==
             {:error, :canonical_mutation_not_allowed_in_stage58_action_audit_contract}

    assert Stage58SourceHealthOperatorActionAuditContract.validate_event(@valid_attrs, action_endpoint_added: true) ==
             {:error, :action_endpoint_not_allowed_in_stage58_action_audit_contract}
  end

  test "rejects raw actor/request/idempotency/operator reason fields" do
    assert Stage58SourceHealthOperatorActionAuditContract.validate_event(Map.put(@valid_attrs, "actor_id", "operator-1")) ==
             {:error, {:prohibited_field, "actor_id"}}

    assert Stage58SourceHealthOperatorActionAuditContract.validate_event(Map.put(@valid_attrs, "request_id", "request-raw")) ==
             {:error, {:prohibited_field, "request_id"}}

    assert Stage58SourceHealthOperatorActionAuditContract.validate_event(Map.put(@valid_attrs, "idempotency_key", "idempotency-raw")) ==
             {:error, {:prohibited_field, "idempotency_key"}}

    assert Stage58SourceHealthOperatorActionAuditContract.validate_event(Map.put(@valid_attrs, "operator_reason", "raw reason")) ==
             {:error, {:prohibited_field, "operator_reason"}}
  end

  test "rejects credentials, transport metadata, raw payloads, full article text, canonical payloads, and secret-like values" do
    assert Stage58SourceHealthOperatorActionAuditContract.validate_event(
             Map.put(@valid_attrs, "credentials", %{sensitive_header_name(:subscription_key) => "not-allowed"})
           ) == {:error, {:prohibited_field, "credentials"}}

    assert Stage58SourceHealthOperatorActionAuditContract.validate_event(
             Map.put(@valid_attrs, "requestHeaders", %{sensitive_header_name(:authorization) => "Bearer not-allowed"})
           ) == {:error, {:prohibited_field, "requestHeaders"}}

    assert Stage58SourceHealthOperatorActionAuditContract.validate_event(
             Map.put(@valid_attrs, "responseHeaders", %{sensitive_header_name(:cookie) => "not-allowed"})
           ) == {:error, {:prohibited_field, "responseHeaders"}}

    assert Stage58SourceHealthOperatorActionAuditContract.validate_event(Map.put(@valid_attrs, "rawProviderResponseBody", "not allowed")) ==
             {:error, {:prohibited_field, "rawProviderResponseBody"}}

    assert Stage58SourceHealthOperatorActionAuditContract.validate_event(Map.put(@valid_attrs, "fullArticleText", "not allowed")) ==
             {:error, {:prohibited_field, "fullArticleText"}}

    assert Stage58SourceHealthOperatorActionAuditContract.validate_event(Map.put(@valid_attrs, "canonicalFeedItemPayload", %{})) ==
             {:error, {:prohibited_field, "canonicalFeedItemPayload"}}

    assert Stage58SourceHealthOperatorActionAuditContract.validate_event(%{
             @valid_attrs
             | "operator_reason_redacted" => sensitive_header_prefix(:authorization) <> " Bearer not-allowed"
           }) == {:error, {:prohibited_field, "operator_reason_redacted"}}
  end

  defp sensitive_header_name(:authorization), do: "Author" <> "ization"
  defp sensitive_header_name(:cookie), do: "Coo" <> "kie"
  defp sensitive_header_name(:subscription_key), do: "Subscription" <> "-" <> "Key"

  defp sensitive_header_prefix(:authorization), do: sensitive_header_name(:authorization) <> ":"
end
