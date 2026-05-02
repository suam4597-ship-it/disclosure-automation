defmodule DisclosureAutomation.Stage58SourceHealthOperatorActionAuthorizationGateTest do
  use ExUnit.Case, async: true

  alias DisclosureAutomation.Runtime.Stage58SourceHealthOperatorActionAuthorizationGate

  @valid_action_attrs %{
    "operation" => "source_health.recheck",
    "source_key" => "stage54_offline_provider_fixture",
    "operator_reason" => "operator requested bounded advisory recheck",
    "idempotency_key" => "stage58-authz-001",
    "request_id" => "stage58-authz-request-001",
    "expected_current_health_status" => "degraded",
    "expected_current_operational_state" => "active",
    "expected_current_redaction_status" => "passed"
  }

  @valid_actor_context %{
    "authenticated" => true,
    "roles" => ["operator"],
    "permissions" => ["source_health.recheck"],
    "source_keys" => ["stage54_offline_provider_fixture"],
    "actor_id_hash" => "sha256:actor-001",
    "result_status" => "accepted",
    "redaction_status" => "passed"
  }

  test "defaults are operator-only authorization gate with no side effects" do
    assert Stage58SourceHealthOperatorActionAuthorizationGate.defaults() == %{
             authorization_scope: "operator_action_authorization_gate_only",
             authenticated_required: true,
             operator_role_required: true,
             action_permission_required: true,
             source_authorization_required: true,
             read_only_permissions_allowed_for_actions: false,
             no_op_preview_only: true,
             operator_only: true,
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

  test "authorizes an operator action and returns a no-op preview only" do
    assert {:ok, result} =
             Stage58SourceHealthOperatorActionAuthorizationGate.authorize_noop_preview(
               @valid_action_attrs,
               @valid_actor_context
             )

    assert result.authorization_scope == "operator_action_authorization_gate_only"
    assert result.authenticated_required == true
    assert result.operator_role_required == true
    assert result.action_permission_required == true
    assert result.source_authorization_required == true
    assert result.read_only_permissions_allowed_for_actions == false
    assert result.no_op_preview_only == true
    assert result.operator_only == true
    assert result.advisory_only == true
    assert result.public_response_shape_mutation == false
    assert result.trigger_live_fetch == false
    assert result.scheduler_enabled == false
    assert result.network_access == "forbidden"
    assert result.db_write == false
    assert result.audit_write_performed == false
    assert result.enqueue_performed == false
    assert result.source_health_mutation == false
    assert result.canonical_feed_mutation == false
    assert result.provider_canonical_feed_item_creation == false
    assert result.news_only_event_creation == false
    assert result.action_endpoint_added == false
    assert result.route_added == false
    assert result.ui_added == false

    assert result.operation == "source_health.recheck"
    assert result.required_permission == "source_health.recheck"
    assert result.source_key == "stage54_offline_provider_fixture"
    assert result.actor_id_hash == "sha256:actor-001"
    assert result.authorized == true
    assert result.authorization_result == "allowed_noop_preview"

    assert result.preview.no_op == true
    assert result.preview.fake_side_effects_only == true
    assert result.preview.action_result.no_op == true
    assert result.preview.action_result.db_write == false
    assert result.preview.action_result.audit_write_performed == false
    assert result.preview.action_result.enqueue_performed == false
    assert result.preview.action_result.canonical_feed_mutation == false
  end

  test "allows admin role and wildcard source authorization" do
    actor_context = %{
      @valid_actor_context
      | "roles" => ["admin"],
        "source_keys" => ["*"],
        "permissions" => ["source_health.pause"]
    }

    action_attrs = %{@valid_action_attrs | "operation" => "source_health.pause"}

    assert {:ok, result} = Stage58SourceHealthOperatorActionAuthorizationGate.authorize_noop_preview(action_attrs, actor_context)
    assert result.operation == "source_health.pause"
    assert result.required_permission == "source_health.pause"
  end

  test "rejects unauthenticated or non-operator actor contexts" do
    assert Stage58SourceHealthOperatorActionAuthorizationGate.authorize_noop_preview(
             @valid_action_attrs,
             %{@valid_actor_context | "authenticated" => false}
           ) == {:error, :operator_action_authentication_required}

    assert Stage58SourceHealthOperatorActionAuthorizationGate.authorize_noop_preview(
             @valid_action_attrs,
             %{@valid_actor_context | "roles" => ["viewer"]}
           ) == {:error, :operator_or_admin_role_required}
  end

  test "rejects missing action permission and read-only permission attempts" do
    assert Stage58SourceHealthOperatorActionAuthorizationGate.authorize_noop_preview(
             @valid_action_attrs,
             %{@valid_actor_context | "permissions" => []}
           ) == {:error, {:missing_action_permission, "source_health.recheck"}}

    assert Stage58SourceHealthOperatorActionAuthorizationGate.authorize_noop_preview(
             @valid_action_attrs,
             %{@valid_actor_context | "permissions" => ["source_health.view"]}
           ) == {:error, {:read_only_permission_cannot_authorize_action, "source_health.recheck"}}
  end

  test "rejects unauthorized source key" do
    assert Stage58SourceHealthOperatorActionAuthorizationGate.authorize_noop_preview(
             @valid_action_attrs,
             %{@valid_actor_context | "source_keys" => ["other_source"]}
           ) == {:error, {:source_not_authorized, "stage54_offline_provider_fixture"}}
  end

  test "rejects malformed or missing actor hash" do
    assert Stage58SourceHealthOperatorActionAuthorizationGate.authorize_noop_preview(
             @valid_action_attrs,
             Map.delete(@valid_actor_context, "actor_id_hash")
           ) == {:error, :actor_id_hash_required}

    assert Stage58SourceHealthOperatorActionAuthorizationGate.authorize_noop_preview(
             @valid_action_attrs,
             %{@valid_actor_context | "actor_id_hash" => "actor-001"}
           ) == {:error, {:invalid_hash, :actor_id_hash_required}}
  end

  test "rejects unknown context keys and raw actor id" do
    assert Stage58SourceHealthOperatorActionAuthorizationGate.authorize_noop_preview(
             @valid_action_attrs,
             Map.put(@valid_actor_context, "unexpected", "value")
           ) == {:error, {:unknown_authorization_context_key, "unexpected"}}

    assert Stage58SourceHealthOperatorActionAuthorizationGate.authorize_noop_preview(
             @valid_action_attrs,
             Map.put(@valid_actor_context, "actor_id", "operator-1")
           ) == {:error, {:prohibited_field, "actor_id"}}
  end

  test "propagates action contract rejection" do
    assert Stage58SourceHealthOperatorActionAuthorizationGate.authorize_noop_preview(
             %{@valid_action_attrs | "operation" => "source_health.view"},
             @valid_actor_context
           ) == {:error, {:read_only_permission_cannot_execute_action, "source_health.view"}}
  end

  test "propagates no-op service audit contract rejection" do
    assert Stage58SourceHealthOperatorActionAuthorizationGate.authorize_noop_preview(
             @valid_action_attrs,
             %{@valid_actor_context | "result_status" => "canonical_mutated"}
           ) == {:error, {:invalid_result_status, "canonical_mutated"}}
  end

  test "rejects side-effect opt-ins" do
    assert Stage58SourceHealthOperatorActionAuthorizationGate.authorize_noop_preview(
             @valid_action_attrs,
             @valid_actor_context,
             db_write: true
           ) == {:error, :runtime_side_effect_not_allowed_in_stage58_authorization_gate}

    assert Stage58SourceHealthOperatorActionAuthorizationGate.authorize_noop_preview(
             @valid_action_attrs,
             @valid_actor_context,
             audit_write_performed: true
           ) == {:error, :runtime_side_effect_not_allowed_in_stage58_authorization_gate}

    assert Stage58SourceHealthOperatorActionAuthorizationGate.authorize_noop_preview(
             @valid_action_attrs,
             @valid_actor_context,
             enqueue_performed: true
           ) == {:error, :runtime_side_effect_not_allowed_in_stage58_authorization_gate}
  end

  test "rejects live fetch, scheduler, mutation, route, UI, and endpoint opt-ins" do
    assert Stage58SourceHealthOperatorActionAuthorizationGate.authorize_noop_preview(
             @valid_action_attrs,
             @valid_actor_context,
             trigger_live_fetch: true
           ) == {:error, :live_fetch_not_allowed_in_stage58_operator_actions}

    assert Stage58SourceHealthOperatorActionAuthorizationGate.authorize_noop_preview(
             @valid_action_attrs,
             @valid_actor_context,
             scheduler_enabled: true
           ) == {:error, :scheduler_not_allowed_in_stage58_operator_actions}

    assert Stage58SourceHealthOperatorActionAuthorizationGate.authorize_noop_preview(
             @valid_action_attrs,
             @valid_actor_context,
             source_health_mutation: true
           ) == {:error, :source_health_mutation_not_allowed_in_stage58_action_contract}

    assert Stage58SourceHealthOperatorActionAuthorizationGate.authorize_noop_preview(
             @valid_action_attrs,
             @valid_actor_context,
             canonical_feed_mutation: true
           ) == {:error, :canonical_mutation_not_allowed_in_stage58_operator_actions}

    assert Stage58SourceHealthOperatorActionAuthorizationGate.authorize_noop_preview(
             @valid_action_attrs,
             @valid_actor_context,
             action_endpoint_added: true
           ) == {:error, :action_endpoint_not_allowed_in_stage58_action_contract}
  end

  test "rejects credentials and secret-like values" do
    assert Stage58SourceHealthOperatorActionAuthorizationGate.authorize_noop_preview(
             Map.put(@valid_action_attrs, "credentials", %{sensitive_header_name(:subscription_key) => "not-allowed"}),
             @valid_actor_context
           ) == {:error, {:prohibited_field, "credentials"}}

    assert Stage58SourceHealthOperatorActionAuthorizationGate.authorize_noop_preview(
             Map.put(@valid_action_attrs, "requestHeaders", %{sensitive_header_name(:authorization) => "Bearer not-allowed"}),
             @valid_actor_context
           ) == {:error, {:prohibited_field, "requestHeaders"}}

    assert Stage58SourceHealthOperatorActionAuthorizationGate.authorize_noop_preview(
             %{@valid_action_attrs | "operator_reason" => sensitive_header_prefix(:authorization) <> " Bearer not-allowed"},
             @valid_actor_context
           ) == {:error, {:prohibited_field, "operator_reason"}}
  end

  defp sensitive_header_name(:authorization), do: "Author" <> "ization"
  defp sensitive_header_name(:subscription_key), do: "Subscription" <> "-" <> "Key"

  defp sensitive_header_prefix(:authorization), do: sensitive_header_name(:authorization) <> ":"
end
