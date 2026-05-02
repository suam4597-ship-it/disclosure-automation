defmodule DisclosureAutomation.Runtime.Stage59DuplicateGroupProjectionContract do
  @moduledoc false

  alias DisclosureAutomation.Runtime.Stage59CrossSourceDuplicateGroupContract

  @allowed_group_fields ~w(
    group_id
    confidence
    member_count
    has_official_tdnet_event
    has_provider_overlay
    match_reasons
    source_keys
    members
  )

  @allowed_member_fields ~w(
    member_id
    member_kind
    source_key
    provider
    external_id_hash
    official_event_id
    overlay_id
    confidence
    match_reasons
    redaction_status
  )

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
    "fulltextsimilaritypayload",
    "externalid"
  ]

  def allowed_group_fields, do: @allowed_group_fields
  def allowed_member_fields, do: @allowed_member_fields

  def defaults do
    %{
      projection_scope: "internal_operator_duplicate_group_projection_only",
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

  def project(attrs, opts \\ [])

  def project(attrs, opts) when is_map(attrs) do
    with :ok <- forbid_projection_escape(opts),
         :ok <- reject_prohibited_fields(attrs),
         {:ok, group} <- Stage59CrossSourceDuplicateGroupContract.validate_group(attrs, opts),
         :ok <- reject_non_projectable_members(group.members) do
      {:ok,
       defaults()
       |> Map.merge(%{
         group_id: group.group_id,
         confidence: group.confidence,
         member_count: group.member_count,
         has_official_tdnet_event: group.has_official_tdnet_event,
         has_provider_overlay: group.has_provider_overlay,
         match_reasons: group.match_reasons,
         source_keys: group.source_keys,
         fields: project_group_fields(group)
       })}
    end
  end

  def project(_attrs, _opts), do: {:error, :invalid_stage59_duplicate_group_projection_attrs}

  defp project_group_fields(group) do
    %{
      group_id: group.group_id,
      confidence: group.confidence,
      member_count: group.member_count,
      has_official_tdnet_event: group.has_official_tdnet_event,
      has_provider_overlay: group.has_provider_overlay,
      match_reasons: group.match_reasons,
      source_keys: group.source_keys,
      members: Enum.map(group.members, &project_member_fields/1)
    }
  end

  defp project_member_fields(member) do
    %{
      member_id: member.member_id,
      member_kind: member.member_kind,
      source_key: member.source_key,
      provider: member.provider,
      external_id_hash: member.external_id_hash,
      official_event_id: member.official_event_id,
      overlay_id: member.overlay_id,
      confidence: member.confidence,
      match_reasons: member.match_reasons,
      redaction_status: member.redaction_status
    }
  end

  defp reject_non_projectable_members(members) do
    case Enum.find_value(members, &non_projectable_member_reason/1) do
      nil -> :ok
      reason -> {:error, reason}
    end
  end

  defp non_projectable_member_reason(member) do
    cond do
      has_present?(member, :external_id) -> {:non_projectable_member_field, :external_id}
      has_present?(member, :created_at) -> {:non_projectable_member_field, :created_at}
      has_present?(member, :updated_at) -> {:non_projectable_member_field, :updated_at}
      true -> nil
    end
  end

  defp has_present?(map, key) when is_map(map) do
    case Map.get(map, key) do
      nil -> false
      "" -> false
      value when is_binary(value) -> String.trim(value) != ""
      _value -> true
    end
  end

  defp forbid_projection_escape(opts) do
    cond do
      Keyword.get(opts, :public_exposure, false) ->
        {:error, :public_exposure_not_allowed_in_stage59_duplicate_group_projection}

      Keyword.get(opts, :public_response_shape_mutation, false) or
          Keyword.get(opts, :public_api_duplicate_group_fields, false) or
          Keyword.get(opts, :public_feed_duplicate_group_fields, false) or
          Keyword.get(opts, :item_overlays_shape_mutation, false) or
          Keyword.get(opts, :news_overlays_shape_mutation, false) or
          Keyword.get(opts, :materializer_output_mutation, false) ->
        {:error, :public_response_shape_mutation_not_allowed_in_stage59_duplicate_group_projection}

      Keyword.get(opts, :canonical_feed_mutation, false) or
          Keyword.get(opts, :provider_canonical_feed_item_creation, false) or
          Keyword.get(opts, :news_only_event_creation, false) or
          Keyword.get(opts, :official_event_merge, false) or
          Keyword.get(opts, :official_fact_override, false) or
          Keyword.get(opts, :official_citation_override, false) ->
        {:error, :canonical_mutation_not_allowed_in_stage59_duplicate_group_projection}

      Keyword.get(opts, :trigger_live_fetch, false) or Keyword.get(opts, :use_live_fetch, false) ->
        {:error, :live_fetch_not_allowed_in_stage59_duplicate_group_projection}

      Keyword.get(opts, :scheduler_enabled, false) ->
        {:error, :scheduler_not_allowed_in_stage59_duplicate_group_projection}

      Keyword.get(opts, :db_write, false) or Keyword.get(opts, :network_access, false) ->
        {:error, :runtime_side_effect_not_allowed_in_stage59_duplicate_group_projection}

      Keyword.get(opts, :route_added, false) or Keyword.get(opts, :ui_added, false) or
          Keyword.get(opts, :action_endpoint_added, false) or Keyword.get(opts, :schema_migration, false) ->
        {:error, :route_ui_action_or_schema_not_allowed_in_stage59_duplicate_group_projection}

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
        key_string in ["external_id_hash"] -> find_prohibited_field(value, current_path)
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

  defp normalize_token(value) do
    value
    |> to_string()
    |> String.downcase()
    |> String.replace(~r/[^a-z0-9]/, "")
  end
end
