defmodule DisclosureAutomation.Canonicalizer do
  @moduledoc false

  def canonicalize_document(document, source, attrs \\ %{}) do
    attrs = Map.new(attrs)

    published_at =
      document[:published_at] || Map.get(document, "published_at") || DateTime.utc_now()

    digest_date = Map.get(attrs, :digest_date, DateTime.to_date(published_at))
    edition = Map.get(attrs, :edition, "breaking")
    story_seed = document[:external_id] || document[:url] || document[:title] || "story"

    %{
      digest_date: digest_date,
      edition: edition,
      story_key: "#{edition}-#{Date.to_iso8601(digest_date)}-#{slug(story_seed)}",
      headline: document[:title] || "Untitled",
      summary: document[:summary] || "",
      canonical_url: document[:url],
      published_at: published_at,
      tickers: [],
      regions: infer_regions(source),
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

  defp infer_regions(source) do
    tags = Enum.map(source.coverage_tags || [], &String.downcase/1)

    cond do
      "global" in tags -> ["global"]
      "kr" in tags or "korea" in tags -> ["kr"]
      "jp" in tags or "japan" in tags -> ["jp"]
      "greater_china" in tags or "cn_tw" in tags -> ["greater_china"]
      "hk" in tags or "hong_kong" in tags or "hongkong" in tags -> ["hk"]
      "cn" in tags or "china" in tags -> ["cn"]
      "tw" in tags or "taiwan" in tags -> ["tw"]
      "eu_north" in tags or "europe_north" in tags -> ["eu_north"]
      "eu_central" in tags or "europe_central" in tags -> ["eu_central"]
      "eu_south" in tags or "europe_south" in tags -> ["eu_south"]
      "eu" in tags or "europe" in tags -> ["eu"]
      "asean" in tags or "southeast_asia" in tags -> ["asean"]
      "india" in tags or "in" in tags -> ["india"]
      "anz" in tags or "australia_nz" in tags -> ["anz"]
      "apac" in tags -> ["apac"]
      "us" in tags or "usa" in tags or "americas" in tags -> ["us"]
      Enum.any?(tags, &(&1 in ["macro", "rates", "regulatory", "markets"])) -> ["us"]
      true -> ["global"]
    end
  end

  defp infer_sectors(source) do
    tags = Enum.map(source.coverage_tags || [], &String.downcase/1)

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
      {:ok, capability} ->
        case parse_by_key(parser_key, raw_payload) do
          {:ok, records} -> {:ok, limit_records(records, capability, opts)}
          {:error, _reason} = error -> error
        end

      :error ->
        {:error, {:unknown_parser_key, parser_key}}
    end
  end

  defp parse_by_key("rss_v1", raw_payload), do: parse_rss(raw_payload)
  defp parse_by_key(parser_key, _raw_payload), do: {:error, {:unsupported_parser_key, parser_key}}

  defp limit_records(records, capability, opts) when is_list(records) and is_map(capability) do
    capability_limit =
      positive_int(
        Map.get(capability, "max_items_per_poll") || Map.get(capability, :max_items_per_poll)
      )

    source_limit = positive_int(Keyword.get(opts, :max_items_per_poll))

    case effective_limit(capability_limit, source_limit) do
      nil -> records
      max_items -> Enum.take(records, max_items)
    end
  end

  defp effective_limit(nil, nil), do: nil
  defp effective_limit(nil, source_limit), do: source_limit
  defp effective_limit(capability_limit, nil), do: capability_limit
  defp effective_limit(capability_limit, source_limit), do: min(capability_limit, source_limit)

  defp positive_int(value) when is_integer(value) and value > 0, do: value

  defp positive_int(value) when is_binary(value) do
    case Integer.parse(value) do
      {parsed, ""} when parsed > 0 -> parsed
      _ -> nil
    end
  end

  defp positive_int(_value), do: nil

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
      {document, _rest} =
        raw_payload
        |> normalize_xml_payload()
        |> :xmerl_scan.string(quiet: true)

      {:ok, document}
    rescue
      error -> {:error, {:invalid_xml, error}}
    catch
      kind, reason -> {:error, {:invalid_xml, {kind, reason}}}
    end
  end

  defp normalize_xml_payload(raw_payload) do
    raw_payload
    |> String.replace(<<0xEF, 0xBB, 0xBF>>, "")
    |> String.replace("…", "...")
    |> String.replace("‘", "'")
    |> String.replace("’", "'")
    |> String.replace("“", "\"")
    |> String.replace("”", "\"")
    |> String.replace("–", "-")
    |> String.replace("—", "-")
    |> String.replace(<<0xC2, 0xA0>>, " ")
    |> String.to_charlist()
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
    query
    |> :xmerl_xpath.string(node)
    |> xpath_value()
    |> to_string()
    |> String.trim()
    |> case do
      "" -> nil
      value -> value
    end
  end

  defp xpath_value({:xmlObj, :string, value}), do: value
  defp xpath_value(value), do: value

  defp xpath_pub_date(node, query) do
    case xpath_string(node, query) do
      nil ->
        DateTime.utc_now()

      pub_date ->
        case :httpd_util.convert_request_date(String.to_charlist(pub_date)) do
          {{year, month, day}, {hour, minute, second}} ->
            case build_utc_datetime(year, month, day, hour, minute, second) do
              {:ok, datetime} -> datetime
              :error -> DateTime.utc_now()
            end

          _ ->
            parse_short_month_pub_date(pub_date)
        end
    end
  end

  defp parse_short_month_pub_date(pub_date) do
    with [_, day_text, month_text, year_text, hour_text, minute_text, second_text] <-
           Regex.run(~r/^(\d{1,2})-([A-Za-z]{3})-(\d{4}) (\d{2}):(\d{2}):(\d{2})$/, pub_date),
         {day, ""} <- Integer.parse(day_text),
         {:ok, month} <- month_number(month_text),
         {year, ""} <- Integer.parse(year_text),
         {hour, ""} <- Integer.parse(hour_text),
         {minute, ""} <- Integer.parse(minute_text),
         {second, ""} <- Integer.parse(second_text),
         {:ok, datetime} <- build_utc_datetime(year, month, day, hour, minute, second) do
      datetime
    else
      _ -> DateTime.utc_now()
    end
  end

  defp month_number(month) do
    case String.downcase(month) do
      "jan" -> {:ok, 1}
      "feb" -> {:ok, 2}
      "mar" -> {:ok, 3}
      "apr" -> {:ok, 4}
      "may" -> {:ok, 5}
      "jun" -> {:ok, 6}
      "jul" -> {:ok, 7}
      "aug" -> {:ok, 8}
      "sep" -> {:ok, 9}
      "oct" -> {:ok, 10}
      "nov" -> {:ok, 11}
      "dec" -> {:ok, 12}
      _ -> :error
    end
  end

  defp build_utc_datetime(year, month, day, hour, minute, second) do
    with {:ok, naive} <- NaiveDateTime.new(year, month, day, hour, minute, second, {0, 6}),
         {:ok, datetime} <- DateTime.from_naive(naive, "Etc/UTC") do
      {:ok, datetime}
    else
      _ -> :error
    end
  end
end

defmodule DisclosureAutomation.Jobs do
  @moduledoc false

  def enqueue(worker_module, args, opts \\ []) when is_atom(worker_module) and is_map(args) do
    queue = Keyword.get(opts, :queue)

    job_opts =
      if queue do
        [queue: queue]
      else
        []
      end

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
  alias DisclosureAutomation.Fixtures
  alias DisclosureAutomation.Http
  alias DisclosureAutomation.Parser
  alias DisclosureAutomation.Repo
  alias DisclosureAutomation.Schema.CanonicalFeedItem
  alias DisclosureAutomation.Schema.IngestionRun
  alias DisclosureAutomation.Schema.RawDocument
  alias DisclosureAutomation.Schema.SourceRegistry
  alias DisclosureAutomation.Sources

  def poll_source(source_key, opts \\ []) when is_binary(source_key) do
    trigger_kind = Keyword.get(opts, :trigger_kind, "manual")
    edition = Keyword.get(opts, :edition, "breaking")
    use_live_fetch = Keyword.get(opts, :use_live_fetch, true)

    with {:ok, %SourceRegistry{} = source} <- Sources.get_source_by_key(source_key),
         {:ok, payload} <- load_payload(source, use_live_fetch: use_live_fetch),
         {:ok, records} <-
           Parser.parse(source.parser_key, payload.raw_payload,
             cache: parser_cache(),
             max_items_per_poll: source_max_items_per_poll(source)
           ) do
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
              {:ok, raw_document} = upsert_raw_document(run, source, record)

              {:ok, canonical_item} =
                upsert_canonical_item(
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
            source_key: source.source_key,
            edition: edition,
            fetch: payload.fetch_info,
            records_seen: length(records),
            records_inserted: length(records),
            raw_documents: Enum.map(persisted, & &1.raw_document.id),
            canonical_items: Enum.map(persisted, & &1.canonical_item.story_key)
          }
        end)

      case result do
        {:ok, poll_result} -> {:ok, poll_result}
        {:error, reason} -> handle_failure(source, reason)
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
      {:ok, payload} ->
        {:ok, payload}

      {:error, _reason} when prefer_live_fetch ->
        load_fixture_payload(source)

      :skip ->
        load_fixture_payload(source)
    end
  end

  defp maybe_load_live_payload(source, true) do
    with {:ok, response} <- Http.fetch(source.base_url, timeout: 8_000),
         true <- response.status_code in 200..299,
         :ok <- validate_live_payload(source, response) do
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

  defp validate_live_payload(%SourceRegistry{parser_key: "rss_v1"}, response) do
    cond do
      html_content_type?(response.headers) ->
        {:error, {:unsupported_live_content_type, "rss_v1", content_type(response.headers)}}

      html_payload?(response.body) ->
        {:error, {:unsupported_live_payload, "rss_v1", :html}}

      true ->
        :ok
    end
  end

  defp validate_live_payload(_source, _response), do: :ok

  defp html_content_type?(headers) do
    headers
    |> content_type()
    |> String.downcase()
    |> String.contains?("text/html")
  end

  defp content_type(headers) do
    Enum.find_value(headers, "", fn {key, value} ->
      if String.downcase(to_string(key)) == "content-type" do
        to_string(value)
      end
    end)
  end

  defp html_payload?(body) when is_binary(body) do
    body
    |> String.trim_leading()
    |> String.downcase()
    |> then(&(String.starts_with?(&1, "<!doctype html") or String.starts_with?(&1, "<html")))
  end

  defp html_payload?(_body), do: false

  defp load_fixture_payload(source) do
    fixture_path =
      source.config["fixture_path"] ||
        source.config[:fixture_path]

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

  defp upsert_raw_document(run, source, record) do
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

  defp upsert_canonical_item(raw_document, source, record, edition, priority_rank, fetch_info) do
    canonical_attrs =
      record
      |> Canonicalizer.canonicalize_document(source,
        edition: edition,
        fetch_mode: fetch_info["mode"]
      )
      |> Map.merge(%{
        raw_document_id: raw_document.id,
        source_registry_id: source.id,
        priority_rank: priority_rank
      })

    changeset = CanonicalFeedItem.changeset(%CanonicalFeedItem{}, canonical_attrs)

    Repo.insert(
      changeset,
      conflict_target: [:story_key],
      on_conflict: [
        set: [
          raw_document_id: canonical_attrs.raw_document_id,
          source_registry_id: canonical_attrs.source_registry_id,
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
          updated_at: DateTime.utc_now()
        ]
      ],
      returning: true
    )
  end

  defp hash_record(record) do
    :sha256
    |> :crypto.hash("#{record.external_id}|#{record.url}|#{record.title}|#{record.published_at}")
    |> Base.encode16(case: :lower)
  end

  defp parser_cache do
    Application.get_env(:disclosure_automation, :parser_capabilities_cache, %{})
  end

  defp source_max_items_per_poll(%SourceRegistry{config: config}) when is_map(config) do
    config["max_items_per_poll"] || config[:max_items_per_poll]
  end

  defp source_max_items_per_poll(_source), do: nil
