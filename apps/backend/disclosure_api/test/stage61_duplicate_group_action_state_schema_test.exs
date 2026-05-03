defmodule DisclosureAutomation.Stage61DuplicateGroupActionStateSchemaTest do
  use ExUnit.Case, async: true

  alias DisclosureAutomation.Schema.SourceDuplicateGroupActionEvent
  alias DisclosureAutomation.Schema.SourceDuplicateGroupReviewState

  @group_id "duplicate_group:jp.tdnet.4527.20260430.material_information_update"

  @valid_review_attrs %{
    "group_id" => @group_id,
    "review_state" => "confirmed_by_operator",
    "last_action_operation" => "confirm_duplicate_group",
    "last_action_request_id_hash" => "sha256:request-001",
    "last_action_idempotency_key_hash" => "sha256:idempotency-001",
    "reviewed_by_actor_id_hash" => "sha256:operator-001",
    "reviewed_at" => ~U[2026-05-03 06:55:00Z],
    "review_reason_redacted" => "REDACTED_OPERATOR_CONFIRMED_DUPLICATE_GROUP",
    "redaction_status" => "passed"
  }

  @valid_event_attrs %{
    "group_id" => @group_id,
    "action_operation" => "confirm_duplicate_group",
    "required_permission" => "duplicate_group:confirm",
    "actor_id_hash" => "sha256:operator-001",
    "request_id_hash" => "sha256:request-001",
    "idempotency_key_hash" => "sha256:idempotency-001",
    "operator_reason_redacted" => "REDACTED_OPERATOR_CONFIRMED_DUPLICATE_GROUP",
    "result_status" => "completed",
    "pre_review_state" => "unknown",
    "post_review_state" => "confirmed_by_operator",
    "failure_code" => nil,
    "redaction_status" => "passed"
  }

  test "review state changeset accepts bounded internal fields" do
    changeset = SourceDuplicateGroupReviewState.changeset(%SourceDuplicateGroupReviewState{}, @valid_review_attrs)

    assert changeset.valid?
    assert {:ok, review_state} = Ecto.Changeset.apply_action(changeset, :insert)
    assert review_state.group_id == @group_id
    assert review_state.review_state == "confirmed_by_operator"
    assert review_state.last_action_operation == "confirm_duplicate_group"
    assert review_state.last_action_request_id_hash == "sha256:request-001"
    assert review_state.last_action_idempotency_key_hash == "sha256:idempotency-001"
    assert review_state.reviewed_by_actor_id_hash == "sha256:operator-001"
    assert review_state.review_reason_redacted == "REDACTED_OPERATOR_CONFIRMED_DUPLICATE_GROUP"
    assert review_state.redaction_status == "passed"
  end

  test "review state changeset rejects invalid states and non-hash identifiers" do
    refute SourceDuplicateGroupReviewState.changeset(%SourceDuplicateGroupReviewState{}, %{
             @valid_review_attrs
             | "review_state" => "canonical_merged"
           }).valid?

    refute SourceDuplicateGroupReviewState.changeset(%SourceDuplicateGroupReviewState{}, %{
             @valid_review_attrs
             | "last_action_operation" => "merge_official_tdnet_events"
           }).valid?

    refute SourceDuplicateGroupReviewState.changeset(%SourceDuplicateGroupReviewState{}, %{
             @valid_review_attrs
             | "reviewed_by_actor_id_hash" => "operator-raw"
           }).valid?
  end

  test "review state changeset rejects raw/private fields" do
    forbidden_attrs = [
      Map.put(@valid_review_attrs, "actor_id", "operator-raw"),
      Map.put(@valid_review_attrs, "request_id", "request-raw"),
      Map.put(@valid_review_attrs, "idempotency_key", "idempotency-raw"),
      Map.put(@valid_review_attrs, "operator_reason", "raw reason"),
      Map.put(@valid_review_attrs, "request" <> "Headers", %{"redacted" => "blocked"}),
      Map.put(@valid_review_attrs, "rawProviderResponseBody", "blocked"),
      Map.put(@valid_review_attrs, "fullArticleText", "blocked"),
      Map.put(@valid_review_attrs, "canonicalFeedItemPayload", %{})
    ]

    Enum.each(forbidden_attrs, fn attrs ->
      changeset = SourceDuplicateGroupReviewState.changeset(%SourceDuplicateGroupReviewState{}, attrs)
      refute changeset.valid?
      assert {_message, _opts} = changeset.errors[:base]
    end)
  end

  test "action event changeset accepts bounded internal fields" do
    changeset = SourceDuplicateGroupActionEvent.changeset(%SourceDuplicateGroupActionEvent{}, @valid_event_attrs)

    assert changeset.valid?
    assert {:ok, event} = Ecto.Changeset.apply_action(changeset, :insert)
    assert event.group_id == @group_id
    assert event.action_operation == "confirm_duplicate_group"
    assert event.required_permission == "duplicate_group:confirm"
    assert event.actor_id_hash == "sha256:operator-001"
    assert event.request_id_hash == "sha256:request-001"
    assert event.idempotency_key_hash == "sha256:idempotency-001"
    assert event.operator_reason_redacted == "REDACTED_OPERATOR_CONFIRMED_DUPLICATE_GROUP"
    assert event.result_status == "completed"
    assert event.pre_review_state == "unknown"
    assert event.post_review_state == "confirmed_by_operator"
    assert event.redaction_status == "passed"
  end

  test "action event changeset validates operation permission and status allowlists" do
    refute SourceDuplicateGroupActionEvent.changeset(%SourceDuplicateGroupActionEvent{}, %{
             @valid_event_attrs
             | "required_permission" => "duplicate_group:reject"
           }).valid?

    refute SourceDuplicateGroupActionEvent.changeset(%SourceDuplicateGroupActionEvent{}, %{
             @valid_event_attrs
             | "action_operation" => "merge_official_tdnet_events"
           }).valid?

    refute SourceDuplicateGroupActionEvent.changeset(%SourceDuplicateGroupActionEvent{}, %{
             @valid_event_attrs
             | "result_status" => "merged"
           }).valid?

    refute SourceDuplicateGroupActionEvent.changeset(%SourceDuplicateGroupActionEvent{}, %{
             @valid_event_attrs
             | "post_review_state" => "canonical_merged"
           }).valid?

    refute SourceDuplicateGroupActionEvent.changeset(%SourceDuplicateGroupActionEvent{}, %{
             @valid_event_attrs
             | "redaction_status" => "raw_allowed"
           }).valid?
  end

  test "action event changeset requires hash-shaped identifiers" do
    refute SourceDuplicateGroupActionEvent.changeset(%SourceDuplicateGroupActionEvent{}, %{
             @valid_event_attrs
             | "actor_id_hash" => "operator-raw"
           }).valid?

    refute SourceDuplicateGroupActionEvent.changeset(%SourceDuplicateGroupActionEvent{}, %{
             @valid_event_attrs
             | "request_id_hash" => "request-raw"
           }).valid?

    refute SourceDuplicateGroupActionEvent.changeset(%SourceDuplicateGroupActionEvent{}, %{
             @valid_event_attrs
             | "idempotency_key_hash" => "idempotency-raw"
           }).valid?
  end

  test "action event changeset rejects raw/private fields" do
    forbidden_attrs = [
      Map.put(@valid_event_attrs, "actor_id", "operator-raw"),
      Map.put(@valid_event_attrs, "actor_email", "operator@example.invalid"),
      Map.put(@valid_event_attrs, "request_id", "request-raw"),
      Map.put(@valid_event_attrs, "idempotency_key", "idempotency-raw"),
      Map.put(@valid_event_attrs, "operator_reason", "raw reason"),
      Map.put(@valid_event_attrs, "request" <> "Headers", %{"redacted" => "blocked"}),
      Map.put(@valid_event_attrs, "rawProviderResponseBody", "blocked"),
      Map.put(@valid_event_attrs, "fullArticleText", "blocked"),
      Map.put(@valid_event_attrs, "canonicalFeedItemPayload", %{})
    ]

    Enum.each(forbidden_attrs, fn attrs ->
      changeset = SourceDuplicateGroupActionEvent.changeset(%SourceDuplicateGroupActionEvent{}, attrs)
      refute changeset.valid?
      assert {_message, _opts} = changeset.errors[:base]
    end)
  end

  test "schema allowlists are exposed" do
    assert "confirmed_by_operator" in SourceDuplicateGroupReviewState.review_states()
    assert "confirm_duplicate_group" in SourceDuplicateGroupReviewState.action_operations()
    assert "passed" in SourceDuplicateGroupReviewState.redaction_statuses()

    assert "confirm_duplicate_group" in SourceDuplicateGroupActionEvent.action_operations()
    assert SourceDuplicateGroupActionEvent.required_permission_for("confirm_duplicate_group") == "duplicate_group:confirm"
    assert "completed" in SourceDuplicateGroupActionEvent.result_statuses()
    assert "confirmed_by_operator" in SourceDuplicateGroupActionEvent.review_states()
    assert "passed" in SourceDuplicateGroupActionEvent.redaction_statuses()
  end
end
