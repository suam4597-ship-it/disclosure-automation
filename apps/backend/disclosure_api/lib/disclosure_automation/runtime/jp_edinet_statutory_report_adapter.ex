defmodule DisclosureAutomation.Runtime.JPEdinetStatutoryReportAdapter do
  @moduledoc false

  @behaviour DisclosureAutomation.Runtime.Adapter

  alias DisclosureAutomation.Fixtures
  alias DisclosureAutomation.Schema.SourceRegistry

  @cursor_key "latest_submit_datetime_and_doc_id_seen"
  @event_family "statutory_report_update"
  @canonical_event_type "extraordinary_report"

  @impl true
  def discover(%SourceRegistry{} = source, _opts \\ []) do
    with {:ok, payload} <- load_fixture(discovery_fixture_path(source)),
         {:ok, decoded} <- Jason.decode(payload) do
      items =
        decoded
        |> Map.get("results", [])
        |> Enum.map(&discovery_item_from(&1))
        |> Enum.filter(&target_row?(&1, source))
        |> Enum.sort_by(& &1.cursor_value)

      {:ok, items}
    end
  end

  @impl true
  def hydrate(%SourceRegistry{} = source, discovery_item, _opts \\ []) do
    primary_fixture_path = primary_fixture_path(source, discovery_item.stable_external_id)

    with {:ok, primary_payload} <- fixture_document(primary_fixture_path) do
      {:ok,
       %{
         discovery_item: discovery_item,
         detail_document: %{
           external_id: "#{discovery_item.stable_external_id}:document-list-row",
           document_identity: "#{discovery_item.stable_external_id}:document-list-row",
           document_type: "edinet_documents_list_row",
           document_role: "discovery_metadata",
           mime_type: "application/json",
           url: discovery_item.discovery_request_shape,
           body_text: discovery_item.raw_json,
           published_at: discovery_item.published_at_utc,
           metadata: base_metadata(discovery_item)
         },
         submission_document: %{
           external_id: "#{discovery_item.stable_external_id}:primary-document:type1",
           document_identity: "#{discovery_item.stable_external_id}:primary-document:type1",
           document_type: "edinet_type1_primary_document_text_fixture",
           document_role: "primary_regulatory_disclosure",
           mime_type: "text/plain",
           url: discovery_item.primary_document_request_shape,
           body_text: primary_payload.raw,
           published_at: discovery_item.published_at_utc,
           metadata: Map.merge(base_metadata(discovery_item), %{"fixture" => primary_payload.fixture_path})
         }
       }}
    end
  end

  @impl true
  def parse(%SourceRegistry{} = source, hydrated_item, _opts \\ []) do
    item = hydrated_item.discovery_item
    primary_text = hydrated_item.submission_document.body_text || ""

    {:ok,
     [
       %{
         event_key: "edinet:#{item.doc_id}",
         external_event_key: item.stable_external_id,
         parser_key: source.parser_key || "jp_edinet_statutory_report_v1",
         event_family: @event_family,
         occurred_at: item.published_at_utc,
         status: "parsed",
         payload: %{
           "stable_external_id" => item.stable_external_id,
           "cursor_value" => item.cursor_value,
           "seq_number" => item.seq_number,
           "doc_id" => item.doc_id,
           "edinet_code" => item.edinet_code,
           "sec_code" => item.sec_code,
           "filer_name" => item.filer_name,
           "doc_type_code" => item.doc_type_code,
           "submit_datetime_local" => item.submit_datetime_local,
           "submit_datetime_utc" => item.submit_datetime_utc_iso,
           "submit_date_local" => item.submit_date_local,
           "doc_description" => item.doc_description,
           "xbrl_flag" => item.xbrl_flag,
           "pdf_flag" => item.pdf_flag,
           "csv_flag" => item.csv_flag,
           "discovery_request_shape" => item.discovery_request_shape,
           "primary_document_request_shape" => item.primary_document_request_shape,
           "primary_document_zip_file" => item.primary_document_zip_file,
           "primary_document_source_path" => item.primary_document_source_path,
           "primary_document_content_type" => item.primary_document_content_type,
           "fact_summary_ko" => summarize_ko(item, primary_text),
           "why_important_ko" => "EDINET statutory extraordinary report fixture preserving official docID, filer, submit datetime, and primary iXBRL text extraction.",
           "raw_excerpt" => String.slice(normalize_space(primary_text), 0, 900)
         },
         metadata: %{
           "discovery_mode" => source.discovery_mode,
           "hydrate_mode" => source.hydrate_mode,
           "api_key_redacted" => true,
           "primary_document_fixture" => true
         }
       }
     ]}
  end

  @impl true
  def normalize(%SourceRegistry{} = source, raw_event, opts \\ []) do
    payload = raw_event.payload || %{}
    published_at = raw_event.occurred_at
    digest_date = Keyword.get(opts, :digest_date, if(published_at, do: DateTime.to_date(published_at), else: Date.utc_today()))
    edition = Keyword.get(opts, :edition, "breaking")
    event_family = raw_event.event_family || @event_family
    edinet_code = payload["edinet_code"]
    doc_id = payload["doc_id"]
    submit_date_compact = String.replace(payload["submit_date_local"], "-", "")
    event_id = "jp.edinet.#{edinet_code}.#{submit_date_compact}.#{@canonical_event_type}.#{event_family}.#{doc_id}"
    region_code = source.region_code || "jp"
    home_market_region_code = source.default_home_market_region_code || region_code

    contract_v1 = %{
      "event_id" => event_id,
      "dedupe_key" => payload["stable_external_id"],
      "issuer_entity_key" => "edinet:#{edinet_code}",
      "issuer_ids" => %{"edinet_code" => edinet_code, "sec_code" => payload["sec_code"]},
      "issuer_name_local" => payload["filer_name"],
      "issuer_name_en" => payload["filer_name"],
      "headline_local" => payload["doc_description"],
      "headline_ko" => "EDINET statutory extraordinary report",
      "fact_summary_ko" => payload["fact_summary_ko"],
      "why_important_ko" => payload["why_important_ko"],
      "canonical_event_type" => @canonical_event_type,
      "event_family" => event_family,
      "official_storage_name" => "EDINET / Financial Services Agency",
      "official_source_name" => "EDINET disclosure document API",
      "official_source_url" => payload["primary_document_request_shape"],
      "discovery_source_name" => "EDINET document-list API row",
      "discovery_source_url" => payload["discovery_request_shape"],
      "raw_source_type" => payload["doc_type_code"],
      "source_tier" => source.default_source_tier || "official_regulatory_storage",
      "country" => "JP",
      "region_code" => region_code,
      "home_market_region_code" => home_market_region_code,
      "published_at_utc" => iso8601(published_at),
      "published_at_local" => payload["submit_datetime_local"],
      "filing_date_local" => payload["submit_date_local"],
      "importance_band" => "P1",
      "source_meta" => %{
        "stable_external_id" => payload["stable_external_id"],
        "cursor_key" => @cursor_key,
        "cursor_value" => payload["cursor_value"],
        "doc_id" => doc_id,
        "edinet_code" => edinet_code,
        "sec_code" => payload["sec_code"],
        "doc_type_code" => payload["doc_type_code"],
        "seq_number" => payload["seq_number"],
        "xbrl_flag" => payload["xbrl_flag"],
        "pdf_flag" => payload["pdf_flag"],
        "csv_flag" => payload["csv_flag"],
        "api_key_redacted" => true,
        "primary_document_zip_file" => payload["primary_document_zip_file"],
        "primary_document_source_path" => payload["primary_document_source_path"],
        "primary_document_content_type" => payload["primary_document_content_type"]
      },
      "risk_flags" => ["jp_edinet_fixture_v0", "api_key_redacted", "primary_document_text_fixture_used"],
      "portable_citations" => [
        %{"source_name" => "EDINET document-list API row", "claim_supported" => "docID, filer, doc type, and submit datetime", "note" => payload["discovery_request_shape"]},
        %{"source_name" => "EDINET type=1 primary document text fixture", "claim_supported" => "extraordinary report body text used for v0 normalization", "note" => payload["primary_document_request_shape"]}
      ]
    }

    {:ok,
     %{
       contract_v1: contract_v1,
       digest_date: digest_date,
       edition: edition,
       story_key: event_id,
       headline: payload["doc_description"],
       summary: payload["fact_summary_ko"],
       canonical_url: payload["primary_document_request_shape"],
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

  defp base_metadata(item) do
    %{
      "mode" => "fixture",
      "doc_id" => item.doc_id,
      "edinet_code" => item.edinet_code,
      "doc_type_code" => item.doc_type_code,
      "submit_datetime_local" => item.submit_datetime_local,
      "api_key_redacted" => true
    }
  end

  defp discovery_fixture_path(source), do: get_in(source.config || %{}, ["fixtures", "discovery_result"]) || get_in(source.config || %{}, [:fixtures, :discovery_result])

  defp primary_fixture_path(source, stable_external_id) do
    primary_documents = get_in(source.config || %{}, ["fixtures", "primary_documents"]) || get_in(source.config || %{}, [:fixtures, :primary_documents]) || %{}
    Map.get(primary_documents, stable_external_id) || Map.get(primary_documents, to_string(stable_external_id))
  end

  defp fixture_document(fixture_path) do
    with {:ok, payload} <- Fixtures.load_source_payload(fixture_path) do
      {:ok, %{raw: payload.raw, fixture_path: payload.relative_path}}
    end
  end

  defp load_fixture(fixture_path) do
    with {:ok, payload} <- Fixtures.load_source_payload(fixture_path), do: {:ok, payload.raw}
  end

  defp discovery_item_from(row) do
    doc_id = row["docID"]
    submit_datetime_local = row["submitDateTimeLocal"]
    submit_datetime_utc_iso = row["submitDateTimeUtc"]
    submit_date_local = row["submitDateLocal"]
    stable_external_id = "EDINET:#{doc_id}"
    cursor_value = "#{submit_datetime_local}|#{doc_id}"
    published_at_utc = parse_utc!(submit_datetime_utc_iso)

    %{
      external_id: cursor_value,
      raw_json: Jason.encode!(row),
      seq_number: row["seqNumber"],
      doc_id: doc_id,
      edinet_code: row["edinetCode"],
      sec_code: row["secCode"],
      filer_name: row["filerName"],
      doc_type_code: row["docTypeCode"],
      submit_datetime_local: submit_datetime_local,
      submit_datetime_utc_iso: submit_datetime_utc_iso,
      submit_date_local: submit_date_local,
      doc_description: row["docDescription"],
      xbrl_flag: row["xbrlFlag"],
      pdf_flag: row["pdfFlag"],
      csv_flag: row["csvFlag"],
      discovery_request_shape: row["discoveryRequestShape"],
      primary_document_request_shape: row["primaryDocumentRequestShape"],
      primary_document_zip_file: row["primaryDocumentZipFile"],
      primary_document_source_path: row["primaryDocumentSourcePath"],
      primary_document_content_type: row["primaryDocumentContentType"],
      stable_external_id: stable_external_id,
      cursor_value: cursor_value,
      published_at_utc: published_at_utc
    }
  end

  defp target_row?(item, %SourceRegistry{} = source) do
    filter = source.config["filter"] || source.config[:filter] || %{}
    same?(item.doc_id, filter["doc_id"] || filter[:doc_id])
  end

  defp same?(_value, nil), do: true
  defp same?(value, expected), do: to_string(value) == to_string(expected)

  defp parse_utc!(value) do
    {:ok, datetime, _offset} = DateTime.from_iso8601(value)
    datetime
  end

  defp summarize_ko(item, primary_text) do
    "#{item.filer_name} filed an EDINET statutory extraordinary report: #{item.doc_description}. #{String.slice(normalize_space(primary_text), 0, 260)}"
  end

  defp normalize_space(text), do: text |> to_string() |> String.replace(~r/\s+/, " ") |> String.trim()
  defp iso8601(nil), do: nil
  defp iso8601(%DateTime{} = value), do: DateTime.to_iso8601(value)
end
