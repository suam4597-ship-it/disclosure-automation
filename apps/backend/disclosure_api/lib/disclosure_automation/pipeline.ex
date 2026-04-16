defmodule DisclosureAutomation.Canonicalizer do
  @moduledoc false

  def canonicalize_document(document, source, attrs \\ %{}) do
    published_at =
      document[:published_at] || Map.get(document, "published_at") || DateTime.utc_now()

    digest_date = Map.get(attrs, :digest_date, DateTime.to_date(published_at))
    edition = Map.get(attrs, :edition, "breaking")
    story_seed = document[:external_id] || document[:url] || document[:title] || "story"
    region_code = infer_region_code(source)
    event_id = "#{source.source_key}-#{slug(story_seed)}"

    contract_v1 = %{
      "event_id" => event_id,
      "headline_local" => document[:title] || "Untitled",
      "fact_summary_ko" => document[:summary] || "",
      "canonical_event_type" => "major_investment_or_asset_sale",
      "event_family" => Map.get(document, :category) || Map.get(document, "category") || "rss_item",
      "official_source_url" => document[:url],
      "source_tier" => Map.get(source, :default_source_tier) || "exchange_regulated_news",
      "region_code" => region_code,
      "home_market_region_code" =>
        Map.get(source, :default_home_market_region_code) || region_code,
      "published_at_utc" => DateTime.to_iso8601(published_at)
    }

    %{
      contract_v1: contract_v1,
      event_id: contract_v1["event_id"],
      region_code: contract_v1["region_code"],
      home_market_region_code: contract_v1["home_market_region_code"],
      canonical_event_type: contract_v1["canonical_event_type"],
      event_family: contract_v1["event_family"],
      digest_date: digest_date,
      edition: edition,
      story_key: "#{edition}-#{Date.to_iso8601(digest_date)}-#{slug(story_seed)}",
      headline: document[:title] || "Untitled",
      summary: document[:summary] || "",
      canonical_url: document[:url],
      published_at: published_at,
      tickers: [],
      regions: [region_code],
      sectors: infer_sectors(source),
      sentiment_label: "neutral",
      relevance_score: Decimal.new("0.900"),
      duplicate_group_key: "#{source.source_key}-#{slug(story_seed)}",
      status: "ready",
      metadata: %{
        "source_type" => source.source_type,
        "coverage_tags" => source.coverage_tags || [],
        "category" => document[:category],
        "fetch_mode" => Map.get(attrs, :fetch_mode)
      }
    }
  end

  defp infer_region_code(source) do
    Map.get(source, :region_code) ||
      cond do
        Enum.any?(source.coverage_tags || [], &(&1 in ["us", "macro", "rates", "regulatory", "markets"])) -> "us"
        Enum.any?(source.coverage_tags || [], &(&1 in ["apac", "japan"])) -> "jp"
        true -> "global"
      end
  end

  defp infer_sectors(source) do
    tags = source.coverage_tags || []

    cond do
      Enum.any?(tags, &(&1 in ["regulatory", "enforcement"])) -> ["regulation"]
      Enum.any?(tags, &(&1 in ["markets", "exchange"])) -> ["markets"]
      true -> tags
    end
  end

  defp slug(value) do
    value
    |> to_string()
    |> String.downcase()
    |> String.replace(~r/[^a-z0-9]+/u, "-")
    |> String.trim("-")
    |> case do
      "" -> "story"
      slug -> slug
    end
  end
end

