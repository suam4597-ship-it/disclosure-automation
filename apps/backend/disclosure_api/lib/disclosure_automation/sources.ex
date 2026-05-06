defmodule DisclosureAutomation.Sources do
  @moduledoc false

  import Ecto.Query

  alias DisclosureAutomation.Jobs
  alias DisclosureAutomation.Repo
  alias DisclosureAutomation.Schema.DeliveryWindow
  alias DisclosureAutomation.Schema.SourceRegistry
  alias DisclosureAutomation.Workers.RecomputeSourceHealthWorker

  def upsert_source(attrs) when is_map(attrs) do
    attrs = normalize_source_attrs(attrs)
    source_key = attrs[:source_key]

    source =
      Repo.get_by(SourceRegistry, source_key: source_key) ||
        %SourceRegistry{}

    source
    |> SourceRegistry.changeset(attrs)
    |> Repo.insert_or_update()
  end

  def upsert_delivery_window(attrs) when is_map(attrs) do
    attrs = normalize_window_attrs(attrs)
    window_key = attrs[:window_key]

    window =
      Repo.get_by(DeliveryWindow, window_key: window_key) ||
        %DeliveryWindow{}

    window
    |> DeliveryWindow.changeset(attrs)
    |> Repo.insert_or_update()
  end

  def list_source_health(params \\ %{}) do
    params = stringify_keys(params)
    page = parse_positive_int(params["page"], 1)
    page_size = parse_positive_int(params["page_size"], 50)

    query =
      SourceRegistry
      |> maybe_filter_active(params["active"])
      |> maybe_filter_string(:health_status, params["health_status"])
      |> maybe_filter_string(:source_type, params["source_type"])

    total_entries = Repo.aggregate(query, :count)

    data =
      query
      |> order_by([source], asc: source.display_name, asc: source.source_key)
      |> offset(^((page - 1) * page_size))
      |> limit(^page_size)
      |> Repo.all()

    {:ok, %{data: data, page: page, page_size: page_size, total_entries: total_entries}}
  end

  def get_source_health(source_key) when is_binary(source_key) do
    case Repo.get_by(SourceRegistry, source_key: source_key) do
      nil -> {:error, :not_found}
      source -> {:ok, %{data: source}}
    end
  end

  def get_source_by_key(source_key) when is_binary(source_key) do
    case Repo.get_by(SourceRegistry, source_key: source_key) do
      nil -> {:error, :not_found}
      source -> {:ok, source}
    end
  end

  def enqueue_source_health_recheck(source_key) when is_binary(source_key) do
    case Repo.get_by(SourceRegistry, source_key: source_key) do
      nil ->
        {:error, :not_found}

      _source ->
        Jobs.enqueue(RecomputeSourceHealthWorker, %{"source_key" => source_key},
          queue: :health_checks
        )
    end
  end

  def recompute_source_health(source_key) when is_binary(source_key) do
    case Repo.get_by(SourceRegistry, source_key: source_key) do
      nil ->
        {:error, :not_found}

      source ->
        source
        |> SourceRegistry.changeset(%{
          health_status: recompute_status(source),
          last_success_at: DateTime.utc_now(),
          last_error: nil
        })
        |> Repo.update()
    end
  end

  def mark_poll_success(%SourceRegistry{} = source, published_at) do
    source
    |> SourceRegistry.changeset(%{
      health_status: "healthy",
      last_seen_published_at: published_at,
      last_success_at: DateTime.utc_now(),
      last_error: nil
    })
    |> Repo.update()
  end

  def mark_poll_failure(%SourceRegistry{} = source, reason) do
    source
    |> SourceRegistry.changeset(%{
      health_status: "failed",
      last_failure_at: DateTime.utc_now(),
      last_error: inspect(reason)
    })
    |> Repo.update()
  end

  defp recompute_status(%SourceRegistry{active: false}), do: "paused"
  defp recompute_status(_source), do: "healthy"

  defp normalize_source_attrs(attrs) do
    %{
      source_key: get_value(attrs, "source_key"),
      display_name: get_value(attrs, "display_name"),
      source_type: get_value(attrs, "source_type"),
      base_url: get_value(attrs, "base_url"),
      healthcheck_url: get_value(attrs, "healthcheck_url"),
      parser_key: get_value(attrs, "parser_key"),
      ranking_weight: get_value(attrs, "ranking_weight") || Decimal.new("1.0"),
      poll_cron: get_value(attrs, "poll_cron"),
      coverage_tags: get_value(attrs, "coverage_tags") || [],
      active: get_value(attrs, "active"),
      config: get_value(attrs, "config") || %{},
      health_status: get_value(attrs, "health_status") || "unknown"
    }
  end

  defp normalize_window_attrs(attrs) do
    %{
      window_key: get_value(attrs, "window_key"),
      edition: get_value(attrs, "edition"),
      channel: get_value(attrs, "channel"),
      timezone: get_value(attrs, "timezone"),
      weekdays: get_value(attrs, "weekdays") || [1, 2, 3, 4, 5],
      opens_at_local: get_value(attrs, "opens_at_local"),
      closes_at_local: get_value(attrs, "closes_at_local"),
      cutoff_minutes: get_value(attrs, "cutoff_minutes") || 30,
      active: get_value(attrs, "active"),
      config: get_value(attrs, "config") || %{}
    }
  end

  defp get_value(map, key), do: Map.get(map, key) || Map.get(map, String.to_atom(key))

  defp maybe_filter_active(query, nil), do: query

  defp maybe_filter_active(query, value) do
    normalized =
      case value do
        true -> true
        false -> false
        "true" -> true
        "false" -> false
        _ -> nil
      end

    if is_boolean(normalized) do
      from source in query, where: source.active == ^normalized
    else
      query
    end
  end

  defp maybe_filter_string(query, _field, nil), do: query

  defp maybe_filter_string(query, field, value) do
    from source in query, where: field(source, ^field) == ^value
  end

  defp parse_positive_int(nil, default), do: default

  defp parse_positive_int(value, default) when is_integer(value),
    do: if(value > 0, do: value, else: default)

  defp parse_positive_int(value, default) when is_binary(value) do
    case Integer.parse(value) do
      {parsed, ""} when parsed > 0 -> parsed
      _ -> default
    end
  end

  defp stringify_keys(map) do
    Enum.into(map, %{}, fn {k, v} -> {to_string(k), v} end)
  end
end
