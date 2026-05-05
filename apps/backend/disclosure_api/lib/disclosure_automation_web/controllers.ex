defmodule DisclosureAutomationWeb.ErrorJSON do
  @moduledoc false

  def render("404.json", _assigns),
    do: %{error: %{code: "not_found", message: "resource not found"}}

  def render("500.json", _assigns),
    do: %{error: %{code: "server_error", message: "internal server error"}}
end

defmodule DisclosureAutomationWeb.FeedDigestJSON do
  @moduledoc false

  alias DisclosureAutomation.Runtime.Stage5NewsOverlayReadModel

  def show(%{digest: digest}), do: decorate_digest(digest)

  def error(%{code: code, message: message}) do
    %{error: %{code: code, message: message}}
  end

  defp decorate_digest(%{} = digest) do
    Map.update(digest, "items", [], fn items -> Enum.map(items || [], &decorate_item/1) end)
  end

  defp decorate_digest(digest), do: digest

  defp decorate_item(%{} = item) do
    Map.put(item, "news_overlays", news_overlays_for(item["event_id"] || item["story_key"]))
  end

  defp decorate_item(item), do: item

  defp news_overlays_for(nil), do: []

  defp news_overlays_for(event_id) when is_binary(event_id) do
    case Stage5NewsOverlayReadModel.get_by_event_id(event_id) do
      {:ok, %{item: %{overlays: overlays}}} -> Enum.map(overlays, &present_overlay/1)
      _ -> []
    end
  end

  defp present_overlay(overlay) do
    %{
      "overlay_id" => overlay.overlayId,
      "overlay_type" => overlay.overlayType,
      "overlay_mode" => overlay.overlayMode,
      "display_state" => overlay.displayState,
      "source_key" => overlay.sourceKey,
      "provider" => overlay.provider,
      "source_tier" => overlay.sourceTier,
      "document_role" => overlay.documentRole,
      "article_external_id" => overlay.articleExternalId,
      "raw_document_external_id" => overlay.rawDocumentExternalId,
      "raw_event_external_id" => overlay.rawEventExternalId,
      "title" => overlay.title,
      "published_at" => overlay.publishedAt,
      "url" => overlay.url,
      "language" => overlay.language,
      "jurisdiction" => overlay.jurisdiction,
      "canonical_fact_override" => overlay.canonicalFactOverride,
      "overlay_claims" => Enum.map(overlay.overlayClaims || [], &present_overlay_claim/1),
      "conflict_flags" => overlay.conflictFlags || [],
      "citations" => Enum.map(overlay.citations || [], &present_overlay_citation/1)
    }
  end

  defp present_overlay_claim(claim) do
    %{
      "claim_id" => claim.claimId,
      "claim_type" => claim.claimType,
      "text" => claim.text,
      "source_key" => claim.sourceKey,
      "source_tier" => claim.sourceTier,
      "document_role" => claim.documentRole,
      "citation_id" => claim.citationId,
      "canonical_fact_override" => claim.canonicalFactOverride
    }
  end

  defp present_overlay_citation(citation) do
    %{
      "citation_id" => citation.citationId,
      "source_key" => citation.sourceKey,
      "source_tier" => citation.sourceTier,
      "document_role" => citation.documentRole,
      "provider" => citation.provider,
      "url" => citation.url,
      "label" => citation.label,
      "is_canonical_source" => citation.isCanonicalSource
    }
  end
end

defmodule DisclosureAutomationWeb.FeedJSON do
  @moduledoc false

  def show(%{feed: feed}), do: feed

  def error(%{code: code, message: message}) do
    %{error: %{code: code, message: message}}
  end
end

defmodule DisclosureAutomationWeb.EventJSON do
  @moduledoc false

  def show(%{event: event}), do: %{data: event}

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

  def show(%{source: source, cursors: cursors}),
    do: %{data: Map.put(source(source), :cursors, cursors)}

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
      adapter_key: source.adapter_key,
      region_code: source.region_code,
      discovery_mode: source.discovery_mode,
      hydrate_mode: source.hydrate_mode,
      default_home_market_region_code: source.default_home_market_region_code,
      source_class: source.source_class,
      default_source_tier: source.default_source_tier,
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
  alias DisclosureAutomation.Runtime.QueueGraph

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
      repo: repo_status,
      queue_graph: QueueGraph.definition()
    })
  end
end