defmodule DisclosureAutomation.Parser do
  @moduledoc false

  alias DisclosureAutomation.ParserCapabilities

  def parse(parser_key, raw_payload, opts \\ [])
      when is_binary(parser_key) and is_binary(raw_payload) do
    case ParserCapabilities.get(parser_key, opts) do
      {:ok, _capability} -> parse_by_key(parser_key, raw_payload)
      :error -> {:error, {:unknown_parser_key, parser_key}}
    end
  end

  defp parse_by_key("rss_v1", raw_payload), do: parse_rss(raw_payload)
  defp parse_by_key(parser_key, _raw_payload), do: {:error, {:unsupported_parser_key, parser_key}}

  defp parse_rss(raw_payload) do
    with {:ok, document} <- parse_xml(raw_payload) do
      items =
        :xmerl_xpath.string(~c"/rss/channel/item", document)
        |> Enum.map(&parse_item/1)
        |> Enum.filter(&(&1.url && &1.title))

      {:ok, items}
    end
  end

  defp parse_xml(raw_payload) do
    try do
      {document, _rest} = :xmerl_scan.string(String.to_charlist(raw_payload), quiet: true)
      {:ok, document}
    rescue
      error -> {:error, {:invalid_xml, error}}
    catch
      kind, reason -> {:error, {:invalid_xml, {kind, reason}}}
    end
  end

  defp parse_item(item) do
    link = xpath_string(item, ~c"string(link)")

    %{
      external_id: xpath_string(item, ~c"string(guid)") || link,
      title: xpath_string(item, ~c"string(title)"),
      url: link,
      summary: xpath_string(item, ~c"string(description)"),
      published_at: xpath_pub_date(item, ~c"string(pubDate)"),
      category: xpath_string(item, ~c"string(category)")
    }
  end

  defp xpath_string(node, query) do
    node
    |> :xmerl_xpath.string(query)
    |> to_string()
    |> String.trim()
    |> case do
      "" -> nil
      value -> value
    end
  end

  defp xpath_pub_date(node, query) do
    case xpath_string(node, query) do
      nil ->
        DateTime.utc_now()

      pub_date ->
        case :httpd_util.convert_request_date(String.to_charlist(pub_date)) do
          {{year, month, day}, {hour, minute, second}} ->
            {:ok, naive} = NaiveDateTime.new(year, month, day, hour, minute, second, {0, 6})
            {:ok, datetime} = DateTime.from_naive(naive, "Etc/UTC")
            datetime

          _ ->
            DateTime.utc_now()
        end
    end
  end
end

defmodule DisclosureAutomation.Jobs do
  @moduledoc false

  def enqueue(worker_module, args, opts \\ []) when is_atom(worker_module) and is_map(args) do
    queue = Keyword.get(opts, :queue)
    job_opts = if(queue, do: [queue: queue], else: [])

    case Oban.insert(worker_module.new(args, job_opts)) do
      {:ok, oban_job} ->
        {:ok,
         %{
           status: "accepted",
           job: %{
             id: oban_job.id,
             queue: oban_job.queue,
             worker: oban_job.worker,
             args: oban_job.args
           }
         }}

      {:error, reason} ->
        {:error, reason}
    end
  end
end

