defmodule DisclosureAutomation.Runtime.UKFCANSMTakeoverSchemeUpdatesAdapter do
  @moduledoc false

  @behaviour DisclosureAutomation.Runtime.Adapter

  alias DisclosureAutomation.Fixtures
  alias DisclosureAutomation.Http
  alias DisclosureAutomation.Schema.SourceRegistry

  @cursor_key "latest_filing_at_and_artefact_id_seen"
  @target_category "Scheme of Arrangement"
  @target_source "Regulatory News Services (RNS)"
  @source_namespace "RNS"

  @impl true
  def discover(%SourceRegistry{} = source, opts \\ []) do
    use_live_fetch = Keyword.get(opts, :use_live_fetch, true)

    with {:ok, payload} <- load_discovery_payload(source, use_live_fetch) do
      {:ok,
       payload
       |> parse_csv_rows()
       |> Enum.map(&normalize_discovery_row/1)
       |> Enum.filter(&target_row?/1)
       |> Enum.sort_by(& &1.cursor_value)}
    end
  end

  @impl true
  def hydrate(%SourceRegistry{} = source, discovery_item, opts \\ []) do
    use_live_fetch = Keyword.get(opts, :use_live_fetch, true)
    detail_fixture_path = detail_fixture_path(source, discovery_item.artefact_token)

    with {:ok, detail_payload} <- load_document(discovery_item.detail_url, detail_fixture_path, use_live_fetch) do
      {:ok,
       %{
         discovery_item: discovery_item,
         detail_document: %{
           external_id: "#{discovery_item.stable_external_id}:discovery-row",
           document_identity: "#{discovery_item.stable_external_id}:discovery-row",
           document_type: "nsm_csv_export_row",
           document_role: "discovery_metadata",
           mime_type: "text/csv",
           url: source.base_url,
           body_text: discovery_item.raw_csv_row,
           published_at: discovery_item.published_at_utc,
           metadata: %{
             "mode" => "fixture",
             "category" => discovery_item.category,
             "source" => discovery_item.source,
             "artefact_token" => discovery_item.artefact_token
           }
         },
         submission_document: %{
           external_id: "#{discovery_item.stable_external_id}:artefact-html",
           document_identity: "#{discovery_item.stable_external_id}:artefact-html",
           document_type: "nsm_artefact_html",
           document_role: "primary_regulatory_disclosure",
           mime_type: "text/html",
           url: discovery_item.detail_url,
           body_text: detail_payload.raw,
           published_at: discovery_item.published_at_utc,
           metadata: %{
             "mode" => detail_payload.mode,
             "fixture" => detail_payload.fixture_path,
             "artefact_token" => discovery_item.artefact_token
           }
         }
       }}
    end
  end

  @impl true
  def parse(%SourceRegistry{} = source, hydrated_item, _opts \\ []) do
    item = hydrated_item.discovery_item
    detail_text = html_to_text(hydrated_item.submission_document.body_text)
    rns_number = extract_rns_number(detail_text)

    {:ok,
     [
       %{
         event_key: "nsm:rns:#{item.artefact_token}",
         external_event_key: item.stable_external_id,
         parser_key: source.parser_key || "uk_fca_nsm_takeover_scheme_html_v1",
         event_family: "takeover_or_scheme_update",
         occurred_at: item.published_at_utc,
         status: "parsed",
         payload: %{
           "stable_external_id" => item.stable_external_id,
           "artefact_token" => item.artefact_token,
           "source_namespace" => item.source_namespace,
           "cursor_value" => item.cursor_value,
           "filing_datetime_local" => item.filing_datetime_local,
           "publication_datetime_local" => item.publication_datetime_local,
           "document_date" => item.document_date,
           "source" => item.source,
           "issuer_lei" => item.issuer_lei,
           "issuer_name" => item.issuer_name,
           "description" => item.description,
           "category" => item.category,
           "detail_url" => item.detail_url,
           "related_organisations" => item.related_organisations,
           "rns_number" => rns_number,
           "fact_summary_ko" => summarize_ko(item, detail_text),
           "why_important_ko" => "UK takeover or scheme-related regulatory disclosure surfaced through FCA NSM metadata.",
           "raw_excerpt" => String.slice(detail_text, 0, 700)
         },
         metadata: %{
           "discovery_mode" => source.discovery_mode,
           "hydrate_mode" => source.hydrate_mode
         }
       }
     ]}
  end

  @impl true
  def normalize(%SourceRegistry{} = source, raw_event, opts \\ []) do
    payload = raw_event.payload || %{}
    published_at = raw_event.occurred_at

    digest_date =
      Keyword.get(
        opts,
        :digest_date,
        if(published_at, do: DateTime.to_date(published_at), else: Date.utc_today())
      )

    edition = Keyword.get(opts, :edition, "breaking")
    issuer_slug = slug(payload["issuer_name"] || "issuer")
    filing_date = local_date_from(payload["filing_datetime_local"], digest_date)
    canonical_event_type = "tender_offer_or_go_private"
    event_family = raw_event.event_family || "takeover_or_scheme_update"
    artefact_token = payload["artefact_token"]

    event_id =
      "uk.fca_nsm.#{issuer_slug}.#{String.replace(filing_date, "-", "")}.#{canonical_event_type}.#{event_family}.#{slug(artefact_token)}"

    region_code = source.region_code || "uk"
    home_market_region_code = source.default_home_market_region_code || region_code

    contract_v1 = %{
      "event_id" => event_id,
      "dedupe_key" => payload["stable_external_id"],
      "issuer_entity_key" => "lei:#{payload["issuer_lei"]}",
      "issuer_ids" => %{"lei" => payload["issuer_lei"]},
      "issuer_name_local" => payload["issuer_name"],
      "issuer_name_en" => payload["issuer_name"],
      "headline_local" => payload["description"],
      "headline_ko" => "UK scheme of arrangement update",
      "fact_summary_ko" => payload["fact_summary_ko"],
      "why_important_ko" => payload["why_important_ko"],
      "canonical_event_type" => canonical_event_type,
      "event_family" => event_family,
      "official_storage_name" => "FCA National Storage Mechanism",
      "official_source_name" => "FCA National Storage Mechanism RNS Artefact",
      "official_source_url" => payload["detail_url"],
      "discovery_source_name" => "FCA National Storage Mechanism CSV Export Row",
      "discovery_source_url" => source.base_url,
      "raw_source_type" => payload["category"],
      "source_tier" => "official_regulatory_storage",
      "country" => "GB",
      "region_code" => region_code,
      "home_market_region_code" => home_market_region_code,
      "published_at_utc" => iso8601(published_at),
      "published_at_local" => payload["publication_datetime_local"],
      "filing_date_local" => filing_date,
      "importance_band" => "P1",
      "source_meta" => %{
        "stable_external_id" => payload["stable_external_id"],
        "artefact_token" => artefact_token,
        "cursor_value" => payload["cursor_value"],
        "filing_datetime_local" => payload["filing_datetime_local"],
        "publication_datetime_local" => payload["publication_datetime_local"],
        "document_date" => payload["document_date"],
        "source" => payload["source"],
        "category" => payload["category"],
        "related_organisations" => payload["related_organisations"],
        "rns_number" => payload["rns_number"]
      },
      "risk_flags" => ["uk_nsm_csv_fixture_v0"],
      "portable_citations" => [
        %{
          "source_name" => "FCA National Storage Mechanism CSV Export Row",
          "claim_supported" => "filing time, publication time, issuer, category, source, and artefact URL",
          "note" => source.base_url
        },
        %{
          "source_name" => "FCA National Storage Mechanism RNS Artefact",
          "claim_supported" => "public artefact body used for v0 normalization",
          "note" => payload["detail_url"]
        }
      ]
    }

    {:ok,
     %{
       contract_v1: contract_v1,
       digest_date: digest_date,
       edition: edition,
       story_key: event_id,
       headline: payload["description"],
       summary: payload["fact_summary_ko"],
       canonical_url: payload["detail_url"],
       published_at: published_at,
       tickers: [],
       regions: [region_code],
       sectors: ["regulatory"],
       sentiment_label: "neutral",
       relevance_score: Decimal.new("0.950"),
       priority_rank: nil,
       duplicate_group_key: payload["stable_external_id"],
       status: "ready"
     }}
  end

  def cursor_key, do: @cursor_key

  defp load_discovery_payload(source, true) do
    fixture_path = get_in(source.config, ["fixtures", "discovery_csv"]) || get_in(source.config, [:fixtures, :discovery_csv])

    with {:ok, response} <- Http.fetch(source.base_url, timeout: 8_000),
         true <- response.status_code in 200..299 do
      {:ok, response.body}
    else
      _ -> load_fixture(fixture_path)
    end
  end

  defp load_discovery_payload(source, false) do
    fixture_path = get_in(source.config, ["fixtures", "discovery_csv"]) || get_in(source.config, [:fixtures, :discovery_csv])
    load_fixture(fixture_path)
  end

  defp detail_fixture_path(source, artefact_token) do
    detail_pages = get_in(source.config, ["fixtures", "detail_pages"]) || get_in(source.config, [:fixtures, :detail_pages]) || %{}
    Map.get(detail_pages, artefact_token) || Map.get(detail_pages, to_string(artefact_token))
  end

  defp load_document(url, fixture_path, true) do
    with {:ok, response} <- Http.fetch(url, timeout: 8_000),
         true <- response.status_code in 200..299 do
      {:ok, %{raw: response.body, mode: "live", fixture_path: nil}}
    else
      _ -> fixture_document(fixture_path)
    end
  end

  defp load_document(_url, fixture_path, false), do: fixture_document(fixture_path)

  defp fixture_document(fixture_path) do
    with {:ok, payload} <- Fixtures.load_source_payload(fixture_path) do
      {:ok, %{raw: payload.raw, mode: "fixture", fixture_path: payload.relative_path}}
    end
  end

  defp load_fixture(fixture_path) do
    with {:ok, payload} <- Fixtures.load_source_payload(fixture_path) do
      {:ok, payload.raw}
    end
  end

  defp parse_csv_rows(raw) do
    raw
    |> String.replace("\uFEFF", "")
    |> String.split(~r/\r?\n/, trim: true)
    |> case do
      [] -> []
      [header | rows] ->
        headers = parse_csv_line(header)

        Enum.map(rows, fn row ->
          values = parse_csv_line(row)
          headers |> Enum.zip(values) |> Map.new()
        end)
    end
  end

  defp parse_csv_line(line) do
    line
    |> String.graphemes()
    |> Enum.reduce({[], "", false}, fn
      "\"", {fields, current, false} -> {fields, current, true}
      "\"", {fields, current, true} -> {fields, current, false}
      ",", {fields, current, false} -> {[current | fields], "", false}
      char, {fields, current, quoted?} -> {fields, current <> char, quoted?}
    end)
    |> then(fn {fields, current, _quoted?} -> [current | fields] |> Enum.reverse() |> Enum.map(&String.trim/1) end)
  end

  defp normalize_discovery_row(row) do
    detail_url = row["Download Link"]
    artefact_token = artefact_token_from_url(detail_url)
    source_namespace = source_namespace_from_url(detail_url)
    stable_external_id = "NSM:#{source_namespace}:#{artefact_token}"
    filing_local = parse_nsm_datetime(row["Filing Date/Time"])
    publication_local = parse_nsm_datetime(row["Publication Date/Time"])
    published_at_utc = london_local_to_utc(publication_local)
    cursor_value = "#{iso_local_datetime(filing_local)}|#{source_namespace}|#{artefact_token}"

    %{
      external_id: cursor_value,
      raw_csv_row: render_csv_row(row),
      filing_datetime_local: iso_local_datetime_with_offset(filing_local),
      publication_datetime_local: iso_local_datetime_with_offset(publication_local),
      published_at_utc: published_at_utc,
      document_date: normalize_date(row["Document Date"]),
      source: row["Source"],
      issuer_lei: row["Disclosing Organisation LEI"],
      issuer_name: row["Disclosing Organisation Name"],
      description: row["Description"],
      category: row["Category"],
      detail_url: detail_url,
      related_organisations: row["Related Organisation(s)"],
      artefact_token: artefact_token,
      source_namespace: source_namespace,
      stable_external_id: stable_external_id,
      cursor_value: cursor_value
    }
  end

  defp target_row?(%{category: @target_category, source: @target_source, source_namespace: @source_namespace}), do: true
  defp target_row?(_), do: false

  defp render_csv_row(row) do
    [
      "Filing Date/Time,Publication Date/Time,Document Date,Source,Disclosing Organisation LEI,Disclosing Organisation Name,Description,Category,ESEF Type,Download Link,Related Organisation(s)",
      Enum.map_join([
        "Filing Date/Time",
        "Publication Date/Time",
        "Document Date",
        "Source",
        "Disclosing Organisation LEI",
        "Disclosing Organisation Name",
        "Description",
        "Category",
        "ESEF Type",
        "Download Link",
        "Related Organisation(s)"
      ], ",", fn key -> csv_escape(row[key]) end)
    ]
    |> Enum.join("\n")
  end

  defp csv_escape(nil), do: ""
  defp csv_escape(value), do: "\"#{String.replace(to_string(value), "\"", "\"\"")}" <> "\""

  defp artefact_token_from_url(url) do
    url
    |> to_string()
    |> String.split("/")
    |> List.last()
    |> to_string()
    |> String.replace_suffix(".html", "")
  end

  defp source_namespace_from_url(url) do
    case Regex.run(~r|/NSM/([^/]+)/|, to_string(url)) do
      [_, namespace] -> namespace
      _ -> "NSM"
    end
  end

  defp parse_nsm_datetime(nil), do: nil

  defp parse_nsm_datetime(value) do
    case Regex.run(~r/^(\d{2})\/(\d{2})\/(\d{4})\s+(\d{2}):(\d{2})$/, to_string(value)) do
      [_, day, month, year, hour, minute] ->
        {:ok, naive} =
          NaiveDateTime.new(
            String.to_integer(year),
            String.to_integer(month),
            String.to_integer(day),
            String.to_integer(hour),
            String.to_integer(minute),
            0
          )

        naive

      _ ->
        nil
    end
  end

  defp normalize_date(nil), do: nil

  defp normalize_date(value) do
    case Regex.run(~r/^(\d{2})\/(\d{2})\/(\d{4})$/, to_string(value)) do
      [_, day, month, year] -> "#{year}-#{month}-#{day}"
      _ -> value
    end
  end

  defp london_local_to_utc(%NaiveDateTime{} = local) do
    {offset_seconds, _offset} = london_offset_for(local)
    utc_naive = NaiveDateTime.add(local, -offset_seconds, :second)
    {:ok, utc} = DateTime.from_naive(utc_naive, "Etc/UTC")
    utc
  end

  defp london_local_to_utc(_), do: nil

  defp iso_local_datetime(nil), do: nil
  defp iso_local_datetime(%NaiveDateTime{} = value), do: NaiveDateTime.to_iso8601(value)

  defp iso_local_datetime_with_offset(nil), do: nil

  defp iso_local_datetime_with_offset(%NaiveDateTime{} = value) do
    {_offset_seconds, offset_string} = london_offset_for(value)
    "#{NaiveDateTime.to_iso8601(value)}#{offset_string}"
  end

  defp london_offset_for(%NaiveDateTime{} = naive) do
    year = naive.year
    dst_start_day = last_weekday_of_month(year, 3, 7)
    dst_end_day = last_weekday_of_month(year, 10, 7)

    {:ok, dst_start} = NaiveDateTime.new(year, 3, dst_start_day, 1, 0, 0)
    {:ok, dst_end} = NaiveDateTime.new(year, 10, dst_end_day, 2, 0, 0)

    if NaiveDateTime.compare(naive, dst_start) in [:eq, :gt] and
         NaiveDateTime.compare(naive, dst_end) == :lt do
      {3600, "+01:00"}
    else
      {0, "+00:00"}
    end
  end

  defp last_weekday_of_month(year, month, weekday_target) do
    Date.days_in_month(Date.new!(year, month, 1))..1//-1
    |> Enum.find(fn day -> Date.day_of_week(Date.new!(year, month, day)) == weekday_target end)
  end

  defp html_to_text(nil), do: ""

  defp html_to_text(html) do
    html
    |> String.replace(~r/<script[\s\S]*?<\/script>/i, " ")
    |> String.replace(~r/<style[\s\S]*?<\/style>/i, " ")
    |> String.replace(~r/<[^>]+>/, " ")
    |> html_entities_to_text()
    |> String.replace(~r/\s+/, " ")
    |> String.trim()
  end

  defp html_entities_to_text(text) do
    text
    |> String.replace("&nbsp;", " ")
    |> String.replace("&amp;", "&")
    |> String.replace("&lt;", "<")
    |> String.replace("&gt;", ">")
    |> String.replace("&quot;", "\"")
  end

  defp extract_rns_number(text) do
    case Regex.run(~r/RNS\s+Number\s*:?\s*([A-Z0-9]+)/i, text) do
      [_, value] -> value
      _ -> nil
    end
  end

  defp summarize_ko(item, detail_text) do
    excerpt =
      detail_text
      |> String.replace(~r/\s+/, " ")
      |> String.slice(0, 360)

    "#{item.issuer_name} filed #{item.description} through FCA NSM. Category #{item.category}. #{excerpt}"
  end

  defp local_date_from(value, fallback_date) when is_binary(value) do
    value
    |> String.split("T", parts: 2)
    |> hd()
  end

  defp local_date_from(_, %Date{} = fallback_date), do: Date.to_iso8601(fallback_date)
  defp local_date_from(_, _), do: Date.utc_today() |> Date.to_iso8601()

  defp slug(value) do
    value
    |> to_string()
    |> String.downcase()
    |> String.replace(~r/[^a-z0-9]+/u, "_")
    |> String.trim("_")
    |> case do
      "" -> "item"
      token -> token
    end
  end

  defp iso8601(nil), do: nil
  defp iso8601(%DateTime{} = value), do: DateTime.to_iso8601(value)
end