defmodule DisclosureAutomationWeb.FeedDigestController do
  use DisclosureAutomationWeb, :controller

  alias DisclosureAutomation.Digest
  alias DisclosureAutomationWeb.FeedDigestJSON

  def latest(conn, %{"edition" => edition} = params) do
    timezone = Map.get(params, "timezone", "UTC")

    case Digest.get_latest_digest(edition, timezone: timezone, fallback_to_fixture: true) do
      {:ok, digest} -> json(conn, FeedDigestJSON.show(%{digest: digest}))
      {:error, :not_found} -> render_error(conn, :not_found, "not_found", "digest not found")
      {:error, reason} -> render_error(conn, :bad_request, "invalid_request", inspect(reason))
    end
  end

  def latest(conn, _params),
    do: render_error(conn, :bad_request, "missing_edition", "edition is required")

  def show(conn, %{"digest_date" => digest_date, "edition" => edition}) do
    case Digest.get_digest_by_date_and_edition(digest_date, edition, fallback_to_fixture: true) do
      {:ok, digest} -> json(conn, FeedDigestJSON.show(%{digest: digest}))
      {:error, :not_found} -> render_error(conn, :not_found, "not_found", "digest not found")
      {:error, reason} -> render_error(conn, :bad_request, "invalid_request", inspect(reason))
    end
  end

  defp render_error(conn, status, code, message) do
    conn
    |> put_status(status)
    |> json(FeedDigestJSON.error(%{code: code, message: message}))
  end
end

defmodule DisclosureAutomationWeb.FeedController do
  use DisclosureAutomationWeb, :controller

  alias DisclosureAutomation.Feed
  alias DisclosureAutomationWeb.FeedJSON

  def hero(conn, _params) do
    case Feed.get_hero() do
      {:ok, feed} -> json(conn, FeedJSON.show(%{feed: feed}))
      {:error, reason} -> render_error(conn, :bad_request, "feed_unavailable", inspect(reason))
    end
  end

  def region(conn, %{"region_code" => region_code}) do
    case Feed.get_region(region_code) do
      {:ok, feed} -> json(conn, FeedJSON.show(%{feed: feed}))
      {:error, reason} -> render_error(conn, :bad_request, "feed_unavailable", inspect(reason))
    end
  end

  defp render_error(conn, status, code, message) do
    conn
    |> put_status(status)
    |> json(FeedJSON.error(%{code: code, message: message}))
  end
end

defmodule DisclosureAutomationWeb.EventController do
  use DisclosureAutomationWeb, :controller

  alias DisclosureAutomation.Feed
  alias DisclosureAutomationWeb.EventJSON

  def show(conn, %{"event_id" => event_id}) do
    case Feed.get_event(event_id) do
      {:ok, event} -> json(conn, EventJSON.show(%{event: event}))
      {:error, :not_found} -> render_error(conn, :not_found, "not_found", "event not found")
      {:error, reason} -> render_error(conn, :bad_request, "invalid_request", inspect(reason))
    end
  end

  defp render_error(conn, status, code, message) do
    conn
    |> put_status(status)
    |> json(EventJSON.error(%{code: code, message: message}))
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
      {:ok, %{data: source, cursors: cursors}} ->
        json(conn, SourceHealthJSON.show(%{source: source, cursors: cursors}))

      {:error, :not_found} ->
        render_error(conn, :not_found, "not_found", "source not found")

      {:error, reason} ->
        render_error(conn, :bad_request, "invalid_request", inspect(reason))
    end
  end

  def recheck(conn, %{"source_key" => source_key} = params) do
    case Sources.enqueue_source_health_recheck(source_key, params) do
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
  alias DisclosureAutomation.SourceHealthPollRuntime
  alias DisclosureAutomationWeb.SourceHealthJSON

  def create(conn, %{"source_key" => source_key} = params) do
    case SourceHealthPollRuntime.prepare_poll(source_key, params) do
      {:ok, %{"poll_status" => "accepted"}} ->
        execute_poll(conn, source_key, params)

      {:ok, result} ->
        conn
        |> put_status(:accepted)
        |> json(SourceHealthJSON.poll_result(%{result: result}))

      {:error, :missing_idempotency_key} ->
        render_error(conn, :conflict, "missing_idempotency_key", "poll idempotency key required")

      {:error, {:rate_limited, rate_limit_status}} ->
        render_rate_limited(conn, rate_limit_status)

      {:error, :not_found} ->
        render_error(conn, :not_found, "not_found", "source not found")
    end
  end

  defp execute_poll(conn, source_key, params) do
    edition = Map.get(params, "edition", "breaking")
    use_live_fetch = parse_bool(Map.get(params, "use_live_fetch", "true"))
    # inline_feed is smoke/admin/debug only; operational default is async feed rebuild
    inline_feed = parse_bool(Map.get(params, "inline_feed", "false"))

    case Ingestion.poll_source(source_key,
           trigger_kind: "manual",
           edition: edition,
           use_live_fetch: use_live_fetch,
           inline_feed: inline_feed
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

  defp render_rate_limited(conn, rate_limit_status) do
    conn
    |> put_status(:too_many_requests)
    |> json(%{
      "error" => %{
        "code" => "rate_limited",
        "message" => "source poll rate limited",
        "rate_limit_status" => rate_limit_status
      }
    })
  end

  defp render_error(conn, status, code, message) do
    conn
    |> put_status(status)
    |> json(SourceHealthJSON.error(%{code: code, message: message}))
  end
end
