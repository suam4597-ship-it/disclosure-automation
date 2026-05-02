defmodule DisclosureAutomation.Runtime.Stage57InternalSourceHealthProjection do
  @moduledoc false

  alias DisclosureAutomation.Runtime.Stage57OperatorViewProjectionContract
  alias DisclosureAutomation.Sources

  def list(params \\ %{}, opts \\ [])

  def list(params, opts) when is_map(params) do
    with :ok <- read_only_opts(opts),
         {:ok, page} <- Sources.list_source_health(params) do
      project_page(page, opts)
    end
  end

  def list(_params, _opts), do: {:error, :invalid_source_health_projection_params}

  def get(source_key, opts \\ [])

  def get(source_key, opts) when is_binary(source_key) do
    with :ok <- read_only_opts(opts),
         {:ok, %{data: source, cursors: cursors}} <- Sources.get_source_health(source_key),
         {:ok, projection} <- project_source(source, cursors, opts) do
      {:ok, projection}
    end
  end

  def get(_source_key, _opts), do: {:error, :invalid_source_key}

  defp project_page(%{data: data} = page, opts) when is_list(data) do
    with {:ok, projections} <- project_sources(data, opts) do
      {:ok,
       %{
         view_scope: "operator_only",
         read_only: true,
         advisory_only: true,
         public_response_shape_mutation: false,
         trigger_live_fetch: false,
         scheduler_enabled: false,
         source_health_mutation: false,
         canonical_feed_mutation: false,
         data: projections,
         page: Map.get(page, :page),
         page_size: Map.get(page, :page_size),
         total_entries: Map.get(page, :total_entries)
       }}
    end
  end

  defp project_sources(sources, opts) do
    sources
    |> Enum.reduce_while({:ok, []}, fn source, {:ok, acc} ->
      case project_source(source, [], opts) do
        {:ok, projection} -> {:cont, {:ok, [projection | acc]}}
        {:error, reason} -> {:halt, {:error, reason}}
      end
    end)
    |> case do
      {:ok, projections} -> {:ok, Enum.reverse(projections)}
      {:error, reason} -> {:error, reason}
    end
  end

  defp project_source(source, cursors, opts) do
    source
    |> projection_attrs(cursors)
    |> Stage57OperatorViewProjectionContract.project(opts)
  end

  defp projection_attrs(source, cursors) do
    %{
      "source_key" => field(source, :source_key),
      "display_name" => field(source, :display_name),
      "provider" => provider(source),
      "source_type" => field(source, :source_type),
      "active" => field(source, :active),
      "health_status" => field(source, :health_status) || "unknown",
      "last_success_at" => field(source, :last_success_at),
      "last_failure_at" => field(source, :last_failure_at),
      "last_seen_published_at" => field(source, :last_seen_published_at),
      "error_class" => error_class(field(source, :last_error)),
      "redaction_status" => redaction_status(source),
      "manual_review_reason" => manual_review_reason(source),
      "request_id_hash" => request_id_hash(source),
      "cursor_keys" => cursor_keys(cursors),
      "has_recent_safe_overlay" => false,
      "has_visible_overlays" => false
    }
  end

  defp read_only_opts(opts) do
    cond do
      Keyword.get(opts, :public_exposure, false) ->
        {:error, :public_exposure_not_allowed_in_stage57_source_health_projection}

      Keyword.get(opts, :trigger_live_fetch, false) or Keyword.get(opts, :use_live_fetch, false) ->
        {:error, :live_fetch_not_allowed_in_stage57_source_health_projection}

      Keyword.get(opts, :scheduler_enabled, false) ->
        {:error, :scheduler_not_allowed_in_stage57_source_health_projection}

      Keyword.get(opts, :source_health_mutation, false) ->
        {:error, :source_health_mutation_not_allowed_in_stage57_source_health_projection}

      true ->
        :ok
    end
  end

  defp field(source, key) when is_map(source) do
    cond do
      Map.has_key?(source, key) -> Map.get(source, key)
      Map.has_key?(source, to_string(key)) -> Map.get(source, to_string(key))
      true -> nil
    end
  end

  defp field(_source, _key), do: nil

  defp provider(source), do: field(source, :adapter_key) || field(source, :source_key)

  defp cursor_keys(cursors) when is_list(cursors) do
    cursors
    |> Enum.map(&field(&1, :cursor_key))
    |> Enum.reject(&is_nil/1)
  end

  defp cursor_keys(_cursors), do: []

  defp error_class(nil), do: nil

  defp error_class(error) when is_binary(error) do
    error
    |> String.split([" ", ":", "{"], parts: 2)
    |> List.first()
  end

  defp error_class(_error), do: "provider_error"

  defp redaction_status(source), do: get_config_value(source, "redaction_status") || "passed"
  defp manual_review_reason(source), do: get_config_value(source, "manual_review_reason")
  defp request_id_hash(source), do: get_config_value(source, "request_id_hash")

  defp get_config_value(source, key) do
    source
    |> field(:config)
    |> case do
      %{} = config -> field(config, key)
      _ -> nil
    end
  end
end
