defmodule DisclosureAutomation.Stage61DuplicateGroupActionStateWriterTest do
  use DisclosureAutomationWeb.ConnCase, async: false

  import Ecto.Query

  alias DisclosureAutomation.Repo
  alias DisclosureAutomation.Runtime.Stage61DuplicateGroupActionStateWriter
  alias DisclosureAutomation.Schema.SourceDuplicateGroupActionEvent
  alias DisclosureAutomation.Schema.SourceDuplicateGroupReviewState

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
    "result_status" => "completed",
    "redaction_status" => "passed",
    "pre_review_state" => "unknown",
    "post_review_state" => "confirmed_by_operator",
    "created_at" => "2026-05-03T07:30:00Z"
  }

  test "records authorized action event and review state transactionally" do
    assert {:ok, result} = Stage61DuplicateGroupActionStateWriter.record_action(@valid_action_attrs, @valid_actor_context)

    assert result.mode == "stage61_duplicate_group_action_state_recorded"
    assert result.writer_scope == "internal_duplicate_group_action_state_writer"
    assert result.operator_only == true
    assert result.advisory_only == true
    assert result.non_canonical == true
    assert result.bounded == true
    assert result.redacted == true
    assert result.action_contract_required == true
    assert result.audit_contract_required == true
    assert result.authorization_gate_required == true
    assert result.transaction_required == true
    assert result.idempotent_event_write == true
    assert result.review_state_upsert == true
    assert result.db_write == true
    assert result.audit_write_performed == true
    assert result.action_operation == "confirm_duplicate_group"
    assert result.required_permission == "duplicate_group:confirm"
    assert result.group_id == @group_id
    assert result.actor_id_hash == "sha256:operator-001"
    assert result.request_id_hash == "sha256:request-001"
    assert result.idempotency_key_hash == "sha256:idempotency-001"
    assert result.result_status == "completed"
    assert result.redaction_status == "passed"
    assert result.pre_review_state == "unknown"
    assert result.post_review_state == "confirmed_by_operator"
    assert result.action_event_inserted == true
    assert result.review_state == "confirmed_by_operator"
    assert result.authorized == true
    assert result.authorization_result == "allowed_noop_preview"

    assert result.public_response_shape_mutation == false
    assert result.public_api_duplicate_group_fields == false
    assert result.public_feed_duplicate_group_fields == false
    assert result.canonical_feed_mutation == false
    assert result.provider_canonical_feed_item_creation == false
    assert result.news_only_event_creation == false
    assert result.official_event_merge == false
    assert result.official_fact_override == false
    assert result.official_citation_override == false
    assert result.trigger_live_fetch == false
    assert result.scheduler_enabled == false
    assert result.network_access == "forbidden"
    assert result.enqueue_performed == false
    assert result.materializer_triggered == false
    assert result.route_added == false
    assert result.ui_added == false
    assert result.action_endpoint_added == false
    assert result.schema_migration == false

    assert event_count(@group_id) == 1
    assert review_state_count(@group_id) == 1

    event = Repo.one!(from event in SourceDuplicateGroupActionEvent, where: event.group_id == ^@group_id)
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

    review_state = Repo.one!(from state in SourceDuplicateGroupReviewState, where: state.group_id == ^@group_id)
    assert review_state.review_state == "confirmed_by_operator"
    assert review_state.last_action_operation == "confirm_duplicate_group"
    assert review_state.last_action_request_id_hash == "sha256:request-001"
    assert review_state.last_action_idempotency_key_hash == "sha256:idempotency-001"
    assert review_state.reviewed_by_actor_id_hash == "sha256:operator-001"
    assert review_state.review_reason_redacted == "REDACTED_OPERATOR_CONFIRMED_DUPLICATE_GROUP"
    assert review_state.redaction_status == "passed"
  end

  test "rerunning the same idempotency identity reuses event and keeps row counts stable" do
    assert {:ok, first_result} = Stage61DuplicateGroupActionStateWriter.record_action(@valid_action_attrs, @valid_actor_context)
    assert first_result.action_event_inserted == true
    assert event_count(@group_id) == 1
    assert review_state_count(@group_id) == 1

    assert {:ok, second_result} = Stage61DuplicateGroupActionStateWriter.record_action(@valid_action_attrs, @valid_actor_context)
    assert second_result.action_event_inserted == false
    assert second_result.action_event_id == first_result.action_event_id
    assert second_result.review_state_id == first_result.review_state_id
    assert event_count(@group_id) == 1
    assert review_state_count(@group_id) == 1
  end

  test "new idempotency key inserts new event and upserts one review state" do
    assert {:ok, _first_result} = Stage61DuplicateGroupActionStateWriter.record_action(@valid_action_attrs, @valid_actor_context)

    second_action_attrs = %{
      @valid_action_attrs
      | "idempotency_key_hash" => "sha256:idempotency-002",
        "request_id_hash" => "sha256:request-002",
        "operator_reason_redacted" => "REDACTED_OPERATOR_CONFIRMED_DUPLICATE_GROUP_AGAIN"
    }

    second_actor_context = %{@valid_actor_context | "created_at" => "2026-05-03T07:31:00Z"}

    assert {:ok, second_result} = Stage61DuplicateGroupActionStateWriter.record_action(second_action_attrs, second_actor_context)
    assert second_result.action_event_inserted == true
    assert second_result.request_id_hash == "sha256:request-002"
    assert second_result.idempotency_key_hash == "sha256:idempotency-002"
    assert event_count(@group_id) == 2
    assert review_state_count(@group_id) == 1
  end

  test "unauthorized action returns error and writes no rows" do
    actor_context = %{@valid_actor_context | "permissions" => ["duplicate_group:read"]}

    assert Stage61DuplicateGroupActionStateWriter.record_action(@valid_action_attrs, actor_context) ==
             {:error, {:read_only_permission_cannot_authorize_action, "duplicate_group:confirm"}}

    assert event_count(@group_id) == 0
    assert review_state_count(@group_id) == 0
  end

  test "invalid action request returns error and writes no rows" do
    attrs = %{@valid_action_attrs | "actor_id_hash" => "operator-raw"}

    assert Stage61DuplicateGroupActionStateWriter.record_action(attrs, @valid_actor_context) ==
             {:error, {:invalid_hash, :actor_id_hash_required}}

    assert event_count(@group_id) == 0
    assert review_state_count(@group_id) == 0
  end

  test "rejects public, canonical, provider, scheduler, route, UI, materializer, enqueue, and network opt-ins" do
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
      :enqueue_performed,
      :materializer_triggered,
      :route_added,
      :ui_added,
      :action_endpoint_added,
      :schema_migration
    ]

    Enum.each(forbidden_opts, fn opt ->
      assert {:error, _reason} = Stage61DuplicateGroupActionStateWriter.record_action(@valid_action_attrs, @valid_actor_context, [{opt, true}])
      assert event_count(@group_id) == 0
      assert review_state_count(@group_id) == 0
    end)
  end

  defp event_count(group_id) do
    SourceDuplicateGroupActionEvent
    |> where([event], event.group_id == ^group_id)
    |> Repo.aggregate(:count)
  end

  defp review_state_count(group_id) do
    SourceDuplicateGroupReviewState
    |> where([state], state.group_id == ^group_id)
    |> Repo.aggregate(:count)
  end
end
