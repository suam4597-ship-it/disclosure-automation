defmodule DisclosureAutomation.Stage60DuplicateGroupOperatorActionAuditContractTest do
  use ExUnit.Case, async: true

  alias DisclosureAutomation.Runtime.Stage60DuplicateGroupOperatorActionAuditContract

  @group_id "duplicate_group:jp.tdnet.4527.20260430.material_information_update"

  @valid_attrs %{
    "group_id" => @group_id,
    "action_operation" => "confirm_duplicate_group",
    "required_permission" => "duplicate_group:confirm",
    "actor_id_hash" => "sha256:operator-001",
    "request_id_hash" => "sha256:request-001",
    "idempotency_key_hash" => "sha256:idempotency-001",
    "operator_reason_redacted" => "REDACTED_OPERATOR_CONFIRMED_DUPLICATE_GROUP",
    "result_status" => "completed",
    "redaction_status" => "passed",
    "pre_review_state" => "unknown",
    "post_review_state" => "confirmed_by_operator",
    "failure_code" => nil,
    "created_at" => "2026-05-03T02:59:00Z"
  }

  test "defaults are bounded operator-only audit contract with no side effects" do
    assert Stage60DuplicateGroupOperatorActionAuditContract.defaults() == %{
             audit_scope: "operator_only_duplicate_group_action_audit",
             bounded: true,
             redacted: true,
             action_attempt_recorded: true,
             operator_only: true,
             advisory_only: true,
             non_canonical: true,
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
             audit_write_performed: false,
             materializer_triggered: false,
             route_added: false,
             ui_added: false,
             action_endpoint_added: false,
             schema_migration: false
           }
  end

  test "validates a completed confirm duplicate group audit event" do
    assert {:ok, event} = Stage60DuplicateGroupOperatorActionAuditContract.validate_event(@valid_attrs)

    assert event.audit_scope == "operator_only_duplicate_group_action_audit"
    assert event.bounded == true
    assert event.redacted == true
    assert event.action_attempt_recorded == true
    assert event.operator_only == true
    assert event.advisory_only == true
    assert event.non_canonical == true
    assert event.action_operation == "confirm_duplicate_group"
    assert event.required_permission == "duplicate_group:confirm"
    assert event.group_id == @group_id
    assert event.actor_id_hash == "sha256:operator-001"
    assert event.request_id_hash == "sha256:request-001"
    assert event.idempotency_key_hash == "sha256:idempotency-001"
    assert event.operator_reason_redacted == "REDACTED_OPERATOR_CONFIRMED_DUPLICATE_GROUP"
    assert event.result_status == "completed"
    assert event.redaction_status == "passed"
    assert event.pre_review_state == "unknown"
    assert event.post_review_state == "confirmed_by_operator"
    assert event.failure_code == nil
    assert event.created_at == "2026-05-03T02:59:00Z"

    assert event.public_response_shape_mutation == false
    assert event.public_api_duplicate_group_fields == false
    assert event.public_feed_duplicate_group_fields == false
    assert event.canonical_feed_mutation == false
    assert event.provider_canonical_feed_item_creation == false
    assert event.news_only_event_creation == false
    assert event.official_event_merge == false
    assert event.official_fact_override == false
    assert event.official_citation_override == false
    assert event.trigger_live_fetch == false
    assert event.scheduler_enabled == false
    assert event.network_access == "forbidden"
    assert event.audit_write_performed == false
    assert event.materializer_triggered == false
    assert event.route_added == false
    assert event.ui_added == false
    assert event.action_endpoint_added == false
    assert event.schema_migration == false
  end

  test "maps each operation to its required action permission" do
    cases = [
      {"confirm_duplicate_group", "duplicate_group:confirm"},
      {"reject_duplicate_group", "duplicate_group:reject"},
      {"mark_duplicate_group_needs_review", "duplicate_group:mark_review"},
      {"clear_duplicate_group_review_state", "duplicate_group:clear_review_state"}
    ]

    Enum.each(cases, fn {operation, permission} ->
      attrs = %{@valid_attrs | "action_operation" => operation, "required_permission" => permission}

      assert {:ok, event} = Stage60DuplicateGroupOperatorActionAuditContract.validate_event(attrs)
      assert event.action_operation == operation
      assert event.required_permission == permission
    end)
  end

  test "rejects read-only permission or mismatched permission" do
    assert Stage60DuplicateGroupOperatorActionAuditContract.validate_event(%{
             @valid_attrs
             | "required_permission" => "duplicate_group:read"
           }) ==
             {:error,
              {:read_only_permission_cannot_authorize_action_audit, "duplicate_group:read", "duplicate_group:confirm"}}

    assert Stage60DuplicateGroupOperatorActionAuditContract.validate_event(%{
             @valid_attrs
             | "required_permission" => "duplicate_group:reject"
           }) == {:error, {:permission_mismatch, "duplicate_group:reject", "duplicate_group:confirm"}}
  end

  test "rejects unknown operation and read permission as operation" do
    assert Stage60DuplicateGroupOperatorActionAuditContract.validate_event(%{
             @valid_attrs
             | "action_operation" => "merge_official_tdnet_events"
           }) == {:error, {:invalid_stage60_duplicate_group_action_operation, "merge_official_tdnet_events"}}

    assert Stage60DuplicateGroupOperatorActionAuditContract.validate_event(%{
             @valid_attrs
             | "action_operation" => "duplicate_group:read"
           }) == {:error, {:read_only_permission_cannot_be_audited_as_action, "duplicate_group:read"}}
  end

  test "requires hash-shaped actor request and idempotency identifiers" do
    assert Stage60DuplicateGroupOperatorActionAuditContract.validate_event(%{
             @valid_attrs
             | "actor_id_hash" => "operator-001"
           }) == {:error, {:invalid_hash, :actor_id_hash_required}}

    assert Stage60DuplicateGroupOperatorActionAuditContract.validate_event(%{
             @valid_attrs
             | "request_id_hash" => "request-001"
           }) == {:error, {:invalid_hash, :request_id_hash_required}}

    assert Stage60DuplicateGroupOperatorActionAuditContract.validate_event(%{
             @valid_attrs
             | "idempotency_key_hash" => "idempotency-001"
           }) == {:error, {:invalid_hash, :idempotency_key_hash_required}}
  end

  test "rejects invalid result review and redaction states" do
    assert Stage60DuplicateGroupOperatorActionAuditContract.validate_event(%{
             @valid_attrs
             | "result_status" => "merged"
           }) == {:error, {:invalid_result_status, "merged"}}

    assert Stage60DuplicateGroupOperatorActionAuditContract.validate_event(%{
             @valid_attrs
             | "post_review_state" => "canonical_merged"
           }) == {:error, {:invalid_post_review_state, "canonical_merged"}}

    assert Stage60DuplicateGroupOperatorActionAuditContract.validate_event(%{
             @valid_attrs
             | "redaction_status" => "raw_allowed"
           }) == {:error, {:invalid_redaction_status, "raw_allowed"}}
  end

  test "rejects raw actor request idempotency and unredacted reason fields" do
    forbidden_attrs = [
      Map.put(@valid_attrs, "actor_id", "operator-raw"),
      Map.put(@valid_attrs, "actor_email", "operator@example.invalid"),
      Map.put(@valid_attrs, "request_id", "request-raw"),
      Map.put(@valid_attrs, "idempotency_key", "idempotency-raw"),
      Map.put(@valid_attrs, "operator_reason", "raw reason")
    ]

    Enum.each(forbidden_attrs, fn attrs ->
      assert {:error, {:prohibited_field, _path}} =
               Stage60DuplicateGroupOperatorActionAuditContract.validate_event(attrs)
    end)
  end

  test "rejects forbidden raw provider transport full text and canonical payload fields" do
    forbidden_attrs = [
      Map.put(@valid_attrs, "rawProviderResponseBody", "blocked"),
      Map.put(@valid_attrs, "request" <> "Headers", %{"redacted" => "blocked"}),
      Map.put(@valid_attrs, "fullArticleText", "blocked"),
      Map.put(@valid_attrs, "canonicalFeedItemPayload", %{}),
      Map.put(@valid_attrs, "providerCanonicalCreationPayload", %{})
    ]

    Enum.each(forbidden_attrs, fn attrs ->
      assert {:error, {:prohibited_field, _path}} =
               Stage60DuplicateGroupOperatorActionAuditContract.validate_event(attrs)
    end)
  end

  test "rejects secret-like values in bounded fields" do
    assert Stage60DuplicateGroupOperatorActionAuditContract.validate_event(%{
             @valid_attrs
             | "group_id" => sensitive_header_prefix(:authorization) <> " Bearer blocked"
           }) == {:error, {:prohibited_value, :group_id_required}}
  end

  test "rejects public canonical provider scheduler route UI action audit schema and materializer opt-ins" do
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
      :audit_write_performed,
      :audit_write,
      :materializer_triggered,
      :route_added,
      :ui_added,
      :action_endpoint_added,
      :schema_migration
    ]

    Enum.each(forbidden_opts, fn opt ->
      assert {:error, _reason} =
               Stage60DuplicateGroupOperatorActionAuditContract.validate_event(@valid_attrs, [{opt, true}])
    end)
  end

  test "exports allowlists" do
    assert Stage60DuplicateGroupOperatorActionAuditContract.allowed_operations() == [
             "confirm_duplicate_group",
             "reject_duplicate_group",
             "mark_duplicate_group_needs_review",
             "clear_duplicate_group_review_state"
           ]

    assert Stage60DuplicateGroupOperatorActionAuditContract.read_only_permissions() == ["duplicate_group:read"]
    assert "duplicate_group:confirm" in Stage60DuplicateGroupOperatorActionAuditContract.action_permissions()
    assert "completed" in Stage60DuplicateGroupOperatorActionAuditContract.allowed_result_statuses()
    assert "confirmed_by_operator" in Stage60DuplicateGroupOperatorActionAuditContract.allowed_review_states()
    assert "passed" in Stage60DuplicateGroupOperatorActionAuditContract.allowed_redaction_statuses()
  end

  defp sensitive_header_prefix(:authorization), do: "Author" <> "ization" <> ":"
end