defmodule DisclosureAutomation.Ingestion do
  @moduledoc false

  import Ecto.Query

  alias DisclosureAutomation.Canonicalizer
  alias DisclosureAutomation.Feed
  alias DisclosureAutomation.Fixtures
  alias DisclosureAutomation.Http
  alias DisclosureAutomation.Parser
  alias DisclosureAutomation.Repo
  alias DisclosureAutomation.Runtime.Adapter
  alias DisclosureAutomation.Runtime.QueueGraph
  alias DisclosureAutomation.Schema.CanonicalFeedItem
  alias DisclosureAutomation.Schema.CanonicalItemSource
  alias DisclosureAutomation.Schema.IngestionRun
  alias DisclosureAutomation.Schema.RawDocument
  alias DisclosureAutomation.Schema.RawEvent
  alias DisclosureAutomation.Schema.SourceRegistry
  alias DisclosureAutomation.Sources

  def poll_source(source_key, opts \\ []) when is_binary(source_key) do
    with {:ok, %SourceRegistry{} = source} <- Sources.get_source_by_key(source_key) do
      case Adapter.resolve(source) do
        {:ok, adapter} -> poll_runtime_source(source, adapter, opts)
        :error -> poll_legacy_source(source, opts)
      end
    else
      {:error, reason} = error ->
        maybe_mark_lookup_failure(source_key, reason)
        error
    end
  end

  def archive_raw_documents_before(%DateTime{} = cutoff) do
    {count, _} =
      from(document in RawDocument, where: document.inserted_at < ^cutoff)
      |> Repo.update_all(set: [status: "archived"])

    {:ok, %{archived_before: cutoff, archived_count: count}}
  end

  defp poll_runtime_source(source, adapter, opts) do
    trigger_kind = Keyword.get(opts, :trigger_kind, "manual")
    edition = Keyword.get(opts, :edition, "breaking")
    use_live_fetch = Keyword.get(opts, :use_live_fetch, true)
    inline_feed = Keyword.get(opts, :inline_feed, false)

    with {:ok, discovered_items} <- adapter.discover(source, use_live_fetch: use_live_fetch) do
      result =
        Repo.transaction(fn ->
          {:ok, run} =
            %IngestionRun{}
            |> IngestionRun.changeset(%{
              source_registry_id: source.id,
              run_key: Ecto.UUID.generate(),
              trigger_kind: trigger_kind,
              status: "running",
              request_url: source.base_url,
              queued_at: DateTime.utc_now(),
              started_at: DateTime.utc_now(),
              meta: %{"queue_graph" => QueueGraph.definition()}
            })
            |> Repo.insert()

          persisted =
            discovered_items
            |> Enum.with_index(1)
            |> Enum.map(fn {discovery_item, rank} ->
              {:ok, hydrated_item} =
                adapter.hydrate(source, discovery_item, use_live_fetch: use_live_fetch)

              {:ok, primary_raw_document} =
                upsert_runtime_raw_document(run, source, hydrated_item.submission_document)

              {:ok, detail_raw_document} =
                upsert_runtime_raw_document(run, source, hydrated_item.detail_document)

              case adapter.parse(source, hydrated_item) do
                {:ok, [raw_event_attrs | _]} ->
                  {:ok, raw_event_record} =
                    upsert_raw_event(source, primary_raw_document, raw_event_attrs)

                  digest_date =
                    if raw_event_record.occurred_at,
                      do: DateTime.to_date(raw_event_record.occurred_at),
                      else: Date.utc_today()

                  {:ok, canonical_attrs} =
                    adapter.normalize(source, raw_event_record,
                      digest_date: digest_date,
                      edition: edition
                    )

                  {:ok, canonical_item} =
                    upsert_runtime_canonical_item(
                      primary_raw_document,
                      source,
                      canonical_attrs,
                      rank
                    )

                  {:ok, _primary_source} =
                    upsert_canonical_item_source(
                      canonical_item,
                      raw_event_record,
                      primary_raw_document,
                      source,
                      source_name: "SEC EDGAR Complete Submission Text File",
                      source_tier: "official_regulatory_storage",
                      source_role: "primary",
                      authority_rank: 1,
                      is_representative: true,
                      metadata: %{}
                    )

                  {:ok, _detail_source} =
                    upsert_canonical_item_source(
                      canonical_item,
                      raw_event_record,
                      detail_raw_document,
                      source,
                      source_name: "SEC EDGAR Filing Detail Index",
                      source_tier: "official_regulatory_storage",
                      source_role: "discovery",
                      authority_rank: 2,
                      is_representative: false,
                      metadata: %{}
                    )

                  %{
                    discovery_item: discovery_item,
                    primary_raw_document: primary_raw_document,
                    detail_raw_document: detail_raw_document,
                    raw_event: raw_event_record,
                    canonical_item: canonical_item
                  }

                _ ->
                  %{
                    discovery_item: discovery_item,
                    primary_raw_document: primary_raw_document,
                    detail_raw_document: detail_raw_document,
                    raw_event: nil,
                    canonical_item: nil
                  }
              end
            end)

          latest_cursor =
            persisted
            |> Enum.map(& &1.discovery_item.accession_no)
            |> Enum.sort()
            |> List.last()

          if latest_cursor do
            {:ok, _cursor} =
              Sources.upsert_source_cursor(source, adapter.cursor_key(), latest_cursor, %{
                "queue_graph" => QueueGraph.definition()
              })
          end

          latest_published_at =
            persisted
            |> Enum.map(fn row -> row.canonical_item && row.canonical_item.published_at end)
            |> Enum.reject(&is_nil/1)
            |> case do
              [] -> DateTime.utc_now()
              values -> Enum.max_by(values, &DateTime.to_unix/1)
            end

          run =
            run
            |> IngestionRun.changeset(%{
              status: "succeeded",
              finished_at: DateTime.utc_now(),
              records_seen: length(discovered_items),
              records_inserted: Enum.count(persisted, & &1.canonical_item),
              records_updated: 0,
              records_rejected: 0,
              source_cursor: latest_cursor
            })
            |> Repo.update!()

          {:ok, _source} = Sources.mark_poll_success(source, latest_published_at)

          %{
            source: source,
            run: run,
            latest_cursor: latest_cursor,
            discovered_count: length(discovered_items),
            persisted: persisted,
            inline_feed: inline_feed,
            region_codes: [source.region_code || "us"]
          }
        end)

      case result do
        {:ok, runtime_result} ->
          feed_result = finalize_feed(runtime_result)

          {:ok,
           %{
             source_key: runtime_result.source.source_key,
             edition: edition,
             queue_graph: QueueGraph.definition(),
             records_seen: runtime_result.discovered_count,
             raw_documents:
               Enum.flat_map(runtime_result.persisted, fn row ->
                 [row.primary_raw_document.id, row.detail_raw_document.id]
               end),
             raw_events:
               runtime_result.persisted
               |> Enum.map(fn row -> row.raw_event && row.raw_event.event_key end)
               |> Enum.reject(&is_nil/1),
             canonical_items:
               runtime_result.persisted
               |> Enum.map(fn row -> row.canonical_item && row.canonical_item.event_id end)
               |> Enum.reject(&is_nil/1),
             cursor: %{
               cursor_key: adapter.cursor_key(),
               cursor_value: runtime_result.latest_cursor
             },
             feed: feed_result
           }}

        {:error, reason} ->
          handle_failure(source, reason)
      end
    else
      {:error, reason} -> handle_failure(source, reason)
    end
  end

  defp finalize_feed(%{inline_feed: true, run: run, region_codes: region_codes}) do
    case Feed.rebuild_snapshots(region_codes, ingestion_run_id: run.id) do
      {:ok, snapshots} ->
        %{mode: "inline", snapshots: Enum.map(snapshots, & &1.payload)}

      {:error, reason} ->
        %{mode: "inline_failed", reason: inspect(reason)}
    end
  end

  defp finalize_feed(%{inline_feed: false, run: run, region_codes: region_codes}) do
    case Feed.enqueue_rebuild(region_codes, ingestion_run_id: run.id) do
      {:ok, job} -> %{mode: "enqueued", job: job}
      {:error, reason} -> %{mode: "enqueue_failed", reason: inspect(reason)}
    end
  end

  defp poll_legacy_source(source, opts) do
    trigger_kind = Keyword.get(opts, :trigger_kind, "manual")
    edition = Keyword.get(opts, :edition, "breaking")
    use_live_fetch = Keyword.get(opts, :use_live_fetch, true)
    inline_feed = Keyword.get(opts, :inline_feed, false)

    with {:ok, payload} <- load_payload(source, use_live_fetch: use_live_fetch),
         {:ok, records} <-
           Parser.parse(source.parser_key, payload.raw_payload, cache: parser_cache()) do
      result =
        Repo.transaction(fn ->
          {:ok, run} =
            %IngestionRun{}
            |> IngestionRun.changeset(%{
              source_registry_id: source.id,
              run_key: Ecto.UUID.generate(),
              trigger_kind: trigger_kind,
              status: "running",
              request_url: source.base_url,
              queued_at: DateTime.utc_now(),
              started_at: DateTime.utc_now(),
              http_status: payload.http_status,
              meta: %{"fetch" => payload.fetch_info}
            })
            |> Repo.insert()

          persisted =
            records
            |> Enum.with_index(1)
            |> Enum.map(fn {record, rank} ->
              {:ok, raw_document} = upsert_legacy_raw_document(run, source, record)

              {:ok, canonical_item} =
                upsert_legacy_canonical_item(
                  raw_document,
                  source,
                  record,
                  edition,
                  rank,
                  payload.fetch_info
                )

              %{raw_document: raw_document, canonical_item: canonical_item}
            end)

          latest_published_at =
            persisted
            |> Enum.map(& &1.raw_document.published_at)
            |> Enum.reject(&is_nil/1)
            |> case do
              [] -> DateTime.utc_now()
              values -> Enum.max_by(values, &DateTime.to_unix/1)
            end

          run =
            run
            |> IngestionRun.changeset(%{
              status: "succeeded",
              finished_at: DateTime.utc_now(),
              records_seen: length(records),
              records_inserted: length(records),
              records_updated: 0,
              records_rejected: 0
            })
            |> Repo.update!()

          {:ok, _source} = Sources.mark_poll_success(source, latest_published_at)

          %{
            source: source,
            run: run,
            persisted: persisted,
            inline_feed: inline_feed,
            region_codes: [source.region_code || "us"],
            fetch: payload.fetch_info,
            records_seen: length(records)
          }
        end)

      case result do
        {:ok, legacy_result} ->
          feed_result = finalize_feed(legacy_result)

          {:ok,
           %{
             source_key: legacy_result.source.source_key,
             edition: edition,
             fetch: legacy_result.fetch,
             records_seen: legacy_result.records_seen,
             records_inserted: length(legacy_result.persisted),
             raw_documents: Enum.map(legacy_result.persisted, & &1.raw_document.id),
             canonical_items:
               Enum.map(
                 legacy_result.persisted,
                 &(&1.canonical_item.event_id || &1.canonical_item.story_key)
               ),
             feed: feed_result
           }}

        {:error, reason} ->
          handle_failure(source, reason)
      end
    else
      {:error, reason} -> handle_failure(source, reason)
    end
  end

  defp maybe_mark_lookup_failure(source_key, reason) do
    with {:ok, source} <- Sources.get_source_by_key(source_key) do
      Sources.mark_poll_failure(source, reason)
    end
  end

  defp handle_failure(source, reason) do
    _ = Sources.mark_poll_failure(source, reason)
    {:error, reason}
  end

  defp load_payload(source, opts) do
    prefer_live_fetch = Keyword.get(opts, :use_live_fetch, true)

    case maybe_load_live_payload(source, prefer_live_fetch) do
      {:ok, payload} -> {:ok, payload}
      {:error, _reason} when prefer_live_fetch -> load_fixture_payload(source)
      :skip -> load_fixture_payload(source)
    end
  end

  defp maybe_load_live_payload(source, true) do
    with {:ok, response} <- Http.fetch(source.base_url, timeout: 8_000),
         true <- response.status_code in 200..299 do
      {:ok,
       %{
         raw_payload: response.body,
         http_status: response.status_code,
         fetch_info: %{
           "mode" => "live",
           "loaded" => true,
           "url" => source.base_url,
           "status_code" => response.status_code,
           "bytes" => response.bytes
         }
       }}
    else
      false -> {:error, :unexpected_status}
      {:error, _reason} = error -> error
    end
  end

  defp maybe_load_live_payload(_source, false), do: :skip

  defp load_fixture_payload(source) do
    fixture_path = source.config["fixture_path"] || source.config[:fixture_path]

    with {:ok, payload} <- Fixtures.load_source_payload(fixture_path) do
      {:ok,
       %{
         raw_payload: payload.raw,
         http_status: nil,
         fetch_info: %{
           "mode" => "fixture",
           "loaded" => true,
           "relative_path" => payload.relative_path,
           "bytes" => payload.bytes
         }
       }}
    end
  end

  defp upsert_runtime_raw_document(run, source, attrs) do
    case Repo.get_by(RawDocument, source_registry_id: source.id, external_id: attrs.external_id) do
      %RawDocument{} = existing ->
        {:ok, existing}

      nil ->
        payload = %{
          ingestion_run_id: run.id,
          source_registry_id: source.id,
          external_id: attrs.external_id,
          document_identity: attrs.document_identity || attrs.external_id,
          document_type: attrs.document_type,
          document_role: attrs.document_role,
          mime_type: attrs.mime_type,
          content_hash: hash_text(attrs.body_text),
          fetched_at: DateTime.utc_now(),
          published_at: attrs.published_at,
          url: attrs.url,
          title: attrs.document_type,
          language: "en",
          raw_text: attrs.body_text,
          payload: %{
            "document_identity" => attrs.document_identity || attrs.external_id,
            "document_type" => attrs.document_type,
            "document_role" => attrs.document_role,
            "url" => attrs.url
          },
          source_metadata: attrs.metadata || %{},
          status: "parsed"
        }

        %RawDocument{}
        |> RawDocument.changeset(payload)
        |> Repo.insert()
    end
  end

  defp upsert_raw_event(source, raw_document, attrs) do
    case Repo.get_by(RawEvent, source_registry_id: source.id, event_key: attrs.event_key) do
      %RawEvent{} = existing ->
        {:ok, existing}

      nil ->
        payload = %{
          source_registry_id: source.id,
          raw_document_id: raw_document.id,
          event_key: attrs.event_key,
          external_event_key: attrs.external_event_key,
          parser_key: attrs.parser_key,
          event_family: attrs.event_family,
          occurred_at: attrs.occurred_at,
          parsed_at: DateTime.utc_now(),
          status: attrs.status || "parsed",
          payload: attrs.payload || %{},
          metadata: attrs.metadata || %{}
        }

        %RawEvent{}
        |> RawEvent.changeset(payload)
        |> Repo.insert()
    end
  end

  defp upsert_runtime_canonical_item(raw_document, source, canonical_attrs, priority_rank) do
    attrs =
      canonical_attrs
      |> Map.put(:raw_document_id, raw_document.id)
      |> Map.put(:source_registry_id, source.id)
      |> Map.put(:priority_rank, priority_rank)
      |> project_contract_v1()

    case Repo.get_by(CanonicalFeedItem, event_id: attrs.event_id) do
      %CanonicalFeedItem{} = existing ->
        {:ok, existing}

      nil ->
        %CanonicalFeedItem{}
        |> CanonicalFeedItem.changeset(attrs)
        |> Repo.insert()
    end
  end

  defp upsert_legacy_raw_document(run, source, record) do
    now = DateTime.utc_now()

    attrs = %{
      ingestion_run_id: run.id,
      source_registry_id: source.id,
      external_id: record.external_id || record.url,
      content_hash: hash_record(record),
      fetched_at: now,
      published_at: record.published_at,
      url: record.url,
      title: record.title,
      raw_text: record.summary,
      payload: %{
        "title" => record.title,
        "summary" => record.summary,
        "url" => record.url,
        "published_at" => record.published_at && DateTime.to_iso8601(record.published_at),
        "category" => record.category
      },
      status: "parsed"
    }

    changeset = RawDocument.changeset(%RawDocument{}, attrs)

    Repo.insert(
      changeset,
      conflict_target: [:source_registry_id, :external_id],
      on_conflict: [
        set: [
          ingestion_run_id: run.id,
          content_hash: attrs.content_hash,
          fetched_at: now,
          published_at: record.published_at,
          url: record.url,
          title: record.title,
          raw_text: record.summary,
          payload: attrs.payload,
          status: "parsed",
          updated_at: now
        ]
      ],
      returning: true
    )
  end

  defp upsert_legacy_canonical_item(raw_document, source, record, edition, priority_rank, fetch_info) do
    canonical_attrs =
      record
      |> Canonicalizer.canonicalize_document(
        source,
        edition: edition,
        fetch_mode: fetch_info["mode"]
      )
      |> Map.merge(%{
        raw_document_id: raw_document.id,
        source_registry_id: source.id,
        priority_rank: priority_rank
      })
      |> project_contract_v1()

    changeset = CanonicalFeedItem.changeset(%CanonicalFeedItem{}, canonical_attrs)

    Repo.insert(
      changeset,
      conflict_target: [:story_key],
      on_conflict: [
        set: [
          raw_document_id: canonical_attrs.raw_document_id,
          source_registry_id: canonical_attrs.source_registry_id,
          event_id: canonical_attrs.event_id,
          region_code: canonical_attrs.region_code,
          home_market_region_code: canonical_attrs.home_market_region_code,
          canonical_event_type: canonical_attrs.canonical_event_type,
          event_family: canonical_attrs.event_family,
          digest_date: canonical_attrs.digest_date,
          edition: canonical_attrs.edition,
          headline: canonical_attrs.headline,
          summary: canonical_attrs.summary,
          canonical_url: canonical_attrs.canonical_url,
          published_at: canonical_attrs.published_at,
          tickers: canonical_attrs.tickers,
          regions: canonical_attrs.regions,
          sectors: canonical_attrs.sectors,
          sentiment_label: canonical_attrs.sentiment_label,
          relevance_score: canonical_attrs.relevance_score,
          priority_rank: canonical_attrs.priority_rank,
          duplicate_group_key: canonical_attrs.duplicate_group_key,
          status: canonical_attrs.status,
          metadata: canonical_attrs.metadata,
          contract_v1: canonical_attrs.contract_v1,
          updated_at: DateTime.utc_now()
        ]
      ],
      returning: true
    )
  end

  defp upsert_canonical_item_source(canonical_item, raw_event, raw_document, source, attrs) do
    source_role = attrs[:source_role]

    case Repo.get_by(CanonicalItemSource,
           canonical_feed_item_id: canonical_item.id,
           raw_event_id: raw_event.id,
           source_role: source_role
         ) do
      %CanonicalItemSource{} = existing ->
        {:ok, existing}

      nil ->
        payload = %{
          canonical_feed_item_id: canonical_item.id,
          raw_event_id: raw_event.id,
          raw_document_id: raw_document.id,
          source_registry_id: source.id,
          source_name: attrs[:source_name],
          source_tier: attrs[:source_tier],
          source_role: source_role,
          authority_rank: attrs[:authority_rank],
          is_representative: attrs[:is_representative] || false,
          linked_at: DateTime.utc_now(),
          promoted_at: if(attrs[:is_representative], do: DateTime.utc_now(), else: nil),
          metadata: attrs[:metadata] || %{}
        }

        %CanonicalItemSource{}
        |> CanonicalItemSource.changeset(payload)
        |> Repo.insert()
    end
  end

  defp project_contract_v1(%{contract_v1: contract_v1} = attrs) when is_map(contract_v1) do
    attrs
    |> Map.put(:event_id, contract_v1["event_id"])
    |> Map.put(:region_code, contract_v1["region_code"])
    |> Map.put(:home_market_region_code, contract_v1["home_market_region_code"])
    |> Map.put(:canonical_event_type, contract_v1["canonical_event_type"])
    |> Map.put(:event_family, contract_v1["event_family"])
    |> Map.put(:metadata, Map.get(attrs, :metadata, %{}) || %{})
  end

  defp hash_record(record) do
    :sha256
    |> :crypto.hash("#{record.external_id}|#{record.url}|#{record.title}|#{record.published_at}")
    |> Base.encode16(case: :lower)
  end

  defp hash_text(text) do
    :sha256
    |> :crypto.hash(text || "")
    |> Base.encode16(case: :lower)
  end

  defp parser_cache do
    Application.get_env(:disclosure_automation, :parser_capabilities_cache, %{})
  end
