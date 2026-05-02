defmodule DisclosureAutomation.Runtime.Stage59DuplicateGroupInternalReadProjection do
  @moduledoc false

  import Ecto.Query

  alias DisclosureAutomation.Repo
  alias DisclosureAutomation.Schema.SourceDuplicateGroup
  alias DisclosureAutomation.Schema.SourceDuplicateGroupMember

  @allowed_filters ~w(confidence source_key member_kind redaction_status limit)
  @max_limit 100

  def allowed_filters, do: @allowed_filters

  def defaults do
    %{
      view_scope: "operator_only_duplicate_group_review",
      read_only: true,
      advisory_only: true,
      bounded: true,
      redacted: true,
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
      route_added: false,
      ui_added: false,
      action_endpoint_added: false,
      materializer_triggered: false
    }
  end

  def list(params \\ %{}, opts \\ [])

  def list(params, opts) when is_map(params) do
    with :ok <- read_only_opts(opts),
         {:ok, filters} <- normalize_filters(params),
         {:ok, groups} <- fetch_groups(filters),
         {:ok, projected} <- project_groups(groups, opts) do
      {:ok,
       defaults()
       |> Map.merge(%{
         mode: "stage59_internal_duplicate_group_list_projection",
         filters: redacted_filters(filters),
         items: projected,
         item_count: length(projected),
         limit: filters.limit
       })}
    end
  end

  def list(_params, _opts), do: {:error, :invalid_stage59_duplicate_group_projection_params}

  def get(group_id, opts \\ [])

  def get(group_id, opts) when is_binary(group_id) do
    with :ok <- read_only_opts(opts),
         {:ok, group_id} <- bounded_group_id(group_id),
         {:ok, group} <- fetch_group(group_id),
         {:ok, projected} <- project_group(group, opts) do
      {:ok,
       defaults()
       |> Map.merge(%{
         mode: "stage59_internal_duplicate_group_show_projection",
         item: projected
       })}
    end
  end

  def get(_group_id, _opts), do: {:error, :invalid_duplicate_group_id}

  defp normalize_filters(params) do
    with :ok <- reject_unknown_filters(params),
         {:ok, confidence} <- optional_bounded_filter(params, :confidence, SourceDuplicateGroup.confidence_states()),
         {:ok, source_key} <- optional_bounded_filter(params, :source_key, nil),
         {:ok, member_kind} <- optional_bounded_filter(params, :member_kind, SourceDuplicateGroupMember.member_kinds()),
         {:ok, redaction_status} <- optional_bounded_filter(params, :redaction_status, SourceDuplicateGroup.redaction_statuses()),
         {:ok, limit} <- bounded_limit(get_param(params, :limit, 50)) do
      {:ok,
       %{
         confidence: confidence,
         source_key: source_key,
         member_kind: member_kind,
         redaction_status: redaction_status,
         limit: limit
       }}
    end
  end

  defp reject_unknown_filters(params) do
    unknown =
      params
      |> Map.keys()
      |> Enum.map(&to_string/1)
      |> Enum.reject(&(&1 in @allowed_filters))

    case unknown do
      [] -> :ok
      [filter | _] -> {:error, {:unsupported_duplicate_group_filter, filter}}
    end
  end

  defp optional_bounded_filter(params, key, allowed_values) do
    case get_param(params, key) do
      nil ->
        {:ok, nil}

      value when is_binary(value) ->
        normalized = String.trim(value)

        cond do
          normalized == "" -> {:ok, nil}
          String.length(normalized) > 160 -> {:error, {:duplicate_group_filter_too_long, key}}
          not is_nil(allowed_values) and normalized not in allowed_values -> {:error, {:invalid_duplicate_group_filter, key, value}}
          true -> {:ok, normalized}
        end

      value ->
        {:error, {:invalid_duplicate_group_filter, key, value}}
    end
  end

  defp bounded_limit(nil), do: {:ok, 50}
  defp bounded_limit(value) when is_integer(value) and value >= 1 and value <= @max_limit, do: {:ok, value}

  defp bounded_limit(value) when is_binary(value) do
    case Integer.parse(value) do
      {limit, ""} -> bounded_limit(limit)
      _ -> {:error, {:invalid_duplicate_group_limit, value}}
    end
  end

  defp bounded_limit(value), do: {:error, {:invalid_duplicate_group_limit, value}}

  defp fetch_groups(filters) do
    groups =
      SourceDuplicateGroup
      |> maybe_filter_group(:confidence, filters.confidence)
      |> maybe_filter_group(:redaction_status, filters.redaction_status)
      |> order_by([group], asc: group.group_id)
      |> limit(^filters.limit)
      |> Repo.all()
      |> Enum.filter(&matches_member_filters?(&1.group_id, filters))

    {:ok, groups}
  end

  defp maybe_filter_group(query, _field, nil), do: query
  defp maybe_filter_group(query, field, value), do: where(query, [group], field(group, ^field) == ^value)

  defp matches_member_filters?(group_id, %{source_key: nil, member_kind: nil}), do: member_count(group_id) > 0

  defp matches_member_filters?(group_id, filters) do
    SourceDuplicateGroupMember
    |> where([member], member.group_id == ^group_id)
    |> maybe_filter_member(:source_key, filters.source_key)
    |> maybe_filter_member(:member_kind, filters.member_kind)
    |> Repo.aggregate(:count) > 0
  end

  defp maybe_filter_member(query, _field, nil), do: query
  defp maybe_filter_member(query, field, value), do: where(query, [member], field(member, ^field) == ^value)

  defp fetch_group(group_id) do
    case Repo.one(from group in SourceDuplicateGroup, where: group.group_id == ^group_id) do
      nil -> {:error, :duplicate_group_not_found}
      group -> {:ok, group}
    end
  end

  defp project_groups(groups, opts) do
    groups
    |> Enum.map(fn group ->
      {:ok, projected} = project_group(group, opts)
      projected
    end)
    |> then(&{:ok, &1})
  end

  defp project_group(group, _opts) do
    members = members_for(group.group_id)

    {:ok,
     %{
       group_id: group.group_id,
       confidence: group.confidence,
       source_keys: items(group.source_keys),
       match_reasons: items(group.match_reasons),
       member_count: group.member_count,
       has_official_tdnet_event: group.has_official_tdnet_event,
       has_provider_overlay: group.has_provider_overlay,
       redaction_status: group.redaction_status,
       inserted_at: group.inserted_at,
       updated_at: group.updated_at,
       members: Enum.map(members, &project_member/1)
     }}
  end

  defp project_member(member) do
    %{
      member_id: member.member_id,
      member_kind: member.member_kind,
      source_key: member.source_key,
      provider: member.provider,
      external_id_hash: member.external_id_hash,
      official_event_id: member.official_event_id,
      overlay_id: member.overlay_id,
      confidence: member.confidence,
      match_reasons: items(member.match_reasons),
      redaction_status: member.redaction_status,
      inserted_at: member.inserted_at,
      updated_at: member.updated_at
    }
  end

  defp members_for(group_id) do
    Repo.all(from member in SourceDuplicateGroupMember, where: member.group_id == ^group_id, order_by: [asc: member.member_id])
  end

  defp member_count(group_id) do
    SourceDuplicateGroupMember
    |> where([member], member.group_id == ^group_id)
    |> Repo.aggregate(:count)
  end

  defp items(%{"items" => items}) when is_list(items), do: items
  defp items(%{items: items}) when is_list(items), do: items
  defp items(_value), do: []

  defp redacted_filters(filters) do
    filters
    |> Map.take([:confidence, :source_key, :member_kind, :redaction_status, :limit])
    |> Enum.reject(fn {_key, value} -> is_nil(value) end)
    |> Map.new()
  end

  defp bounded_group_id(group_id) do
    normalized = String.trim(group_id)

    cond do
      normalized == "" -> {:error, :invalid_duplicate_group_id}
      String.length(normalized) > 160 -> {:error, :invalid_duplicate_group_id}
      true -> {:ok, normalized}
    end
  end

  defp read_only_opts(opts) do
    cond do
      Keyword.get(opts, :public_exposure, false) ->
        {:error, :public_exposure_not_allowed_in_stage59_duplicate_group_read_projection}

      Keyword.get(opts, :public_response_shape_mutation, false) or
          Keyword.get(opts, :public_api_duplicate_group_fields, false) or
          Keyword.get(opts, :public_feed_duplicate_group_fields, false) or
          Keyword.get(opts, :item_overlays_shape_mutation, false) or
          Keyword.get(opts, :news_overlays_shape_mutation, false) or
          Keyword.get(opts, :materializer_output_mutation, false) ->
        {:error, :public_response_shape_mutation_not_allowed_in_stage59_duplicate_group_read_projection}

      Keyword.get(opts, :canonical_feed_mutation, false) or
          Keyword.get(opts, :provider_canonical_feed_item_creation, false) or
          Keyword.get(opts, :news_only_event_creation, false) or
          Keyword.get(opts, :official_event_merge, false) or
          Keyword.get(opts, :official_fact_override, false) or
          Keyword.get(opts, :official_citation_override, false) ->
        {:error, :canonical_mutation_not_allowed_in_stage59_duplicate_group_read_projection}

      Keyword.get(opts, :trigger_live_fetch, false) or Keyword.get(opts, :use_live_fetch, false) ->
        {:error, :live_fetch_not_allowed_in_stage59_duplicate_group_read_projection}

      Keyword.get(opts, :scheduler_enabled, false) ->
        {:error, :scheduler_not_allowed_in_stage59_duplicate_group_read_projection}

      Keyword.get(opts, :network_access, false) ->
        {:error, :network_access_not_allowed_in_stage59_duplicate_group_read_projection}

      Keyword.get(opts, :route_added, false) or Keyword.get(opts, :ui_added, false) or
          Keyword.get(opts, :action_endpoint_added, false) or Keyword.get(opts, :materializer_triggered, false) ->
        {:error, :route_ui_action_or_materializer_not_allowed_in_stage59_duplicate_group_read_projection}

      true ->
        :ok
    end
  end

  defp get_param(params, key, default \\ nil) do
    cond do
      Map.has_key?(params, key) -> Map.get(params, key)
      Map.has_key?(params, to_string(key)) -> Map.get(params, to_string(key))
      true -> default
    end
  end
end
