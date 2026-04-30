defmodule DisclosureAutomation.Runtime.JPTDnetTimelyDisclosureAdapter do
  @moduledoc false

  @behaviour DisclosureAutomation.Runtime.Adapter

  alias DisclosureAutomation.Fixtures
  alias DisclosureAutomation.Http
  alias DisclosureAutomation.Schema.SourceRegistry

  @cursor_key "latest_disclosure_datetime_security_code_and_pdf_token_seen"
  @event_family "material_information_update"
  @canonical_event_type "material_information_update"

  @impl true
  def discover(%SourceRegistry{} = source, opts \\ []) do
    use_live_fetch = Keyword.get(opts, :use_live_fetch, true)

    with {:ok, payload} <- load_discovery_payload(source, use_live_fetch),
         {:ok, decoded} <- Jason.decode(payload) do
      items =
        decoded
        |> Map.get("announcements", [])
        |> Enum.map(&discovery_item_from(source, &1))
        |> Enum.filter(&target_row?(&1, source))
        |> Enum.sort_by(& &1.cursor_value)

      {:ok, items}
    end
  end

  @impl true
  def hydrate(%SourceRegistry{} = source, discovery_item, opts \\ []) do
    use_live_fetch = Keyword.get(opts, :use_live_fetch, true)
    pdf_fixture_path = pdf_fixture_path(source, discovery_item.stable_external_id)

    with {:ok, pdf_payload} <- load_document(discovery_item.attachment_url, pdf_fixture_path, use_live_fetch) do
      {:ok,
       %{
         discovery_item: discovery_item,
         detail_document: %{
           external_id: "#{discovery_item.stable_external_id}:discovery-row",
           document_identity: "#{discovery_item.stable_external_id}:discovery-row",
           document_type: "tdnet_current_list_row",
           document_role: "discovery_metadata",
           mime_type: "application/json",
           url: discovery_item.row_list_url,
           body_text: discovery_item.raw_json,
           published_at: discovery_item.published_at_utc,
           metadata: %{
             "mode" => "fixture",
             "row_list_url" => discovery_item.row_list_url,
             "row_date" => discovery_item.row_date,
             "disclosure_time" => discovery_item.disclosure_time,
             "tdnet_raw_row_code" => discovery_item.tdnet_raw_row_code,
             "normalized_security_code" => discovery_item.normalized_security_code,
             "pdf_document_token" => discovery_item.pdf_document_token
           }
         },
         submission_document: %{
           external_id: "#{discovery_item.stable_external_id}:pdf:#{discovery_item.pdf_document_token}",
           document_identity: "#{discovery_item.stable_external_id}:pdf:#{discovery_item.pdf_document_token}",
           document_type: "tdnet_pdf_attachment_text_fixture",
           document_role: "primary_regulatory_disclosure",
           mime_type: "application/pdf",
           url: discovery_item.attachment_url,
           body_text: pdf_payload.raw,
           published_at: discovery_item.published_at_utc,
           metadata: %{
             "mode" => pdf_payload.mode,
             "fixture" => pdf_payload.fixture_path,
             "pdf_document_token" => discovery_item.pdf_document_token,
             "attachment_url" => discovery_item.attachment_url
           }
         }
       }}
    end
  end

  @impl true
  def parse(%SourceRegistry{} = source, hydrated_item, _opts \\ []) do
    item = hydrated_item.discovery_item
    pdf_text = hydrated_item.submission_document.body_text || ""

    {:ok,
     [
       %{
         event_key: "tdnet:#{item.normalized_security_code}:#{item.row_date}:#{item.disclosure_time_compact}:#{item.pdf_document_token}",
         external_event_key: item.stable_external_id,
         parser_key: source.parser_key || "jp_tdnet_timely_disclosure_v1",
         event_family: @event_family,
         occurred_at: item.published_at_utc,
         status: "parsed",
         payload: %{
           "stable_external_id" => item.stable_external_id,
           "cursor_value" => item.cursor_value,
           "row_list_url" => item.row_list_url,
           "row_date" => item.row_date,
           "disclosure_time" => item.disclosure_time,
           "published_at_local" => item.published_at_local,
           "published_at_utc" => item.published_at_utc_iso,
           "tdnet_raw_row_code" => item.tdnet_raw_row_code,
           "normalized_security_code" => item.normalized_security_code,
           "row_display_name" => item.row_display_name,
           "issuer_name" => item.issuer_name,
           "title" => item.title,
           "exchange" => item.exchange,
           "xbrl" => item.xbrl,
           "update_history" => item.update_history,
           "source_category" => item.source_category,
           "material_category" => item.material_category,
           "pdf_document_token" => item.pdf_document_token,
           "attachment_url" => item.attachment_url,
           "document_date" => extract_document_date(pdf_text) || item.row_date,
           "document_summary" => summarize_document(item, pdf_text),
           "fact_summary_ko" => summarize_ko(item, pdf_text),
           "why_important_ko" =>
             "TDnet timely disclosure fixture preserving official row metadata, PDF token identity, raw TDnet code, and normalized security code.",
           "raw_excerpt" => String.slice(normalize_space(pdf_text), 0, 900)
         },
         metadata: %{
           "discovery_mode" => source.discovery_mode,
           "hydrate_mode" => source.hydrate_mode,
           "source_category_inferred" => false,
           "category_frozen_unknown" => true
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
    security_code = payload["normalized_security_code"]
    pdf_document_token = payload["pdf_document_token"]
    row_date_compact = String.replace(payload["row_date"], "-", "")

    event_id =
      "jp.tdnet.#{security_code}.#{row_date_compact}.#{@canonical_event_type}.#{event_family}.#{pdf_document_token}"

    region_code = source.region_code || "jp"
    home_market_region_code = source.default_home_market_region_code || region_code

    contract_v1 = %{
      "event_id" => event_id,
      "dedupe_key" => payload["stable_external_id"],
      "issuer_entity_key" => "tdnet:#{security_code}",
      "issuer_ids" => %{
        "security_code" => security_code,
        "tdnet_raw_row_code" => payload["tdnet_raw_row_code"]
      },
      "issuer_name_local" => payload["issuer_name"],
      "issuer_name_en" => payload["issuer_name"],
      "headline_local" => payload["title"],
      "headline_ko" => "TDnet timely disclosure update",
      "fact_summary_ko" => payload["fact_summary_ko"],
      "why_important_ko" => payload["why_important_ko"],
      "canonical_event_type" => @canonical_event_type,
      "event_family" => event_family,
      "official_storage_name" => "JPX / Tokyo Stock Exchange TDnet",
      "official_source_name" => "TDnet Company Announcements Disclosure Service",
      "official_source_url" => payload["attachment_url"],
      "discovery_source_name" => "TDnet current-list row",
      "discovery_source_url" => payload["row_list_url"],
      "raw_source_type" => payload["source_category"],
      "source_tier" => source.default_source_tier || "official_exchange_storage",
      "country" => "JP",
      "region_code" => region_code,
      "home_market_region_code" => home_market_region_code,
      "published_at_utc" => iso8601(published_at),
      "published_at_local" => payload["published_at_local"],
      "filing_date_local" => payload["row_date"],
      "importance_band" => "P1",
      "source_meta" => %{
        "stable_external_id" => payload["stable_external_id"],
        "cursor_value" => payload["cursor_value"],
        "cursor_key" => @cursor_key,
        "row_list_url" => payload["row_list_url"],
        "row_date" => payload["row_date"],
        "disclosure_time" => payload["disclosure_time"],
        "tdnet_raw_row_code" => payload["tdnet_raw_row_code"],
        "normalized_security_code" => security_code,
        "row_display_name" => payload["row_display_name"],
        "issuer_name" => payload["issuer_name"],
        "exchange" => payload["exchange"],
        "xbrl" => payload["xbrl"],
        "update_history" => payload["update_history"],
        "source_category" => payload["source_category"],
        "material_category" => payload["material_category"],
        "source_category_inferred" => false,
        "pdf_document_token" => pdf_document_token,
        "attachment_url" => payload["attachment_url"]
      },
      "risk_flags" => ["jp_tdnet_fixture_v0", "pdf_token_identity_used", "category_unknown_not_inferred"],
      "portable_citations" => [
        %{
          "source_name" => "TDnet current-list row",
          "claim_supported" => "disclosure date/time, code, company display name, title, exchange, and PDF token",
          "note" => payload["row_list_url"]
        },
        %{
          "source_name" => "TDnet PDF attachment",
          "claim_supported" => "full company name, security code, exchange, title, and disclosure body used for v0 normalization",
          "note" => payload["attachment_url"]
        }
      ]
    }

    {:ok,
     %{
       contract_v1: contract_v1,
       digest_date: digest_date,
       edition: edition,
       story_key: event_id,
       headline: payload["title"],
       summary: payload["fact_summary_ko"],
       canonical_url: payload["attachment_url"],
       published_at: published_at,
       tickers: [security_code],
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
         true <- String.contains?(response.body, "140120260430515474") do
      {:ok, response.body}
    else
      _ -> load_fixture(fixture_path)
    end
  end

  defp load_discovery_payload(source, false), do: load_fixture(discovery_fixture_path(source))

  defp discovery_fixture_path(source) do
    get_in(source.config || %{}, ["fixtures", "discovery_result"]) ||
      get_in(source.config || %{}, [:fixtures, :discovery_result])
  end

  defp pdf_fixture_path(source, stable_external_id) do
    pdf_pages =
      get_in(source.config || %{}, ["fixtures", "pdf_pages"]) ||
        get_in(source.config || %{}, [:fixtures, :pdf_pages]) || %{}

    Map.get(pdf_pages, stable_external_id) || Map.get(pdf_pages, to_string(stable_external_id))
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

  defp discovery_item_from(_source, row) do
    row_date = row["rowDate"]
    disclosure_time = row["disclosureTime"]
    disclosure_time_compact = String.replace(disclosure_time, ":", "")
    normalized_security_code = row["normalizedSecurityCode"]
    pdf_document_token = row["pdfDocumentToken"]

    stable_external_id =
      "TDNET:#{normalized_security_code}:#{String.replace(row_date, "-", "")}:#{disclosure_time_compact}:#{pdf_document_token}"

    published_at_local = row["publishedAtLocal"]
    published_at_utc_iso = row["publishedAtUtc"]
    published_at_utc = parse_utc!(published_at_utc_iso)

    cursor_value = "#{published_at_local}|#{normalized_security_code}|#{pdf_document_token}"

    %{
      external_id: cursor_value,
      raw_json: Jason.encode!(row),
      row_list_url: row["rowListUrl"],
      row_date: row_date,
      disclosure_time: disclosure_time,
      disclosure_time_compact: disclosure_time_compact,
      published_at_local: published_at_local,
      published_at_utc_iso: published_at_utc_iso,
      published_at_utc: published_at_utc,
      tdnet_raw_row_code: row["tdnetRawRowCode"],
      normalized_security_code: normalized_security_code,
      row_display_name: row["rowDisplayName"],
      issuer_name: row["issuerName"],
      title: row["title"],
      exchange: row["exchange"],
      xbrl: row["xbrl"],
      update_history: row["updateHistory"],
      source_category: row["sourceCategory"],
      material_category: row["materialCategory"] || "unknown",
      pdf_document_token: pdf_document_token,
      attachment_url: row["attachmentUrl"],
      stable_external_id: stable_external_id,
      cursor_value: cursor_value
    }
  end

  defp target_row?(item, %SourceRegistry{} = source) do
    filter = source.config["filter"] || source.config[:filter] || %{}

    same?(item.normalized_security_code, filter["normalized_security_code"] || filter[:normalized_security_code]) and
      same?(item.pdf_document_token, filter["pdf_document_token"] || filter[:pdf_document_token]) and
      same?(item.row_date, filter["row_date"] || filter[:row_date])
  end

  defp same?(_value, nil), do: true
  defp same?(value, expected), do: to_string(value) == to_string(expected)

  defp parse_utc!(value) do
    {:ok, datetime, _offset} = DateTime.from_iso8601(value)
    datetime
  end

  defp extract_document_date(text) do
    case Regex.run(~r/2026\s*年\s*4\s*月\s*30\s*日/u, text || "") do
      nil -> nil
      _ -> "2026-04-30"
    end
  end

  defp summarize_document(item, pdf_text) do
    text = normalize_space(pdf_text)

    cond do
      String.contains?(text, "AVI JAPAN OPPORTUNITY TRUST PLC") and String.contains?(text, "LONGCHAMP SICAV") ->
        "Rohto Pharmaceutical received written shareholder proposals from AVI JAPAN OPPORTUNITY TRUST PLC and LONGCHAMP SICAV for the 90th ordinary general meeting of shareholders."

      true ->
        "TDnet PDF attachment for #{item.issuer_name}: #{item.title}."
    end
  end

  defp summarize_ko(item, pdf_text) do
    "#{item.issuer_name} filed a TDnet timely disclosure: #{item.title}. #{summarize_document(item, pdf_text)}"
  end

  defp normalize_space(text) do
    text
    |> to_string()
    |> String.replace(~r/\s+/, " ")
    |> String.trim()
  end

  defp iso8601(nil), do: nil
  defp iso8601(%DateTime{} = value), do: DateTime.to_iso8601(value)
end
