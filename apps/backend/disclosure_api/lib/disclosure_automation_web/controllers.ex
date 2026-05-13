defmodule DisclosureAutomationWeb.ErrorJSON do
  @moduledoc false

  def render("404.json", _assigns),
    do: %{error: %{code: "not_found", message: "resource not found"}}

  def render("500.json", _assigns),
    do: %{error: %{code: "server_error", message: "internal server error"}}
end

defmodule DisclosureAutomationWeb.FeedDigestJSON do
  @moduledoc false

  def show(%{digest: digest}), do: digest

  def error(%{code: code, message: message}) do
    %{error: %{code: code, message: message}}
  end
end

defmodule DisclosureAutomationWeb.SourceHealthJSON do
  @moduledoc false

  def index(%{page: page}) do
    %{
      data: Enum.map(page.data, &source/1),
      page: page.page,
      page_size: page.page_size,
      total_entries: page.total_entries
    }
  end

  def show(%{source: source}), do: %{data: source(source)}
  def accepted_job(%{job: job}), do: job
  def poll_result(%{result: result}), do: result

  def error(%{code: code, message: message}) do
    %{error: %{code: code, message: message}}
  end

  def source(source) do
    %{
      source_key: source.source_key,
      display_name: source.display_name,
      source_type: source.source_type,
      base_url: source.base_url,
      healthcheck_url: source.healthcheck_url,
      parser_key: source.parser_key,
      ranking_weight: decimal_to_number(source.ranking_weight),
      poll_cron: source.poll_cron,
      coverage_tags: source.coverage_tags || [],
      active: source.active,
      config: source.config || %{},
      health_status: source.health_status,
      last_seen_published_at: iso8601(source.last_seen_published_at),
      last_success_at: iso8601(source.last_success_at),
      last_failure_at: iso8601(source.last_failure_at),
      last_error: source.last_error
    }
  end

  defp decimal_to_number(nil), do: nil
  defp decimal_to_number(%Decimal{} = value), do: Decimal.to_float(value)

  defp iso8601(nil), do: nil
  defp iso8601(%DateTime{} = value), do: DateTime.to_iso8601(value)
end

defmodule DisclosureAutomationWeb.HealthController do
  use DisclosureAutomationWeb, :controller

  alias DisclosureAutomation.Repo

  def show(conn, _params) do
    repo_status =
      case Ecto.Adapters.SQL.query(Repo, "select 1", []) do
        {:ok, _result} -> "up"
        {:error, _reason} -> "down"
      end

    json(conn, %{
      status: "ok",
      service: "disclosure_automation",
      phase: "phase1",
      repo: repo_status
    })
  end
end

defmodule DisclosureAutomationWeb.FeedDigestController do
  use DisclosureAutomationWeb, :controller

  alias DisclosureAutomation.Digest
  alias DisclosureAutomationWeb.FeedDigestJSON

  def latest(conn, %{"edition" => edition} = params) do
    timezone = Map.get(params, "timezone", "UTC")

    case Digest.get_latest_digest(edition, digest_opts(params, timezone)) do
      {:ok, digest} -> json(conn, FeedDigestJSON.show(%{digest: digest}))
      {:error, :not_found} -> render_error(conn, :not_found, "not_found", "digest not found")
      {:error, reason} -> render_error(conn, :bad_request, "invalid_request", inspect(reason))
    end
  end

  def latest(conn, _params),
    do: render_error(conn, :bad_request, "missing_edition", "edition is required")

  def show(conn, %{"digest_date" => digest_date, "edition" => edition}) do
    case Digest.get_digest_by_date_and_edition(
           digest_date,
           edition,
           digest_opts(conn.params, "UTC")
         ) do
      {:ok, digest} -> json(conn, FeedDigestJSON.show(%{digest: digest}))
      {:error, :not_found} -> render_error(conn, :not_found, "not_found", "digest not found")
      {:error, reason} -> render_error(conn, :bad_request, "invalid_request", inspect(reason))
    end
  end

  defp digest_opts(params, timezone) do
    [
      timezone: timezone,
      fallback_to_fixture: true,
      limit: bounded_positive_int(Map.get(params, "limit"), 100),
      recent_date_limit: bounded_positive_int(Map.get(params, "recent_date_limit"), 90),
      region_scope: Map.get(params, "region"),
      source_scope: source_key_list(Map.get(params, "source_keys")),
      excluded_source_keys: source_key_list(Map.get(params, "exclude_source_keys"))
    ]
    |> Enum.reject(fn {_key, value} -> is_nil(value) end)
  end

  defp bounded_positive_int(nil, _max), do: nil

  defp bounded_positive_int(value, max) when is_binary(value) do
    case Integer.parse(value) do
      {parsed, ""} when parsed > 0 -> min(parsed, max)
      _ -> nil
    end
  end

  defp source_key_list(nil), do: nil
  defp source_key_list(""), do: nil

  defp source_key_list(value) when is_binary(value) do
    value
    |> String.split(",", trim: true)
    |> Enum.map(&String.trim/1)
    |> Enum.filter(&Regex.match?(~r/^[a-z0-9_:-]+$/, &1))
    |> Enum.uniq()
    |> case do
      [] -> nil
      keys -> keys
    end
  end

  defp render_error(conn, status, code, message) do
    conn
    |> put_status(status)
    |> json(FeedDigestJSON.error(%{code: code, message: message}))
  end
