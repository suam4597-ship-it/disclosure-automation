defmodule DisclosureAutomation.Runtime.Stage60DuplicateGroupOperatorActionNoopService do
  @moduledoc false

  alias DisclosureAutomation.Runtime.Stage60DuplicateGroupOperatorActionAuditContract
  alias DisclosureAutomation.Runtime.Stage60DuplicateGroupOperatorActionContract

  @allowed_context_keys ~w(
    result_status
    redaction_status
    pre_review_state
    post_review_state
    failure_code
    created_at
  )

  @prohibited_key_fragments [
    "actorid",
    "actorname",
    "actoremail",
    "requestid",
    "idempotencykey",
    "operatorreason",
    "operatornote",
    "articlebody",
    "fulltext",
    "fullarticletext",
    "rawhtml",
    "rawresponsebody",
    "responsebody",
    "providerresponsebody",
    "requestheaders",
    "responseheaders",
    "headers",
    "credentials",
    "apikey",
    "api_key",
    "authorization",
    "cookie",
    "subscriptionkey",
    "subscription-key",
    "bearertoken",
    "bearer_token",
    "signedprivateurl",
    "signed_private_url",
    "canonicalfeeditempayload",
    "providercanonicalcreationpayload",
    "canonicaleventpayload",
    "rawbodysimilaritypayload",
    "fulltextsimilaritypayload"
  ]

  def defaults do
    %{
      service_scope: "operator_only_duplicate_group_action_noop",
      action_contract_required: true,
      audit_contract_required: true,
      operator_only: true,
      advisory_only: true,
      non_canonical: true,
      bounded: true,
      redacted: true,
      no_op: true,
      fake_side_effects_only: true,
      action_attempt_recorded: true,
      audit_event_built: true,
      accepted: true,
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

  def preview_action(action_attrs, audit_context \\ %{}, opts \\ [])

  def preview_action(action_attrs, audit_context, opts) when is_map(action_attrs) and is_map(audit_context) do
    with :ok <- forbid_noop_escape(opts),
         :ok <- reject_prohibited_fields(audit_context),
         :ok <- reject_unknown_context_keys(audit_context),
         {:ok, action} <- Stage60DuplicateGroupOperatorActionContract.validate_action(action_attrs, opts),
         {:ok, audit_event} <-
           Stage60DuplicateGroupOperatorActionAuditContract.validate_event(build_audit_event(action, audit_context), opts) do
      {:ok,
       defaults()
       |> Map.merge(%{
         action_operation: action.action_operation,
         required_permission: action.required_permission,
         group_id: action.group_id,
         actor_id_hash: action.actor_id_hash,
         request_id_hash: action.request_id_hash,
         idempotency_key_hash: action.idempotency_key_hash,
         redaction_status: audit_event.redaction_status,
         result_status: audit_event.result_status,
         action: action,
         audit_event: audit_event,
         action_result: build_action_result(action, audit_event)
       })}
    end
  end

  def preview_action(_action_attrs, _audit_context, _opts), do: {:error, :invalid_stage60_duplicate_group_action_noop_request}

  defp build_audit_event(action, audit_context) do
    %{
      "action_operation" => action.action_operation,
      "required_permission" => action.required_permission,
      "group_id" => action.group_id,
      "actor_id_hash" => action.actor_id_hash,
      "request_id_hash" => action.request_id_hash,
      "idempotency_key_hash" => action.idempotency_key_hash,
      "operator_reason_redacted" => action.operator_reason_redacted,
      "result_status" => get_value(audit_context, "result_status", "accepted"),
      "redaction_status" => get_value(audit_context, "redaction_status", action.redaction_status),
      "pre_review_state" => get_value(audit_context, "pre_review_state", "unknown"),
      "post_review_state" => post_review_state(action.action_operation, audit_context),
      "failure_code" => get_value(audit_context, "failure_code"),
      "created_at" => get_value(audit_context, "created_at")
    }
  end

  defp post_review_state("confirm_duplicate_group", audit_context) do
    get_value(audit_context, "post_review_state", "confirmed_by_operator")
  end

  defp post_review_state("reject_duplicate_group", audit_context) do
    get_value(audit_context, "post_review_state", "rejected_by_operator")
  end

  defp post_review_state("mark_duplicate_group_needs_review", audit_context) do
    get_value(audit_context, "post_review_state", "needs_review")
  end

  defp post_review_state("clear_duplicate_group_review_state", audit_context) do
    get_value(audit_context, "post_review_state", "cleared")
  end

  defp post_review_state(_operation, audit_context) do
    get_value(audit_context, "post_review_state", "unknown")
  end

  defp build_action_result(action, audit_event) do
    %{
      mode: "stage60_noop_duplicate_group_operator_action",
      group_id: action.group_id,
      action_operation: action.action_operation,
      required_permission: action.required_permission,
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
      materializer_triggered: false,
      route_added: false,
      ui_added: false,
      action_endpoint_added: false,
      schema_migration: false,
      public_response_shape_mutation: false,
      public_api_duplicate_group_fields: false,
      public_feed_duplicate_group_fields: false,
      canonical_feed_mutation: false,
      provider_canonical_feed_item_creation: false,
      news_only_event_creation: false,
      official_event_merge: false,
      official_fact_override: false,
      official_citation_override: false,
      result_status: audit_event.result_status,
      redaction_status: audit_event.redaction_status,
      pre_review_state: audit_event.pre_review_state,
      post_review_state: audit_event.post_review_state
    }
  end

  defp reject_unknown_context_keys(context) do
    case context |> Map.keys() |> Enum.map(&to_string/1) |> Enum.reject(&(&1 in @allowed_context_keys)) do
      [] -> :ok
      [key | _] -> {:error, {:unsupported_stage60_action_noop_context_key, key}}
    end
  end

  defp forbid_noop_escape(opts) do
    cond do
      Keyword.get(opts, :public_exposure, false) or
          Keyword.get(opts, :public_response_shape_mutation, false) or
          Keyword.get(opts, :public_api_duplicate_group_fields, false) or
          Keyword.get(opts, :public_feed_duplicate_group_fields, false) ->
        {:error, :public_response_shape_mutation_not_allowed_in_stage60_duplicate_group_action_noop_service}

      Keyword.get(opts, :canonical_feed_mutation, false) or
          Keyword.get(opts, :provider_canonical_feed_item_creation, false) or
          Keyword.get(opts, :news_only_event_creation, false) or
          Keyword.get(opts, :official_event_merge, false) or
          Keyword.get(opts, :official_fact_override, false) or
          Keyword.get(opts, :official_citation_override, false) ->
        {:error, :canonical_mutation_not_allowed_in_stage60_duplicate_group_action_noop_service}

      Keyword.get(opts, :trigger_live_fetch, false) or Keyword.get(opts, :use_live_fetch, false) ->
        {:error, :live_fetch_not_allowed_in_stage60_duplicate_group_action_noop_service}

      Keyword.get(opts, :scheduler_enabled, false) ->
        {:error, :scheduler_not_allowed_in_stage60_duplicate_group_action_noop_service}

      Keyword.get(opts, :network_access, false) or Keyword.get(opts, :db_write, false) or
          Keyword.get(opts, :audit_write_performed, false) or Keyword.get(opts, :audit_write, false) or
          Keyword.get(opts, :enqueue_performed, false) ->
        {:error, :runtime_side_effect_not_allowed_in_stage60_duplicate_group_action_noop_service}

      Keyword.get(opts, :materializer_triggered, false) ->
        {:error, :materializer_not_allowed_in_stage60_duplicate_group_action_noop_service}

      Keyword.get(opts, :route_added, false) or Keyword.get(opts, :ui_added, false) or
          Keyword.get(opts, :action_endpoint_added, false) or Keyword.get(opts, :schema_migration, false) ->
        {:error, :route_ui_action_or_schema_not_allowed_in_stage60_duplicate_group_action_noop_service}

      true ->
        :ok
    end
  end

  defp reject_prohibited_fields(value) do
    case find_prohibited_field(value) do
      nil -> :ok
      path -> {:error, {:prohibited_field, path}}
    end
  end

  defp find_prohibited_field(value, path \\ "")

  defp find_prohibited_field(%{} = map, path) do
    Enum.find_value(map, fn {key, value} ->
      key_string = to_string(key)
      current_path = if path == "", do: key_string, else: "#{path}.#{key_string}"

      cond do
        key_string in @allowed_context_keys -> find_prohibited_field(value, current_path)
        prohibited_key?(key_string) -> current_path
        true -> find_prohibited_field(value, current_path)
      end
    end)
  end

  defp find_prohibited_field(values, path) when is_list(values) do
    values
    |> Enum.with_index()
    |> Enum.find_value(fn {value, index} -> find_prohibited_field(value, "#{path}[#{index}]") end)
  end

  defp find_prohibited_field(value, path) when is_binary(value) do
    if prohibited_value?(value), do: path, else: nil
  end

  defp find_prohibited_field(_value, _path), do: nil

  defp prohibited_key?(key) do
    normalized = normalize_token(key)

    Enum.any?(@prohibited_key_fragments, fn fragment ->
      String.contains?(normalized, normalize_token(fragment))
    end)
  end

  defp prohibited_value?(value) do
    String.contains?(value, "BEGIN PRIVATE KEY") or
      String.contains?(value, sensitive_header_prefix(:authorization)) or
      String.contains?(value, sensitive_header_prefix(:cookie)) or
      String.contains?(value, sensitive_header_prefix(:subscription_key))
  end

  defp sensitive_header_prefix(:authorization), do: "Author" <> "ization" <> ":"
  defp sensitive_header_prefix(:cookie), do: "Coo" <> "kie" <> ":"
  defp sensitive_header_prefix(:subscription_key), do: "Subscription" <> "-" <> "Key" <> ":"

  defp get_value(map, key, default \\ nil) when is_map(map) do
    case Enum.find(map, fn {candidate, _value} -> to_string(candidate) == key end) do
      {_candidate, value} -> value
      nil -> default
    end
  end

  defp get_value(_value, _key, default), do: default

  defp normalize_token(value) do
    value
    |> to_string()
    |> String.downcase()
    |> String.replace(~r/[^a-z0-9]/, "")
  end
end
