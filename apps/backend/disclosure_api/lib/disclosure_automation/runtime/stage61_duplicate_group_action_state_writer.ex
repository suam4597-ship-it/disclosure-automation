defmodule DisclosureAutomation.Runtime.Stage61DuplicateGroupActionStateWriter do
  @moduledoc false

  alias DisclosureAutomation.Repo
  alias DisclosureAutomation.Runtime.Stage60DuplicateGroupOperatorActionAuthorizationGate
  alias DisclosureAutomation.Schema.SourceDuplicateGroupActionEvent
  alias DisclosureAutomation.Schema.SourceDuplicateGroupReviewState

  def defaults do
    %{
      writer_scope: "internal_duplicate_group_action_state_writer",
      operator_only: true,
      advisory_only: true,
      non_canonical: true,
      bounded: true,
      redacted: true,
      action_contract_required: true,
      audit_contract_required: true,
      authorization_gate_required: true,
      transaction_required: true,
      idempotent_event_write: true,
      review_state_upsert: true,
      db_write: true,
      audit_write_performed: true,
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
      enqueue_performed: false,
      materializer_triggered: false,
      route_added: false,
      ui_added: false,
      action_endpoint_added: false,
      schema_migration: false
    }
  end

  def record_action(action_attrs, actor_context, opts \\ [])

  def record_action(action_attrs, actor_context, opts) when is_map(action_attrs) and is_map(actor_context) do
    with :ok <- forbid_writer_escape(opts),
         {:ok, authorized} <- Stage60DuplicateGroupOperatorActionAuthorizationGate.authorize_noop_preview(action_attrs, actor_context) do
      persist_authorized_action(authorized)
    end
  end

  def record_action(_action_attrs, _actor_context, _opts), do: {:error, :invalid_stage61_duplicate_group_action_state_writer_request}

  defp persist_authorized_action(authorized) do
    Repo.transaction(fn ->
      with {:ok, event, event_inserted?} <- insert_or_get_action_event(authorized.preview.audit_event),
           {:ok, review_state} <- upsert_review_state(authorized.preview.audit_event) do
        build_result(authorized, event, event_inserted?, review_state)
      else
        {:error, reason} -> Repo.rollback(reason)
      end
    end)
  end

  defp insert_or_get_action_event(audit_event) do
    case existing_action_event(audit_event) do
      nil ->
        attrs = action_event_attrs(audit_event)

        changeset =
          %SourceDuplicateGroupActionEvent{}
          |> SourceDuplicateGroupActionEvent.changeset(attrs)

        case Repo.insert(changeset) do
          {:ok, event} -> {:ok, event, true}
          {:error, reason} -> {:error, reason}
        end

      event ->
        {:ok, event, false}
    end
  end

  defp existing_action_event(audit_event) do
    import Ecto.Query

    Repo.one(
      from event in SourceDuplicateGroupActionEvent,
        where: event.group_id == ^audit_event.group_id,
        where: event.action_operation == ^audit_event.action_operation,
        where: event.actor_id_hash == ^audit_event.actor_id_hash,
        where: event.idempotency_key_hash == ^audit_event.idempotency_key_hash
    )
  end

  defp upsert_review_state(audit_event) do
    attrs = review_state_attrs(audit_event)

    %SourceDuplicateGroupReviewState{}
    |> SourceDuplicateGroupReviewState.changeset(attrs)
    |> Repo.insert(
      on_conflict: {:replace, [
        :review_state,
        :last_action_operation,
        :last_action_request_id_hash,
        :last_action_idempotency_key_hash,
        :reviewed_by_actor_id_hash,
        :reviewed_at,
        :review_reason_redacted,
        :redaction_status,
        :updated_at
      ]},
      conflict_target: [:group_id],
      returning: true
    )
  end

  defp build_result(authorized, event, event_inserted?, review_state) do
    defaults()
    |> Map.merge(%{
      mode: "stage61_duplicate_group_action_state_recorded",
      action_operation: authorized.action_operation,
      required_permission: authorized.required_permission,
      group_id: authorized.group_id,
      actor_id_hash: authorized.actor_id_hash,
      request_id_hash: event.request_id_hash,
      idempotency_key_hash: event.idempotency_key_hash,
      result_status: event.result_status,
      redaction_status: event.redaction_status,
      pre_review_state: event.pre_review_state,
      post_review_state: event.post_review_state,
      action_event_id: event.id,
      action_event_inserted: event_inserted?,
      review_state_id: review_state.id,
      review_state: review_state.review_state,
      authorized: true,
      authorization_result: authorized.authorization_result
    })
  end

  defp action_event_attrs(audit_event) do
    %{
      "group_id" => audit_event.group_id,
      "action_operation" => audit_event.action_operation,
      "required_permission" => audit_event.required_permission,
      "actor_id_hash" => audit_event.actor_id_hash,
      "request_id_hash" => audit_event.request_id_hash,
      "idempotency_key_hash" => audit_event.idempotency_key_hash,
      "operator_reason_redacted" => audit_event.operator_reason_redacted,
      "result_status" => audit_event.result_status,
      "pre_review_state" => audit_event.pre_review_state,
      "post_review_state" => audit_event.post_review_state,
      "failure_code" => audit_event.failure_code,
      "redaction_status" => audit_event.redaction_status
    }
  end

  defp review_state_attrs(audit_event) do
    %{
      "group_id" => audit_event.group_id,
      "review_state" => audit_event.post_review_state || "unknown",
      "last_action_operation" => audit_event.action_operation,
      "last_action_request_id_hash" => audit_event.request_id_hash,
      "last_action_idempotency_key_hash" => audit_event.idempotency_key_hash,
      "reviewed_by_actor_id_hash" => audit_event.actor_id_hash,
      "reviewed_at" => DateTime.utc_now(),
      "review_reason_redacted" => audit_event.operator_reason_redacted,
      "redaction_status" => audit_event.redaction_status
    }
  end

  defp forbid_writer_escape(opts) do
    cond do
      Keyword.get(opts, :public_exposure, false) or
          Keyword.get(opts, :public_response_shape_mutation, false) or
          Keyword.get(opts, :public_api_duplicate_group_fields, false) or
          Keyword.get(opts, :public_feed_duplicate_group_fields, false) ->
        {:error, :public_response_shape_mutation_not_allowed_in_stage61_action_state_writer}

      Keyword.get(opts, :canonical_feed_mutation, false) or
          Keyword.get(opts, :provider_canonical_feed_item_creation, false) or
          Keyword.get(opts, :news_only_event_creation, false) or
          Keyword.get(opts, :official_event_merge, false) or
          Keyword.get(opts, :official_fact_override, false) or
          Keyword.get(opts, :official_citation_override, false) ->
        {:error, :canonical_mutation_not_allowed_in_stage61_action_state_writer}

      Keyword.get(opts, :trigger_live_fetch, false) or Keyword.get(opts, :use_live_fetch, false) ->
        {:error, :live_fetch_not_allowed_in_stage61_action_state_writer}

      Keyword.get(opts, :scheduler_enabled, false) ->
        {:error, :scheduler_not_allowed_in_stage61_action_state_writer}

      Keyword.get(opts, :network_access, false) or Keyword.get(opts, :enqueue_performed, false) ->
        {:error, :runtime_side_effect_not_allowed_in_stage61_action_state_writer}

      Keyword.get(opts, :materializer_triggered, false) ->
        {:error, :materializer_not_allowed_in_stage61_action_state_writer}

      Keyword.get(opts, :route_added, false) or Keyword.get(opts, :ui_added, false) or
          Keyword.get(opts, :action_endpoint_added, false) or Keyword.get(opts, :schema_migration, false) ->
        {:error, :route_ui_action_or_schema_not_allowed_in_stage61_action_state_writer}

      true ->
        :ok
    end
  end
end