end

defmodule DisclosureAutomationWeb.AdminSourceHealthController do
  use DisclosureAutomationWeb, :controller

  alias DisclosureAutomation.Sources
  alias DisclosureAutomationWeb.SourceHealthJSON

  def index(conn, params) do
    {:ok, page} = Sources.list_source_health(params)
    json(conn, SourceHealthJSON.index(%{page: page}))
  end

  def show(conn, %{"source_key" => source_key}) do
    case Sources.get_source_health(source_key) do
      {:ok, %{data: source}} -> json(conn, SourceHealthJSON.show(%{source: source}))
      {:error, :not_found} -> render_error(conn, :not_found, "not_found", "source not found")
      {:error, reason} -> render_error(conn, :bad_request, "invalid_request", inspect(reason))
    end
  end

  def recheck(conn, %{"source_key" => source_key}) do
    case Sources.enqueue_source_health_recheck(source_key) do
      {:ok, job} ->
        conn
        |> put_status(:accepted)
        |> json(SourceHealthJSON.accepted_job(%{job: job}))

      {:error, :not_found} ->
        render_error(conn, :not_found, "not_found", "source not found")

      {:error, reason} ->
        render_error(conn, :bad_request, "enqueue_failed", inspect(reason))
    end
  end

  defp render_error(conn, status, code, message) do
    conn
    |> put_status(status)
    |> json(SourceHealthJSON.error(%{code: code, message: message}))
  end
end

defmodule DisclosureAutomationWeb.AdminSourcePollController do
  use DisclosureAutomationWeb, :controller

  alias DisclosureAutomation.Ingestion
  alias DisclosureAutomationWeb.SourceHealthJSON

  def create(conn, %{"source_key" => source_key} = params) do
    edition = Map.get(params, "edition", "breaking")
    use_live_fetch = parse_bool(Map.get(params, "use_live_fetch", "true"))

    case Ingestion.poll_source(source_key,
           trigger_kind: "manual",
           edition: edition,
           use_live_fetch: use_live_fetch
         ) do
      {:ok, result} ->
        conn
        |> put_status(:accepted)
        |> json(SourceHealthJSON.poll_result(%{result: result}))

      {:error, :not_found} ->
        render_error(conn, :not_found, "not_found", "source not found")

      {:error, reason} ->
        render_error(conn, :bad_request, "poll_failed", inspect(reason))
    end
  end

  defp parse_bool(value) when value in [true, "true", "1", 1], do: true
  defp parse_bool(_value), do: false

  defp render_error(conn, status, code, message) do
    conn
    |> put_status(status)
    |> json(SourceHealthJSON.error(%{code: code, message: message}))
  end
end
