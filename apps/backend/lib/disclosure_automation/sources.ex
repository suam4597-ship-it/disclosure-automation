defmodule DisclosureAutomation.Sources do
  @moduledoc """
  Reference runtime for source-registry and delivery-window operations.
  """

  alias DisclosureAutomation.Jobs
  alias DisclosureAutomation.Store
  alias DisclosureAutomation.Workers.RecomputeSourceHealthWorker

  def upsert_source(attrs) when is_map(attrs) do
    source_key = attrs["source_key"] || attrs[:source_key]

    if blank?(source_key) do
      {:error, :missing_source_key}
    else
      normalized =
        attrs
        |> stringify_keys()
        |> Map.put_new("health_status", "unknown")
        |> Map.put_new("active", true)
        |> Map.put_new("coverage_tags", [])

      Store.put(:sources, source_key, normalized)
    end
  end

  def upsert_delivery_window(attrs) when is_map(attrs) do
    window_key = attrs["window_key"] || attrs[:window_key]

    if blank?(window_key) do
      {:error, :missing_window_key}
    else
      normalized = attrs |> stringify_keys() |> Map.put_new("active", true)
      Store.put(:delivery_windows, window_key, normalized)
    end
  end

  def list_source_health(params \\ %{}) do
    params = stringify_keys(params)

    sources =
      Store.list(:sources)
      |> Enum.filter(&matches_filters?(&1, params))
      |> Enum.sort_by(&{&1["display_name"] || "", &1["source_key"] || ""})

    page = parse_positive_int(params["page"], 1)
    page_size = parse_positive_int(params["page_size"], 50)
    offset = max(page - 1, 0) * page_size
    paged = sources |> Enum.drop(offset) |> Enum.take(page_size)

    {:ok,
     %{
       data: paged,
       page: page,
       page_size: page_size,
       total_entries: length(sources)
     }}
  end

  def get_source_health(source_key) when is_binary(source_key) do
    case Store.get(:sources, source_key) do
      nil -> {:error, :not_found}
      source -> {:ok, %{data: source}}
    end
  end

  def enqueue_source_health_recheck(source_key) when is_binary(source_key) do
    case Store.get(:sources, source_key) do
      nil -> {:error, :not_found}
      _source -> Jobs.enqueue(RecomputeSourceHealthWorker, :health_checks, %{"source_key" => source_key})
    end
  end

  def recompute_source_health(source_key) when is_binary(source_key) do
    case Store.get(:sources, source_key) do
      nil -> {:error, :not_found}
      source ->
        updated =
          source
          |> Map.put("health_status", recompute_status(source))
          |> Map.put("last_success_at", DateTime.utc_now())
          |> Map.put("last_error", nil)

        Store.put(:sources, source_key, updated)
    end
  end

  def get_source_by_key(source_key) when is_binary(source_key) do
    case Store.get(:sources, source_key) do
      nil -> nil
      source -> source
    end
  end

  defp recompute_status(%{"active" => false}), do: "paused"
  defp recompute_status(_source), do: "healthy"

  defp matches_filters?(source, params) do
    matches_boolean_filter?(source, "active", params["active"]) and
      matches_string_filter?(source, "health_status", params["health_status"]) and
      matches_string_filter?(source, "source_type", params["source_type"])
  end

  defp matches_boolean_filter?(_source, _key, nil), do: true
  defp matches_boolean_filter?(source, key, expected) do
    to_string(source[key]) == to_string(expected)
  end

  defp matches_string_filter?(_source, _key, nil), do: true
  defp matches_string_filter?(source, key, expected), do: source[key] == expected

  defp parse_positive_int(nil, default), do: default
  defp parse_positive_int(value, default) when is_integer(value), do: if(value > 0, do: value, else: default)
  defp parse_positive_int(value, default) when is_binary(value) do
    case Integer.parse(value) do
      {parsed, ""} when parsed > 0 -> parsed
      _ -> default
    end
  end

  defp stringify_keys(map) do
    map
    |> Enum.map(fn {k, v} -> {to_string(k), v} end)
    |> Enum.into(%{})
  end

  defp blank?(value), do: is_nil(value) or value == ""
end