end

defmodule DisclosureAutomation.Digest do
  @moduledoc false

  import Ecto.Query

  alias DisclosureAutomation.Fixtures
  alias DisclosureAutomation.Repo
  alias DisclosureAutomation.Schema.CanonicalFeedItem

  def get_latest_digest(edition, opts \\ []) when is_binary(edition) do
    case latest_digest_date_for_edition(edition) do
      nil -> fallback_to_fixture(edition, nil, opts)
      digest_date -> get_digest_by_date_and_edition(Date.to_iso8601(digest_date), edition, opts)
    end
  end

  def get_digest_by_date_and_edition(digest_date, edition, opts \\ [])
      when is_binary(digest_date) and is_binary(edition) do
    timezone = Keyword.get(opts, :timezone, "UTC")
    limit = Keyword.get(opts, :limit, 12)

    with {:ok, digest_date} <- Date.from_iso8601(digest_date) do
      items =
        from(item in CanonicalFeedItem,
          where:
            item.digest_date == ^digest_date and item.edition == ^edition and
              item.status in ["ready", "published"],
          order_by: [asc: item.priority_rank, desc: item.published_at],
          limit: ^limit
        )
        |> Repo.all()

      if items == [] do
        fallback_to_fixture(edition, digest_date, opts)
      else
        {:ok,
         %{
           "digest_date" => Date.to_iso8601(digest_date),
           "edition" => edition,
           "timezone" => timezone,
           "generated_at" =>
             DateTime.utc_now() |> DateTime.truncate(:second) |> DateTime.to_iso8601(),
           "generated_by" => "repo",
           "item_count" => length(items),
           "items" => Enum.map(items, &present_item/1),
           "metadata" => %{
             "fallback_to_fixture" => false,
             "top_n" => limit
           }
         }}
      end
    else
      {:error, _reason} -> {:error, :not_found}
    end
  end

  defp latest_digest_date_for_edition(edition) do
    from(item in CanonicalFeedItem,
      where: item.edition == ^edition and item.status in ["ready", "published"],
      select: max(item.digest_date)
    )
    |> Repo.one()
  end

  defp fallback_to_fixture(edition, digest_date, opts) do
    if Keyword.get(opts, :fallback_to_fixture, false) do
      with {:ok, digest} <- Fixtures.load_daily_digest(),
           true <- digest["edition"] == edition,
           true <- is_nil(digest_date) or digest["digest_date"] == Date.to_iso8601(digest_date) do
        {:ok, digest}
      else
        _ -> {:error, :not_found}
      end
    else
      {:error, :not_found}
    end
  end

  defp present_item(item) do
    if map_size(item.contract_v1 || %{}) > 0 do
      item.contract_v1
    else
      %{
        "story_key" => item.story_key,
        "headline" => item.headline,
        "summary" => item.summary
      }
    end
  end
