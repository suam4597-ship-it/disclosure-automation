defmodule DisclosureAutomation.Runtime.Stage59DuplicateGroupInternalMaterializer do
  @moduledoc false

  alias DisclosureAutomation.Repo
  alias DisclosureAutomation.Runtime.Stage59DuplicateGroupNoopService
  alias DisclosureAutomation.Schema.SourceDuplicateGroup
  alias DisclosureAutomation.Schema.SourceDuplicateGroupMember

  def defaults do
    %{
      materializer_scope: "internal_duplicate_group_materializer_only",
      bounded: true,
      redacted: true,
      advisory_only: true,
      operator_only: true,
      non_canonical: true,
      existing_fixtures_only: true,
      duplicate_group_contract_required: true,
      duplicate_group_projection_required: true,
      schema_changesets_required: true,
      grouping_materialized: true,
      network_access: "forbidden",
      trigger_live_fetch: false,
      scheduler_enabled: false,
      route_added: false,
      ui_added: false,
      action_endpoint_added: false,
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
      official_citation_override: false
    }
  end

  def materialize_group(attrs, opts \\ [])

  def materialize_group(attrs, opts) when is_map(attrs) do
    with :ok <- forbid_materializer_escape(opts),
         {:ok, preview} <- Stage59DuplicateGroupNoopService.preview_group(attrs, opts),
         {:ok, persisted} <- persist_projection(preview.projection) do
      {:ok, build_result(preview, persisted)}
    end
  end

  def materialize_group(_attrs, _opts), do: {:error, :invalid_stage59_duplicate_group_materializer_attrs}

  defp persist_projection(projection) do
    Repo.transaction(fn ->
      with {:ok, group} <- upsert_group(projection),
           {:ok, members} <- upsert_members(projection) do
        %{group: group, members: members}
      else
        {:error, reason} -> Repo.rollback(reason)
      end
    end)
  end

  defp upsert_group(projection) do
    fields = projection.fields

    attrs = %{
      "group_id" => fields.group_id,
      "confidence" => fields.confidence,
      "source_keys" => %{"items" => fields.source_keys},
      "match_reasons" => %{"items" => fields.match_reasons},
      "member_count" => fields.member_count,
      "has_official_tdnet_event" => fields.has_official_tdnet_event,
      "has_provider_overlay" => fields.has_provider_overlay,
      "redaction_status" => group_redaction_status(fields.members)
    }

    %SourceDuplicateGroup{}
    |> SourceDuplicateGroup.changeset(attrs)
    |> Repo.insert(
      on_conflict: {:replace_all_except, [:id, :inserted_at]},
      conflict_target: [:group_id],
      returning: true
    )
  end

  defp upsert_members(projection) do
    projection.fields.members
    |> Enum.reduce_while({:ok, []}, fn member, {:ok, acc} ->
      case upsert_member(projection.group_id, member) do
        {:ok, persisted} -> {:cont, {:ok, [persisted | acc]}}
        {:error, reason} -> {:halt, {:error, reason}}
      end
    end)
    |> case do
      {:ok, members} -> {:ok, Enum.reverse(members)}
      error -> error
    end
  end

  defp upsert_member(group_id, member) do
    attrs = %{
      "group_id" => group_id,
      "member_id" => member.member_id,
      "member_kind" => member.member_kind,
      "source_key" => member.source_key,
      "provider" => member.provider,
      "external_id_hash" => member.external_id_hash,
      "official_event_id" => member.official_event_id,
      "overlay_id" => member.overlay_id,
      "confidence" => member.confidence,
      "match_reasons" => %{"items" => member.match_reasons},
      "redaction_status" => member.redaction_status
    }

    %SourceDuplicateGroupMember{}
    |> SourceDuplicateGroupMember.changeset(attrs)
    |> Repo.insert(
      on_conflict: {:replace_all_except, [:id, :inserted_at]},
      conflict_target: [:group_id, :member_id],
      returning: true
    )
  end

  defp build_result(preview, persisted) do
    defaults()
    |> Map.merge(%{
      mode: "stage59_internal_duplicate_group_materialized",
      group_id: preview.group_id,
      members_seen: preview.member_count,
      groups_upserted: if(is_nil(persisted.group), do: 0, else: 1),
      members_upserted: length(persisted.members)
    })
  end

  defp group_redaction_status(members) do
    statuses = Enum.map(members, & &1.redaction_status)

    cond do
      Enum.any?(statuses, &(&1 == "blocked")) -> "blocked"
      Enum.any?(statuses, &(&1 == "failed")) -> "failed"
      Enum.all?(statuses, &(&1 == "passed")) -> "passed"
      true -> "unknown"
    end
  end

  defp forbid_materializer_escape(opts) do
    cond do
      Keyword.get(opts, :public_exposure, false) ->
        {:error, :public_exposure_not_allowed_in_stage59_duplicate_group_materializer}

      Keyword.get(opts, :public_response_shape_mutation, false) or
          Keyword.get(opts, :public_api_duplicate_group_fields, false) or
          Keyword.get(opts, :public_feed_duplicate_group_fields, false) or
          Keyword.get(opts, :item_overlays_shape_mutation, false) or
          Keyword.get(opts, :news_overlays_shape_mutation, false) or
          Keyword.get(opts, :materializer_output_mutation, false) ->
        {:error, :public_response_shape_mutation_not_allowed_in_stage59_duplicate_group_materializer}

      Keyword.get(opts, :canonical_feed_mutation, false) or
          Keyword.get(opts, :provider_canonical_feed_item_creation, false) or
          Keyword.get(opts, :news_only_event_creation, false) or
          Keyword.get(opts, :official_event_merge, false) or
          Keyword.get(opts, :official_fact_override, false) or
          Keyword.get(opts, :official_citation_override, false) ->
        {:error, :canonical_mutation_not_allowed_in_stage59_duplicate_group_materializer}

      Keyword.get(opts, :trigger_live_fetch, false) or Keyword.get(opts, :use_live_fetch, false) ->
        {:error, :live_fetch_not_allowed_in_stage59_duplicate_group_materializer}

      Keyword.get(opts, :scheduler_enabled, false) ->
        {:error, :scheduler_not_allowed_in_stage59_duplicate_group_materializer}

      Keyword.get(opts, :network_access, false) ->
        {:error, :network_access_not_allowed_in_stage59_duplicate_group_materializer}

      Keyword.get(opts, :route_added, false) or Keyword.get(opts, :ui_added, false) or
          Keyword.get(opts, :action_endpoint_added, false) or Keyword.get(opts, :schema_migration, false) ->
        {:error, :route_ui_action_or_schema_not_allowed_in_stage59_duplicate_group_materializer}

      true ->
        :ok
    end
  end
end
