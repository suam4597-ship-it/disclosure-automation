defmodule DisclosureAutomation.Runtime.Stage59DuplicateGroupNoopService do
  @moduledoc false

  alias DisclosureAutomation.Runtime.Stage59DuplicateGroupProjectionContract

  @allowed_source_keys ~w(
    jp_tdnet_timely_disclosure
    stage5_news_overlay_fixture
    stage53_news_overlay_fixture
  )

  def allowed_source_keys, do: @allowed_source_keys

  def defaults do
    %{
      service_scope: "internal_duplicate_group_noop_only",
      bounded: true,
      redacted: true,
      advisory_only: true,
      operator_only: true,
      non_canonical: true,
      no_op: true,
      fake_existing_fixtures_only: true,
      duplicate_group_contract_required: true,
      duplicate_group_projection_required: true,
      grouping_materialized: false,
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

  def preview_group(attrs, opts \\ [])

  def preview_group(attrs, opts) when is_map(attrs) do
    with :ok <- forbid_noop_escape(opts),
         {:ok, projection} <- Stage59DuplicateGroupProjectionContract.project(attrs, opts),
         :ok <- validate_existing_fixture_sources(projection.source_keys) do
      {:ok,
       defaults()
       |> Map.merge(%{
         group_id: projection.group_id,
         confidence: projection.confidence,
         member_count: projection.member_count,
         source_keys: projection.source_keys,
         match_reasons: projection.match_reasons,
         projection: projection,
         preview_result: build_preview_result(projection)
       })}
    end
  end

  def preview_group(_attrs, _opts), do: {:error, :invalid_stage59_duplicate_group_noop_attrs}

  defp build_preview_result(projection) do
    %{
      mode: "stage59_noop_duplicate_group_preview",
      group_id: projection.group_id,
      confidence: projection.confidence,
      member_count: projection.member_count,
      source_keys: projection.source_keys,
      match_reasons: projection.match_reasons,
      no_op: true,
      fake_existing_fixtures_only: true,
      grouping_materialized: false,
      db_write: false,
      network_access: "forbidden",
      trigger_live_fetch: false,
      scheduler_enabled: false,
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
      route_added: false,
      ui_added: false,
      action_endpoint_added: false,
      schema_migration: false
    }
  end

  defp validate_existing_fixture_sources(source_keys) when is_list(source_keys) do
    case Enum.find(source_keys, &(&1 not in @allowed_source_keys)) do
      nil -> :ok
      source_key -> {:error, {:source_key_not_allowed_in_stage59_noop_service, source_key}}
    end
  end

  defp validate_existing_fixture_sources(_source_keys), do: {:error, :source_keys_required}

  defp forbid_noop_escape(opts) do
    cond do
      Keyword.get(opts, :public_exposure, false) ->
        {:error, :public_exposure_not_allowed_in_stage59_noop_service}

      Keyword.get(opts, :public_response_shape_mutation, false) or
          Keyword.get(opts, :public_api_duplicate_group_fields, false) or
          Keyword.get(opts, :public_feed_duplicate_group_fields, false) or
          Keyword.get(opts, :item_overlays_shape_mutation, false) or
          Keyword.get(opts, :news_overlays_shape_mutation, false) or
          Keyword.get(opts, :materializer_output_mutation, false) ->
        {:error, :public_response_shape_mutation_not_allowed_in_stage59_noop_service}

      Keyword.get(opts, :canonical_feed_mutation, false) or
          Keyword.get(opts, :provider_canonical_feed_item_creation, false) or
          Keyword.get(opts, :news_only_event_creation, false) or
          Keyword.get(opts, :official_event_merge, false) or
          Keyword.get(opts, :official_fact_override, false) or
          Keyword.get(opts, :official_citation_override, false) ->
        {:error, :canonical_mutation_not_allowed_in_stage59_noop_service}

      Keyword.get(opts, :trigger_live_fetch, false) or Keyword.get(opts, :use_live_fetch, false) ->
        {:error, :live_fetch_not_allowed_in_stage59_noop_service}

      Keyword.get(opts, :scheduler_enabled, false) ->
        {:error, :scheduler_not_allowed_in_stage59_noop_service}

      Keyword.get(opts, :db_write, false) or Keyword.get(opts, :network_access, false) ->
        {:error, :runtime_side_effect_not_allowed_in_stage59_noop_service}

      Keyword.get(opts, :route_added, false) or Keyword.get(opts, :ui_added, false) or
          Keyword.get(opts, :action_endpoint_added, false) or Keyword.get(opts, :schema_migration, false) ->
        {:error, :route_ui_action_or_schema_not_allowed_in_stage59_noop_service}

      true ->
        :ok
    end
  end
end
