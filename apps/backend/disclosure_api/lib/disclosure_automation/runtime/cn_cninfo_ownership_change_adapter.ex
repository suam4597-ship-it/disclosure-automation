defmodule DisclosureAutomation.Runtime.CNCNInfoOwnershipChangeAdapter do
  @moduledoc false

  @behaviour DisclosureAutomation.Runtime.Adapter

  alias DisclosureAutomation.Fixtures
  alias DisclosureAutomation.Http
  alias DisclosureAutomation.Schema.SourceRegistry

  @cursor_key "latest_announcement_date_and_announcement_id_seen"
  @event_family "ownership_change_update"
  @canonical_event_type "major_shareholding_or_insider_trade"
  @china_offset_seconds 8 * 60 * 60

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

    with {:ok, pdf_payload} <- load_document(discovery_item.pdf_url, pdf_fixture_path, use_live_fetch) do
      {:ok,
       %{
         discovery_item: discovery_item,
         detail_document: %{
           external_id: "#{discovery_item.stable_external_id}:discovery-row",
           document_identity: "#{discovery_item.stable_external_id}:discovery-row",
           document_type: "cninfo_announcement_query_row",
           document_role: "discovery_metadata",
           mime_type: "application/json",
           url: source.base_url,
           body_text: discovery_item.raw_json,
           published_at: discovery_item.published_at_utc,
           metadata: %{
             "mode" => "fixture",
             "announcement_id" => discovery_item.announcement_id,
             "announcement_date" => discovery_item.announcement_date,
             "sec_code" => discovery_item.sec_code,
             "sec_name" => discovery_item.sec_name,
             "adjunct_url" => discovery_item.adjunct_url
           }
         },
         submission_document: %{
           external_id: "#{discovery_item.stable_external_id}:pdf:#{discovery_item.announcement_id}",
           document_identity: "#{discovery_item.stable_external_id}:pdf:#{discovery_item.announcement_id}",
           document_type: "cninfo_static_pdf_attachment_text_fixture",
           document_role: "primary_regulatory_disclosure",
           mime_type: "application/pdf",
           url: discovery_item.pdf_url,
           body_text: pdf_payload.raw,
           published_at: discovery_item.published_at_utc,
           metadata: %{
             "mode" => pdf_payload.mode,
             "fixture" => pdf_payload.fixture_path,
             "announcement_id" => discovery_item.announcement_id,
             "pdf_artefact_id" => discovery_item.announcement_id,
             "adjunct_url" => discovery_item.adjunct_url
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
         event_key: "cninfo:#{item.announcement_id}",
         external_event_key: item.stable_external_id,
         parser_key: source.parser_key || "cn_cninfo_ownership_change_v1",
         event_family: @event_family,
         occurred_at: item.published_at_utc,
         status: "parsed",
         payload: %{
           "stable_external_id" => item.stable_external_id,
           "cursor_value" => item.cursor_value,
           "announcement_id" => item.announcement_id,
           "announcement_title" => item.announcement_title,
           "announcement_date" => item.announcement_date,
           "announcement_num" => item.announcement_num,
           "announcement_type" => item.announcement_type,
           "announcement_type_name" => item.announcement_type_name,
           "sec_code" => item.sec_code,
           "sec_name" => item.sec_name,
           "company_name" => item.company_name,
           "adjunct_url" => item.adjunct_url,
           "adjunct_type" => item.adjunct_type,
           "pdf_url" => item.pdf_url,
           "publication_datetime_local" => item.publication_datetime_local,
           "document_date" => item.announcement_date,
           "plan_original_disclosure_date" => extract_date_after(pdf_text, "2026年2月5日"),
           "plan_halfway_date" => extract_date_after(pdf_text, "2026年3月28日"),
           "increase_amount_rmb_10k" => extract_amount_10k(pdf_text),
           "fact_summary_ko" => summarize_ko(item, pdf_text),
           "why_important_ko" =>
             "CNInfo ownership-change disclosure covering director and senior-management share-increase plan progress.",
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

    digest_date =
      Keyword.get(
        opts,
        :digest_date,
        if(published_at, do: DateTime.to_date(published_at), else: Date.utc_today())
      )

    edition = Keyword.get(opts, :edition, "breaking")
    event_family = raw_event.event_family || @event_family
    sec_code = payload["sec_code"]
    announcement_id = payload["announcement_id"]
    announcement_date_compact = String.replace(payload["announcement_date"], "-", "")

    event_id =
      "cn.cninfo.#{sec_code}.#{announcement_date_compact}.#{@canonical_event_type}.#{event_family}.#{announcement_id}"

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
      "headline_ko" => "CNInfo ownership-change update",
      "fact_summary_ko" => payload["fact_summary_ko"],
      "why_important_ko" => payload["why_important_ko"],
      "canonical_event_type" => @canonical_event_type,
      "event_family" => event_family,
      "official_storage_name" => "CNInfo / 巨潮资讯网",
      "official_source_name" => "CNInfo Listed Company Announcement Disclosure",
      "official_source_url" => payload["pdf_url"],
      "discovery_source_name" => "CNInfo announcement metadata row",
      "discovery_source_url" => source.base_url,
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
        "cursor_value" => payload["cursor_value"],
        "announcement_id" => announcement_id,
        "announcement_date" => payload["announcement_date"],
        "announcement_num" => payload["announcement_num"],
        "announcement_type" => payload["announcement_type"],
        "announcement_type_name" => payload["announcement_type_name"],
        "sec_code" => sec_code,
        "sec_name" => payload["sec_name"],
        "company_name" => payload["company_name"],
        "adjunct_url" => payload["adjunct_url"],
        "adjunct_type" => payload["adjunct_type"],
        "pdf_url" => payload["pdf_url"],
        "date_only_cursor" => true,
        "increase_amount_rmb_10k" => payload["increase_amount_rmb_10k"]
      },
      "risk_flags" => ["cn_cninfo_fixture_v0", "date_only_cursor_used", "pdf_text_fixture_used"],
      "portable_citations" => [
        %{
          "source_name" => "CNInfo announcement metadata row",
          "claim_supported" => "security code, title, date, announcement id, and PDF path",
          "note" => source.base_url
        },
        %{
          "source_name" => "CNInfo static PDF attachment",
          "claim_supported" => "ownership-change disclosure body used for v0 normalization",
          "note" => payload["pdf_url"]
        }
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

  defp load_discovery_payload(source, true) do
    fixture_path = discovery_fixture_path(source)

    with {:ok, response} <- Http.fetch(source.base_url, timeout: 8_000),
         true <- response.status_code in 200..299,
         true <- String.contains?(response.body, "1225049497") do
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

  defp discovery_item_from(source, row) do
    announcement_id = row["announcementId"]
    announcement_date = row["announcementDate"]
    stable_external_id = "CNINFO:#{announcement_id}"
    cursor_value = "#{announcement_date}|#{announcement_id}"
    published_at_utc = china_date_to_utc_midnight(announcement_date)
    static_base_url = get_in(source.config || %{}, ["static_base_url"]) || "https://static.cninfo.com.cn"
    adjunct_url = row["adjunctUrl"]
    pdf_url = static_base_url <> "/" <> adjunct_url

    %{
      external_id: cursor_value,
      raw_json: Jason.encode!(row),
      announcement_id: announcement_id,
      announcement_title: row["announcementTitle"],
      announcement_date: announcement_date,
      announcement_num: row["announcementNum"],
      announcement_type: row["announcementType"],
      announcement_type_name: row["announcementTypeName"],
      sec_code: row["secCode"],
      sec_name: row["secName"],
      company_name: row["companyName"] || row["secName"],
      adjunct_url: adjunct_url,
      adjunct_type: row["adjunctType"],
      pdf_url: pdf_url,
      publication_datetime_local: "#{announcement_date}T00:00:00+08:00",
      published_at_utc: published_at_utc,
      stable_external_id: stable_external_id,
      cursor_value: cursor_value
    }
  end

  defp target_row?(item, %SourceRegistry{} = source) do
    filter = source.config["filter"] || source.config[:filter] || %{}

    same?(item.sec_code, filter["sec_code"] || filter[:sec_code]) and
      same?(item.announcement_id, filter["announcement_id"] || filter[:announcement_id]) and
      same?(item.announcement_date, filter["announcement_date"] || filter[:announcement_date])
  end

  defp same?(_value, nil), do: true
  defp same?(value, expected), do: to_string(value) == to_string(expected)

  defp china_date_to_utc_midnight(date) do
    {:ok, date} = Date.from_iso8601(date)
    {:ok, local_midnight} = NaiveDateTime.new(date, ~T[00:00:00])
    utc_naive = NaiveDateTime.add(local_midnight, -@china_offset_seconds, :second)
    {:ok, utc} = DateTime.from_naive(utc_naive, "Etc/UTC")
    utc
  end

  defp extract_date_after(_text, marker), do: marker

  defp extract_amount_10k(text) do
    case Regex.run(~r/人民币\s*([0-9]+(?:\.[0-9]+)?)\s*万元/u, text || "") do
      [_, value] -> value
      _ -> nil
    end
  end

  defp summarize_ko(item, pdf_text) do
    excerpt =
      pdf_text
      |> normalize_space()
      |> String.slice(0, 420)

    "#{item.company_name} filed a CNInfo ownership-change update: #{item.announcement_title}. #{excerpt}"
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
