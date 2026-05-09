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
      summary: canonical_summary(document),
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
      "uk" in tags or "united_kingdom" in tags -> ["uk"]
      "ch" in tags or "switzerland" in tags -> ["ch"]
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

  defp canonical_summary(document) do
    document
    |> Map.get(:summary)
    |> case do
      summary when is_binary(summary) ->
        case String.trim(summary) do
          "" -> "Summary unavailable from source feed."
          value -> value
        end

      _summary ->
        "Summary unavailable from source feed."
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

  @afm_reporting_csv_limit 25
  @emarket_storage_html_limit 25
  @emarket_storage_base_url "https://www.emarketstorage.it"
  @luxse_oam_search_url "https://www.luxse.com/issuer-services-overview/oam/oam-search"
  @fsma_stori_download_url "https://webapi.fsma.be/api/v1/en/stori/download"
  @fca_nsm_artefacts_base_url "https://data.fca.org.uk/artefacts/"
  @fca_nsm_search_url "https://data.fca.org.uk/#/nsm/nationalstoragemechanism"
  @wiener_borse_announcements_url "https://www.wienerborse.at/en/legal/announcements/"
  @xetra_newsboard_url "https://www.xetra.com/xetra-en/newsroom/xetra-newsboard/"
  @oslo_newsweb_message_url "https://newsweb.oslobors.no/message/"
  @gpw_espi_ebi_report_base_url "https://www.gpw.pl/"
  @bse_issuers_news_url "https://www.bse.hu/issuers_news"
  @bvb_current_reports_url "https://bvb.ro/FinancialInstruments/SelectedData/CurrentReports"
  @ceri_search_url "https://ceri.nbs.sk/search"
  @ceri_document_base_url "https://ceri.nbs.sk/static/data/"
  @ee_oam_base_url "https://oam.fi.ee"

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

  defp parse_by_key("euronext_company_pr_rss_v1", raw_payload),
    do: parse_euronext_company_pr_rss(raw_payload)

  defp parse_by_key("info_financiere_oam_v1", raw_payload), do: parse_info_financiere(raw_payload)

  defp parse_by_key("afm_financial_reporting_csv_v1", raw_payload),
    do: parse_afm_reporting(raw_payload)

  defp parse_by_key("emarket_storage_html_v1", raw_payload),
    do: parse_emarket_storage(raw_payload)

  defp parse_by_key("luxse_oam_graphql_v1", raw_payload),
    do: parse_luxse_oam(raw_payload)

  defp parse_by_key("fsma_stori_api_v1", raw_payload), do: parse_fsma_stori(raw_payload)

  defp parse_by_key("fca_nsm_search_api_v1", raw_payload), do: parse_fca_nsm_search(raw_payload)

  defp parse_by_key("nasdaq_nordic_cns_jsonp_v1", raw_payload),
    do: parse_nasdaq_nordic_cns(raw_payload)

  defp parse_by_key("oslo_newsweb_json_v1", raw_payload),
    do: parse_oslo_newsweb(raw_payload)

  defp parse_by_key("gpw_espi_ebi_html_v1", raw_payload),
    do: parse_gpw_espi_ebi(raw_payload)

  defp parse_by_key("bse_issuers_news_html_v1", raw_payload),
    do: parse_bse_issuers_news(raw_payload)

  defp parse_by_key("bvb_current_reports_html_v1", raw_payload),
    do: parse_bvb_current_reports(raw_payload)

  defp parse_by_key("ceri_regulated_information_html_v1", raw_payload),
    do: parse_ceri_regulated_information(raw_payload)

  defp parse_by_key("ee_oam_market_announcements_html_v1", raw_payload),
    do: parse_ee_oam_market_announcements(raw_payload)

  defp parse_by_key("wiener_borse_announcements_html_v1", raw_payload),
    do: parse_wiener_borse_announcements(raw_payload)

  defp parse_by_key("xetra_newsboard_html_v1", raw_payload),
    do: parse_xetra_newsboard(raw_payload)

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
        rss_item_nodes(document)
        |> Enum.map(&parse_item/1)
        |> Enum.filter(&(&1.url && &1.title))

      {:ok, items}
    end
  end

  defp parse_euronext_company_pr_rss(raw_payload) do
    with {:ok, records} <- parse_rss(raw_payload) do
      records =
        records
        |> euronext_prefer_english_records()
        |> Enum.map(&clean_euronext_company_pr_record/1)

      {:ok, records}
    end
  end

  defp euronext_prefer_english_records(records) do
    english_records =
      Enum.filter(records, fn record ->
        record
        |> Map.get(:url)
        |> case do
          url when is_binary(url) -> String.contains?(url, "/en/")
          _ -> false
        end
      end)

    case english_records do
      [] -> records
      _records -> english_records
    end
  end

  defp clean_euronext_company_pr_record(record) do
    Map.update(record, :summary, nil, fn summary ->
      summary
      |> euronext_company_pr_summary(record[:title])
      |> case do
        nil -> "Euronext company press release."
        cleaned -> cleaned
      end
    end)
  end

  defp euronext_company_pr_summary(summary, title) when is_binary(summary) do
    summary
    |> decode_html_entities()
    |> String.replace(~r/<[^>]+>/, " ")
    |> decode_html_entities()
    |> String.replace(~r/<[^>]+>/, " ")
    |> String.replace(~r/https?:\/\/\S+/u, " ")
    |> String.replace(~r/[\w.-]+">\s*/u, " ")
    |> String.replace(~r/\bmaster_of_puppets\b/u, " ")
    |> String.replace(~r/\s+/u, " ")
    |> String.trim()
    |> euronext_after_language_marker()
    |> trim_euronext_summary_prefix(title)
    |> String.slice(0, 360)
    |> String.trim()
    |> case do
      "" -> nil
      cleaned -> cleaned
    end
  end

  defp euronext_company_pr_summary(_summary, _title), do: nil

  defp euronext_after_language_marker(summary) do
    case Regex.split(
           ~r/\bLanguage\s+(?:English|French|Dutch|Portuguese|Italian|Norwegian)\s+/u,
           summary,
           parts: 2
         ) do
      [_before, after_marker] -> after_marker
      _parts -> summary
    end
  end

  defp trim_euronext_summary_prefix(summary, title) when is_binary(title) do
    summary
    |> String.replace_prefix(title, "")
    |> String.trim()
    |> String.replace(~r/^html\s+xmlns=.*?\bbody\s*;?\s*/iu, "")
    |> String.replace(~r/^Stocks\s+/u, "")
    |> String.replace(~r/^Bonds\s+Stocks\s+/u, "")
    |> String.replace(~r/^Fri\s+\d{2}\/\d{2}\/\d{4}\s+-\s+\d{2}:\d{2}\s+/u, "")
    |> String.replace(~r/^ven\s+\d{2}\/\d{2}\/\d{4}\s+-\s+\d{2}:\d{2}\s+/u, "")
    |> String.replace(~r/^[\s;:,-]+/u, "")
  end

  defp trim_euronext_summary_prefix(summary, _title), do: summary

  defp rss_item_nodes(document) do
    [
      ~c"/rss/channel/item",
      ~c"/rss/Channel/item",
      ~c"/rss/channel/Item",
      ~c"/rss/Channel/Item"
    ]
    |> Enum.flat_map(&:xmerl_xpath.string(&1, document))
  end

  defp parse_info_financiere(raw_payload) do
    with {:ok, decoded} <- Jason.decode(raw_payload),
         records when is_list(records) <- info_financiere_records(decoded) do
      items =
        records
        |> Enum.map(&parse_info_financiere_record/1)
        |> Enum.filter(&(&1.url && &1.title))

      {:ok, items}
    else
      {:error, error} -> {:error, {:invalid_json, error}}
      _ -> {:error, {:invalid_json_shape, "info_financiere_oam_v1"}}
    end
  end

  defp info_financiere_records(%{"results" => records}) when is_list(records), do: records

  defp info_financiere_records(%{"records" => records}) when is_list(records) do
    Enum.map(records, fn
      %{"fields" => fields} when is_map(fields) -> fields
      record -> record
    end)
  end

  defp info_financiere_records(records) when is_list(records), do: records
  defp info_financiere_records(_decoded), do: nil

  defp parse_info_financiere_record(record) when is_map(record) do
    company = string_field(record, "identificationsociete_iso_nom_soc")
    issuer_title = string_field(record, "informationdeposee_inf_tit_inf")

    type =
      string_field(record, "type_of_information") || string_field(record, "type_d_information")

    subtype =
      string_field(record, "subtype_of_information") ||
        string_field(record, "sous_type_d_information")

    isin = string_field(record, "identificationsociete_iso_cd_isi")
    ticker = string_field(record, "identificationsociete_iso_code_tkr_iso_cd_tkr")
    language = string_field(record, "informationdeposee_inf_lng_inf")

    %{
      external_id:
        string_field(record, "uin_idt_uin") || string_field(record, "url_de_recuperation"),
      title: join_non_empty([company, issuer_title || subtype || type], " - "),
      url: string_field(record, "url_de_recuperation"),
      summary:
        join_non_empty(
          [
            type,
            subtype,
            prefixed("ISIN", isin),
            prefixed("Ticker", ticker),
            prefixed("Language", language)
          ],
          " | "
        ),
      published_at:
        datetime_field(record, [
          "informationdeposee_inf_dat_emt",
          "uin_dat_amf",
          "uin_dat_mar"
        ]),
      category: subtype || type
    }
  end

  defp parse_info_financiere_record(_record) do
    %{
      external_id: nil,
      title: nil,
      url: nil,
      summary: nil,
      published_at: DateTime.utc_now(),
      category: nil
    }
  end

  defp parse_afm_reporting(raw_payload) do
    items =
      raw_payload
      |> afm_csv_to_utf8()
      |> String.split(~r/\r?\n/, trim: true)
      |> Enum.drop(1)
      |> Enum.take(@afm_reporting_csv_limit)
      |> Enum.map(&parse_afm_reporting_record/1)
      |> Enum.filter(&(&1.url && &1.title))

    {:ok, items}
  end

  defp afm_csv_to_utf8(raw_payload) do
    if String.valid?(raw_payload) do
      raw_payload
    else
      :unicode.characters_to_binary(raw_payload, :latin1, :utf8)
    end
  end

  defp parse_afm_reporting_record(row) do
    case parse_afm_csv_row(row) do
      [published_at_text, issuer, year, category | _rest] ->
        %{
          external_id: join_non_empty([published_at_text, issuer, year, category], "|"),
          title: join_non_empty([issuer, category], " - "),
          url: afm_reporting_register_url(),
          summary:
            join_non_empty(
              [
                prefixed("Reporting year", year),
                prefixed("Document type", category)
              ],
              " | "
            ),
          published_at: parse_afm_datetime(published_at_text),
          category: category
        }

      _ ->
        empty_afm_reporting_record()
    end
  end

  defp empty_afm_reporting_record do
    %{
      external_id: nil,
      title: nil,
      url: nil,
      summary: nil,
      published_at: DateTime.utc_now(),
      category: nil
    }
  end

  defp afm_reporting_register_url do
    "https://www.afm.nl/en/sector/registers/meldingenregisters/financiele-verslaggeving"
  end

  defp parse_emarket_storage(raw_payload) do
    items =
      raw_payload
      |> String.split(~r/<div class="views-row">/)
      |> Enum.drop(1)
      |> Enum.take(@emarket_storage_html_limit)
      |> Enum.map(&parse_emarket_storage_row/1)
      |> Enum.filter(&(&1.url && &1.title))

    {:ok, items}
  end

  defp parse_emarket_storage_row(row) do
    pdf_path =
      regex_capture(row, ~r/href="(\/sites\/default\/files\/comunicati\/[^"]+\.pdf)"/)

    company = regex_capture(row, ~r/<div class="news-azienda">.*?<a[^>]*>(.*?)<\/a>/s)
    title = regex_capture(row, ~r/<div class="news-title">.*?<a[^>]*>(.*?)<\/a>/s)
    published_at_text = regex_capture(row, ~r/<time[^>]*>(.*?)<\/time>/s)
    protocol = regex_capture(row, ~r/data-protocollo="([^"]+)"/)

    %{
      external_id: protocol || pdf_path,
      title: join_non_empty([company, title], " - "),
      url: emarket_storage_url(pdf_path),
      summary: join_non_empty(["Comunicati Regolamentati", prefixed("Issuer", company)], " | "),
      published_at: parse_emarket_storage_datetime(published_at_text),
      category: "Comunicati Regolamentati"
    }
  end

  defp emarket_storage_url(nil), do: nil
  defp emarket_storage_url("http" <> _rest = url), do: url
  defp emarket_storage_url("/" <> _rest = path), do: @emarket_storage_base_url <> path
  defp emarket_storage_url(path), do: @emarket_storage_base_url <> "/" <> path

  defp parse_luxse_oam(raw_payload) do
    with {:ok, decoded} <- Jason.decode(raw_payload),
         records when is_list(records) <- luxse_oam_records(decoded) do
      items =
        records
        |> Enum.map(&parse_luxse_oam_record/1)
        |> Enum.filter(&(&1.url && &1.title))

      {:ok, items}
    else
      {:error, error} -> {:error, {:invalid_json, error}}
      _ -> {:error, {:invalid_json_shape, "luxse_oam_graphql_v1"}}
    end
  end

  defp luxse_oam_records(%{
         "data" => %{"oamSubmissionsSearch" => %{"submissions" => records}}
       })
       when is_list(records),
       do: records

  defp luxse_oam_records(_decoded), do: nil

  defp parse_luxse_oam_record(record) when is_map(record) do
    issuer = string_field(record, "issuerName")
    category = string_field(record, "submissionTypeLabel")

    %{
      external_id: string_field(record, "submissionId"),
      title: join_non_empty([issuer, category], " - "),
      url: @luxse_oam_search_url,
      summary:
        join_non_empty(
          [
            "LuxSE OAM",
            prefixed("Action", string_field(record, "actionsList")),
            prefixed("Reference year", string_field(record, "referenceYear")),
            prefixed("Reference period", luxse_reference_period(record))
          ],
          " | "
        ),
      published_at:
        parse_iso8601_datetime(string_field(record, "publicationDate")) || DateTime.utc_now(),
      category: category
    }
  end

  defp parse_luxse_oam_record(_record) do
    %{
      external_id: nil,
      title: nil,
      url: nil,
      summary: nil,
      published_at: DateTime.utc_now(),
      category: nil
    }
  end

  defp luxse_reference_period(record) do
    join_non_empty(
      [
        iso_date_part(string_field(record, "referenceStartDate")),
        iso_date_part(string_field(record, "referenceEndDate"))
      ],
      " to "
    )
  end

  defp iso_date_part(nil), do: nil
  defp iso_date_part(value), do: String.slice(value, 0, 10)

  defp parse_fsma_stori(raw_payload) do
    with {:ok, decoded} <- Jason.decode(raw_payload),
         records when is_list(records) <- fsma_stori_records(decoded) do
      items =
        records
        |> Enum.map(&parse_fsma_stori_record/1)
        |> Enum.filter(&(&1.url && &1.title))

      {:ok, items}
    else
      {:error, error} -> {:error, {:invalid_json, error}}
      _ -> {:error, {:invalid_json_shape, "fsma_stori_api_v1"}}
    end
  end

  defp fsma_stori_records(%{"storiResultItems" => records}) when is_list(records), do: records

  defp fsma_stori_records(%{"data" => %{"storiResultItems" => records}}) when is_list(records),
    do: records

  defp fsma_stori_records(_decoded), do: nil

  defp parse_fsma_stori_record(record) when is_map(record) do
    company_name = string_field(record, "companyName")
    topic_name = string_field(record, "reportingTopicName")
    document_title = string_field(record, "documentTitle")
    document = fsma_stori_primary_document(record)

    %{
      external_id: fsma_stori_external_id(record, document),
      title: join_non_empty([company_name, document_title || topic_name], " - "),
      url: fsma_stori_document_url(document),
      summary: fsma_stori_summary(record, document),
      published_at: fsma_stori_datetime(record),
      category: topic_name
    }
  end

  defp parse_fsma_stori_record(_record) do
    %{
      external_id: nil,
      title: nil,
      url: nil,
      summary: nil,
      published_at: DateTime.utc_now(),
      category: nil
    }
  end

  defp fsma_stori_primary_document(record) do
    record
    |> Map.get("mainDocuments", [])
    |> case do
      [document | _rest] when is_map(document) -> document
      _documents -> nil
    end
  end

  defp fsma_stori_external_id(record, document) do
    string_field(record, "requiredReportingTopicId") ||
      string_field(document || %{}, "fileDataId") ||
      join_non_empty(
        [
          string_field(record, "companyName"),
          string_field(record, "reportingTopicName"),
          string_field(record, "datePublication")
        ],
        "-"
      )
  end

  defp fsma_stori_datetime(record) do
    ["datePublication", "dateReceived"]
    |> Enum.find_value(fn key ->
      record
      |> string_field(key)
      |> parse_fsma_stori_datetime()
    end)
    |> case do
      nil -> DateTime.utc_now()
      datetime -> datetime
    end
  end

  defp parse_fsma_stori_datetime(nil), do: nil

  defp parse_fsma_stori_datetime(value) do
    parse_iso8601_datetime(value) || parse_naive_iso8601_datetime(value)
  end

  defp parse_naive_iso8601_datetime(value) do
    with {:ok, naive_datetime} <- NaiveDateTime.from_iso8601(value),
         {:ok, datetime} <- DateTime.from_naive(naive_datetime, "Etc/UTC") do
      datetime
    else
      _ -> nil
    end
  end

  defp fsma_stori_document_url(nil), do: "https://www.fsma.be/en/stori"

  defp fsma_stori_document_url(document) do
    case string_field(document, "fileDataId") do
      nil -> "https://www.fsma.be/en/stori"
      file_data_id -> "#{@fsma_stori_download_url}?fileDataId=#{file_data_id}"
    end
  end

  defp fsma_stori_summary(record, document) do
    documents =
      record
      |> Map.get("mainDocuments", [])
      |> Enum.map(&string_field(&1, "originalFileName"))
      |> Enum.reject(&is_nil/1)
      |> Enum.take(3)
      |> Enum.join(", ")

    isin_codes =
      record
      |> Map.get("isinCodes", [])
      |> Enum.map(&string_field(&1, "code"))
      |> Enum.reject(&is_nil/1)
      |> Enum.take(3)
      |> Enum.join(", ")

    join_non_empty(
      [
        "FSMA STORI regulated information",
        prefixed("Topic", string_field(record, "reportingTopicName")),
        prefixed("Document", string_field(document || %{}, "originalFileName") || documents),
        prefixed("ISIN", isin_codes)
      ],
      " | "
    )
  end

  defp parse_fca_nsm_search(raw_payload) do
    with {:ok, decoded} <- Jason.decode(raw_payload),
         records when is_list(records) <- fca_nsm_records(decoded) do
      items =
        records
        |> Enum.map(&parse_fca_nsm_record/1)
        |> Enum.filter(&(&1.url && &1.title))

      {:ok, items}
    else
      {:error, error} -> {:error, {:invalid_json, error}}
      _ -> {:error, {:invalid_json_shape, "fca_nsm_search_api_v1"}}
    end
  end

  defp fca_nsm_records(%{"hits" => %{"hits" => records}}) when is_list(records), do: records

  defp fca_nsm_records(%{"data" => %{"hits" => %{"hits" => records}}}) when is_list(records),
    do: records

  defp fca_nsm_records(_decoded), do: nil

  defp parse_fca_nsm_record(%{"_source" => record}) when is_map(record),
    do: parse_fca_nsm_record(record)

  defp parse_fca_nsm_record(record) when is_map(record) do
    company = string_field(record, "company")
    headline = string_field(record, "headline")

    %{
      external_id:
        string_field(record, "disclosure_id") ||
          string_field(record, "seq_id") ||
          string_field(record, "download_link"),
      title: fca_nsm_title(company, headline),
      url: fca_nsm_url(string_field(record, "download_link")),
      summary: fca_nsm_summary(record),
      published_at:
        datetime_field(record, ["publication_date", "submitted_date", "document_date"]),
      category: string_field(record, "type")
    }
  end

  defp parse_fca_nsm_record(_record) do
    %{
      external_id: nil,
      title: nil,
      url: nil,
      summary: nil,
      published_at: DateTime.utc_now(),
      category: nil
    }
  end

  defp fca_nsm_title(nil, headline), do: headline
  defp fca_nsm_title(company, nil), do: company

  defp fca_nsm_title(company, headline) do
    if String.downcase(company) == String.downcase(headline) do
      headline
    else
      join_non_empty([company, headline], " - ")
    end
  end

  defp fca_nsm_url(nil), do: @fca_nsm_search_url
  defp fca_nsm_url("http" <> _rest = url), do: url
  defp fca_nsm_url("/" <> rest), do: @fca_nsm_artefacts_base_url <> rest
  defp fca_nsm_url(path), do: @fca_nsm_artefacts_base_url <> path

  defp fca_nsm_summary(record) do
    join_non_empty(
      [
        "FCA NSM regulated information",
        prefixed("Category", string_field(record, "type")),
        prefixed("Source", string_field(record, "source")),
        prefixed("LEI", string_field(record, "lei")),
        prefixed("ESEF", string_field(record, "tag_esef"))
      ],
      " | "
    )
  end

  defp parse_nasdaq_nordic_cns(raw_payload) do
    with {:ok, decoded} <- decode_json_or_jsonp(raw_payload),
         records when is_list(records) <- nasdaq_nordic_cns_records(decoded) do
      items =
        records
        |> Enum.map(&parse_nasdaq_nordic_cns_record/1)
        |> Enum.filter(&(&1.url && &1.title))

      {:ok, items}
    else
      {:error, error} -> {:error, {:invalid_jsonp, error}}
      _ -> {:error, {:invalid_json_shape, "nasdaq_nordic_cns_jsonp_v1"}}
    end
  end

  defp decode_json_or_jsonp(raw_payload) do
    raw_payload
    |> String.trim()
    |> case do
      "" ->
        {:error, :empty_payload}

      payload ->
        json =
          case Regex.run(~r/^\s*[A-Za-z_$][\w.$]*\((.*)\)\s*;?\s*$/s, payload) do
            [_, wrapped_json] -> wrapped_json
            _no_callback -> payload
          end

        Jason.decode(json)
    end
  end

  defp nasdaq_nordic_cns_records(%{"results" => %{"item" => records}})
       when is_list(records),
       do: records

  defp nasdaq_nordic_cns_records(%{"results" => %{"item" => record}})
       when is_map(record),
       do: [record]

  defp nasdaq_nordic_cns_records(_decoded), do: nil

  defp parse_nasdaq_nordic_cns_record(record) when is_map(record) do
    company = string_field(record, "company")
    headline = string_field(record, "headline")
    category = string_field(record, "cnsCategory")
    market = string_field(record, "market")
    language = string_field(record, "language")

    %{
      external_id: string_field(record, "disclosureId") || string_field(record, "messageUrl"),
      title: nasdaq_nordic_cns_title(company, headline),
      url: string_field(record, "messageUrl"),
      summary:
        join_non_empty(
          [
            "Nasdaq Nordic company news",
            prefixed("Category", category),
            prefixed("Market", market),
            prefixed("Language", language),
            prefixed("Attachments", nasdaq_nordic_attachment_count(record))
          ],
          " | "
        ),
      published_at:
        parse_nasdaq_nordic_cns_datetime(
          string_field(record, "published") || string_field(record, "releaseTime")
        ),
      category: category
    }
  end

  defp parse_nasdaq_nordic_cns_record(_record) do
    %{
      external_id: nil,
      title: nil,
      url: nil,
      summary: nil,
      published_at: DateTime.utc_now(),
      category: nil
    }
  end

  defp nasdaq_nordic_cns_title(company, headline)
       when is_binary(company) and is_binary(headline) do
    if String.contains?(String.downcase(headline), String.downcase(company)) do
      headline
    else
      join_non_empty([company, headline], " - ")
    end
  end

  defp nasdaq_nordic_cns_title(company, headline), do: join_non_empty([company, headline], " - ")

  defp nasdaq_nordic_attachment_count(%{"attachment" => attachments}) when is_list(attachments),
    do: Integer.to_string(length(attachments))

  defp nasdaq_nordic_attachment_count(_record), do: nil

  defp parse_nasdaq_nordic_cns_datetime(nil), do: DateTime.utc_now()

  defp parse_nasdaq_nordic_cns_datetime(value) do
    with [_, year_text, month_text, day_text, hour_text, minute_text, second_text] <-
           Regex.run(
             ~r/^(\d{4})-(\d{2})-(\d{2}) (\d{2}):(\d{2}):(\d{2})$/,
             value
           ),
         {year, ""} <- Integer.parse(year_text),
         {month, ""} <- Integer.parse(month_text),
         {day, ""} <- Integer.parse(day_text),
         {hour, ""} <- Integer.parse(hour_text),
         {minute, ""} <- Integer.parse(minute_text),
         {second, ""} <- Integer.parse(second_text),
         {:ok, datetime} <- build_utc_datetime(year, month, day, hour, minute, second) do
      datetime
    else
      _ -> DateTime.utc_now()
    end
  end

  defp parse_oslo_newsweb(raw_payload) do
    with {:ok, decoded} <- Jason.decode(raw_payload),
         records when is_list(records) <- oslo_newsweb_records(decoded) do
      items =
        records
        |> Enum.map(&parse_oslo_newsweb_record/1)
        |> Enum.filter(&(&1.url && &1.title))

      {:ok, items}
    else
      {:error, error} -> {:error, {:invalid_json, error}}
      _ -> {:error, {:invalid_json_shape, "oslo_newsweb_json_v1"}}
    end
  end

  defp oslo_newsweb_records(%{"data" => %{"messages" => records}}) when is_list(records),
    do: records

  defp oslo_newsweb_records(_decoded), do: nil

  defp parse_oslo_newsweb_record(record) when is_map(record) do
    issuer = string_field(record, "issuerName")
    title = string_field(record, "title")
    category = oslo_newsweb_category(record)
    markets = oslo_newsweb_markets(record)

    %{
      external_id:
        string_field(record, "clientAnnouncementId") || string_field(record, "messageId"),
      title: oslo_newsweb_title(issuer, title),
      url: oslo_newsweb_url(record),
      summary:
        join_non_empty(
          [
            "Oslo Bors NewsWeb issuer announcement",
            prefixed("Issuer", issuer),
            prefixed("Ticker", string_field(record, "issuerSign")),
            prefixed("Market", markets),
            prefixed("Category", category),
            prefixed("Attachments", string_field(record, "numbAttachments"))
          ],
          " | "
        ),
      published_at:
        parse_iso8601_datetime(string_field(record, "publishedTime")) || DateTime.utc_now(),
      category: category
    }
  end

  defp parse_oslo_newsweb_record(_record) do
    %{
      external_id: nil,
      title: nil,
      url: nil,
      summary: nil,
      published_at: DateTime.utc_now(),
      category: nil
    }
  end

  defp oslo_newsweb_title(issuer, title) when is_binary(issuer) and is_binary(title) do
    if String.contains?(String.downcase(title), String.downcase(issuer)) do
      title
    else
      join_non_empty([issuer, title], " - ")
    end
  end

  defp oslo_newsweb_title(issuer, title), do: join_non_empty([issuer, title], " - ")

  defp oslo_newsweb_url(record) do
    case string_field(record, "messageId") do
      nil -> nil
      message_id -> @oslo_newsweb_message_url <> message_id
    end
  end

  defp oslo_newsweb_category(%{"category" => [first | _rest]}) when is_map(first) do
    string_field(first, "category_en") || string_field(first, "category_no")
  end

  defp oslo_newsweb_category(%{"category" => first}) when is_map(first) do
    string_field(first, "category_en") || string_field(first, "category_no")
  end

  defp oslo_newsweb_category(_record), do: nil

  defp oslo_newsweb_markets(%{"markets" => markets}) when is_list(markets) do
    markets
    |> Enum.map(&to_string/1)
    |> Enum.map(&String.trim/1)
    |> Enum.reject(&(&1 == ""))
    |> Enum.join(", ")
    |> case do
      "" -> nil
      value -> value
    end
  end

  defp oslo_newsweb_markets(_record), do: nil

  defp parse_gpw_espi_ebi(raw_payload) do
    items =
      Regex.scan(
        ~r/<li[^>]*>\s*<span class="date">(.*?)<\/span>(.*?)<\/li>/s,
        raw_payload
      )
      |> Enum.map(&parse_gpw_espi_ebi_row/1)
      |> Enum.filter(&(&1.url && &1.title))

    {:ok, items}
  end

  defp parse_gpw_espi_ebi_row([_row, metadata_text, row_html]) do
    href =
      row_html
      |> regex_capture_raw(~r/<a\s+href="([^"]*espi-ebi-report\?geru_id=[^"]+)"/s)
      |> gpw_espi_ebi_url()

    company =
      regex_capture(
        row_html,
        ~r/<strong class="name">\s*<a[^>]*>\s*(.*?)\s*<\/a>\s*<\/strong>/s
      )

    report_title = regex_capture(row_html, ~r/<p[^>]*>\s*(.*?)\s*<\/p>/s)
    metadata = gpw_espi_ebi_metadata(metadata_text)

    %{
      external_id: gpw_espi_ebi_external_id(href),
      title: gpw_espi_ebi_title(company, report_title),
      url: href,
      summary: gpw_espi_ebi_summary(metadata),
      published_at: gpw_espi_ebi_datetime(metadata["published_at"]),
      category: gpw_espi_ebi_category(metadata)
    }
  end

  defp parse_gpw_espi_ebi_row(_row), do: empty_gpw_espi_ebi_record()

  defp empty_gpw_espi_ebi_record do
    %{
      external_id: nil,
      title: nil,
      url: nil,
      summary: nil,
      published_at: DateTime.utc_now(),
      category: nil
    }
  end

  defp gpw_espi_ebi_metadata(nil), do: %{}

  defp gpw_espi_ebi_metadata(value) do
    parts =
      value
      |> clean_html()
      |> case do
        nil -> []
        cleaned -> String.split(cleaned, "|", trim: true)
      end
      |> Enum.map(&String.trim/1)

    %{
      "published_at" => Enum.at(parts, 0),
      "status" => Enum.at(parts, 1),
      "system" => Enum.at(parts, 2),
      "report_number" => Enum.at(parts, 3)
    }
  end

  defp gpw_espi_ebi_title(nil, nil), do: nil
  defp gpw_espi_ebi_title(company, nil), do: company
  defp gpw_espi_ebi_title(nil, report_title), do: report_title
  defp gpw_espi_ebi_title(company, report_title), do: company <> " - " <> report_title

  defp gpw_espi_ebi_summary(metadata) do
    join_non_empty(
      [
        "GPW ESPI/EBI company report",
        prefixed("Status", metadata["status"]),
        prefixed("System", metadata["system"]),
        prefixed("Report", metadata["report_number"])
      ],
      " | "
    )
  end

  defp gpw_espi_ebi_category(metadata) do
    join_non_empty([metadata["system"], metadata["status"]], " ")
  end

  defp gpw_espi_ebi_external_id(nil), do: nil

  defp gpw_espi_ebi_external_id(url) do
    url
    |> decode_html_entities()
    |> URI.parse()
    |> Map.get(:query)
    |> case do
      query when is_binary(query) -> URI.decode_query(query)
      _query -> %{}
    end
    |> Map.get("geru_id")
  end

  defp gpw_espi_ebi_url(nil), do: nil

  defp gpw_espi_ebi_url(raw_url) do
    url = decode_html_entities(raw_url)

    cond do
      String.starts_with?(url, "http") ->
        url

      String.starts_with?(url, "/") ->
        String.trim_trailing(@gpw_espi_ebi_report_base_url, "/") <> url

      true ->
        @gpw_espi_ebi_report_base_url <> url
    end
  end

  defp gpw_espi_ebi_datetime(nil), do: DateTime.utc_now()

  defp gpw_espi_ebi_datetime(value) do
    with [_, day_text, month_text, year_text, hour_text, minute_text, second_text] <-
           Regex.run(~r/^(\d{2})-(\d{2})-(\d{4}) (\d{2}):(\d{2}):(\d{2})$/, value),
         {day, ""} <- Integer.parse(day_text),
         {month, ""} <- Integer.parse(month_text),
         {year, ""} <- Integer.parse(year_text),
         {hour, ""} <- Integer.parse(hour_text),
         {minute, ""} <- Integer.parse(minute_text),
         {second, ""} <- Integer.parse(second_text),
         {:ok, datetime} <- build_utc_datetime(year, month, day, hour, minute, second) do
      gpw_apply_warsaw_zone(datetime)
    else
      _ -> DateTime.utc_now()
    end
  end

  defp gpw_apply_warsaw_zone(%DateTime{month: month} = datetime) when month in 4..10,
    do: DateTime.add(datetime, -7_200, :second)

  defp gpw_apply_warsaw_zone(datetime), do: DateTime.add(datetime, -3_600, :second)

  defp parse_bse_issuers_news(raw_payload) do
    items =
      Regex.scan(
        ~r/<a href="([^"]*\/site\/newkib\/[^"]+)">(.*?)<\/a>/s,
        raw_payload
      )
      |> Enum.map(&parse_bse_issuers_news_row/1)
      |> Enum.filter(&(&1.url && &1.title))

    {:ok, items}
  end

  defp parse_bse_issuers_news_row([_row, href, row_html]) do
    issuer = regex_capture(row_html, ~r/<h2 class="issuer">\s*(.*?)\s*<\/h2>/s)
    title = regex_capture(row_html, ~r/<div class="title">\s*(.*?)\s*<\/div>/s)

    published_at_text =
      regex_capture(row_html, ~r/<span class="list-date list-attribute">\s*(.*?)\s*<\/span>/s)

    url = bse_issuers_news_url(href)

    %{
      external_id: bse_issuers_news_external_id(url),
      title: bse_issuers_news_title(issuer, title),
      url: url,
      summary:
        join_non_empty(
          [
            "Budapest Stock Exchange issuer news",
            prefixed("Issuer", issuer)
          ],
          " | "
        ),
      published_at: parse_bse_issuers_news_datetime(published_at_text),
      category: "Issuer news"
    }
  end

  defp parse_bse_issuers_news_row(_row), do: empty_bse_issuers_news_record()

  defp empty_bse_issuers_news_record do
    %{
      external_id: nil,
      title: nil,
      url: nil,
      summary: nil,
      published_at: DateTime.utc_now(),
      category: nil
    }
  end

  defp bse_issuers_news_title(nil, nil), do: nil
  defp bse_issuers_news_title(issuer, nil), do: issuer
  defp bse_issuers_news_title(nil, title), do: title

  defp bse_issuers_news_title(issuer, title) do
    normalized_title = String.downcase(title)
    normalized_issuer = String.downcase(issuer)

    if normalized_title == normalized_issuer or
         String.starts_with?(normalized_title, normalized_issuer <> " - ") do
      title
    else
      issuer <> " - " <> title
    end
  end

  defp bse_issuers_news_url(nil), do: nil

  defp bse_issuers_news_url(raw_url) do
    url = decode_html_entities(raw_url)

    cond do
      String.starts_with?(url, "http") -> url
      String.starts_with?(url, "/") -> "https://www.bse.hu" <> url
      true -> @bse_issuers_news_url
    end
  end

  defp bse_issuers_news_external_id(nil), do: nil

  defp bse_issuers_news_external_id(url) do
    url
    |> String.split("/")
    |> List.last()
    |> case do
      nil -> nil
      slug -> regex_capture(slug, ~r/_(\d+)$/) || slug
    end
  end

  defp parse_bse_issuers_news_datetime(nil), do: DateTime.utc_now()

  defp parse_bse_issuers_news_datetime(value) do
    with [_, day_text, month_text, year_text, hour_text, minute_text] <-
           Regex.run(~r/^(\d{2}) ([A-Za-z]+) (\d{4})\. (\d{2}):(\d{2})$/, value),
         {day, ""} <- Integer.parse(day_text),
         {:ok, month} <- xetra_month(month_text),
         {year, ""} <- Integer.parse(year_text),
         {hour, ""} <- Integer.parse(hour_text),
         {minute, ""} <- Integer.parse(minute_text),
         {:ok, datetime} <- build_utc_datetime(year, month, day, hour, minute, 0) do
      bse_apply_budapest_zone(datetime)
    else
      _ -> DateTime.utc_now()
    end
  end

  defp bse_apply_budapest_zone(%DateTime{month: month} = datetime) when month in 4..10,
    do: DateTime.add(datetime, -7_200, :second)

  defp bse_apply_budapest_zone(datetime), do: DateTime.add(datetime, -3_600, :second)

  defp parse_bvb_current_reports(raw_payload) do
    items =
      Regex.scan(~r/<tr[^>]*>(.*?)<\/tr>/s, raw_payload)
      |> Enum.map(&parse_bvb_current_report_row/1)
      |> Enum.filter(&(&1.url && &1.title))

    {:ok, items}
  end

  defp parse_bvb_current_report_row([_row, row_html]) do
    cells =
      Regex.scan(~r/<td[^>]*>(.*?)<\/td>/s, row_html)
      |> Enum.map(fn [_cell, value] -> value end)

    symbol = bvb_clean(Enum.at(cells, 6)) || bvb_symbol_from_visible_cell(Enum.at(cells, 0))
    isin = bvb_clean(Enum.at(cells, 7))
    company = bvb_clean(Enum.at(cells, 1))
    description = bvb_current_report_description(row_html, Enum.at(cells, 8), Enum.at(cells, 2))
    published_at_text = bvb_clean(Enum.at(cells, 3))
    category = bvb_clean(Enum.at(cells, 4))
    url = bvb_current_report_primary_url(row_html)

    %{
      external_id: bvb_current_report_external_id(url),
      title: bvb_current_report_title(company, description),
      url: url,
      summary:
        join_non_empty(
          [
            "Bucharest Stock Exchange current report",
            prefixed("Issuer", company),
            prefixed("Symbol", symbol),
            prefixed("ISIN", isin),
            prefixed("Document type", category)
          ],
          " | "
        ),
      published_at: parse_bvb_current_report_datetime(published_at_text),
      category: category
    }
  end

  defp parse_bvb_current_report_row(_row), do: empty_bvb_current_report_record()

  defp empty_bvb_current_report_record do
    %{
      external_id: nil,
      title: nil,
      url: nil,
      summary: nil,
      published_at: DateTime.utc_now(),
      category: nil
    }
  end

  defp bvb_clean(nil), do: nil
  defp bvb_clean(value), do: clean_html(value)

  defp bvb_symbol_from_visible_cell(nil), do: nil

  defp bvb_symbol_from_visible_cell(cell_html) do
    regex_capture(cell_html, ~r/<b>\s*(.*?)\s*<\/b>/s) || clean_html(cell_html)
  end

  defp bvb_current_report_description(row_html, hidden_description, visible_description) do
    row_html
    |> regex_capture_raw(~r/<input[^>]+value="([^"]+)"/s)
    |> decode_bvb_attr()
    |> case do
      nil -> bvb_clean(hidden_description) || bvb_clean(visible_description)
      value -> value
    end
  end

  defp decode_bvb_attr(nil), do: nil

  defp decode_bvb_attr(value) do
    value
    |> decode_html_entities()
    |> String.replace(~r/\s+/u, " ")
    |> String.trim()
    |> case do
      "" -> nil
      decoded -> decoded
    end
  end

  defp bvb_current_report_title(nil, nil), do: nil
  defp bvb_current_report_title(company, nil), do: company
  defp bvb_current_report_title(nil, description), do: description

  defp bvb_current_report_title(company, description) do
    if String.contains?(String.downcase(description), String.downcase(company)) do
      description
    else
      company <> " - " <> description
    end
  end

  defp bvb_current_report_primary_url(row_html) do
    row_html
    |> regex_capture_raw(
      ~r/(https:\/\/bvb\.ro\/FinancialInstruments\/SelectedData\/NewsItem\/[^<;\s]+)/s
    )
    |> case do
      nil ->
        row_html
        |> regex_capture_raw(
          ~r/href=['"]([^'"]*\/FinancialInstruments\/SelectedData\/NewsItem\/[^'"]+)['"]/s
        )
        |> bvb_current_report_url()

      url ->
        bvb_current_report_url(url)
    end
    |> case do
      nil ->
        row_html
        |> regex_capture_raw(~r/href=['"]([^'"]*(?:\/infocont\/|\/info\/Raportari\/)[^'"]+)['"]/s)
        |> bvb_current_report_url()

      url ->
        url
    end
  end

  defp bvb_current_report_url(nil), do: nil

  defp bvb_current_report_url(raw_url) do
    url = decode_html_entities(raw_url)

    cond do
      String.starts_with?(url, "http") -> url
      String.starts_with?(url, "/") -> "https://bvb.ro" <> url
      true -> @bvb_current_reports_url
    end
  end

  defp bvb_current_report_external_id(nil), do: nil

  defp bvb_current_report_external_id(url) do
    url
    |> URI.parse()
    |> Map.get(:path)
    |> case do
      nil -> nil
      path -> List.last(String.split(path, "/", trim: true))
    end
  end

  defp parse_bvb_current_report_datetime(nil), do: DateTime.utc_now()

  defp parse_bvb_current_report_datetime(value) do
    with [_, day_text, month_text, year_text, hour_text, minute_text] <-
           Regex.run(~r/^(\d{2})\.(\d{2})\.(\d{4}) (\d{2}):(\d{2})$/, value),
         {day, ""} <- Integer.parse(day_text),
         {month, ""} <- Integer.parse(month_text),
         {year, ""} <- Integer.parse(year_text),
         {hour, ""} <- Integer.parse(hour_text),
         {minute, ""} <- Integer.parse(minute_text),
         {:ok, datetime} <- build_utc_datetime(year, month, day, hour, minute, 0) do
      bvb_apply_bucharest_zone(datetime)
    else
      _ -> DateTime.utc_now()
    end
  end

  defp bvb_apply_bucharest_zone(%DateTime{month: month} = datetime) when month in 4..10,
    do: DateTime.add(datetime, -10_800, :second)

  defp bvb_apply_bucharest_zone(datetime), do: DateTime.add(datetime, -7_200, :second)

  defp parse_ceri_regulated_information(raw_payload) do
    items =
      Regex.scan(
        ~r/<tr class="(?:even|odd)">\s*<td rowspan="2"[^>]*>\s*<span class="ceridoc" id="img([^"]+)"[^>]*>.*?<\/span>\s*<\/td>\s*<td>(.*?)<\/td>\s*<td[^>]*title="([^"]*)"[^>]*>(.*?)<\/td>\s*<td[^>]*title="([^"]*)"[^>]*>(.*?)<\/td>\s*<td>(\d{2}\.\d{2}\.\d{4}\s+\d{2}:\d{2})<\/td>\s*<\/tr>\s*<tr class="(?:even|odd)">\s*<td colspan="4">\s*<span class="ceridoc" id="tit([^"]+)"[^>]*>(.*?)<\/span>\s*<\/td>\s*<\/tr>/s,
        raw_payload
      )
      |> Enum.map(&parse_ceri_regulated_information_row/1)
      |> Enum.filter(&(&1.url && &1.title))

    {:ok, items}
  end

  defp parse_ceri_regulated_information_row([
         _row,
         file_id,
         issuer,
         mark_title,
         mark,
         category_title,
         category,
         published_at_text,
         _title_file_id,
         document_title
       ]) do
    issuer = clean_html(issuer)
    document_title = clean_html(document_title)
    category = clean_html(category)
    regulated? = ceri_regulated_information?(mark_title, mark, category_title)
    url = ceri_document_url(file_id)

    %{
      external_id: ceri_document_id(file_id),
      title: ceri_title(issuer, document_title),
      url: url,
      summary:
        join_non_empty(
          [
            "Slovakia CERI regulated information",
            prefixed("Issuer", issuer),
            prefixed("Document type", category),
            if(regulated?, do: "Regulated information", else: nil)
          ],
          " | "
        ),
      published_at: parse_ceri_datetime(published_at_text),
      category: category
    }
  end

  defp parse_ceri_regulated_information_row(_row), do: empty_ceri_regulated_information_record()

  defp empty_ceri_regulated_information_record do
    %{
      external_id: nil,
      title: nil,
      url: nil,
      summary: nil,
      published_at: DateTime.utc_now(),
      category: nil
    }
  end

  defp ceri_regulated_information?(mark_title, mark, category_title) do
    [mark_title, mark, category_title]
    |> Enum.map(&(clean_html(&1) || ""))
    |> Enum.any?(fn value ->
      String.contains?(value, "Regulovan")
    end)
  end

  defp ceri_title(nil, nil), do: nil
  defp ceri_title(issuer, nil), do: issuer
  defp ceri_title(nil, document_title), do: document_title
  defp ceri_title(issuer, document_title), do: issuer <> " - " <> document_title

  defp ceri_document_id(nil), do: nil

  defp ceri_document_id(file_id) do
    file_id
    |> decode_html_entities()
    |> String.replace_prefix("img", "")
    |> String.replace_prefix("tit", "")
  end

  defp ceri_document_url(nil), do: nil

  defp ceri_document_url(file_id) do
    document_id = ceri_document_id(file_id)

    case document_id do
      nil ->
        nil

      <<prefix::binary-size(5), _rest::binary>> ->
        @ceri_document_base_url <> prefix <> "/" <> document_id

      _document_id ->
        @ceri_search_url
    end
  end

  defp parse_ceri_datetime(nil), do: DateTime.utc_now()

  defp parse_ceri_datetime(value) do
    with [_, day_text, month_text, year_text, hour_text, minute_text] <-
           Regex.run(~r/^(\d{2})\.(\d{2})\.(\d{4})\s+(\d{2}):(\d{2})$/, value),
         {day, ""} <- Integer.parse(day_text),
         {month, ""} <- Integer.parse(month_text),
         {year, ""} <- Integer.parse(year_text),
         {hour, ""} <- Integer.parse(hour_text),
         {minute, ""} <- Integer.parse(minute_text),
         {:ok, datetime} <- build_utc_datetime(year, month, day, hour, minute, 0) do
      ceri_apply_slovakia_zone(datetime)
    else
      _ -> DateTime.utc_now()
    end
  end

  defp ceri_apply_slovakia_zone(%DateTime{month: month} = datetime) when month in 4..10,
    do: DateTime.add(datetime, -7_200, :second)

  defp ceri_apply_slovakia_zone(datetime), do: DateTime.add(datetime, -3_600, :second)

  defp parse_ee_oam_market_announcements(raw_payload) do
    items =
      Regex.scan(
        ~r/<tr class="(?:even|odd)">\s*<td><span class="text-nowrap">(\d{2}\.\d{2}\.\d{4}\s+\d{2}:\d{2}:\d{2})<\/span><\/td>\s*<td>(.*?)<\/td>\s*<td>(.*?)<\/td>\s*<td>(.*?)<\/td>\s*<td>.*?<\/td>\s*<td><a href="([^"]*\/en\/borsiteated\/\d+)">View<\/a><\/td>\s*<\/tr>/s,
        raw_payload
      )
      |> Enum.map(&parse_ee_oam_market_announcement_row/1)
      |> Enum.filter(&(&1.url && &1.title))

    {:ok, items}
  end

  defp parse_ee_oam_market_announcement_row([
         _row,
         published_at_text,
         issuer,
         category,
         title,
         href
       ]) do
    issuer = clean_html(issuer)
    category = clean_html(category)
    title = clean_html(title)
    url = ee_oam_market_announcement_url(href)

    %{
      external_id: ee_oam_market_announcement_external_id(url),
      title: ee_oam_market_announcement_title(issuer, title),
      url: url,
      summary:
        join_non_empty(
          [
            "Estonia OAM market announcement",
            prefixed("Issuer", issuer),
            prefixed("Document type", category)
          ],
          " | "
        ),
      published_at: parse_ee_oam_datetime(published_at_text),
      category: category
    }
  end

  defp parse_ee_oam_market_announcement_row(_row), do: empty_ee_oam_market_announcement()

  defp empty_ee_oam_market_announcement do
    %{
      external_id: nil,
      title: nil,
      url: nil,
      summary: nil,
      published_at: DateTime.utc_now(),
      category: nil
    }
  end

  defp ee_oam_market_announcement_title(nil, nil), do: nil
  defp ee_oam_market_announcement_title(issuer, nil), do: issuer
  defp ee_oam_market_announcement_title(nil, title), do: title
  defp ee_oam_market_announcement_title(issuer, title), do: issuer <> " - " <> title

  defp ee_oam_market_announcement_url(nil), do: nil

  defp ee_oam_market_announcement_url(raw_url) do
    url = decode_html_entities(raw_url)

    cond do
      String.starts_with?(url, "http") -> url
      String.starts_with?(url, "/") -> @ee_oam_base_url <> url
      true -> @ee_oam_base_url <> "/" <> url
    end
  end

  defp ee_oam_market_announcement_external_id(nil), do: nil

  defp ee_oam_market_announcement_external_id(url) do
    url
    |> URI.parse()
    |> Map.get(:path)
    |> case do
      nil -> nil
      path -> List.last(String.split(path, "/", trim: true))
    end
  end

  defp parse_ee_oam_datetime(nil), do: DateTime.utc_now()

  defp parse_ee_oam_datetime(value) do
    with [_, day_text, month_text, year_text, hour_text, minute_text, second_text] <-
           Regex.run(~r/^(\d{2})\.(\d{2})\.(\d{4})\s+(\d{2}):(\d{2}):(\d{2})$/, value),
         {day, ""} <- Integer.parse(day_text),
         {month, ""} <- Integer.parse(month_text),
         {year, ""} <- Integer.parse(year_text),
         {hour, ""} <- Integer.parse(hour_text),
         {minute, ""} <- Integer.parse(minute_text),
         {second, ""} <- Integer.parse(second_text),
         {:ok, datetime} <- build_utc_datetime(year, month, day, hour, minute, second) do
      ee_oam_apply_estonia_zone(datetime)
    else
      _ -> DateTime.utc_now()
    end
  end

  defp ee_oam_apply_estonia_zone(%DateTime{month: month} = datetime) when month in 4..10,
    do: DateTime.add(datetime, -10_800, :second)

  defp ee_oam_apply_estonia_zone(datetime), do: DateTime.add(datetime, -7_200, :second)

  defp parse_wiener_borse_announcements(raw_payload) do
    items =
      Regex.scan(~r/<tr data-key="([^"]+)">(.*?)<\/tr>/s, raw_payload)
      |> Enum.map(&parse_wiener_borse_announcement_row/1)
      |> Enum.filter(&(&1.url && &1.title))

    {:ok, items}
  end

  defp parse_wiener_borse_announcement_row([_row, row_id, row_html]) do
    cells =
      Regex.scan(~r/<td[^>]*>(.*?)<\/td>/s, row_html)
      |> Enum.map(fn [_cell, value] -> clean_html(value) end)

    href =
      row_html
      |> regex_capture_raw(~r/href="([^"]+)"/)
      |> wiener_borse_url()

    case cells do
      [date_text, kind, company, security_type, category, market | _rest] ->
        company = reject_placeholder(company)

        %{
          external_id: row_id || href,
          title: wiener_borse_title(company, kind),
          url: href,
          summary:
            join_non_empty(
              [
                "Vienna Stock Exchange announcement",
                prefixed("Security", reject_placeholder(security_type)),
                prefixed("Category", reject_placeholder(category)),
                prefixed("Market", reject_placeholder(market))
              ],
              " | "
            ),
          published_at: parse_wiener_borse_date(date_text),
          category: kind
        }

      _cells ->
        empty_wiener_borse_announcement()
    end
  end

  defp parse_wiener_borse_announcement_row(_row), do: empty_wiener_borse_announcement()

  defp empty_wiener_borse_announcement do
    %{
      external_id: nil,
      title: nil,
      url: nil,
      summary: nil,
      published_at: DateTime.utc_now(),
      category: nil
    }
  end

  defp reject_placeholder(nil), do: nil
  defp reject_placeholder("-"), do: nil
  defp reject_placeholder(value), do: value

  defp wiener_borse_title(nil, _kind), do: nil
  defp wiener_borse_title(company, kind), do: join_non_empty([company, kind], " - ")

  defp wiener_borse_url(nil), do: nil

  defp wiener_borse_url(raw_url) do
    url = decode_html_entities(raw_url)

    cond do
      String.starts_with?(url, "http") -> url
      String.starts_with?(url, "/") -> "https://www.wienerborse.at" <> url
      true -> @wiener_borse_announcements_url
    end
  end

  defp parse_wiener_borse_date(nil), do: DateTime.utc_now()

  defp parse_wiener_borse_date(value) do
    with [_, first_text, second_text, year_text] <-
           Regex.run(~r/^(\d{2})\/(\d{2})\/(\d{4})$/, value),
         datetime <- parse_wiener_borse_date_parts(first_text, second_text, year_text),
         true <- not is_nil(datetime) do
      datetime
    else
      _ -> DateTime.utc_now()
    end
  end

  defp parse_wiener_borse_date_parts(first_text, second_text, year_text) do
    # The English page renders current dates as MM/DD/YYYY, but fall back to DD/MM
    # if the primary interpretation would land implausibly far in the future.
    parse_wiener_borse_mmdd(first_text, second_text, year_text) ||
      parse_wiener_borse_ddmm(first_text, second_text, year_text)
  end

  defp parse_wiener_borse_mmdd(month_text, day_text, year_text) do
    build_wiener_borse_date(year_text, month_text, day_text)
  end

  defp parse_wiener_borse_ddmm(day_text, month_text, year_text) do
    build_wiener_borse_date(year_text, month_text, day_text)
  end

  defp build_wiener_borse_date(year_text, month_text, day_text) do
    with {year, ""} <- Integer.parse(year_text),
         {month, ""} <- Integer.parse(month_text),
         {day, ""} <- Integer.parse(day_text),
         {:ok, datetime} <- build_utc_datetime(year, month, day, 0, 0, 0),
         true <-
           DateTime.compare(datetime, DateTime.add(DateTime.utc_now(), 86_400, :second)) != :gt do
      datetime
    else
      _ -> nil
    end
  end

  defp parse_xetra_newsboard(raw_payload) do
    items =
      Regex.scan(
        ~r/<a class="teasable-search-result-link[^"]*" href="([^"]+)">(.*?)<\/a>/s,
        raw_payload
      )
      |> Enum.map(&parse_xetra_newsboard_row/1)
      |> Enum.filter(&(&1.url && &1.title))

    {:ok, items}
  end

  defp parse_xetra_newsboard_row([_row, href, row_html]) do
    published_at_text =
      regex_capture(row_html, ~r/<p class="search-result-date">(.*?)<\/p>/s)

    venue =
      regex_capture(row_html, ~r/<h2 class="search-result-tagline">\s*(.*?)\s*<\/h2>/s)

    title =
      regex_capture(row_html, ~r/<h1 class="search-result-description[^"]*">\s*(.*?)\s*<\/h1>/s)

    if xetra_newsboard_company_notice?(title) do
      %{
        external_id: xetra_newsboard_external_id(href),
        title: title,
        url: xetra_newsboard_url(href),
        summary:
          join_non_empty(
            [
              "Xetra Frankfurt Newsboard announcement",
              prefixed("Venue", venue),
              prefixed("Notice type", xetra_newsboard_notice_type(title))
            ],
            " | "
          ),
        published_at: parse_xetra_newsboard_datetime(published_at_text),
        category: xetra_newsboard_notice_type(title)
      }
    else
      empty_xetra_newsboard_record()
    end
  end

  defp parse_xetra_newsboard_row(_row), do: empty_xetra_newsboard_record()

  defp empty_xetra_newsboard_record do
    %{
      external_id: nil,
      title: nil,
      url: nil,
      summary: nil,
      published_at: DateTime.utc_now(),
      category: nil
    }
  end

  defp xetra_newsboard_company_notice?(nil), do: false

  defp xetra_newsboard_company_notice?(title) do
    normalized = String.downcase(title)

    Enum.any?(
      [
        "dividend",
        "capital adjustment",
        "instrument_suspension",
        "new instrument",
        "deletion of instruments",
        "isin change",
        "aussetzung",
        "suspension",
        "wiederaufnahme",
        "resumption"
      ],
      &String.contains?(normalized, &1)
    ) and not String.contains?(normalized, "service is down")
  end

  defp xetra_newsboard_external_id(nil), do: nil

  defp xetra_newsboard_external_id(href) do
    href
    |> decode_html_entities()
    |> String.split("-")
    |> List.last()
  end

  defp xetra_newsboard_url(nil), do: nil

  defp xetra_newsboard_url(raw_url) do
    url = decode_html_entities(raw_url)

    cond do
      String.starts_with?(url, "http") -> url
      String.starts_with?(url, "/") -> "https://www.cashmarket.deutsche-boerse.com" <> url
      true -> @xetra_newsboard_url
    end
  end

  defp xetra_newsboard_notice_type(nil), do: nil

  defp xetra_newsboard_notice_type(title) do
    normalized = String.downcase(title)

    cond do
      String.contains?(normalized, "dividend") ->
        "Dividend"

      String.contains?(normalized, "capital adjustment") ->
        "Capital adjustment"

      String.contains?(normalized, "new instrument") ->
        "New instrument"

      String.contains?(normalized, "deletion of instruments") ->
        "Deletion of instruments"

      String.contains?(normalized, "isin change") ->
        "ISIN change"

      String.contains?(normalized, "wiederaufnahme") or String.contains?(normalized, "resumption") ->
        "Resumption"

      String.contains?(normalized, "aussetzung") or String.contains?(normalized, "suspension") ->
        "Suspension"

      true ->
        "Exchange notice"
    end
  end

  defp parse_xetra_newsboard_datetime(nil), do: DateTime.utc_now()

  defp parse_xetra_newsboard_datetime(value) do
    with [_, month_text, day_text, year_text, hour_text, minute_text, second_text, am_pm, zone] <-
           Regex.run(
             ~r/^([A-Za-z]+) (\d{2}), (\d{4}) (\d{2}):(\d{2}):(\d{2}) ([AP]M) (CEST|CET)$/,
             value
           ),
         {:ok, month} <- xetra_month(month_text),
         {day, ""} <- Integer.parse(day_text),
         {year, ""} <- Integer.parse(year_text),
         {hour_12, ""} <- Integer.parse(hour_text),
         {minute, ""} <- Integer.parse(minute_text),
         {second, ""} <- Integer.parse(second_text),
         hour <- xetra_24_hour(hour_12, am_pm),
         {:ok, datetime} <- build_utc_datetime(year, month, day, hour, minute, second) do
      xetra_apply_zone(datetime, zone)
    else
      _ -> DateTime.utc_now()
    end
  end

  defp xetra_month("January"), do: {:ok, 1}
  defp xetra_month("February"), do: {:ok, 2}
  defp xetra_month("March"), do: {:ok, 3}
  defp xetra_month("April"), do: {:ok, 4}
  defp xetra_month("May"), do: {:ok, 5}
  defp xetra_month("June"), do: {:ok, 6}
  defp xetra_month("July"), do: {:ok, 7}
  defp xetra_month("August"), do: {:ok, 8}
  defp xetra_month("September"), do: {:ok, 9}
  defp xetra_month("October"), do: {:ok, 10}
  defp xetra_month("November"), do: {:ok, 11}
  defp xetra_month("December"), do: {:ok, 12}
  defp xetra_month(_month), do: :error

  defp xetra_24_hour(12, "AM"), do: 0
  defp xetra_24_hour(12, "PM"), do: 12
  defp xetra_24_hour(hour, "PM"), do: hour + 12
  defp xetra_24_hour(hour, _am_pm), do: hour

  defp xetra_apply_zone(datetime, "CEST"), do: DateTime.add(datetime, -7_200, :second)
  defp xetra_apply_zone(datetime, "CET"), do: DateTime.add(datetime, -3_600, :second)
  defp xetra_apply_zone(datetime, _zone), do: datetime

  defp parse_afm_csv_row(row) do
    row
    |> String.trim()
    |> String.trim_leading("\"")
    |> String.trim_trailing("\"")
    |> String.split("\";\"")
    |> Enum.map(&String.replace(&1, "\"\"", "\""))
  end

  defp string_field(record, key) do
    record
    |> Map.get(key)
    |> case do
      value when is_binary(value) -> String.trim(value)
      value when is_integer(value) or is_float(value) -> to_string(value)
      _ -> nil
    end
    |> case do
      "" -> nil
      value -> value
    end
  end

  defp regex_capture(raw, regex) do
    case Regex.run(regex, raw, capture: :all_but_first) do
      [value | _rest] -> clean_html(value)
      _ -> nil
    end
  end

  defp regex_capture_raw(raw, regex) do
    case Regex.run(regex, raw, capture: :all_but_first) do
      [value | _rest] -> value
      _ -> nil
    end
  end

  defp clean_html(value) do
    value
    |> String.replace(~r/<[^>]+>/, " ")
    |> decode_html_entities()
    |> String.replace(~r/\s+/u, " ")
    |> String.trim()
    |> case do
      "" -> nil
      cleaned -> cleaned
    end
  end

  defp decode_html_entities(value) do
    decoded =
      value
      |> String.replace("&quot;", "\"")
      |> String.replace("&#039;", "'")
      |> String.replace("&apos;", "'")
      |> String.replace("&amp;", "&")
      |> String.replace("&nbsp;", " ")
      |> String.replace("&lt;", "<")
      |> String.replace("&gt;", ">")

    decoded
    |> then(&Regex.replace(~r/&#(\d+);/, &1, fn _match, code -> decode_decimal_entity(code) end))
    |> then(
      &Regex.replace(~r/&#x([0-9a-fA-F]+);/, &1, fn _match, code -> decode_hex_entity(code) end)
    )
  end

  defp decode_decimal_entity(code_text) do
    code_text
    |> Integer.parse()
    |> case do
      {code, ""} -> unicode_codepoint(code)
      _ -> ""
    end
  rescue
    _ -> ""
  end

  defp decode_hex_entity(code_text) do
    code_text
    |> Integer.parse(16)
    |> case do
      {code, ""} -> unicode_codepoint(code)
      _ -> ""
    end
  rescue
    _ -> ""
  end

  defp unicode_codepoint(code) when code in 0..0x10FFFF, do: <<code::utf8>>
  defp unicode_codepoint(_code), do: ""

  defp datetime_field(record, keys) do
    keys
    |> Enum.find_value(&parse_iso8601_datetime(string_field(record, &1)))
    |> case do
      nil -> DateTime.utc_now()
      datetime -> datetime
    end
  end

  defp parse_iso8601_datetime(nil), do: nil

  defp parse_iso8601_datetime(value) do
    case DateTime.from_iso8601(value) do
      {:ok, datetime, _offset} ->
        if DateTime.compare(datetime, DateTime.add(DateTime.utc_now(), 86_400, :second)) == :gt do
          nil
        else
          datetime
        end

      _ ->
        nil
    end
  end

  defp parse_afm_datetime(nil), do: DateTime.utc_now()

  defp parse_afm_datetime(value) do
    with [_, year_text, month_text, day_text, hour_text, minute_text, second_text] <-
           Regex.run(
             ~r/^(\d{4})-(\d{2})-(\d{2}) (\d{2}):(\d{2}):(\d{2})$/,
             value
           ),
         {year, ""} <- Integer.parse(year_text),
         {month, ""} <- Integer.parse(month_text),
         {day, ""} <- Integer.parse(day_text),
         {hour, ""} <- Integer.parse(hour_text),
         {minute, ""} <- Integer.parse(minute_text),
         {second, ""} <- Integer.parse(second_text),
         {:ok, datetime} <- build_utc_datetime(year, month, day, hour, minute, second) do
      datetime
    else
      _ -> DateTime.utc_now()
    end
  end

  defp parse_emarket_storage_datetime(nil), do: DateTime.utc_now()

  defp parse_emarket_storage_datetime(value) do
    with [_, day_text, month_text, year_text, hour_text, minute_text] <-
           Regex.run(~r/^(\d{2})\/(\d{2})\/(\d{4}) - (\d{2}):(\d{2})$/, value),
         {year, ""} <- Integer.parse(year_text),
         {month, ""} <- Integer.parse(month_text),
         {day, ""} <- Integer.parse(day_text),
         {hour, ""} <- Integer.parse(hour_text),
         {minute, ""} <- Integer.parse(minute_text),
         {:ok, datetime} <- build_utc_datetime(year, month, day, hour, minute, 0) do
      datetime
    else
      _ -> DateTime.utc_now()
    end
  end

  defp prefixed(_label, nil), do: nil
  defp prefixed(_label, ""), do: nil
  defp prefixed(label, value), do: "#{label}: #{value}"

  defp join_non_empty(values, separator) do
    values
    |> Enum.reject(&is_nil/1)
    |> Enum.map(&String.trim/1)
    |> Enum.reject(&(&1 == ""))
    |> Enum.join(separator)
    |> case do
      "" -> nil
      value -> value
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
    # xmerl expects encoded XML bytes so the XML declaration can drive UTF-8 decoding.
    |> :binary.bin_to_list()
  end

  defp parse_item(item) do
    link = xpath_string_any(item, [~c"string(link)", ~c"string(Link)"])

    %{
      external_id: xpath_string_any(item, [~c"string(guid)", ~c"string(Guid)"]) || link,
      title: xpath_string_any(item, [~c"string(title)", ~c"string(Title)"]),
      url: link,
      summary: xpath_string_any(item, [~c"string(description)", ~c"string(Description)"]),
      published_at: xpath_pub_date_any(item, [~c"string(pubDate)", ~c"string(PubDate)"]),
      category: xpath_string_any(item, [~c"string(category)", ~c"string(Category)"])
    }
  end

  defp xpath_string_any(node, queries) do
    Enum.find_value(queries, &xpath_string(node, &1))
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

  defp xpath_pub_date_any(node, queries) do
    Enum.find_value(queries, fn query ->
      case xpath_string(node, query) do
        nil -> nil
        pub_date -> parse_pub_date(pub_date)
      end
    end) || DateTime.utc_now()
  end

  defp parse_pub_date(pub_date) do
    case :httpd_util.convert_request_date(String.to_charlist(pub_date)) do
      {{year, month, day}, {hour, minute, second}} ->
        case build_utc_datetime(year, month, day, hour, minute, second) do
          {:ok, datetime} -> datetime
          :error -> nil
        end

      _ ->
        parse_iso8601_pub_date(pub_date) || parse_rfc1123_pub_date_without_zone(pub_date) ||
          parse_short_month_pub_date(pub_date)
    end
  end

  defp parse_iso8601_pub_date(pub_date) do
    case DateTime.from_iso8601(pub_date) do
      {:ok, datetime, _offset} -> datetime
      _ -> nil
    end
  end

  defp parse_rfc1123_pub_date_without_zone(pub_date) do
    with [_, _weekday, day_text, month_text, year_text, hour_text, minute_text, second_text] <-
           Regex.run(
             ~r/^(Mon|Tue|Wed|Thu|Fri|Sat|Sun),\s+(\d{1,2})\s+([A-Za-z]{3})\s+(\d{4})\s+(\d{2}):(\d{2}):(\d{2})\s*$/u,
             pub_date
           ),
         {day, ""} <- Integer.parse(day_text),
         {:ok, month} <- month_number(month_text),
         {year, ""} <- Integer.parse(year_text),
         {hour, ""} <- Integer.parse(hour_text),
         {minute, ""} <- Integer.parse(minute_text),
         {second, ""} <- Integer.parse(second_text),
         {:ok, datetime} <- build_utc_datetime(year, month, day, hour, minute, second) do
      datetime
    else
      _ -> nil
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

  @default_live_headers [{"user-agent", "disclosure-automation-phase1"}]

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

          raw_document_ids =
            persisted
            |> Enum.map(& &1.raw_document.id)
            |> Enum.uniq()

          canonical_item_keys =
            persisted
            |> Enum.map(& &1.canonical_item.story_key)
            |> Enum.uniq()

          unique_persisted =
            Enum.uniq_by(persisted, & &1.raw_document.id)

          latest_published_at =
            unique_persisted
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
            records_inserted: length(raw_document_ids),
            records_updated: max(length(records) - length(raw_document_ids), 0),
            records_rejected: 0
          })
          |> Repo.update!()

          {:ok, _source} = Sources.mark_poll_success(source, latest_published_at)

          %{
            source_key: source.source_key,
            edition: edition,
            fetch: payload.fetch_info,
            records_seen: length(records),
            records_inserted: length(raw_document_ids),
            raw_documents: raw_document_ids,
            canonical_items: canonical_item_keys
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
    with {:ok, response} <-
           Http.fetch(source.base_url,
             timeout: source_live_timeout(source),
             headers: source_live_headers(source),
             method: source_live_method(source),
             body: source_live_body(source),
             content_type: source_live_content_type(source)
           ),
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

  defp validate_live_payload(%SourceRegistry{parser_key: parser_key}, response)
       when parser_key in ["rss_v1", "euronext_company_pr_rss_v1"] do
    cond do
      html_content_type?(response.headers) ->
        {:error, {:unsupported_live_content_type, parser_key, content_type(response.headers)}}

      html_payload?(response.body) ->
        {:error, {:unsupported_live_payload, parser_key, :html}}

      true ->
        :ok
    end
  end

  defp validate_live_payload(%SourceRegistry{parser_key: "info_financiere_oam_v1"}, response) do
    cond do
      html_content_type?(response.headers) ->
        {:error,
         {:unsupported_live_content_type, "info_financiere_oam_v1",
          content_type(response.headers)}}

      html_payload?(response.body) ->
        {:error, {:unsupported_live_payload, "info_financiere_oam_v1", :html}}

      not json_content_type?(response.headers) ->
        {:error,
         {:unsupported_live_content_type, "info_financiere_oam_v1",
          content_type(response.headers)}}

      true ->
        :ok
    end
  end

  defp validate_live_payload(
         %SourceRegistry{parser_key: "afm_financial_reporting_csv_v1"},
         response
       ) do
    cond do
      html_content_type?(response.headers) ->
        {:error,
         {:unsupported_live_content_type, "afm_financial_reporting_csv_v1",
          content_type(response.headers)}}

      html_payload?(response.body) ->
        {:error, {:unsupported_live_payload, "afm_financial_reporting_csv_v1", :html}}

      not afm_reporting_csv_payload?(response.body) ->
        {:error, {:unsupported_live_payload, "afm_financial_reporting_csv_v1", :unexpected_csv}}

      true ->
        :ok
    end
  end

  defp validate_live_payload(%SourceRegistry{parser_key: "emarket_storage_html_v1"}, response) do
    cond do
      not html_content_type?(response.headers) ->
        {:error,
         {:unsupported_live_content_type, "emarket_storage_html_v1",
          content_type(response.headers)}}

      not emarket_storage_html_payload?(response.body) ->
        {:error, {:unsupported_live_payload, "emarket_storage_html_v1", :unexpected_html}}

      true ->
        :ok
    end
  end

  defp validate_live_payload(%SourceRegistry{parser_key: "luxse_oam_graphql_v1"}, response) do
    cond do
      html_content_type?(response.headers) ->
        {:error,
         {:unsupported_live_content_type, "luxse_oam_graphql_v1", content_type(response.headers)}}

      html_payload?(response.body) ->
        {:error, {:unsupported_live_payload, "luxse_oam_graphql_v1", :html}}

      not json_content_type?(response.headers) ->
        {:error,
         {:unsupported_live_content_type, "luxse_oam_graphql_v1", content_type(response.headers)}}

      not luxse_oam_graphql_payload?(response.body) ->
        {:error, {:unsupported_live_payload, "luxse_oam_graphql_v1", :unexpected_json}}

      true ->
        :ok
    end
  end

  defp validate_live_payload(%SourceRegistry{parser_key: "fsma_stori_api_v1"}, response) do
    cond do
      html_content_type?(response.headers) ->
        {:error,
         {:unsupported_live_content_type, "fsma_stori_api_v1", content_type(response.headers)}}

      html_payload?(response.body) ->
        {:error, {:unsupported_live_payload, "fsma_stori_api_v1", :html}}

      not json_content_type?(response.headers) ->
        {:error,
         {:unsupported_live_content_type, "fsma_stori_api_v1", content_type(response.headers)}}

      not fsma_stori_payload?(response.body) ->
        {:error, {:unsupported_live_payload, "fsma_stori_api_v1", :unexpected_json}}

      true ->
        :ok
    end
  end

  defp validate_live_payload(%SourceRegistry{parser_key: "fca_nsm_search_api_v1"}, response) do
    cond do
      html_content_type?(response.headers) ->
        {:error,
         {:unsupported_live_content_type, "fca_nsm_search_api_v1", content_type(response.headers)}}

      html_payload?(response.body) ->
        {:error, {:unsupported_live_payload, "fca_nsm_search_api_v1", :html}}

      not json_content_type?(response.headers) ->
        {:error,
         {:unsupported_live_content_type, "fca_nsm_search_api_v1", content_type(response.headers)}}

      not fca_nsm_search_payload?(response.body) ->
        {:error, {:unsupported_live_payload, "fca_nsm_search_api_v1", :unexpected_json}}

      true ->
        :ok
    end
  end

  defp validate_live_payload(%SourceRegistry{parser_key: "nasdaq_nordic_cns_jsonp_v1"}, response) do
    cond do
      html_content_type?(response.headers) ->
        {:error,
         {:unsupported_live_content_type, "nasdaq_nordic_cns_jsonp_v1",
          content_type(response.headers)}}

      html_payload?(response.body) ->
        {:error, {:unsupported_live_payload, "nasdaq_nordic_cns_jsonp_v1", :html}}

      not javascript_or_json_content_type?(response.headers) ->
        {:error,
         {:unsupported_live_content_type, "nasdaq_nordic_cns_jsonp_v1",
          content_type(response.headers)}}

      not nasdaq_nordic_cns_payload?(response.body) ->
        {:error, {:unsupported_live_payload, "nasdaq_nordic_cns_jsonp_v1", :unexpected_jsonp}}

      true ->
        :ok
    end
  end

  defp validate_live_payload(%SourceRegistry{parser_key: "oslo_newsweb_json_v1"}, response) do
    cond do
      html_content_type?(response.headers) ->
        {:error,
         {:unsupported_live_content_type, "oslo_newsweb_json_v1", content_type(response.headers)}}

      html_payload?(response.body) ->
        {:error, {:unsupported_live_payload, "oslo_newsweb_json_v1", :html}}

      not json_content_type?(response.headers) ->
        {:error,
         {:unsupported_live_content_type, "oslo_newsweb_json_v1", content_type(response.headers)}}

      not oslo_newsweb_payload?(response.body) ->
        {:error, {:unsupported_live_payload, "oslo_newsweb_json_v1", :unexpected_json}}

      true ->
        :ok
    end
  end

  defp validate_live_payload(%SourceRegistry{parser_key: "gpw_espi_ebi_html_v1"}, response) do
    cond do
      not html_content_type?(response.headers) ->
        {:error,
         {:unsupported_live_content_type, "gpw_espi_ebi_html_v1", content_type(response.headers)}}

      not gpw_espi_ebi_payload?(response.body) ->
        {:error, {:unsupported_live_payload, "gpw_espi_ebi_html_v1", :unexpected_html}}

      true ->
        :ok
    end
  end

  defp validate_live_payload(%SourceRegistry{parser_key: "bse_issuers_news_html_v1"}, response) do
    cond do
      not html_content_type?(response.headers) ->
        {:error,
         {:unsupported_live_content_type, "bse_issuers_news_html_v1",
          content_type(response.headers)}}

      not bse_issuers_news_payload?(response.body) ->
        {:error, {:unsupported_live_payload, "bse_issuers_news_html_v1", :unexpected_html}}

      true ->
        :ok
    end
  end

  defp validate_live_payload(%SourceRegistry{parser_key: "bvb_current_reports_html_v1"}, response) do
    cond do
      not html_content_type?(response.headers) ->
        {:error,
         {:unsupported_live_content_type, "bvb_current_reports_html_v1",
          content_type(response.headers)}}

      not bvb_current_reports_payload?(response.body) ->
        {:error, {:unsupported_live_payload, "bvb_current_reports_html_v1", :unexpected_html}}

      true ->
        :ok
    end
  end

  defp validate_live_payload(
         %SourceRegistry{parser_key: "ceri_regulated_information_html_v1"},
         response
       ) do
    cond do
      not html_content_type?(response.headers) ->
        {:error,
         {:unsupported_live_content_type, "ceri_regulated_information_html_v1",
          content_type(response.headers)}}

      not ceri_regulated_information_payload?(response.body) ->
        {:error,
         {:unsupported_live_payload, "ceri_regulated_information_html_v1", :unexpected_html}}

      true ->
        :ok
    end
  end

  defp validate_live_payload(
         %SourceRegistry{parser_key: "ee_oam_market_announcements_html_v1"},
         response
       ) do
    cond do
      not html_content_type?(response.headers) ->
        {:error,
         {:unsupported_live_content_type, "ee_oam_market_announcements_html_v1",
          content_type(response.headers)}}

      not ee_oam_market_announcements_payload?(response.body) ->
        {:error,
         {:unsupported_live_payload, "ee_oam_market_announcements_html_v1", :unexpected_html}}

      true ->
        :ok
    end
  end

  defp validate_live_payload(
         %SourceRegistry{parser_key: "wiener_borse_announcements_html_v1"},
         response
       ) do
    cond do
      not html_content_type?(response.headers) ->
        {:error,
         {:unsupported_live_content_type, "wiener_borse_announcements_html_v1",
          content_type(response.headers)}}

      not wiener_borse_announcements_payload?(response.body) ->
        {:error,
         {:unsupported_live_payload, "wiener_borse_announcements_html_v1", :unexpected_html}}

      true ->
        :ok
    end
  end

  defp validate_live_payload(%SourceRegistry{parser_key: "xetra_newsboard_html_v1"}, response) do
    cond do
      not html_content_type?(response.headers) ->
        {:error,
         {:unsupported_live_content_type, "xetra_newsboard_html_v1",
          content_type(response.headers)}}

      not xetra_newsboard_payload?(response.body) ->
        {:error, {:unsupported_live_payload, "xetra_newsboard_html_v1", :unexpected_html}}

      true ->
        :ok
    end
  end

  defp validate_live_payload(_source, _response), do: :ok

  defp source_live_headers(%SourceRegistry{config: config}) when is_map(config) do
    config
    |> source_config_headers()
    |> Enum.reduce(@default_live_headers, fn {key, value}, headers ->
      header_key = String.downcase(to_string(key))

      existing =
        Enum.reject(headers, fn {existing_key, _existing_value} ->
          String.downcase(to_string(existing_key)) == header_key
        end)

      existing ++ [{to_string(key), to_string(value)}]
    end)
    |> Enum.map(fn {key, value} -> {String.to_charlist(key), String.to_charlist(value)} end)
  end

  defp source_live_headers(_source) do
    Enum.map(@default_live_headers, fn {key, value} ->
      {String.to_charlist(key), String.to_charlist(value)}
    end)
  end

  defp source_config_headers(config) do
    case Map.get(config, "live_headers") || Map.get(config, :live_headers) do
      headers when is_map(headers) -> headers
      _ -> %{}
    end
  end

  defp source_live_method(%SourceRegistry{config: config}) when is_map(config) do
    config
    |> Map.get("live_method", Map.get(config, :live_method))
    |> case do
      method when is_binary(method) -> method
      _method -> "get"
    end
  end

  defp source_live_method(_source), do: "get"

  defp source_live_body(%SourceRegistry{config: config}) when is_map(config) do
    case Map.get(config, "live_body") || Map.get(config, :live_body) do
      body when is_binary(body) -> body
      body when is_map(body) -> Jason.encode!(body)
      _body -> ""
    end
  end

  defp source_live_body(_source), do: ""

  defp source_live_content_type(%SourceRegistry{config: config}) when is_map(config) do
    config
    |> Map.get("live_content_type", Map.get(config, :live_content_type))
    |> case do
      content_type when is_binary(content_type) -> content_type
      _content_type -> "application/json"
    end
  end

  defp source_live_content_type(_source), do: "application/json"

  defp source_live_timeout(%SourceRegistry{config: config}) when is_map(config) do
    config
    |> Map.get("live_timeout_ms", Map.get(config, :live_timeout_ms))
    |> positive_live_timeout()
  end

  defp source_live_timeout(_source), do: 8_000

  defp positive_live_timeout(value) when is_integer(value) and value > 0, do: value

  defp positive_live_timeout(value) when is_binary(value) do
    case Integer.parse(value) do
      {parsed, ""} when parsed > 0 -> parsed
      _ -> 8_000
    end
  end

  defp positive_live_timeout(_value), do: 8_000

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

  defp json_content_type?(headers) do
    headers
    |> content_type()
    |> String.downcase()
    |> String.contains?("json")
  end

  defp javascript_or_json_content_type?(headers) do
    content_type = headers |> content_type() |> String.downcase()

    String.contains?(content_type, "javascript") or String.contains?(content_type, "json")
  end

  defp html_payload?(body) when is_binary(body) do
    body
    |> String.trim_leading()
    |> String.downcase()
    |> then(&(String.starts_with?(&1, "<!doctype html") or String.starts_with?(&1, "<html")))
  end

  defp html_payload?(_body), do: false

  defp afm_reporting_csv_payload?(body) when is_binary(body) do
    body
    |> String.trim_leading()
    |> String.starts_with?("\"Datum deponering\";\"Uitgevende instelling\"")
  end

  defp afm_reporting_csv_payload?(_body), do: false

  defp emarket_storage_html_payload?(body) when is_binary(body) do
    body =~ "Comunicati Regolamentati" and
      body =~ "azienda-wrapper" and
      body =~ "/sites/default/files/comunicati/"
  end

  defp emarket_storage_html_payload?(_body), do: false

  defp luxse_oam_graphql_payload?(body) when is_binary(body) do
    body =~ "\"oamSubmissionsSearch\"" and body =~ "\"submissions\""
  end

  defp luxse_oam_graphql_payload?(_body), do: false

  defp fsma_stori_payload?(body) when is_binary(body) do
    body =~ "\"storiResultItems\"" and body =~ "\"resultCount\""
  end

  defp fsma_stori_payload?(_body), do: false

  defp fca_nsm_search_payload?(body) when is_binary(body) do
    body =~ "\"hits\"" and body =~ "\"_source\"" and body =~ "\"download_link\""
  end

  defp fca_nsm_search_payload?(_body), do: false

  defp nasdaq_nordic_cns_payload?(body) when is_binary(body) do
    body =~ "handleResponse(" and body =~ "\"results\"" and body =~ "\"item\""
  end

  defp nasdaq_nordic_cns_payload?(_body), do: false

  defp oslo_newsweb_payload?(body) when is_binary(body) do
    body =~ "\"messages\"" and body =~ "\"messageId\"" and body =~ "\"publishedTime\"" and
      body =~ "\"issuerName\""
  end

  defp oslo_newsweb_payload?(_body), do: false

  defp gpw_espi_ebi_payload?(body) when is_binary(body) do
    body =~ "ESPI/EBI Company reports" and body =~ "espi-union-reports" and
      body =~ "espi-ebi-report?geru_id="
  end

  defp gpw_espi_ebi_payload?(_body), do: false

  defp bse_issuers_news_payload?(body) when is_binary(body) do
    body =~ "Issuers News" and body =~ "bet-newkib-list" and
      body =~ "/site/newkib/"
  end

  defp bse_issuers_news_payload?(_body), do: false

  defp bvb_current_reports_payload?(body) when is_binary(body) do
    body =~ "BVB - Rapoarte si informari" and
      body =~ "CurrentReports" and
      body =~ "FinancialInstruments/SelectedData/NewsItem"
  end

  defp bvb_current_reports_payload?(_body), do: false

  defp ceri_regulated_information_payload?(body) when is_binary(body) do
    body =~ "Centr" and
      body =~ "evidencia regulovan" and
      body =~ "Aktu" and
      body =~ "class=\"ceridoc\"" and
      body =~ "prijatia"
  end

  defp ceri_regulated_information_payload?(_body), do: false

  defp ee_oam_market_announcements_payload?(body) when is_binary(body) do
    body =~ "Market announcements" and
      body =~ "/en/borsiteated/" and
      body =~ "text-nowrap" and
      body =~ "Category"
  end

  defp ee_oam_market_announcements_payload?(_body), do: false

  defp wiener_borse_announcements_payload?(body) when is_binary(body) do
    body =~ "Announcements Found" and body =~ "filter-announcements" and
      body =~ "kv-grid-table" and body =~ "<tr data-key="
  end

  defp wiener_borse_announcements_payload?(_body), do: false

  defp xetra_newsboard_payload?(body) when is_binary(body) do
    body =~ "Xetra-Frankfurt-Newsboard" and body =~ "teasable-search-result-link" and
      body =~ "search-result-description"
  end

  defp xetra_newsboard_payload?(_body), do: false

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
