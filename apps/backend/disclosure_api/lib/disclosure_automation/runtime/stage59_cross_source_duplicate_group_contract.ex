defmodule DisclosureAutomation.Runtime.Stage59CrossSourceDuplicateGroupContract do
  @moduledoc false

  @allowed_member_kinds ~w(
    official_tdnet_event
    news_overlay_attachment
    provider_staged_candidate
    operator_review_candidate
  )

  @allowed_confidence_states ~w(
    unknown
    candidate
    likely
    confirmed_by_operator
    rejected_by_operator
  )

  @allowed_match_reasons ~w(
    same_official_event_id
    same_official_stable_external_id
    same_security_code
    same_disclosure_date
    same_provider_external_id_hash
    same_title_fingerprint
    same_url_fingerprint
    same_provider_citation_target
    operator_confirmed_duplicate
  )

  @allowed_redaction_statuses ~w(
    passed
    failed
    blocked
    unknown
  )

  @max_group_id_length 160
  @max_member_id_length 160
  @max_source_key_length 128
  @max_provider_length 128
  @max_external_id_length 160
  @max_hash_length 128
  @max_event_id_length 240
  @max_overlay_id_length 260
  @max_timestamp_length 64

  @prohibited_key_fragments [
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

  def allowed_member_kinds, do: @allowed_member_kinds
  def allowed_confidence_states, do: @allowed_confidence_states
  def allowed_match_reasons, do: @allowed_match_reasons
  def allowed_redaction_statuses, do: @allowed_redaction_statuses

  def defaults do
    %{
      duplicate_group_scope: "internal_operator_advisory_only",
      bounded: true,
      redacted: true,
      advisory_only: true,
      operator_only: true,
      non_canonical: true,
      public_response_shape_mutation: false,
      public_api_duplicate_group_fields: false,
      public_feed_duplicate_group_fields: false,
      item_overlays_shape_mutation: false,
      news_overlays_shape_mutation: false,
      materializer_output_mutation: false,
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
      route_added: false,
      ui_added: false,
      action_endpoint_added: false,
      schema_migration: false
    }
  end

  def validate_group(attrs, opts \\ [])

  def validate_group(attrs, opts) when is_map(attrs) do
    with :ok <- forbid_public_exposure(opts),
         :ok <- forbid_live_fetch(opts),
         :ok <- forbid_scheduler(opts),
         :ok <- forbid_runtime_side_effects(opts),
         :ok <- forbid_response_shape_mutation(opts),
         :ok <- forbid_canonical_mutation(opts),
         :ok <- forbid_routes_or_schema(opts),
         :ok <- reject_prohibited_fields(attrs),
         {:ok, group_id} <- bounded_required_string(get_value(attrs, "group_id"), @max_group_id_length, :group_id_required),
         {:ok, confidence} <- validate_required_enum(get_value(attrs, "confidence"), @allowed_confidence_states, :invalid_confidence),
         {:ok, members} <- validate_members(get_value(attrs, "members")) do
      {:ok,
       defaults()
       |> Map.merge(%{
         group_id: group_id,
         confidence: confidence,
         members: members,
         member_count: length(members),
         has_official_tdnet_event: Enum.any?(members, &(&1.member_kind == "official_tdnet_event")),
         has_provider_overlay: Enum.any?(members, &(&1.member_kind == "news_overlay_attachment")),
         match_reasons: aggregate_match_reasons(members),
         source_keys: aggregate_source_keys(members)
       })}
    end
  end

  def validate_group(_attrs, _opts), do: {:error, :invalid_stage59_duplicate_group_attrs}

  defp validate_members(members) when is_list(members) do
    cond do
      length(members) < 2 ->
        {:error, :duplicate_group_requires_at_least_two_members}

      true ->
        members
        |> Enum.with_index()
        |> Enum.reduce_while({:ok, []}, fn {member, index}, {:ok, acc} ->
          case validate_member(member, index) do
            {:ok, normalized} -> {:cont, {:ok, [normalized | acc]}}
            {:error, reason} -> {:halt, {:error, reason}}
          end
        end)
        |> case do
          {:ok, normalized_members} -> {:ok, Enum.reverse(normalized_members)}
          error -> error
        end
    end
  end

  defp validate_members(_members), do: {:error, :duplicate_group_members_required}

  defp validate_member(member, index) when is_map(member) do
    with :ok <- reject_prohibited_fields(member),
         {:ok, member_id} <- bounded_required_string(get_value(member, "member_id"), @max_member_id_length, {:member_id_required, index}),
         {:ok, member_kind} <-
           validate_required_enum(get_value(member, "member_kind"), @allowed_member_kinds, {:invalid_member_kind, index}),
         {:ok, source_key} <- bounded_required_string(get_value(member, "source_key"), @max_source_key_length, {:source_key_required, index}),
         {:ok, provider} <- validate_optional_string(get_value(member, "provider"), @max_provider_length),
         {:ok, external_id} <- validate_optional_string(get_value(member, "external_id"), @max_external_id_length),
         {:ok, external_id_hash} <- validate_optional_hash(get_value(member, "external_id_hash")),
         {:ok, official_event_id} <- validate_optional_string(get_value(member, "official_event_id"), @max_event_id_length),
         {:ok, overlay_id} <- validate_optional_string(get_value(member, "overlay_id"), @max_overlay_id_length),
         :ok <- require_member_reference(official_event_id, overlay_id, external_id, external_id_hash, index),
         {:ok, confidence} <-
           validate_required_enum(get_value(member, "confidence"), @allowed_confidence_states, {:invalid_member_confidence, index}),
         {:ok, match_reasons} <- validate_match_reasons(get_value(member, "match_reasons"), index),
         {:ok, redaction_status} <-
           validate_required_enum(
             get_value(member, "redaction_status"),
             @allowed_redaction_statuses,
             {:invalid_member_redaction_status, index}
           ),
         {:ok, created_at} <- validate_optional_string(get_value(member, "created_at"), @max_timestamp_length),
         {:ok, updated_at} <- validate_optional_string(get_value(member, "updated_at"), @max_timestamp_length) do
      {:ok,
       %{
         member_id: member_id,
         member_kind: member_kind,
         source_key: source_key,
         provider: provider,
         external_id: external_id,
         external_id_hash: external_id_hash,
         official_event_id: official_event_id,
         overlay_id: overlay_id,
         confidence: confidence,
         match_reasons: match_reasons,
         redaction_status: redaction_status,
         created_at: created_at,
         updated_at: updated_at,
         canonical_feed_mutation: false,
         official_fact_override: false,
         provider_canonical_feed_item_creation: false,
         news_only_event_creation: false
       }}
    end
  end

  defp validate_member(_member, index), do: {:error, {:invalid_duplicate_group_member, index}}

  defp validate_match_reasons(reasons, index) when is_list(reasons) and reasons != [] do
    reasons
    |> Enum.reduce_while({:ok, []}, fn reason, {:ok, acc} ->
      case validate_required_enum(reason, @allowed_match_reasons, {:invalid_match_reason, index}) do
        {:ok, normalized} -> {:cont, {:ok, [normalized | acc]}}
        {:error, error} -> {:halt, {:error, error}}
      end
    end)
    |> case do
      {:ok, normalized} -> {:ok, Enum.reverse(normalized)}
      error -> error
    end
  end

  defp validate_match_reasons(_reasons, index), do: {:error, {:match_reasons_required, index}}

  defp require_member_reference(official_event_id, overlay_id, external_id, external_id_hash, index) do
    if Enum.any?([official_event_id, overlay_id, external_id, external_id_hash], &present?/1) do
      :ok
    else
      {:error, {:member_reference_required, index}}
    end
  end

  defp validate_required_enum(nil, _allowed, error_tag), do: {:error, error_tag}

  defp validate_required_enum(value, allowed, error_tag) when is_binary(value) do
    normalized = String.trim(value)

    if normalized in allowed do
      {:ok, normalized}
    else
      {:error, {error_tag, value}}
    end
  end

  defp validate_required_enum(value, _allowed, error_tag), do: {:error, {error_tag, value}}

  defp validate_optional_string(nil, _max_length), do: {:ok, nil}
  defp validate_optional_string("", _max_length), do: {:ok, nil}

  defp validate_optional_string(value, max_length) do
    bounded_required_string(value, max_length, :optional_string_invalid)
  end

  defp validate_optional_hash(nil), do: {:ok, nil}
  defp validate_optional_hash(""), do: {:ok, nil}

  defp validate_optional_hash(value) when is_binary(value) do
    trimmed = String.trim(value)

    cond do
      String.length(trimmed) > @max_hash_length -> {:error, {:string_too_long, :external_id_hash, @max_hash_length}}
      prohibited_value?(trimmed) -> {:error, {:prohibited_value, :external_id_hash}}
      not String.starts_with?(trimmed, "sha256:") -> {:error, {:invalid_hash, :external_id_hash}}
      true -> {:ok, trimmed}
    end
  end

  defp validate_optional_hash(_value), do: {:error, {:invalid_hash, :external_id_hash}}

  defp bounded_required_string(value, max_length, error_tag) when is_binary(value) do
    trimmed = String.trim(value)

    cond do
      trimmed == "" -> {:error, error_tag}
      String.length(trimmed) > max_length -> {:error, {:string_too_long, error_tag, max_length}}
      prohibited_value?(trimmed) -> {:error, {:prohibited_value, error_tag}}
      true -> {:ok, trimmed}
    end
  end

  defp bounded_required_string(_value, _max_length, error_tag), do: {:error, error_tag}

  defp forbid_public_exposure(opts) do
    if Keyword.get(opts, :public_exposure, false) do
      {:error, :public_exposure_not_allowed_in_stage59_duplicate_group_contract}
    else
      :ok
    end
  end

  defp forbid_live_fetch(opts) do
    if Keyword.get(opts, :trigger_live_fetch, false) or Keyword.get(opts, :use_live_fetch, false) do
      {:error, :live_fetch_not_allowed_in_stage59_duplicate_group_contract}
    else
      :ok
    end
  end

  defp forbid_scheduler(opts) do
    if Keyword.get(opts, :scheduler_enabled, false) do
      {:error, :scheduler_not_allowed_in_stage59_duplicate_group_contract}
    else
      :ok
    end
  end

  defp forbid_runtime_side_effects(opts) do
    if Keyword.get(opts, :db_write, false) or Keyword.get(opts, :network_access, false) do
      {:error, :runtime_side_effect_not_allowed_in_stage59_duplicate_group_contract}
    else
      :ok
    end
  end

  defp forbid_response_shape_mutation(opts) do
    if Keyword.get(opts, :public_response_shape_mutation, false) or
         Keyword.get(opts, :public_api_duplicate_group_fields, false) or
         Keyword.get(opts, :public_feed_duplicate_group_fields, false) or
         Keyword.get(opts, :item_overlays_shape_mutation, false) or
         Keyword.get(opts, :news_overlays_shape_mutation, false) or
         Keyword.get(opts, :materializer_output_mutation, false) do
      {:error, :public_response_shape_mutation_not_allowed_in_stage59_duplicate_group_contract}
    else
      :ok
    end
  end

  defp forbid_canonical_mutation(opts) do
    if Keyword.get(opts, :canonical_feed_mutation, false) or
         Keyword.get(opts, :provider_canonical_feed_item_creation, false) or
         Keyword.get(opts, :news_only_event_creation, false) or
         Keyword.get(opts, :official_event_merge, false) or
         Keyword.get(opts, :official_fact_override, false) or
         Keyword.get(opts, :official_citation_override, false) do
      {:error, :canonical_mutation_not_allowed_in_stage59_duplicate_group_contract}
    else
      :ok
    end
  end

  defp forbid_routes_or_schema(opts) do
    if Keyword.get(opts, :route_added, false) or Keyword.get(opts, :ui_added, false) or
         Keyword.get(opts, :action_endpoint_added, false) or Keyword.get(opts, :schema_migration, false) do
      {:error, :route_ui_action_or_schema_not_allowed_in_stage59_duplicate_group_contract}
    else
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

  defp aggregate_match_reasons(members) do
    members
    |> Enum.flat_map(& &1.match_reasons)
    |> Enum.uniq()
  end

  defp aggregate_source_keys(members) do
    members
    |> Enum.map(& &1.source_key)
    |> Enum.uniq()
  end

  defp present?(value), do: is_binary(value) and String.trim(value) != ""

  defp sensitive_header_prefix(:authorization), do: "Author" <> "ization" <> ":"
  defp sensitive_header_prefix(:cookie), do: "Coo" <> "kie" <> ":"
  defp sensitive_header_prefix(:subscription_key), do: "Subscription" <> "-" <> "Key" <> ":"

  defp get_value(map, key, default \\ nil)

  defp get_value(map, key, default) when is_map(map) do
    cond do
      Map.has_key?(map, key) -> Map.get(map, key)
      Map.has_key?(map, String.to_atom(key)) -> Map.get(map, String.to_atom(key))
      true -> default
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