end

defmodule DisclosureAutomation.Workers.RecomputeSourceHealthWorker do
  @moduledoc false

  use Oban.Worker, queue: :health_checks, max_attempts: 5

  alias DisclosureAutomation.Sources

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"source_key" => source_key}}) do
    case Sources.recompute_source_health(source_key) do
      {:ok, _source} -> :ok
      {:error, :not_found} -> {:cancel, :source_not_found}
      {:error, reason} -> {:error, inspect(reason)}
    end
  end
end

defmodule DisclosureAutomation.Workers.PollSourceWorker do
  @moduledoc false

  use Oban.Worker, queue: :source_polling, max_attempts: 5

  alias DisclosureAutomation.Ingestion

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"source_key" => source_key} = args}) do
    trigger_kind = Map.get(args, "trigger_kind", "scheduled")
    edition = Map.get(args, "edition", "breaking")
    use_live_fetch = Map.get(args, "use_live_fetch", true)
    inline_feed = Map.get(args, "inline_feed", false)

    case Ingestion.poll_source(source_key,
           trigger_kind: trigger_kind,
           edition: edition,
           use_live_fetch: use_live_fetch,
           inline_feed: inline_feed
         ) do
      {:ok, _result} -> :ok
      {:error, :not_found} -> {:cancel, :source_not_found}
      {:error, reason} -> {:error, inspect(reason)}
    end
  end
end
