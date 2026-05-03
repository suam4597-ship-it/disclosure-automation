defmodule DisclosureAutomation.Stage60DuplicateGroupOperatorActionAuthorizationGateTest do
  use ExUnit.Case, async: true

  alias DisclosureAutomation.Runtime.Stage60DuplicateGroupOperatorActionAuthorizationGate

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

  @valid_actor_context %{
    "authenticated" => true,
    "roles" => ["operator"],
    "permissions" => ["duplicate_group:confirm"],
    "actor_id_hash" => "sha256:operator-001",
    "result_status" => "accepted",
    "redaction_status" => "passed",
    "pre_review_state" => "unknown",
    "post_review_state" => "confirmed_by_operator",
    "created_at" => "2026-05-03T05:22:00Z"
  }

  test "defaults are operator-only authorization gate with no side effects" do
    assert Stage60DuplicateGroupOperatorActionAuthorizationGate.defaults() == %{
             authorization_scope: "operator_only_duplicate_group_action_authorization_gate",
             authenticated_required: true,
             operator_role_required: true,
             action_permission_required: true,
             read_only_permissions_allowed_for_actions: false,
             actor_hash_required: true,
             no_op_preview_only: true,
             operator_only: true,
             advisory_only: true,
             non_canonical: true,
             bounded: true,
             redacted: true,
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

  test "authorizes operator no-op preview when action and actor context are valid" do
    assert {:ok, authorized} =
             Stage60DuplicateGroupOperatorActionAuthorizationGate.authorize_noop_preview(
               @valid_action_attrs,
               @valid_actor_context
             )

    assert authorized.authorization_scope == "operator_only_duplicate_group_action_authorization_gate"
    assert authorized.authenticated_required == true
    assert authorized.operator_role_required == true
    assert authorized.action_permission_required == true
    assert authorized.read_only_permissions_allowed_for_actions == false
    assert authorized.actor_hash_required == true
    assert authorized.no_op_preview_only == true
    assert authorized.operator_only == true
    assert authorized.advisory_only == true
    assert authorized.non_canonical == true
    assert authorized.bounded == true
    assert authorized.redacted == true
    assert authorized.action_operation == "confirm_duplicate_group"
    assert authorized.required_permission == "duplicate_group:confirm"
    assert authorized.group_id == @group_id
    assert authorized.actor_id_hash == "sha256:operator-001"
    assert authorized.authorized == true
    assert authorized.authorization_result == "allowed_noop_preview"

    assert authorized.public_response_shape_mutation == false
    assert authorized.public_api_duplicate_group_fields == false
    assert authorized.public_feed_duplicate_group_fields == false
    assert authorized.canonical_feed_mutation == false
    assert authorized.provider_canonical_feed_item_creation == false
    assert authorized.news_only_event_creation == false
    assert authorized.official_event_merge == false
    assert authorized.official_fact_override == false
    assert authorized.official_citation_override == false
    assert authorized.trigger_live_fetch == false
    assert authorized.scheduler_enabled == false
    assert authorized.network_access == "forbidden"
    assert authorized.db_write == false
    assert authorized.audit_write_performed == false
    assert authorized.enqueue_performed == false
    assert authorized.materializer_triggered == false
    assert authorized.route_added == false
    assert authorized.ui_added == false
    assert authorized.action_endpoint_added == false
    assert authorized.schema_migration == false

    assert authorized.preview.no_op == true
    assert authorized.preview.action_operation == "confirm_duplicate_group"
    assert authorized.preview.action_result.post_review_state == "confirmed_by_operator"
  end

  test "allows admin role as operator role" do
    context = %{@valid_actor_context | "roles" => ["admin"]}

    assert {:ok, authorized} =
             Stage60DuplicateGroupOperatorActionAuthorizationGate.authorize_noop_preview(@valid_action_attrs, context)

    assert authorized.authorized == true
  end

  test "rejects unauthenticated actor context" do
    assert Stage60DuplicateGroupOperatorActionAuthorizationGate.authorize_noop_preview(
             @valid_action_attrs,
             %{@valid_actor_context | "authenticated" => false}
           ) == {:error, :duplicate_group_action_authentication_required}
  end

  test "rejects actor without operator or admin role" do
    assert Stage60DuplicateGroupOperatorActionAuthorizationGate.authorize_noop_preview(
             @valid_action_attrs,
             %{@valid_actor_context | "roles" => ["viewer"]}
           ) == {:error, :operator_or_admin_role_required}
  end

  test "rejects missing action permission and read-only permission" do
    assert Stage60DuplicateGroupOperatorActionAuthorizationGate.authorize_noop_preview(
             @valid_action_attrs,
             %{@valid_actor_context | "permissions" => []}
           ) == {:error, {:missing_action_permission, "duplicate_group:confirm"}}

    assert Stage60DuplicateGroupOperatorActionAuthorizationGate.authorize_noop_preview(
             @valid_action_attrs,
             %{@valid_actor_context | "permissions" => ["duplicate_group:read"]}
           ) == {:error, {:read_only_permission_cannot_authorize_action, "duplicate_group:confirm"}}
  end

  test "rejects actor hash mismatch and non-hash actor context" do
    assert Stage60DuplicateGroupOperatorActionAuthorizationGate.authorize_noop_preview(
             @valid_action_attrs,
             %{@valid_actor_context | "actor_id_hash" => "sha256:other-operator"}
           ) == {:error, :actor_hash_mismatch}

    assert Stage60DuplicateGroupOperatorActionAuthorizationGate.authorize_noop_preview(
             @valid_action_attrs,
             %{@valid_actor_context | "actor_id_hash" => "operator-raw"}
           ) == {:error, {:invalid_hash, :actor_id_hash_required}}
  end

  test "propagates action contract and no-op service errors" do
    assert Stage60DuplicateGroupOperatorActionAuthorizationGate.authorize_noop_preview(
             %{@valid_action_attrs | "action_operation" => "merge_official_tdnet_events"},
             @valid_actor_context
           ) == {:error, {:invalid_stage60_duplicate_group_action_operation, "merge_official_tdnet_events"}}

    assert Stage60DuplicateGroupOperatorActionAuthorizationGate.authorize_noop_preview(
             @valid_action_attrs,
             %{@valid_actor_context | "post_review_state" => "canonical_merged"}
           ) == {:error, {:invalid_post_review_state, "canonical_merged"}}
  end

  test "rejects unknown actor context keys" do
    assert Stage60DuplicateGroupOperatorActionAuthorizationGate.authorize_noop_preview(
             @valid_action_attrs,
             Map.put(@valid_actor_context, "rawDiagnosticPayload", "blocked")
           ) == {:error, {:unknown_authorization_context_key, "rawDiagnosticPayload"}}
  end

  test "rejects raw actor request idempotency reason and provider material in actor context" do
    forbidden_contexts = [
      Map.put(@valid_actor_context, "actor_id", "operator-raw"),
      Map.put(@valid_actor_context, "actor_email", "operator@example.invalid"),
      Map.put(@valid_actor_context, "request_id", "request-raw"),
      Map.put(@valid_actor_context, "idempotency_key", "idempotency-raw"),
      Map.put(@valid_actor_context, "operator_reason", "raw reason"),
      Map.put(@valid_actor_context, "request" <> "Headers", %{"redacted" => "blocked"}),
      Map.put(@valid_actor_context, "rawProviderResponseBody", "blocked"),
      Map.put(@valid_actor_context, "fullArticleText", "blocked"),
      Map.put(@valid_actor_context, "canonicalFeedItemPayload", %{})
    ]

    Enum.each(forbidden_contexts, fn context ->
      assert {:error, {:prohibited_field, _path}} =
               Stage60DuplicateGroupOperatorActionAuthorizationGate.authorize_noop_preview(@valid_action_attrs, context)
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
               Stage60DuplicateGroupOperatorActionAuthorizationGate.authorize_noop_preview(
                 @valid_action_attrs,
                 @valid_actor_context,
                 [{opt, true}]
               )
    end)
  end
end
