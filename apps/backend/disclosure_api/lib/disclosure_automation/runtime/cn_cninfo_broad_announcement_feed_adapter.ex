defmodule DisclosureAutomation.Runtime.CNCNInfoBroadAnnouncementFeedAdapter do
  @moduledoc false

  @behaviour DisclosureAutomation.Runtime.Adapter

  alias DisclosureAutomation.Fixtures
  alias DisclosureAutomation.Schema.SourceRegistry

  @cursor_key "latest_announcement_date_and_announcement_id_seen"
  @china_offset_seconds 8 * 60 * 60

  @impl true
  def discover(%SourceRegistry{} = source, _opts \\ []) do
    with {:ok, payload} <- load_fixture(discovery_fixture_path(source)),
         {:ok, decoded} <- Jason.decode(payload) do
      items =
        decoded
        |> Map.get("announcements", [])
        |> Enum.map(&discovery_item_from(&1))
        |> Enum.filter(&target_row?(&1, source))
        |> Enum.sort_by(& &1.cursor_value)

      {:ok, items}
    end
  end

  @impl true
  def hydrate(%SourceRegistry{} = source, discovery_item, _opts \\ []) do
    pdf_fixture_path = pdf_fixture_path(source, discovery_item.stable_external_id)

    with {:ok, pdf_payload} <- fixture_document(pdf_fixture_path) do
      {:ok,
       %{
         discovery_item: discovery_item,
         detail_document: %{
           external_id: "#{discovery_item.stable_external_id}:discovery-row",
           document_identity: "#{discovery_item.stable_external_id}:discovery-row",
           document_type: "cninfo_broad_announcement_row",
           document_role: "discovery_metadata",
           mime_type: "application/json",
           url: discovery_item.detail_url,
           body_text: discovery_item.raw_json,
           published_at: discovery_item.published_at_utc,
           metadata: base_metadata(discovery_item)
         },
         submission_document: %{
           external_id: "#{discovery_item.stable_external_id}:pdf:#{discovery_item.announcement_id}",
           document_identity: "#{discovery_item.stable_external_id}:pdf:#{discovery_item.announcement_id}",
           document_type: "cninfo_broad_pdf_attachment_text_fixture",
           document_role: "primary_regulatory_disclosure",
           mime_type: "application/pdf",
           url: discovery_item.pdf_url,
           body_text: pdf_payload.raw,
           published_at: discovery_item.published_at_utc,
           metadata: Map.merge(base_metadata(discovery_item), %{"fixture" => pdf_payload.fixture_path})
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
         event_key: "cninfo:#{item.sec_code}:#{item.announcement_date}:#{item.announcement_id}",
         external_event_key: item.stable_external_id,
         parser_key: source.parser_key || "cn_cninfo_broad_announcement_feed_v1",
         event_family: item.event_family,
         occurred_at: item.published_at_utc,
         status: "parsed",
         payload: %{
           "stable_external_id" => item.stable_external_id,
           "cursor_value" => item.cursor_value,
           "announcement_id" => item.announcement_id,
           "announcement_date" => item.announcement_date,
           "publication_datetime_local" => item.publication_datetime_local,
           "sec_code" => item.sec_code,
           "sec_name" => item.sec_name,
           "company_name" => item.company_name,
           "announcement_title" => item.announcement_title,
           "announcement_type" => item.announcement_type,
           "announcement_type_name" => item.announcement_type_name,
           "org_id" => item.org_id,
           "detail_url" => item.detail_url,
           "adjunct_url" => item.adjunct_url,
           "pdf_url" => item.pdf_url,
           "event_family" => item.event_family,
           "canonical_event_type" => item.canonical_event_type,
           "fact_summary_ko" => summarize_ko(item, pdf_text),
           "why_important_ko" => "CNInfo controlled broad announcement feed fixture preserving announcement id, issuer, document path, and family mapping.",
           "raw_excerpt" => String.slice(normalize_space(pdf_text), 0, 900)
         },
         metadata: %{
           "discovery_mode" => source.discovery_mode,
           "hydrate_mode" => source.hydrate_mode,
           "date_only_cursor" => true
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
    event_family = payload["event_family"] || raw_event.event_family
    canonical_event_type = payload["canonical_event_type"]
    sec_code = payload["sec_code"]
    announcement_id = payload["announcement_id"]
    date_compact = String.replace(payload["announcement_date"], "-", "")
    event_id = "cn.cninfo.#{sec_code}.#{date_compact}.#{canonical_event_type}.#{event_family}.#{announcement_id}"
    region_code = source.region_code || "cn"
    home_market_region_code = source.default_home_market_region_code || region_code

    contract_v1 = %{
      "event_id" => event_id,
      "dedupe_key" => payload["stable_external_id"],
      "issuer_entity_key" => "cninfo:#{sec_code}",
      "issuer_ids" => %{"security_code" => sec_code},
      "issuer_name_local" => payload["company_name"],
      "issuer_name_en" => payload["company_name"],
      "headline_local" => payload["announcement_title"],
      "headline_ko" => "CNInfo broad announcement update",
      "fact_summary_ko" => payload["fact_summary_ko"],
      "why_important_ko" => payload["why_important_ko"],
      "canonical_event_type" => canonical_event_type,
      "event_family" => event_family,
      "official_storage_name" => "CNInfo / 巨潮资讯网",
      "official_source_name" => "CNInfo broad announcement feed",
      "official_source_url" => payload["pdf_url"],
      "discovery_source_name" => "CNInfo latest announcement row",
      "discovery_source_url" => payload["detail_url"],
      "raw_source_type" => payload["announcement_type_name"],
      "source_tier" => source.default_source_tier || "official_exchange_storage",
      "country" => "CN",
      "region_code" => region_code,
      "home_market_region_code" => home_market_region_code,
      "published_at_utc" => iso8601(published_at),
      "published_at_local" => payload["publication_datetime_local"],
      "filing_date_local" => payload["announcement_date"],
      "importance_band" => "P1",
      "source_meta" => %{
        "stable_external_id" => payload["stable_external_id"],
        "cursor_key" => @cursor_key,
        "cursor_value" => payload["cursor_value"],
        "announcement_id" => announcement_id,
        "announcement_date" => payload["announcement_date"],
        "sec_code" => sec_code,
        "sec_name" => payload["sec_name"],
        "company_name" => payload["company_name"],
        "org_id" => payload["org_id"],
        "detail_url" => payload["detail_url"],
        "adjunct_url" => payload["adjunct_url"],
        "pdf_url" => payload["pdf_url"],
        "date_only_cursor" => true
      },
      "risk_flags" => ["cn_cninfo_broad_fixture_v0", "date_only_cursor_used"],
      "portable_citations" => [
        %{"source_name" => "CNInfo latest announcement row", "claim_supported" => "security code, title, date, announcement id, and detail URL", "note" => payload["detail_url"]},
        %{"source_name" => "CNInfo PDF attachment", "claim_supported" => "announcement PDF body used for v0 normalization", "note" => payload["pdf_url"]}
      ]
    }

    {:ok,
     %{
       contract_v1: contract_v1,
       digest_date: digest_date,
       edition: edition,
       story_key: event_id,
       headline: payload["announcement_title"],
       summary: payload["fact_summary_ko"],
       canonical_url: payload["pdf_url"],
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
    %{"mode" => "fixture", "announcement_id" => item.announcement_id, "announcement_date" => item.announcement_date, "sec_code" => item.sec_code, "sec_name" => item.sec_name, "org_id" => item.org_id, "adjunct_url" => item.adjunct_url}
  end

  defp discovery_fixture_path(source), do: get_in(source.config || %{}, ["fixtures", "discovery_result"]) || get_in(source.config || %{}, [:fixtures, :discovery_result])
  defp pdf_fixture_path(source, stable_external_id) do
    pdf_pages = get_in(source.config || %{}, ["fixtures", "pdf_pages"]) || get_in(source.config || %{}, [:fixtures, :pdf_pages]) || %{}
    Map.get(pdf_pages, stable_external_id) || Map.get(pdf_pages, to_string(stable_external_id))
  end
  defp fixture_document(fixture_path) do
    with {:ok, payload} <- Fixtures.load_source_payload(fixture_path), do: {:ok, %{raw: payload.raw, fixture_path: payload.relative_path}}
  end
  defp load_fixture(fixture_path), do: with({:ok, payload} <- Fixtures.load_source_payload(fixture_path), do: {:ok, payload.raw})

  defp discovery_item_from(row) do
    announcement_date = row["announcementDate"]
    announcement_id = row["announcementId"]
    sec_code = row["secCode"]
    date_compact = String.replace(announcement_date, "-", "")
    stable_external_id = "CNINFO:#{sec_code}:#{date_compact}:#{announcement_id}"
    cursor_value = "#{announcement_date}|#{announcement_id}"
    published_at_utc = china_date_to_utc_midnight(announcement_date)

    %{
      external_id: cursor_value,
      raw_json: Jason.encode!(row),
      announcement_id: announcement_id,
      announcement_date: announcement_date,
      publication_datetime_local: "#{announcement_date}T00:00:00+08:00",
      published_at_utc: published_at_utc,
      sec_code: sec_code,
      sec_name: row["secName"],
      company_name: row["companyName"] || row["secName"],
      announcement_title: row["announcementTitle"],
      announcement_type: row["announcementType"],
      announcement_type_name: row["announcementTypeName"],
      org_id: row["orgId"],
      detail_url: row["detailUrl"],
      adjunct_url: row["adjunctUrl"],
      pdf_url: row["pdfUrl"],
      event_family: row["eventFamily"],
      canonical_event_type: row["canonicalEventType"],
      stable_external_id: stable_external_id,
      cursor_value: cursor_value
    }
  end

  defp target_row?(item, %SourceRegistry{} = source) do
    filter = source.config["filter"] || source.config[:filter] || %{}
    ids = filter["announcement_ids"] || filter[:announcement_ids] || []
    same?(item.announcement_date, filter["announcement_date"] || filter[:announcement_date]) and (ids == [] or item.announcement_id in ids)
  end

  defp china_date_to_utc_midnight(date) do
    {:ok, date} = Date.from_iso8601(date)
    {:ok, local_midnight} = NaiveDateTime.new(date, ~T[00:00:00])
    utc_naive = NaiveDateTime.add(local_midnight, -@china_offset_seconds, :second)
    {:ok, utc} = DateTime.from_naive(utc_naive, "Etc/UTC")
    utc
  end

  defp same?(_value, nil), do: true
  defp same?(value, expected), do: to_string(value) == to_string(expected)
  defp summarize_ko(item, pdf_text), do: "#{item.company_name} filed a CNInfo broad announcement: #{item.announcement_title}. #{String.slice(normalize_space(pdf_text), 0, 260)}"
  defp normalize_space(text), do: text |> to_string() |> String.replace(~r/\s+/, " ") |> String.trim()
  defp iso8601(nil), do: nil
  defp iso8601(%DateTime{} = value), do: DateTime.to_iso8601(value)
end
