defmodule DisclosureAutomation.Stage60DuplicateGroupOperatorActionContractTest do
  use ExUnit.Case, async: true

  alias DisclosureAutomation.Runtime.Stage60DuplicateGroupOperatorActionContract

  @group_id "duplicate_group:jp.tdnet.4527.20260430.material_information_update"

  @valid_attrs %{
    "group_id" => @group_id,
    "action_operation" => "confirm_duplicate_group",
    "actor_permissions" => ["duplicate_group:confirm"],
    "actor_id_hash" => "sha256:operator-001",
    "request_id_hash" => "sha256:request-001",
    "idempotency_key_hash" => "sha256:idempotency-001",
    "operator_reason_redacted" => "REDACTED_OPERATOR_CONFIRMED_DUPLICATE_GROUP",
    "redaction_status" => "passed"
  }

  test "defaults are operator-only action contract with no side effects" do
    assert Stage60DuplicateGroupOperatorActionContract.defaults() == %{
             action_scope: "operator_only_duplicate_group_action",
             bounded: true,
             redacted: true,
             advisory_only: true,
             operator_only: true,
             non_canonical: true,
             read_only_permission_allowed: false,
             action_permission_required: true,
             operator_reason_required: true,
             idempotency_required: true,
             audit_required: true,
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
             materializer_triggered: false,
             route_added: false,
             ui_added: false,
             action_endpoint_added: false,
             audit_write: false,
             schema_migration: false
           }
  end

  test "validates confirm duplicate group action with action-specific permission" do
    assert {:ok, action} = Stage60DuplicateGroupOperatorActionContract.validate_action(@valid_attrs)

    assert action.action_scope == "operator_only_duplicate_group_action"
    assert action.action_operation == "confirm_duplicate_group"
    assert action.required_permission == "duplicate_group:confirm"
    assert action.group_id == @group_id
    assert action.actor_id_hash == "sha256:operator-001"
    assert action.request_id_hash == "sha256:request-001"
    assert action.idempotency_key_hash == "sha256:idempotency-001"
    assert action.operator_reason_redacted == "REDACTED_OPERATOR_CONFIRMED_DUPLICATE_GROUP"
    assert action.redaction_status == "passed"

    assert action.idempotency_identity == %{
             group_id: @group_id,
             action_operation: "confirm_duplicate_group",
             actor_id_hash: "sha256:operator-001",
             idempotency_key_hash: "sha256:idempotency-001"
           }

    assert action.public_response_shape_mutation == false
    assert action.public_api_duplicate_group_fields == false
    assert action.public_feed_duplicate_group_fields == false
    assert action.canonical_feed_mutation == false
    assert action.provider_canonical_feed_item_creation == false
    assert action.news_only_event_creation == false
    assert action.official_event_merge == false
    assert action.official_fact_override == false
    assert action.official_citation_override == false
    assert action.trigger_live_fetch == false
    assert action.scheduler_enabled == false
    assert action.network_access == "forbidden"
    assert action.materializer_triggered == false
    assert action.route_added == false
    assert action.ui_added == false
    assert action.action_endpoint_added == false
    assert action.audit_write == false
    assert action.schema_migration == false
  end

  test "maps each allowed operation to its action-specific permission" do
    cases = [
      {"confirm_duplicate_group", "duplicate_group:confirm"},
      {"reject_duplicate_group", "duplicate_group:reject"},
      {"mark_duplicate_group_needs_review", "duplicate_group:mark_review"},
      {"clear_duplicate_group_review_state", "duplicate_group:clear_review_state"}
    ]

    Enum.each(cases, fn {operation, permission} ->
      attrs = %{@valid_attrs | "action_operation" => operation, "actor_permissions" => [permission]}

      assert {:ok, action} = Stage60DuplicateGroupOperatorActionContract.validate_action(attrs)
      assert action.action_operation == operation
      assert action.required_permission == permission
    end)
  end

  test "rejects read-only permission or missing action permission" do
    assert Stage60DuplicateGroupOperatorActionContract.validate_action(%{
             @valid_attrs
             | "actor_permissions" => ["duplicate_group:read"]
           }) == {:error, {:read_only_permission_cannot_execute_action, "duplicate_group:confirm"}}

    assert Stage60DuplicateGroupOperatorActionContract.validate_action(%{
             @valid_attrs
             | "actor_permissions" => []
           }) == {:error, {:required_permission_missing, "duplicate_group:confirm"}}
  end

  test "rejects unknown operations and read permission as an operation" do
    assert Stage60DuplicateGroupOperatorActionContract.validate_action(%{
             @valid_attrs
             | "action_operation" => "merge_official_tdnet_events"
           }) == {:error, {:invalid_stage60_duplicate_group_action_operation, "merge_official_tdnet_events"}}

    assert Stage60DuplicateGroupOperatorActionContract.validate_action(%{
             @valid_attrs
             | "action_operation" => "duplicate_group:read"
           }) == {:error, {:read_only_permission_cannot_execute_action, "duplicate_group:read"}}
  end

  test "requires hash-shaped actor, request, and idempotency identifiers" do
    assert Stage60DuplicateGroupOperatorActionContract.validate_action(%{
             @valid_attrs
             | "actor_id_hash" => "operator-001"
           }) == {:error, {:invalid_hash, :actor_id_hash_required}}

    assert Stage60DuplicateGroupOperatorActionContract.validate_action(%{
             @valid_attrs
             | "request_id_hash" => "request-001"
           }) == {:error, {:invalid_hash, :request_id_hash_required}}

    assert Stage60DuplicateGroupOperatorActionContract.validate_action(%{
             @valid_attrs
             | "idempotency_key_hash" => "idempotency-001"
           }) == {:error, {:invalid_hash, :idempotency_key_hash_required}}
  end

  test "rejects raw actor, request, idempotency, and unredacted reason fields" do
    forbidden_attrs = [
      Map.put(@valid_attrs, "actor_id", "operator-raw"),
      Map.put(@valid_attrs, "actor_email", "operator@example.invalid"),
      Map.put(@valid_attrs, "request_id", "request-raw"),
      Map.put(@valid_attrs, "idempotency_key", "idempotency-raw"),
      Map.put(@valid_attrs, "operator_reason", "raw reason")
    ]

    Enum.each(forbidden_attrs, fn attrs ->
      assert {:error, {:prohibited_field, _path}} = Stage60DuplicateGroupOperatorActionContract.validate_action(attrs)
    end)
  end

  test "rejects forbidden raw provider, transport, full text, and canonical payload fields" do
    forbidden_attrs = [
      Map.put(@valid_attrs, "rawProviderResponseBody", "blocked"),
      Map.put(@valid_attrs, "request" <> "Headers", %{"redacted" => "blocked"}),
      Map.put(@valid_attrs, "fullArticleText", "blocked"),
      Map.put(@valid_attrs, "canonicalFeedItemPayload", %{}),
      Map.put(@valid_attrs, "providerCanonicalCreationPayload", %{})
    ]

    Enum.each(forbidden_attrs, fn attrs ->
      assert {:error, {:prohibited_field, _path}} = Stage60DuplicateGroupOperatorActionContract.validate_action(attrs)
    end)
  end

  test "rejects secret-like values in bounded fields" do
    assert Stage60DuplicateGroupOperatorActionContract.validate_action(%{
             @valid_attrs
             | "group_id" => sensitive_header_prefix(:authorization) <> " Bearer blocked"
           }) == {:error, {:prohibited_value, :group_id_required}}
  end

  test "rejects public, canonical, provider, scheduler, route, UI, action endpoint, audit, and schema opt-ins" do
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
      :materializer_triggered,
      :route_added,
      :ui_added,
      :action_endpoint_added,
      :audit_write,
      :schema_migration
    ]

    Enum.each(forbidden_opts, fn opt ->
      assert {:error, _reason} = Stage60DuplicateGroupOperatorActionContract.validate_action(@valid_attrs, [{opt, true}])
    end)
  end

  test "exports operation and permission allowlists" do
    assert Stage60DuplicateGroupOperatorActionContract.allowed_operations() == [
             "confirm_duplicate_group",
             "reject_duplicate_group",
             "mark_duplicate_group_needs_review",
             "clear_duplicate_group_review_state"
           ]

    assert Stage60DuplicateGroupOperatorActionContract.read_only_permissions() == ["duplicate_group:read"]

    assert Enum.sort(Stage60DuplicateGroupOperatorActionContract.action_permissions()) ==
             Enum.sort([
               "duplicate_group:confirm",
               "duplicate_group:reject",
               "duplicate_group:mark_review",
               "duplicate_group:clear_review_state"
             ])
  end

  defp sensitive_header_prefix(:authorization), do: "Author" <> "ization" <> ":"
end
