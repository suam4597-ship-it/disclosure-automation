defmodule DisclosureAutomation.Runtime.TWMOPSMaterialInformationAdapter do
  @moduledoc false

  @behaviour DisclosureAutomation.Runtime.Adapter

  alias DisclosureAutomation.Fixtures
  alias DisclosureAutomation.Http
  alias DisclosureAutomation.Schema.SourceRegistry

  @cursor_key "latest_spoke_date_time_and_sequence_seen"
  @event_family "material_information_update"
  @canonical_event_type "major_investment_or_asset_sale"
  @taipei_offset_seconds 8 * 60 * 60

  @impl true
  def discover(%SourceRegistry{} = source, opts \\ []) do
    use_live_fetch = Keyword.get(opts, :use_live_fetch, true)

    with {:ok, payload} <- load_discovery_payload(source, use_live_fetch) do
      items =
        payload
        |> parse_discovery_items()
        |> Enum.filter(&target_row?(&1, source))
        |> Enum.sort_by(& &1.cursor_value)

      {:ok, items}
    end
  end

  @impl true
  def hydrate(%SourceRegistry{} = source, discovery_item, opts \\ []) do
    use_live_fetch = Keyword.get(opts, :use_live_fetch, true)
    detail_fixture_path = detail_fixture_path(source, discovery_item.stable_external_id)

    with {:ok, detail_payload} <- load_document(discovery_item.detail_url, detail_fixture_path, use_live_fetch) do
      {:ok,
       %{
         discovery_item: discovery_item,
         detail_document: %{
           external_id: "#{discovery_item.stable_external_id}:discovery-row",
           document_identity: "#{discovery_item.stable_external_id}:discovery-row",
           document_type: "mops_material_information_result_row",
           document_role: "discovery_metadata",
           mime_type: "text/html",
           url: source.base_url,
           body_text: discovery_item.raw_html,
           published_at: discovery_item.published_at_utc,
           metadata: %{
             "mode" => "fixture",
             "co_id" => discovery_item.co_id,
             "seq_no" => discovery_item.seq_no,
             "skey" => discovery_item.skey,
             "spoke_date" => discovery_item.spoke_date,
             "spoke_time" => discovery_item.spoke_time
           }
         },
         submission_document: %{
           external_id: "#{discovery_item.stable_external_id}:detail-page",
           document_identity: "#{discovery_item.stable_external_id}:detail-page",
           document_type: "mops_material_information_detail_html",
           document_role: "primary_regulatory_disclosure",
           mime_type: "text/html",
           url: discovery_item.detail_url,
           body_text: detail_payload.raw,
           published_at: discovery_item.published_at_utc,
           metadata: %{
             "mode" => detail_payload.mode,
             "fixture" => detail_payload.fixture_path,
             "co_id" => discovery_item.co_id,
             "seq_no" => discovery_item.seq_no,
             "skey" => discovery_item.skey
           }
         }
       }}
    end
  end

  @impl true
  def parse(%SourceRegistry{} = source, hydrated_item, _opts \\ []) do
    item = hydrated_item.discovery_item
    detail_text = html_to_text(hydrated_item.submission_document.body_text)

    {:ok,
     [
       %{
         event_key: "mops:#{item.co_id}:#{item.spoke_date}:#{item.spoke_time}:#{item.seq_no}",
         external_event_key: item.stable_external_id,
         parser_key: source.parser_key || "tw_mops_material_information_html_v1",
         event_family: @event_family,
         occurred_at: item.published_at_utc,
         status: "parsed",
         payload: %{
           "stable_external_id" => item.stable_external_id,
           "cursor_value" => item.cursor_value,
           "co_id" => item.co_id,
           "company_name" => item.company_name,
           "market" => item.market,
           "seq_no" => item.seq_no,
           "skey" => item.skey,
           "spoke_date" => item.spoke_date,
           "spoke_time" => item.spoke_time,
           "roc_date" => item.roc_date,
           "publication_datetime_local" => item.publication_datetime_local,
           "document_date" => item.document_date,
           "subject" => item.subject,
           "clause" => item.clause,
           "fact_date_roc" => extract_fact_date(detail_text) || item.roc_date,
           "spokesperson" => extract_after_label(detail_text, "發言人"),
           "spokesperson_title" => extract_after_label(detail_text, "發言人職稱"),
           "detail_url" => item.detail_url,
           "fact_summary_ko" => summarize_ko(item, detail_text),
           "why_important_ko" => "Taiwan MOPS material-information disclosure from a listed company.",
           "raw_excerpt" => String.slice(detail_text, 0, 900)
         },
         metadata: %{
           "discovery_mode" => source.discovery_mode,
           "hydrate_mode" => source.hydrate_mode,
           "roc_year_conversion" => true
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
    event_family = raw_event.event_family || @event_family
    co_id = payload["co_id"]
    spoke_date = payload["spoke_date"]
    seq_no = payload["seq_no"]

    event_id = "tw.mops.#{co_id}.#{spoke_date}.#{@canonical_event_type}.#{event_family}.#{seq_no}"
    region_code = source.region_code || "tw"
    home_market_region_code = source.default_home_market_region_code || region_code

    contract_v1 = %{
      "event_id" => event_id,
      "dedupe_key" => payload["stable_external_id"],
      "issuer_entity_key" => "twse:#{co_id}",
      "issuer_ids" => %{"company_code" => co_id},
      "issuer_name_local" => payload["company_name"],
      "issuer_name_en" => payload["company_name"],
      "headline_local" => payload["subject"],
      "headline_ko" => "Taiwan MOPS material information update",
      "fact_summary_ko" => payload["fact_summary_ko"],
      "why_important_ko" => payload["why_important_ko"],
      "canonical_event_type" => @canonical_event_type,
      "event_family" => event_family,
      "official_storage_name" => "Taiwan MOPS",
      "official_source_name" => "MOPS Material Information Detail Page",
      "official_source_url" => payload["detail_url"],
      "discovery_source_name" => "MOPS Material Information Result Row",
      "discovery_source_url" => source.base_url,
      "raw_source_type" => payload["clause"],
      "source_tier" => source.default_source_tier || "official_regulatory_storage",
      "country" => "TW",
      "region_code" => region_code,
      "home_market_region_code" => home_market_region_code,
      "published_at_utc" => iso8601(published_at),
      "published_at_local" => payload["publication_datetime_local"],
      "filing_date_local" => gregorian_date_from_spoke_date(spoke_date),
      "importance_band" => "P1",
      "source_meta" => %{
        "stable_external_id" => payload["stable_external_id"],
        "cursor_value" => payload["cursor_value"],
        "co_id" => co_id,
        "company_name" => payload["company_name"],
        "market" => payload["market"],
        "seq_no" => seq_no,
        "skey" => payload["skey"],
        "spoke_date" => spoke_date,
        "spoke_time" => payload["spoke_time"],
        "roc_date" => payload["roc_date"],
        "clause" => payload["clause"],
        "detail_url" => payload["detail_url"],
        "fact_date_roc" => payload["fact_date_roc"]
      },
      "risk_flags" => ["tw_mops_fixture_v0", "roc_year_conversion_used"],
      "portable_citations" => [
        %{
          "source_name" => "MOPS Material Information Result Row",
          "claim_supported" => "company code, subject, date/time, sequence, and detail URL parameters",
          "note" => source.base_url
        },
        %{
          "source_name" => "MOPS Material Information Detail Page",
          "claim_supported" => "material information detail body used for v0 normalization",
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
       headline: payload["subject"],
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
    fixture_path = discovery_fixture_path(source)

    with {:ok, response} <- Http.fetch(source.base_url, timeout: 8_000),
         true <- response.status_code in 200..299,
         true <- String.contains?(response.body, "mops-result") do
      {:ok, response.body}
    else
      _ -> load_fixture(fixture_path)
    end
  end

  defp load_discovery_payload(source, false), do: load_fixture(discovery_fixture_path(source))

  defp discovery_fixture_path(source) do
    get_in(source.config || %{}, ["fixtures", "discovery_result"]) ||
      get_in(source.config || %{}, [:fixtures, :discovery_result]) ||
      get_in(source.config || %{}, ["fixtures", "discovery_html"]) ||
      get_in(source.config || %{}, [:fixtures, :discovery_html])
  end

  defp detail_fixture_path(source, stable_external_id) do
    detail_pages =
      get_in(source.config || %{}, ["fixtures", "detail_pages"]) ||
        get_in(source.config || %{}, [:fixtures, :detail_pages]) || %{}

    Map.get(detail_pages, stable_external_id) || Map.get(detail_pages, to_string(stable_external_id))
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

  defp parse_discovery_items(html) do
    Regex.scan(~r/<article\s+class="mops-result"([\s\S]*?)>([\s\S]*?)<\/article>/i, html || "")
    |> Enum.map(fn [_, attrs, inner] -> discovery_item_from(attrs, inner) end)
  end

  defp discovery_item_from(attrs, inner) do
    co_id = attr(attrs, "data-co-id")
    company_name = attr(attrs, "data-company-name")
    market = attr(attrs, "data-market")
    seq_no = attr(attrs, "data-seq-no")
    skey = attr(attrs, "data-skey")
    spoke_date = attr(attrs, "data-spoke-date")
    spoke_time = attr(attrs, "data-spoke-time")
    roc_date = attr(attrs, "data-roc-date")
    subject = attr(attrs, "data-subject") || html_to_text(inner)
    clause = attr(attrs, "data-clause")
    detail_url = attr(attrs, "data-detail-url")
    stable_external_id = "MOPS:#{co_id}:#{spoke_date}:#{spoke_time}:#{seq_no}"
    publication_local = local_naive_from_spoke(spoke_date, spoke_time)
    published_at_utc = taipei_local_to_utc(publication_local)
    cursor_value = "#{spoke_date}|#{spoke_time}|#{co_id}|#{seq_no}"

    %{
      external_id: cursor_value,
      raw_html: "<article class=\"mops-result\"#{attrs}>#{inner}</article>",
      co_id: co_id,
      company_name: company_name,
      market: market,
      seq_no: seq_no,
      skey: skey,
      spoke_date: spoke_date,
      spoke_time: spoke_time,
      roc_date: roc_date,
      publication_datetime_local: "#{NaiveDateTime.to_iso8601(publication_local)}+08:00",
      published_at_utc: published_at_utc,
      document_date: gregorian_date_from_spoke_date(spoke_date),
      subject: subject,
      clause: clause,
      detail_url: detail_url,
      stable_external_id: stable_external_id,
      cursor_value: cursor_value
    }
  end

  defp target_row?(item, %SourceRegistry{} = source) do
    filter = source.config["filter"] || source.config[:filter] || %{}

    same?(item.co_id, filter["co_id"] || filter[:co_id]) and
      same?(item.seq_no, filter["seq_no"] || filter[:seq_no]) and
      same?(item.spoke_date, filter["spoke_date"] || filter[:spoke_date]) and
      same?(item.spoke_time, filter["spoke_time"] || filter[:spoke_time])
  end

  defp same?(_value, nil), do: true
  defp same?(value, expected), do: to_string(value) == to_string(expected)

  defp attr(attrs, name) do
    case Regex.run(~r/#{Regex.escape(name)}="([^"]*)"/, attrs || "") do
      [_, value] -> html_entities_to_text(value)
      _ -> nil
    end
  end

  defp local_naive_from_spoke(spoke_date, spoke_time) do
    {:ok, naive} =
      NaiveDateTime.new(
        String.slice(spoke_date, 0, 4) |> String.to_integer(),
        String.slice(spoke_date, 4, 2) |> String.to_integer(),
        String.slice(spoke_date, 6, 2) |> String.to_integer(),
        String.slice(spoke_time, 0, 2) |> String.to_integer(),
        String.slice(spoke_time, 2, 2) |> String.to_integer(),
        String.slice(spoke_time, 4, 2) |> String.to_integer()
      )

    naive
  end

  defp taipei_local_to_utc(%NaiveDateTime{} = local) do
    utc_naive = NaiveDateTime.add(local, -@taipei_offset_seconds, :second)
    {:ok, utc} = DateTime.from_naive(utc_naive, "Etc/UTC")
    utc
  end

  defp gregorian_date_from_spoke_date(spoke_date) do
    "#{String.slice(spoke_date, 0, 4)}-#{String.slice(spoke_date, 4, 2)}-#{String.slice(spoke_date, 6, 2)}"
  end

  defp html_to_text(nil), do: ""

  defp html_to_text(html) do
    html
    |> String.replace(~r/<script[\s\S]*?<\/script>/i, " ")
    |> String.replace(~r/<style[\s\S]*?<\/style>/i, " ")
    |> String.replace(~r/<br\s*\/?>/i, "\n")
    |> String.replace(~r/<[^>]+>/, " ")
    |> html_entities_to_text()
    |> String.replace(~r/\s+/, " ")
    |> String.trim()
  end

  defp html_entities_to_text(text) do
    text
    |> to_string()
    |> String.replace("&nbsp;", " ")
    |> String.replace("&amp;", "&")
    |> String.replace("&lt;", "<")
    |> String.replace("&gt;", ">")
    |> String.replace("&quot;", "\"")
  end

  defp extract_fact_date(text) do
    case Regex.run(~r/事實發生日\s*(\d{3}\/\d{2}\/\d{2})/, text || "") do
      [_, value] -> value
      _ -> nil
    end
  end

  defp extract_after_label(text, label) do
    case Regex.run(~r/#{Regex.escape(label)}\s+([^\s]+)/u, text || "") do
      [_, value] -> value
      _ -> nil
    end
  end

  defp summarize_ko(item, detail_text) do
    excerpt =
      detail_text
      |> String.replace(~r/\s+/, " ")
      |> String.slice(0, 420)

    "#{item.company_name} filed MOPS material information: #{item.subject}. Clause #{item.clause}. #{excerpt}"
  end

  defp iso8601(nil), do: nil
  defp iso8601(%DateTime{} = value), do: DateTime.to_iso8601(value)
end