end

defmodule DisclosureAutomation.Digest do
  @moduledoc false

  import Ecto.Query

  alias DisclosureAutomation.Fixtures
  alias DisclosureAutomation.Repo
  alias DisclosureAutomation.Schema.CanonicalFeedItem

  def get_latest_digest(edition, opts \\ []) when is_binary(edition) do
    case latest_digest_date_for_edition(edition) do
      nil ->
        fallback_to_fixture(edition, nil, opts)

      digest_date ->
        get_digest_by_date_and_edition(Date.to_iso8601(digest_date), edition, opts)
    end
  end

  def get_digest_by_date_and_edition(digest_date, edition, opts \\ [])
      when is_binary(digest_date) and is_binary(edition) do
    timezone = Keyword.get(opts, :timezone, "UTC")
    limit = Keyword.get(opts, :limit, 12)
    candidate_limit = max(positive_int(Keyword.get(opts, :candidate_limit)) || limit * 8, limit)

    max_per_source =
      positive_int(Keyword.get(opts, :max_per_source)) || default_max_per_source(limit)

    max_per_region =
      positive_int(Keyword.get(opts, :max_per_region)) || default_max_per_region(limit)

    with {:ok, digest_date} <- Date.from_iso8601(digest_date) do
      candidates =
        from(item in CanonicalFeedItem,
          join: source in assoc(item, :source),
          where:
            item.digest_date == ^digest_date and item.edition == ^edition and
              item.status in ["ready", "published"],
          order_by: [asc: item.priority_rank, desc: item.published_at],
          limit: ^candidate_limit,
          select: {item, source}
        )
        |> Repo.all()

      items = select_diverse_items(candidates, limit, max_per_source, max_per_region)

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

  defp select_diverse_items(candidates, limit, max_per_source, max_per_region) do
    {selected_reversed, _source_counts, _region_counts} =
      Enum.reduce(candidates, {[], %{}, %{}}, fn candidate,
                                                 {selected, source_counts, region_counts} ->
        if length(selected) >= limit or
             over_diversity_cap?(
               candidate,
               source_counts,
               region_counts,
               max_per_source,
               max_per_region
             ) do
          {selected, source_counts, region_counts}
        else
          {[candidate | selected], increment_source(candidate, source_counts),
           increment_region(candidate, region_counts)}
        end
      end)

    selected = Enum.reverse(selected_reversed)
    selected_ids = MapSet.new(selected, fn {item, _source} -> item.id end)

    backfill =
      candidates
      |> Enum.reject(fn {item, _source} -> MapSet.member?(selected_ids, item.id) end)
      |> Enum.take(max(limit - length(selected), 0))

    selected ++ backfill
  end

  defp over_diversity_cap?(
         candidate,
         source_counts,
         region_counts,
         max_per_source,
         max_per_region
       ) do
    source_key = source_key(candidate)
    region_key = primary_region(candidate)

    Map.get(source_counts, source_key, 0) >= max_per_source or
      Map.get(region_counts, region_key, 0) >= max_per_region
  end

  defp increment_source(candidate, source_counts) do
    Map.update(source_counts, source_key(candidate), 1, &(&1 + 1))
  end

  defp increment_region(candidate, region_counts) do
    Map.update(region_counts, primary_region(candidate), 1, &(&1 + 1))
  end

  defp source_key({_item, source}), do: source.source_key || "unknown"

  defp primary_region({item, _source}) do
    case item.regions || [] do
      [region | _rest] -> region
      _empty -> "global"
    end
  end

  defp default_max_per_source(limit), do: max(2, ceil(limit / 3))
  defp default_max_per_region(limit), do: max(3, ceil(limit / 2))

  defp positive_int(value) when is_integer(value) and value > 0, do: value

  defp positive_int(value) when is_binary(value) do
    case Integer.parse(value) do
      {parsed, ""} when parsed > 0 -> parsed
      _ -> nil
    end
  end

  defp positive_int(_value), do: nil

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

  defp present_item({item, source}) do
    %{
      "story_key" => item.story_key,
      "priority_rank" => item.priority_rank,
      "headline" => item.headline,
      "summary" => item.summary,
      "canonical_url" => item.canonical_url,
      "published_at" => DateTime.to_iso8601(item.published_at),
      "source" => %{
        "source_key" => source.source_key,
        "display_name" => source.display_name
      },
      "tickers" => item.tickers || [],
      "regions" => item.regions || [],
      "sectors" => item.sectors || [],
      "sentiment_label" => item.sentiment_label,
      "relevance_score" => decimal_to_number(item.relevance_score),
      "duplicate_group_key" => item.duplicate_group_key,
      "metadata" => item.metadata || %{}
    }
  end

  defp decimal_to_number(nil), do: nil
  defp decimal_to_number(%Decimal{} = value), do: Decimal.to_float(value)
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

    case Ingestion.poll_source(source_key,
           trigger_kind: trigger_kind,
           edition: edition,
           use_live_fetch: use_live_fetch
         ) do
      {:ok, _result} -> :ok
      {:error, :not_found} -> {:cancel, :source_not_found}
      {:error, reason} -> {:error, inspect(reason)}
    end
  end
end
