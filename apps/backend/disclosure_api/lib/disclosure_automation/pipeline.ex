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
      "tr" in tags or "turkey" in tags -> ["tr"]
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
  @lt_oam_base_url "https://www.oam.lt"
  @lv_csri_base_url "https://csri.investinfo.lv"
  @cmvm_portal_url "https://www.cmvm.pt/PInstitucional/PortalInstitucional?Input_language=en-US"
  @oekb_oam_detail_base_url "https://my.oekb.at/kapitalmarkt-services/kms-output/oamn/iic/detail?doc-id="
  @oekb_oam_download_base_url "https://my.oekb.at/issuer-info/rest/public/meldedaten/download/"
  @oekb_oam_list_url "https://my.oekb.at/kapitalmarkt-services/kms-output/oamn/iic/list"
  @pse_news_base_url "https://www.pse.cz/en/news/"
  @pse_detail_base_url "https://www.pse.cz/en/detail/"
  @de_company_register_publication_url "https://www.unternehmensregister.de/en/publication?payload="
  @de_company_register_strategy "germany_company_register_token_preflight_v1"
  @malta_mse_base_url "https://www.borzamalta.com.mt"
  @x3news_base_url "https://www.x3news.com/"
  @kap_base_url "https://www.kap.org.tr"
  @cse_oam_base_url "https://publicoam.cse.com.cy"
  @mse_base_url "https://www.mse.mk"
  @seinet_document_base_url "https://www.seinet.com.mk/en/document/"
  @mnse_base_url "https://www.mnse.me"
  @md_msi_base_url "https://emitent-msi.market.md"
  @dfsa_oam_module_id "9217fa13-5d9a-46c6-9921-69ee7e6cfaf6"
  @dfsa_oam_details_base_url "https://appft.gold.extension.gopublic.dk/api/#{@dfsa_oam_module_id}/details/"
  @belex_base_url "https://www.belex.rs"
  @blse_strategy "blse_multi_issuer_news_rss_v1"
  @sase_strategy "sase_multi_issuer_announcements_xml_v1"
  @sase_profile_base_url "https://www.sase.ba/v1/en-us/Market/Issuers-Securities/Issuer-profile/symbol/"
  @set_thailand_base_url "https://www.set.or.th"
  @tw_mops_material_info_base_url "https://mops.twse.com.tw/mops"

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

  defp parse_by_key("cmvm_portal_info_privi_json_v1", raw_payload),
    do: parse_cmvm_portal_info_privi(raw_payload)

  defp parse_by_key("oekb_oam_issuer_info_json_v1", raw_payload),
    do: parse_oekb_oam_issuer_info(raw_payload)

  defp parse_by_key("cse_oam_listing_versions_json_v1", raw_payload),
    do: parse_cse_oam_listing_versions(raw_payload)

  defp parse_by_key("blse_multi_issuer_news_rss_v1", raw_payload),
    do: parse_blse_multi_issuer_news(raw_payload)

  defp parse_by_key("pse_multi_isin_issuer_news_json_v1", raw_payload),
    do: parse_pse_multi_isin_issuer_news(raw_payload)

  defp parse_by_key("pse_multi_isin_issuer_report_calendar_json_v1", raw_payload),
    do: parse_pse_multi_isin_issuer_report_calendar(raw_payload)

  defp parse_by_key("germany_company_register_capital_market_flight_v1", raw_payload),
    do: parse_de_company_register_capital_market(raw_payload)

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

  defp parse_by_key("lt_oam_regulated_information_html_v1", raw_payload),
    do: parse_lt_oam_regulated_information(raw_payload)

  defp parse_by_key("lv_csri_regulated_information_html_v1", raw_payload),
    do: parse_lv_csri_regulated_information(raw_payload)

  defp parse_by_key("wiener_borse_announcements_html_v1", raw_payload),
    do: parse_wiener_borse_announcements(raw_payload)

  defp parse_by_key("xetra_newsboard_html_v1", raw_payload),
    do: parse_xetra_newsboard(raw_payload)

  defp parse_by_key("malta_mse_announcements_html_v1", raw_payload),
    do: parse_malta_mse_announcements(raw_payload)

  defp parse_by_key("bg_x3news_issuer_disclosures_html_v1", raw_payload),
    do: parse_x3news_issuer_disclosures(raw_payload)

  defp parse_by_key("kap_company_notifications_html_v1", raw_payload),
    do: parse_kap_company_notifications(raw_payload)

  defp parse_by_key("mse_free_market_announcements_html_v1", raw_payload),
    do: parse_mse_free_market_announcements(raw_payload)

  defp parse_by_key("seinet_public_documents_json_v1", raw_payload),
    do: parse_seinet_public_documents(raw_payload)

  defp parse_by_key("mnse_corporate_news_html_v1", raw_payload),
    do: parse_mnse_corporate_news(raw_payload)

  defp parse_by_key("md_msi_regulated_information_html_v1", raw_payload),
    do: parse_md_msi_regulated_information(raw_payload)

  defp parse_by_key("dfsa_oam_company_announcements_json_v1", raw_payload),
    do: parse_dfsa_oam_company_announcements(raw_payload)

  defp parse_by_key("set_thailand_company_news_json_v1", raw_payload),
    do: parse_set_thailand_company_news(raw_payload)

  defp parse_by_key("tw_mops_daily_material_info_json_v1", raw_payload),
    do: parse_tw_mops_daily_material_info(raw_payload)

  defp parse_by_key("belex_issuer_news_html_v1", raw_payload),
    do: parse_belex_issuer_news(raw_payload)

  defp parse_by_key("sase_multi_issuer_announcements_xml_v1", raw_payload),
    do: parse_sase_multi_issuer_announcements(raw_payload)

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

  defp parse_cmvm_portal_info_privi(raw_payload) do
    with {:ok, decoded} <- Jason.decode(raw_payload),
         records when is_list(records) <- cmvm_portal_info_privi_records(decoded) do
      items =
        records
        |> Enum.map(&parse_cmvm_portal_info_privi_record/1)
        |> Enum.filter(&(&1.url && &1.title))

      {:ok, items}
    else
      {:error, error} -> {:error, {:invalid_json, error}}
      _ -> {:error, {:invalid_json_shape, "cmvm_portal_info_privi_json_v1"}}
    end
  end

  defp cmvm_portal_info_privi_records(%{
         "data" => %{"InfoPrivi" => %{"List" => records}}
       })
       when is_list(records),
       do: records

  defp cmvm_portal_info_privi_records(_decoded), do: nil

  defp parse_cmvm_portal_info_privi_record(record) when is_map(record) do
    description = string_field(record, "Desc")
    {issuer, headline} = cmvm_portal_info_privi_description_parts(description)
    id = string_field(record, "Id")
    table = string_field(record, "Table")

    %{
      external_id: join_non_empty(["cmvm", table, id], ":"),
      title: cmvm_portal_info_privi_title(issuer, headline, description),
      url: cmvm_portal_info_privi_url(id, table),
      summary: cmvm_portal_info_privi_summary(record, issuer, headline),
      published_at: cmvm_portal_info_privi_datetime(record),
      category: string_field(record, "Tipo")
    }
  end

  defp parse_cmvm_portal_info_privi_record(_record) do
    %{
      external_id: nil,
      title: nil,
      url: nil,
      summary: nil,
      published_at: DateTime.utc_now(),
      category: nil
    }
  end

  defp cmvm_portal_info_privi_description_parts(nil), do: {nil, nil}

  defp cmvm_portal_info_privi_description_parts(description) do
    case Regex.run(~r/^(.+?)\s+informs on:\s+(.+)$/iu, description, capture: :all_but_first) do
      [issuer, headline] -> {String.trim(issuer), String.trim(headline)}
      _ -> {nil, description}
    end
  end

  defp cmvm_portal_info_privi_title(nil, nil, fallback), do: fallback
  defp cmvm_portal_info_privi_title(nil, headline, _fallback), do: headline
  defp cmvm_portal_info_privi_title(issuer, nil, _fallback), do: issuer
  defp cmvm_portal_info_privi_title(issuer, headline, _fallback), do: issuer <> " - " <> headline

  defp cmvm_portal_info_privi_url(nil, _table), do: @cmvm_portal_url

  defp cmvm_portal_info_privi_url(id, table) do
    fragment =
      ["cmvm-info-privi", table, id]
      |> Enum.reject(&is_nil/1)
      |> Enum.join("-")
      |> String.downcase()
      |> String.replace(~r/[^a-z0-9_-]+/, "-")
      |> String.trim("-")

    @cmvm_portal_url <> "#" <> fragment
  end

  defp cmvm_portal_info_privi_summary(record, issuer, headline) do
    join_non_empty(
      [
        "CMVM inside information and other issuer information",
        prefixed("Issuer", issuer),
        prefixed("Disclosure", headline),
        prefixed("Category", string_field(record, "Tipo")),
        prefixed("Record table", string_field(record, "Table"))
      ],
      " | "
    )
  end

  defp cmvm_portal_info_privi_datetime(record) do
    date = string_field(record, "Date")
    time = string_field(record, "Time") || "00:00:00"

    with value when is_binary(value) <- date,
         [_, year_text, month_text, day_text, hour_text, minute_text, second_text] <-
           Regex.run(
             ~r/^(\d{4})-(\d{2})-(\d{2})\s+(\d{2}):(\d{2}):(\d{2})$/,
             value <> " " <> time
           ),
         {year, ""} <- Integer.parse(year_text),
         {month, ""} <- Integer.parse(month_text),
         {day, ""} <- Integer.parse(day_text),
         {hour, ""} <- Integer.parse(hour_text),
         {minute, ""} <- Integer.parse(minute_text),
         {second, ""} <- Integer.parse(second_text),
         {:ok, datetime} <- build_utc_datetime(year, month, day, hour, minute, second) do
      cmvm_apply_lisbon_zone(datetime)
    else
      _ -> DateTime.utc_now()
    end
  end

  defp cmvm_apply_lisbon_zone(%DateTime{month: month} = datetime) when month in 4..10,
    do: DateTime.add(datetime, -3_600, :second)

  defp cmvm_apply_lisbon_zone(datetime), do: datetime

  defp parse_oekb_oam_issuer_info(raw_payload) do
    with {:ok, decoded} <- Jason.decode(raw_payload),
         records when is_list(records) <- oekb_oam_issuer_info_records(decoded) do
      items =
        records
        |> Enum.map(&parse_oekb_oam_issuer_info_record/1)
        |> Enum.filter(&(&1.url && &1.title))

      {:ok, items}
    else
      {:error, error} -> {:error, {:invalid_json, error}}
      _ -> {:error, {:invalid_json_shape, "oekb_oam_issuer_info_json_v1"}}
    end
  end

  defp oekb_oam_issuer_info_records(%{"dokumente" => records}) when is_list(records),
    do: records

  defp oekb_oam_issuer_info_records(_decoded), do: nil

  defp parse_oekb_oam_issuer_info_record(record) when is_map(record) do
    issuer = record |> Map.get("emittent", %{}) |> string_field("name")
    title = string_field(record, "titel")
    file_id = oekb_oam_first_file_id(record)

    %{
      external_id: join_non_empty(["oekb", string_field(record, "id") || file_id], ":"),
      title: oekb_oam_title(issuer, title),
      url: oekb_oam_url(string_field(record, "id"), file_id),
      summary: oekb_oam_summary(record, issuer),
      published_at: oekb_oam_datetime(record),
      category: string_field(record, "meldetypCode")
    }
  end

  defp parse_oekb_oam_issuer_info_record(_record) do
    %{
      external_id: nil,
      title: nil,
      url: nil,
      summary: nil,
      published_at: DateTime.utc_now(),
      category: nil
    }
  end

  defp oekb_oam_title(nil, title), do: title
  defp oekb_oam_title(issuer, nil), do: issuer

  defp oekb_oam_title(issuer, title) do
    if String.contains?(String.downcase(title), String.downcase(issuer)) do
      title
    else
      join_non_empty([issuer, title], " - ")
    end
  end

  defp oekb_oam_url(nil, nil), do: @oekb_oam_list_url

  defp oekb_oam_url(_record_id, file_id) when is_binary(file_id),
    do: @oekb_oam_download_base_url <> file_id

  defp oekb_oam_url(record_id, nil), do: @oekb_oam_detail_base_url <> record_id

  defp oekb_oam_summary(record, issuer) do
    files =
      record
      |> Map.get("dateien", [])
      |> Enum.map(&string_field(&1, "dateiname"))
      |> Enum.reject(&is_nil/1)
      |> Enum.take(3)
      |> Enum.join(", ")

    isin_values =
      record
      |> Map.get("isinBezug", [])
      |> oekb_oam_string_list()
      |> Enum.take(3)
      |> Enum.join(", ")

    join_non_empty(
      [
        "OeKB OAM Issuer Info regulated information",
        prefixed("Issuer", issuer),
        prefixed("Type", string_field(record, "meldetypCode")),
        prefixed("Obligation", string_field(record, "meldeTypType")),
        prefixed("Language", string_field(record, "sprachcode")),
        prefixed("ISIN", isin_values),
        prefixed("Files", files)
      ],
      " | "
    )
  end

  defp oekb_oam_first_file_id(%{"dateien" => files}) when is_list(files) do
    Enum.find_value(files, &string_field(&1, "id"))
  end

  defp oekb_oam_first_file_id(_record), do: nil

  defp oekb_oam_string_list(values) when is_list(values) do
    values
    |> Enum.map(fn
      value when is_binary(value) ->
        value
        |> String.trim()
        |> case do
          "" -> nil
          cleaned -> cleaned
        end

      _value ->
        nil
    end)
    |> Enum.reject(&is_nil/1)
  end

  defp oekb_oam_string_list(_values), do: []

  defp parse_cse_oam_listing_versions(raw_payload) do
    with {:ok, decoded} <- Jason.decode(raw_payload),
         records when is_list(records) <- cse_oam_listing_version_records(decoded) do
      items =
        records
        |> Enum.filter(&cse_oam_listed_record?/1)
        |> Enum.map(&parse_cse_oam_listing_version_record/1)
        |> Enum.filter(&(&1.url && &1.title && &1.published_at))

      {:ok, items}
    else
      {:error, error} -> {:error, {:invalid_json, error}}
      _ -> {:error, {:invalid_json_shape, "cse_oam_listing_versions_json_v1"}}
    end
  end

  defp cse_oam_listing_version_records(%{"content" => records}) when is_list(records),
    do: records

  defp cse_oam_listing_version_records(_decoded), do: nil

  defp cse_oam_listed_record?(record) when is_map(record) do
    Map.get(record, "isListed") == true or Map.get(record, "listed") == true or
      Map.get(record, "listedComplete") == true
  end

  defp cse_oam_listed_record?(_record), do: false

  defp parse_cse_oam_listing_version_record(record) when is_map(record) do
    issuer = string_field(record, "listedCompanyEnglish") || string_field(record, "companyNameEn")
    headline = string_field(record, "nameEnglish") || string_field(record, "name")
    category = string_field(record, "infoCategoriesNameEnglish")

    %{
      external_id: join_non_empty(["cse-oam", string_field(record, "id")], ":"),
      title: join_non_empty([issuer, headline], " - "),
      url: cse_oam_listing_version_url(record),
      summary: cse_oam_listing_version_summary(record, category),
      published_at: cse_oam_listing_version_datetime(record),
      category: category
    }
  end

  defp parse_cse_oam_listing_version_record(_record) do
    %{
      external_id: nil,
      title: nil,
      url: nil,
      summary: nil,
      published_at: DateTime.utc_now(),
      category: nil
    }
  end

  defp cse_oam_listing_version_url(record) do
    id = string_field(record, "id")

    if id do
      @cse_oam_base_url <>
        "/card-details/" <> id <> "/" <> cse_oam_translation_segment(record, id)
    end
  end

  defp cse_oam_translation_segment(record, id) do
    case string_field(record, "translationId") do
      nil -> id <> "tr"
      "0" -> id <> "tr"
      translation_id -> translation_id <> "tr"
    end
  end

  defp cse_oam_listing_version_summary(record, category) do
    body =
      (string_field(record, "translationVersionContent") || string_field(record, "versionContent"))
      |> cse_oam_body_excerpt()

    join_non_empty(
      [
        "CSE OAM",
        prefixed("Category", category),
        prefixed("Security", string_field(record, "securityCodesCode")),
        prefixed("Market", string_field(record, "marketTypesDescription")),
        body
      ],
      " | "
    )
  end

  defp cse_oam_body_excerpt(nil), do: nil

  defp cse_oam_body_excerpt(value) do
    value
    |> clean_html()
    |> case do
      nil -> nil
      cleaned -> cleaned |> String.slice(0, 360) |> String.trim()
    end
  end

  defp cse_oam_listing_version_datetime(record) do
    cse_oam_epoch_millis(record, "publicationTimestamp") ||
      cse_oam_epoch_millis(record, "translationRegistryTimestamp") ||
      DateTime.utc_now()
  end

  defp cse_oam_epoch_millis(record, key) do
    record
    |> Map.get(key)
    |> case do
      value when is_integer(value) -> value
      value when is_binary(value) -> parse_epoch_millis(value)
      _ -> nil
    end
    |> case do
      value when is_integer(value) ->
        case DateTime.from_unix(value, :millisecond) do
          {:ok, datetime} ->
            if DateTime.compare(datetime, DateTime.add(DateTime.utc_now(), 86_400, :second)) ==
                 :gt,
               do: nil,
               else: datetime

          _ ->
            nil
        end

      _ ->
        nil
    end
  end

  defp parse_epoch_millis(value) do
    case Integer.parse(value) do
      {parsed, ""} -> parsed
      _ -> nil
    end
  end

  defp parse_de_company_register_capital_market(raw_payload) do
    with {:ok, decoded} <- Jason.decode(raw_payload),
         true <- Map.get(decoded, "strategy") == @de_company_register_strategy,
         responses when is_list(responses) <- Map.get(decoded, "responses") do
      items =
        responses
        |> Enum.flat_map(&parse_de_company_register_response/1)
        |> Enum.filter(&(&1.url && &1.title && &1.published_at))

      {:ok, items}
    else
      {:error, error} ->
        {:error, {:invalid_json, error}}

      false ->
        {:error, {:invalid_json_shape, "germany_company_register_capital_market_flight_v1"}}

      _ ->
        {:error, {:invalid_json_shape, "germany_company_register_capital_market_flight_v1"}}
    end
  end

  defp parse_de_company_register_response(%{"data" => rows}) when is_list(rows) do
    Enum.map(rows, &parse_de_company_register_record/1)
  end

  defp parse_de_company_register_response(_response), do: []

  defp parse_de_company_register_record(record) when is_map(record) do
    payload = string_field(record, "encryptedPayload")
    issuer = string_field(record, "companyNameAtTimeOfPublication")
    title = string_field(record, "title")
    source_date = string_field(record, "sourceDate")
    category = de_company_register_category(record)

    %{
      external_id: de_company_register_external_id(payload),
      title: title,
      url: de_company_register_publication_url(payload),
      summary: de_company_register_summary(record, issuer, source_date, category),
      published_at: parse_de_company_register_date(source_date),
      category: category
    }
  end

  defp parse_de_company_register_record(_record) do
    %{
      external_id: nil,
      title: nil,
      url: nil,
      summary: nil,
      published_at: nil,
      category: nil
    }
  end

  defp de_company_register_external_id(nil), do: nil

  defp de_company_register_external_id(payload) do
    digest =
      :sha256
      |> :crypto.hash(payload)
      |> Base.encode16(case: :lower)
      |> String.slice(0, 32)

    "de-company-register:" <> digest
  end

  defp de_company_register_publication_url(nil), do: nil

  defp de_company_register_publication_url(payload) do
    @de_company_register_publication_url <> URI.encode(payload, &URI.char_unreserved?/1)
  end

  defp de_company_register_summary(record, issuer, source_date, category) do
    join_non_empty(
      [
        "Germany Company Register capital-market information",
        prefixed("Issuer", issuer),
        prefixed("Source", string_field(record, "sourceName")),
        prefixed("Date", source_date),
        prefixed("Category", category),
        prefixed("Language", string_field(record, "language")),
        prefixed("PDF", string_field(record, "hasPdf"))
      ],
      " | "
    )
  end

  defp de_company_register_category(record) do
    category_id = de_company_register_nested_id(record, "publicationCategory")
    type_id = de_company_register_nested_id(record, "publicationType")

    cond do
      category_id == "69" -> "Securities"
      category_id == "70" -> "Securities acquisition and takeover"
      category_id == "79" -> "Insider information"
      category_id == "80" -> "Managers' transactions"
      category_id == "81" -> "Voting rights announcement"
      category_id == "82" -> "Prospectus notice"
      category_id == "83" -> "Miscellaneous capital-market information"
      category_id == "85" -> "Accounting / financial report"
      category_id == "87" -> "Country of origin"
      category_id == "90" -> "Further financial report"
      category_id -> "Capital-market information category " <> category_id
      type_id -> "Capital-market information type " <> type_id
      true -> "Capital-market information"
    end
  end

  defp de_company_register_nested_id(record, key) do
    case Map.get(record, key) do
      %{"id" => value} when is_integer(value) or is_binary(value) -> to_string(value)
      %{id: value} when is_integer(value) or is_binary(value) -> to_string(value)
      _ -> string_field(record, key <> "Id")
    end
  end

  defp parse_de_company_register_date(nil), do: nil

  defp parse_de_company_register_date(value) do
    with [_, year_text, month_text, day_text] <- Regex.run(~r/^(\d{4})-(\d{2})-(\d{2})$/, value),
         {year, ""} <- Integer.parse(year_text),
         {month, ""} <- Integer.parse(month_text),
         {day, ""} <- Integer.parse(day_text),
         {:ok, datetime} <- build_utc_datetime(year, month, day, 0, 0, 0) do
      datetime
    else
      _ -> nil
    end
  end

  defp parse_blse_multi_issuer_news(raw_payload) do
    with {:ok, decoded} <- Jason.decode(raw_payload),
         true <- Map.get(decoded, "strategy") == @blse_strategy,
         records when is_list(records) <- blse_multi_issuer_news_records(decoded) do
      items =
        records
        |> Enum.flat_map(&parse_blse_issuer_news_response/1)
        |> Enum.filter(&(&1.url && &1.title))

      {:ok, items}
    else
      {:error, error} -> {:error, {:invalid_json, error}}
      false -> {:error, {:invalid_json_shape, "blse_multi_issuer_news_rss_v1"}}
      _ -> {:error, {:invalid_json_shape, "blse_multi_issuer_news_rss_v1"}}
    end
  end

  defp blse_multi_issuer_news_records(%{"responses" => records}) when is_list(records),
    do: records

  defp blse_multi_issuer_news_records(_decoded), do: nil

  defp parse_blse_issuer_news_response(
         %{"code" => code, "issuer" => issuer, "data" => rss} = response
       )
       when is_binary(rss) do
    case parse_rss(rss) do
      {:ok, records} ->
        records
        |> blse_take_kept_records(Map.get(response, "records_kept"))
        |> Enum.map(&parse_blse_issuer_news_record(&1, code, issuer))

      _error ->
        []
    end
  end

  defp parse_blse_issuer_news_response(_response), do: []

  defp blse_take_kept_records(records, limit) when is_integer(limit) and limit > 0,
    do: Enum.take(records, limit)

  defp blse_take_kept_records(records, _limit), do: records

  defp parse_blse_issuer_news_record(record, code, issuer) do
    url = Map.get(record, :url)

    %{
      record
      | external_id: join_non_empty(["blse", code, blse_document_id(url)], ":"),
        summary: blse_issuer_news_summary(record, code, issuer),
        category: "issuer_news"
    }
  end

  defp blse_document_id(url) when is_binary(url) do
    case Regex.run(~r/[?&]id=(\d+)/i, url, capture: :all_but_first) do
      [id] -> id
      _ -> url
    end
  end

  defp blse_document_id(_url), do: nil

  defp blse_issuer_news_summary(record, code, issuer) do
    description =
      record
      |> Map.get(:summary)
      |> blse_clean_summary()

    join_non_empty(
      [
        description || "BLSE issuer announcement.",
        prefixed("Issuer", issuer),
        prefixed("Code", code)
      ],
      " | "
    )
  end

  defp blse_clean_summary(nil), do: nil

  defp blse_clean_summary(value) do
    value
    |> decode_html_entities()
    |> String.replace("&rsquo;", "'")
    |> String.replace("&ldquo;", "\"")
    |> String.replace("&rdquo;", "\"")
    |> String.replace("&scaron;", "s")
    |> String.replace("&Scaron;", "S")
    |> String.replace(~r/<[^>]+>/, " ")
    |> String.replace(~r/\s+/u, " ")
    |> String.trim()
    |> String.slice(0, 320)
    |> case do
      "" -> nil
      cleaned -> cleaned
    end
  end

  defp parse_pse_multi_isin_issuer_news(raw_payload) do
    with {:ok, decoded} <- Jason.decode(raw_payload),
         records when is_list(records) <- pse_multi_isin_news_records(decoded) do
      items =
        records
        |> Enum.flat_map(&parse_pse_multi_isin_news_response/1)
        |> Enum.filter(&(&1.url && &1.title))

      {:ok, items}
    else
      {:error, error} -> {:error, {:invalid_json, error}}
      _ -> {:error, {:invalid_json_shape, "pse_multi_isin_issuer_news_json_v1"}}
    end
  end

  defp pse_multi_isin_news_records(%{"responses" => records}) when is_list(records),
    do: records

  defp pse_multi_isin_news_records(_decoded), do: nil

  defp parse_pse_multi_isin_news_response(%{"isin" => query_isin, "data" => rows})
       when is_binary(query_isin) and is_list(rows) do
    rows
    |> Enum.filter(&pse_news_matches_query_isin?(&1, query_isin))
    |> Enum.map(&parse_pse_issuer_news_record(&1, query_isin))
  end

  defp parse_pse_multi_isin_news_response(_response), do: []

  defp parse_pse_issuer_news_record(record, query_isin) when is_map(record) do
    slug = string_field(record, "slug")

    %{
      external_id: join_non_empty(["pse-news", query_isin, string_field(record, "id")], ":"),
      title: string_field(record, "title"),
      url: pse_issuer_news_url(slug, query_isin),
      summary: pse_issuer_news_summary(record, query_isin),
      published_at: pse_issuer_news_datetime(record),
      category: string_field(record, "type")
    }
  end

  defp pse_issuer_news_url(nil, query_isin), do: @pse_detail_base_url <> query_isin
  defp pse_issuer_news_url(slug, _query_isin), do: @pse_news_base_url <> slug

  defp parse_pse_multi_isin_issuer_report_calendar(raw_payload) do
    with {:ok, decoded} <- Jason.decode(raw_payload),
         records when is_list(records) <- pse_multi_isin_calendar_records(decoded) do
      items =
        records
        |> Enum.flat_map(&parse_pse_multi_isin_calendar_response/1)
        |> Enum.filter(&(&1.url && &1.title && &1.published_at))

      {:ok, items}
    else
      {:error, error} -> {:error, {:invalid_json, error}}
      _ -> {:error, {:invalid_json_shape, "pse_multi_isin_issuer_report_calendar_json_v1"}}
    end
  end

  defp pse_multi_isin_calendar_records(%{"responses" => records}) when is_list(records),
    do: records

  defp pse_multi_isin_calendar_records(_decoded), do: nil

  defp parse_pse_multi_isin_calendar_response(%{"isin" => query_isin, "data" => rows})
       when is_binary(query_isin) and is_list(rows) do
    rows
    |> Enum.filter(&pse_report_calendar_row?(&1, query_isin))
    |> Enum.map(&parse_pse_report_calendar_record(&1, query_isin))
  end

  defp parse_pse_multi_isin_calendar_response(_response), do: []

  defp pse_report_calendar_row?(record, query_isin) when is_map(record) do
    pse_report_calendar_matches_query_isin?(record, query_isin) and
      not is_nil(string_field(record, "ref")) and
      not is_nil(parse_pse_report_calendar_date(string_field(record, "date")))
  end

  defp pse_report_calendar_row?(_record, _query_isin), do: false

  defp pse_report_calendar_matches_query_isin?(record, query_isin) do
    record
    |> string_field("instrumentIsin")
    |> case do
      nil -> true
      isin -> normalize_isin(isin) == normalize_isin(query_isin)
    end
  end

  defp parse_pse_report_calendar_record(record, query_isin) when is_map(record) do
    ref = string_field(record, "ref")
    title = string_field(record, "name")

    %{
      external_id:
        join_non_empty(
          ["pse-report-calendar", query_isin, string_field(record, "id") || ref],
          ":"
        ),
      title: title,
      url: pse_report_calendar_url(query_isin, ref),
      summary: pse_report_calendar_summary(record, query_isin),
      published_at: parse_pse_report_calendar_date(string_field(record, "date")),
      category: "PSE issuer report"
    }
  end

  defp pse_report_calendar_url(_query_isin, nil), do: nil

  defp pse_report_calendar_url(query_isin, ref) do
    @pse_detail_base_url <> query_isin <> "?do=download&path=" <> ref
  end

  defp pse_report_calendar_summary(record, query_isin) do
    join_non_empty(
      [
        "Prague Stock Exchange issuer report calendar document",
        prefixed("Issuer", string_field(record, "instrumentName")),
        prefixed("ISIN", query_isin),
        prefixed("Date", string_field(record, "date")),
        prefixed("Extension", string_field(record, "extension")),
        prefixed("Size", string_field(record, "sizeFormatted")),
        prefixed("File", string_field(record, "ref"))
      ],
      " | "
    )
  end

  defp parse_pse_report_calendar_date(nil), do: nil

  defp parse_pse_report_calendar_date(value) do
    with [_, day_text, month_text, year_text] <-
           Regex.run(~r/^(\d{2})\.(\d{2})\.(\d{4})$/, value),
         {year, ""} <- Integer.parse(year_text),
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

  defp pse_issuer_news_summary(record, query_isin) do
    join_non_empty(
      [
        "Prague Stock Exchange issuer news",
        prefixed("ISIN", query_isin),
        prefixed("Type", string_field(record, "type")),
        prefixed("Source", string_field(record, "source")),
        pse_bounded_text(string_field(record, "content"))
      ],
      " | "
    )
  end

  defp pse_bounded_text(nil), do: nil

  defp pse_bounded_text(value) do
    value
    |> clean_html()
    |> case do
      nil -> nil
      cleaned -> String.slice(cleaned, 0, 500)
    end
  end

  defp pse_news_matches_query_isin?(record, query_isin) when is_map(record) do
    query_isin = normalize_isin(query_isin)

    record
    |> string_field("isin")
    |> pse_isin_list()
    |> Enum.member?(query_isin)
  end

  defp pse_news_matches_query_isin?(_record, _query_isin), do: false

  defp pse_isin_list(nil), do: []

  defp pse_isin_list(value) do
    value
    |> String.split(",")
    |> Enum.map(&normalize_isin/1)
    |> Enum.reject(&(&1 == ""))
  end

  defp normalize_isin(value) when is_binary(value) do
    value
    |> String.trim()
    |> String.upcase()
  end

  defp normalize_isin(_value), do: ""

  defp pse_issuer_news_datetime(record) do
    record
    |> string_field("publishedAt")
    |> parse_pse_news_datetime()
    |> case do
      nil -> DateTime.utc_now()
      datetime -> datetime
    end
  end

  defp parse_pse_news_datetime(nil), do: nil

  defp parse_pse_news_datetime(value) do
    with [_, year_text, month_text, day_text, hour_text, minute_text, second_text] <-
           Regex.run(
             ~r/^(\d{4})-(\d{2})-(\d{2})\s+(\d{2}):(\d{2}):(\d{2})$/,
             value
           ),
         {year, ""} <- Integer.parse(year_text),
         {month, ""} <- Integer.parse(month_text),
         {day, ""} <- Integer.parse(day_text),
         {hour, ""} <- Integer.parse(hour_text),
         {minute, ""} <- Integer.parse(minute_text),
         {second, ""} <- Integer.parse(second_text),
         {:ok, datetime} <- build_utc_datetime(year, month, day, hour, minute, second) do
      pse_apply_prague_zone(datetime)
    else
      _ -> parse_iso8601_datetime(value)
    end
  end

  defp pse_apply_prague_zone(%DateTime{month: month} = datetime) when month in 4..10,
    do: DateTime.add(datetime, -7_200, :second)

  defp pse_apply_prague_zone(datetime), do: DateTime.add(datetime, -3_600, :second)

  defp oekb_oam_datetime(record) do
    record
    |> Map.get("uploadzeitpunkt")
    |> oekb_oam_unix_ms_datetime()
    |> case do
      %DateTime{} = datetime -> datetime
      nil -> DateTime.utc_now()
    end
  end

  defp oekb_oam_unix_ms_datetime(value) when is_integer(value) do
    case DateTime.from_unix(value, :millisecond) do
      {:ok, datetime} ->
        if DateTime.compare(datetime, DateTime.add(DateTime.utc_now(), 86_400, :second)) == :gt do
          nil
        else
          datetime
        end

      _ ->
        nil
    end
  end

  defp oekb_oam_unix_ms_datetime(value) when is_binary(value) do
    case Integer.parse(value) do
      {parsed, ""} -> oekb_oam_unix_ms_datetime(parsed)
      _ -> nil
    end
  end

  defp oekb_oam_unix_ms_datetime(_value), do: nil

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

  defp parse_lt_oam_regulated_information(raw_payload) do
    items =
      Regex.scan(
        ~r/<nef-table-row class="message-row">\s*<nef-table-cell class="table-published">.*?<span class="table-content"[^>]*>(.*?)<\/span>.*?<\/nef-table-cell>\s*<nef-table-cell class="table-company">.*?<span\s+class="table-content">(.*?)<\/span>.*?<\/nef-table-cell>\s*<nef-table-cell class="table-headline">.*?<nef-link href="([^"]+)"[^>]*>.*?<span class="table-link">(.*?)<\/span>.*?<\/nef-table-cell>\s*<nef-table-cell class="table-category">.*?<span class="table-content">(.*?)<\/span>.*?<\/nef-table-cell>\s*<\/nef-table-row>/s,
        raw_payload
      )
      |> Enum.map(&parse_lt_oam_regulated_information_row/1)
      |> Enum.filter(&(&1.url && &1.title))

    {:ok, items}
  end

  defp parse_lt_oam_regulated_information_row([
         _row,
         published_at_text,
         issuer,
         href,
         headline,
         category
       ]) do
    issuer = clean_html(issuer)
    headline = clean_html(headline)
    category = clean_html(category)
    url = lt_oam_regulated_information_url(href)

    %{
      external_id: lt_oam_regulated_information_external_id(url),
      title: lt_oam_regulated_information_title(issuer, headline),
      url: url,
      summary:
        join_non_empty(
          [
            "Lithuania OAM regulated information",
            prefixed("Issuer", issuer),
            prefixed("Message category", category)
          ],
          " | "
        ),
      published_at: parse_lt_oam_datetime(clean_html(published_at_text)),
      category: category
    }
  end

  defp parse_lt_oam_regulated_information_row(_row), do: empty_lt_oam_regulated_information()

  defp empty_lt_oam_regulated_information do
    %{
      external_id: nil,
      title: nil,
      url: nil,
      summary: nil,
      published_at: DateTime.utc_now(),
      category: nil
    }
  end

  defp lt_oam_regulated_information_title(nil, nil), do: nil
  defp lt_oam_regulated_information_title(issuer, nil), do: issuer
  defp lt_oam_regulated_information_title(nil, headline), do: headline
  defp lt_oam_regulated_information_title(issuer, headline), do: issuer <> " - " <> headline

  defp lt_oam_regulated_information_url(nil), do: nil

  defp lt_oam_regulated_information_url(raw_url) do
    url = decode_html_entities(raw_url)

    cond do
      String.starts_with?(url, "http") -> url
      String.starts_with?(url, "/") -> @lt_oam_base_url <> url
      true -> @lt_oam_base_url <> "/" <> url
    end
  end

  defp lt_oam_regulated_information_external_id(nil), do: nil

  defp lt_oam_regulated_information_external_id(url) do
    url
    |> URI.parse()
    |> Map.get(:path)
    |> case do
      nil -> nil
      path -> List.last(String.split(path, "/", trim: true))
    end
  end

  defp parse_lt_oam_datetime(nil), do: DateTime.utc_now()

  defp parse_lt_oam_datetime(value) do
    with [_, year_text, month_text, day_text, hour_text, minute_text, second_text] <-
           Regex.run(
             ~r/^(\d{4})-(\d{2})-(\d{2})\s+(\d{2}):(\d{2}):(\d{2})(?:\s+[A-Z]+)?$/,
             value
           ),
         {day, ""} <- Integer.parse(day_text),
         {month, ""} <- Integer.parse(month_text),
         {year, ""} <- Integer.parse(year_text),
         {hour, ""} <- Integer.parse(hour_text),
         {minute, ""} <- Integer.parse(minute_text),
         {second, ""} <- Integer.parse(second_text),
         {:ok, datetime} <- build_utc_datetime(year, month, day, hour, minute, second) do
      lt_oam_apply_lithuania_zone(datetime)
    else
      _ -> DateTime.utc_now()
    end
  end

  defp lt_oam_apply_lithuania_zone(%DateTime{month: month} = datetime) when month in 4..10,
    do: DateTime.add(datetime, -10_800, :second)

  defp lt_oam_apply_lithuania_zone(datetime), do: DateTime.add(datetime, -7_200, :second)

  defp parse_lv_csri_regulated_information(raw_payload) do
    items =
      Regex.scan(
        ~r/<tr>\s*<td>\s*(\d{4}-\d{2}-\d{2}\s+\d{2}:\d{2}:\d{2})\s*<\/td>\s*<td>\s*<a href="[^"]*">\s*(.*?)\s*<\/a>\s*<\/td>\s*<td>\s*(.*?)\s*<\/td>\s*<td>\s*(.*?)\s*<\/td>\s*<td>\s*<a href="([^"]+)">\s*(.*?)\s*<\/a>\s*<\/td>\s*<\/tr>/s,
        raw_payload
      )
      |> Enum.map(&parse_lv_csri_regulated_information_row/1)
      |> Enum.filter(&(&1.url && &1.title))

    {:ok, items}
  end

  defp parse_lv_csri_regulated_information_row([
         _row,
         published_at_text,
         issuer,
         version,
         language,
         href,
         title
       ]) do
    issuer = clean_html(issuer)
    version = clean_html(version)
    language = clean_html(language)
    title = clean_html(title)
    url = lv_csri_regulated_information_url(href)

    %{
      external_id: lv_csri_regulated_information_external_id(url),
      title: lv_csri_regulated_information_title(issuer, title),
      url: url,
      summary:
        join_non_empty(
          [
            "Latvia CSRI regulated information",
            prefixed("Issuer", issuer),
            prefixed("Language", language),
            prefixed("Version", version)
          ],
          " | "
        ),
      published_at: parse_lv_csri_datetime(clean_html(published_at_text)),
      category: "Regulated information"
    }
  end

  defp parse_lv_csri_regulated_information_row(_row),
    do: empty_lv_csri_regulated_information()

  defp empty_lv_csri_regulated_information do
    %{
      external_id: nil,
      title: nil,
      url: nil,
      summary: nil,
      published_at: DateTime.utc_now(),
      category: nil
    }
  end

  defp lv_csri_regulated_information_title(nil, nil), do: nil
  defp lv_csri_regulated_information_title(issuer, nil), do: issuer
  defp lv_csri_regulated_information_title(nil, title), do: title
  defp lv_csri_regulated_information_title(issuer, title), do: issuer <> " - " <> title

  defp lv_csri_regulated_information_url(nil), do: nil

  defp lv_csri_regulated_information_url(raw_url) do
    url = decode_html_entities(raw_url)

    cond do
      String.starts_with?(url, "http") -> url
      String.starts_with?(url, "/") -> @lv_csri_base_url <> url
      true -> @lv_csri_base_url <> "/" <> url
    end
  end

  defp lv_csri_regulated_information_external_id(nil), do: nil

  defp lv_csri_regulated_information_external_id(url) do
    case URI.parse(url) do
      %URI{query: query} when is_binary(query) ->
        query
        |> URI.decode_query()
        |> Map.get("id")

      %URI{path: path} when is_binary(path) ->
        List.last(String.split(path, "/", trim: true))

      _uri ->
        nil
    end
  end

  defp parse_lv_csri_datetime(nil), do: DateTime.utc_now()

  defp parse_lv_csri_datetime(value) do
    with [_, year_text, month_text, day_text, hour_text, minute_text, second_text] <-
           Regex.run(~r/^(\d{4})-(\d{2})-(\d{2})\s+(\d{2}):(\d{2}):(\d{2})$/, value),
         {day, ""} <- Integer.parse(day_text),
         {month, ""} <- Integer.parse(month_text),
         {year, ""} <- Integer.parse(year_text),
         {hour, ""} <- Integer.parse(hour_text),
         {minute, ""} <- Integer.parse(minute_text),
         {second, ""} <- Integer.parse(second_text),
         {:ok, datetime} <- build_utc_datetime(year, month, day, hour, minute, second) do
      lv_csri_apply_latvia_zone(datetime)
    else
      _ -> DateTime.utc_now()
    end
  end

  defp lv_csri_apply_latvia_zone(%DateTime{month: month} = datetime) when month in 4..10,
    do: DateTime.add(datetime, -10_800, :second)

  defp lv_csri_apply_latvia_zone(datetime), do: DateTime.add(datetime, -7_200, :second)

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

  defp parse_malta_mse_announcements(raw_payload) do
    items =
      Regex.scan(~r/<a\s+href="([^"]+)"[^>]*class="box event-box"[^>]*>(.*?)<\/a>/s, raw_payload)
      |> Enum.map(&parse_malta_mse_announcement_row/1)
      |> Enum.filter(&(&1.url && &1.title))

    {:ok, items}
  end

  defp parse_malta_mse_announcement_row([_row, href, row_html]) do
    issuer = regex_capture(row_html, ~r/<h3[^>]*>\s*(.*?)\s*<\/h3>/s)
    headline = regex_capture(row_html, ~r/<p[^>]*>\s*(.*?)\s*<\/p>/s)
    date_text = regex_capture(row_html, ~r/<date[^>]*>\s*(.*?)\s*<\/date>/s)
    url = malta_mse_url(href)

    %{
      external_id: malta_mse_external_id(url),
      title: join_non_empty([issuer, headline], " - "),
      url: url,
      summary:
        join_non_empty(
          [
            "Malta Stock Exchange announcement",
            prefixed("Issuer", issuer),
            prefixed("Announcement", headline)
          ],
          " | "
        ),
      published_at: parse_malta_mse_date(date_text),
      category: headline
    }
  end

  defp parse_malta_mse_announcement_row(_row), do: empty_malta_mse_announcement()

  defp empty_malta_mse_announcement do
    %{
      external_id: nil,
      title: nil,
      url: nil,
      summary: nil,
      published_at: DateTime.utc_now(),
      category: nil
    }
  end

  defp malta_mse_external_id(nil), do: nil

  defp malta_mse_external_id(url) do
    url
    |> String.split("/")
    |> List.last()
  end

  defp malta_mse_url(nil), do: nil

  defp malta_mse_url(raw_url) do
    url = decode_html_entities(raw_url)

    cond do
      String.starts_with?(url, "http") -> url
      String.starts_with?(url, "/") -> @malta_mse_base_url <> url
      true -> @malta_mse_base_url <> "/news-and-articles/announcements"
    end
  end

  defp parse_malta_mse_date(nil), do: DateTime.utc_now()

  defp parse_malta_mse_date(value) do
    with [_, day_text, month_text, year_text] <- Regex.run(~r/^(\d{2})-(\d{2})-(\d{4})$/, value),
         {year, ""} <- Integer.parse(year_text),
         {month, ""} <- Integer.parse(month_text),
         {day, ""} <- Integer.parse(day_text),
         {:ok, datetime} <- build_utc_datetime(year, month, day, 0, 0, 0),
         true <-
           DateTime.compare(datetime, DateTime.add(DateTime.utc_now(), 86_400, :second)) != :gt do
      datetime
    else
      _ -> DateTime.utc_now()
    end
  end

  defp parse_x3news_issuer_disclosures(raw_payload) do
    items =
      Regex.scan(
        ~r/<div class="news-row">\s*(.*?)<div id="newsContainer_\d+"[^>]*><\/div>\s*<\/div>/s,
        raw_payload
      )
      |> Enum.map(&parse_x3news_issuer_disclosure_row/1)
      |> Enum.filter(&(&1.url && &1.title))

    {:ok, items}
  end

  defp parse_x3news_issuer_disclosure_row([_row, row_html]) do
    external_id = regex_capture_raw(row_html, ~r/showNews\('\d+',\s*(\d+)\);/)
    issuer = x3news_text(regex_capture_raw(row_html, ~r/<div><b>\s*(.*?)\s*<\/b><\/div>/s))

    headline =
      x3news_text(
        regex_capture_raw(
          row_html,
          ~r/<div class="newsHeaderLink show-date-on-right">\s*(.*?)\s*<\/div>/s
        )
      )

    date_text =
      x3news_text(
        regex_capture_raw(row_html, ~r/<span\s+style="float:right;">\s*(.*?)\s*<\/span>/s)
      )

    url = x3news_url(external_id)

    %{
      external_id: prefixed("x3news", external_id),
      title: x3news_title(issuer, headline),
      url: url,
      summary:
        join_non_empty(
          [
            "Bulgaria X3News issuer disclosure",
            prefixed("Issuer", issuer),
            prefixed("Disclosure", headline)
          ],
          " | "
        ),
      published_at: parse_x3news_datetime(date_text),
      category: headline
    }
  end

  defp parse_x3news_issuer_disclosure_row(_row), do: empty_x3news_issuer_disclosure()

  defp empty_x3news_issuer_disclosure do
    %{
      external_id: nil,
      title: nil,
      url: nil,
      summary: nil,
      published_at: DateTime.utc_now(),
      category: nil
    }
  end

  defp x3news_title(nil, nil), do: nil
  defp x3news_title(issuer, nil), do: issuer
  defp x3news_title(nil, headline), do: headline

  defp x3news_title(issuer, headline) do
    normalized_issuer = String.downcase(issuer)
    normalized_headline = String.downcase(headline)

    if String.starts_with?(normalized_headline, normalized_issuer) do
      headline
    else
      issuer <> " - " <> headline
    end
  end

  defp x3news_url(nil), do: nil

  defp x3news_url(external_id) do
    @x3news_base_url <> "?page=ShowNews&ExtriID=" <> external_id <> "&output=ajax"
  end

  defp x3news_text(nil), do: nil

  defp x3news_text(value) do
    value
    |> x3news_utf8()
    |> String.replace(~r/<[^>]+>/, " ")
    |> decode_html_entities()
    |> String.replace(~r/\s+/u, " ")
    |> String.trim()
    |> case do
      "" -> nil
      cleaned -> cleaned
    end
  end

  defp x3news_utf8(value) do
    if String.valid?(value) do
      value
    else
      :unicode.characters_to_binary(value, :latin1, :utf8)
    end
  end

  defp parse_x3news_datetime(nil), do: DateTime.utc_now()

  defp parse_x3news_datetime(value) do
    with [_, day_text, month_text, year_text, hour_text, minute_text] <-
           Regex.run(~r/^(\d{2})-(\d{2})-(\d{4}) (\d{2}):(\d{2})$/, value),
         {day, ""} <- Integer.parse(day_text),
         {month, ""} <- Integer.parse(month_text),
         {year, ""} <- Integer.parse(year_text),
         {hour, ""} <- Integer.parse(hour_text),
         {minute, ""} <- Integer.parse(minute_text),
         {:ok, datetime} <- build_utc_datetime(year, month, day, hour, minute, 0) do
      x3news_apply_sofia_zone(datetime)
    else
      _ -> DateTime.utc_now()
    end
  end

  defp x3news_apply_sofia_zone(%DateTime{month: month} = datetime) when month in 4..10,
    do: DateTime.add(datetime, -10_800, :second)

  defp x3news_apply_sofia_zone(datetime), do: DateTime.add(datetime, -7_200, :second)

  defp parse_kap_company_notifications(raw_payload) do
    with {:ok, data_json} <- kap_company_notifications_data_json(raw_payload),
         {:ok, rows} <- Jason.decode(data_json) do
      items =
        rows
        |> Enum.map(&parse_kap_company_notification_row/1)
        |> Enum.filter(&(&1.url && &1.title))

      {:ok, items}
    else
      {:error, _reason} = error -> error
      _ -> {:error, {:invalid_html_shape, "kap_company_notifications_html_v1"}}
    end
  end

  defp kap_company_notifications_data_json(raw_payload) do
    case Regex.run(~r/\\"data\\":(\[.*?\]),\\"SERVER_BASE_URL\\"/s, raw_payload) do
      [_, escaped_json] ->
        Jason.decode(<<?", escaped_json::binary, ?">>)

      _ ->
        {:error, {:invalid_html_shape, "kap_company_notifications_html_v1"}}
    end
  end

  defp parse_kap_company_notification_row(%{"disclosureBasic" => basic})
       when is_map(basic) do
    external_id =
      basic
      |> Map.get("disclosureIndex")
      |> kap_string()

    issuer = kap_clean_text(Map.get(basic, "companyTitle"))
    title = kap_clean_text(Map.get(basic, "title"))
    summary = kap_clean_text(Map.get(basic, "summary"))
    stock_code = kap_clean_text(Map.get(basic, "stockCode"))
    disclosure_class = kap_clean_text(Map.get(basic, "disclosureClass"))
    publish_date = kap_clean_text(Map.get(basic, "publishDate"))

    %{
      external_id: prefixed("kap", external_id),
      title: join_non_empty([issuer, title], " - "),
      url: kap_notification_url(external_id),
      summary:
        join_non_empty(
          [
            "Turkey KAP company notification",
            prefixed("Code", stock_code),
            prefixed("Type", disclosure_class),
            prefixed("Summary", summary)
          ],
          " | "
        ),
      published_at: parse_kap_datetime(publish_date),
      category: disclosure_class || title
    }
  end

  defp parse_kap_company_notification_row(_row), do: empty_kap_company_notification()

  defp empty_kap_company_notification do
    %{
      external_id: nil,
      title: nil,
      url: nil,
      summary: nil,
      published_at: DateTime.utc_now(),
      category: nil
    }
  end

  defp kap_string(nil), do: nil
  defp kap_string(value) when is_binary(value), do: value
  defp kap_string(value), do: to_string(value)

  defp kap_notification_url(nil), do: nil

  defp kap_notification_url(external_id) do
    @kap_base_url <> "/en/Bildirim/" <> external_id
  end

  defp kap_clean_text(nil), do: nil

  defp kap_clean_text(value) do
    value
    |> to_string()
    |> decode_html_entities()
    |> String.replace(~r/\\n/u, " ")
    |> String.replace(~r/\s+/u, " ")
    |> String.trim()
    |> case do
      "" -> nil
      cleaned -> cleaned
    end
  end

  defp parse_kap_datetime(nil), do: DateTime.utc_now()

  defp parse_kap_datetime(value) do
    with [_, day_text, month_text, year_text, hour_text, minute_text, second_text] <-
           Regex.run(~r/^(\d{2})\.(\d{2})\.(\d{4}) (\d{2}):(\d{2}):(\d{2})$/, value),
         {day, ""} <- Integer.parse(day_text),
         {month, ""} <- Integer.parse(month_text),
         {year, ""} <- Integer.parse(year_text),
         {hour, ""} <- Integer.parse(hour_text),
         {minute, ""} <- Integer.parse(minute_text),
         {second, ""} <- Integer.parse(second_text),
         {:ok, datetime} <- build_utc_datetime(year, month, day, hour, minute, second) do
      DateTime.add(datetime, -10_800, :second)
    else
      _ -> DateTime.utc_now()
    end
  end

  defp parse_mse_free_market_announcements(raw_payload) do
    items =
      Regex.scan(
        ~r/<div class="container-announcement166b">\s*<a href="([^"]+)">\s*<ul class="flex-container">\s*<li class="flex-item-1x4">\s*<h4>\s*(.*?)\s*<\/h4>\s*<\/li>\s*<li class="flex-item-3x4">\s*<h4>\s*(.*?)\s*<\/h4>/s,
        raw_payload
      )
      |> Enum.map(&parse_mse_free_market_announcement_row/1)
      |> Enum.filter(&(&1.url && &1.title))

    {:ok, items}
  end

  defp parse_mse_free_market_announcement_row([_row, href, published_at_text, title_html]) do
    title = clean_html(title_html)
    {issuer, category} = mse_free_market_title_parts(title)
    url = mse_url(href)

    %{
      external_id: mse_free_market_external_id(url),
      title: title,
      url: url,
      summary:
        join_non_empty(
          [
            "Macedonian Stock Exchange free-market company announcement",
            prefixed("Issuer", issuer),
            prefixed("Announcement", category)
          ],
          " | "
        ),
      published_at: parse_mse_free_market_date(clean_html(published_at_text)),
      category: category
    }
  end

  defp parse_mse_free_market_announcement_row(_row), do: empty_mse_free_market_announcement()

  defp empty_mse_free_market_announcement do
    %{
      external_id: nil,
      title: nil,
      url: nil,
      summary: nil,
      published_at: DateTime.utc_now(),
      category: nil
    }
  end

  defp mse_free_market_title_parts(nil), do: {nil, nil}

  defp mse_free_market_title_parts(title) do
    case String.split(title, " - ", parts: 2) do
      [issuer, category] -> {blank_to_nil(issuer), blank_to_nil(category)}
      [value] -> {nil, blank_to_nil(value)}
      _parts -> {nil, nil}
    end
  end

  defp mse_url(nil), do: nil

  defp mse_url(raw_url) do
    url = decode_html_entities(raw_url)

    cond do
      String.starts_with?(url, "http") -> url
      String.starts_with?(url, "/") -> @mse_base_url <> url
      true -> @mse_base_url <> "/" <> url
    end
  end

  defp mse_free_market_external_id(nil), do: nil

  defp mse_free_market_external_id(url) do
    url
    |> URI.parse()
    |> Map.get(:path)
    |> case do
      nil -> nil
      path -> path |> String.split("/", trim: true) |> Enum.join("-")
    end
  end

  defp parse_mse_free_market_date(nil), do: DateTime.utc_now()

  defp parse_mse_free_market_date(value) do
    with [_, month_text, day_text, year_text] <-
           Regex.run(~r/^(\d{1,2})\/(\d{1,2})\/(\d{4})$/, value),
         {year, ""} <- Integer.parse(year_text),
         {month, ""} <- Integer.parse(month_text),
         {day, ""} <- Integer.parse(day_text),
         {:ok, datetime} <- build_utc_datetime(year, month, day, 0, 0, 0),
         true <-
           DateTime.compare(datetime, DateTime.add(DateTime.utc_now(), 86_400, :second)) != :gt do
      datetime
    else
      _ -> DateTime.utc_now()
    end
  end

  defp parse_afm_csv_row(row) do
    row
    |> String.trim()
    |> String.trim_leading("\"")
    |> String.trim_trailing("\"")
    |> String.split("\";\"")
    |> Enum.map(&String.replace(&1, "\"\"", "\""))
  end

  defp blank_to_nil(nil), do: nil

  defp blank_to_nil(value) do
    value
    |> to_string()
    |> String.trim()
    |> case do
      "" -> nil
      trimmed -> trimmed
    end
  end

  defp parse_seinet_public_documents(raw_payload) do
    with {:ok, decoded} <- Jason.decode(raw_payload),
         true <- Map.get(decoded, "isSuccess") == true,
         records when is_list(records) <- Map.get(decoded, "data") do
      items =
        records
        |> Enum.map(&parse_seinet_public_document/1)
        |> Enum.filter(&(&1.url && &1.title && &1.published_at))

      {:ok, items}
    else
      {:error, error} -> {:error, {:invalid_json, error}}
      false -> {:error, {:invalid_json_shape, "seinet_public_documents_json_v1"}}
      _ -> {:error, {:invalid_json_shape, "seinet_public_documents_json_v1"}}
    end
  end

  defp parse_seinet_public_document(record) when is_map(record) do
    document_id = string_field(record, "documentId")
    issuer = seinet_issuer_name(record)
    layout = seinet_layout_description(record)
    content = record |> string_field("content") |> seinet_clean_content()

    %{
      external_id:
        join_non_empty(["seinet", string_field(record, "publicId") || document_id], ":"),
      title: join_non_empty([issuer, layout], " - "),
      url: seinet_document_url(document_id),
      summary:
        join_non_empty(
          [
            "SEI-NET listed-company disclosure",
            prefixed("Issuer", issuer),
            prefixed("Layout", layout),
            prefixed("Published", string_field(record, "publishedDate")),
            content
          ],
          " | "
        ),
      published_at: seinet_document_datetime(record),
      category: layout
    }
  end

  defp parse_seinet_public_document(_record) do
    %{
      external_id: nil,
      title: nil,
      url: nil,
      summary: nil,
      published_at: nil,
      category: nil
    }
  end

  defp seinet_issuer_name(record) do
    record
    |> Map.get("issuer")
    |> case do
      issuer when is_map(issuer) ->
        localized_term_field(issuer, "displayName", 2) ||
          localized_term_field(issuer, "displayName", 1) ||
          string_field(issuer, "code")

      _issuer ->
        nil
    end
  end

  defp seinet_layout_description(record) do
    record
    |> Map.get("layout")
    |> case do
      layout when is_map(layout) ->
        string_field(layout, "description") ||
          localized_term_field(layout, "description", 2) ||
          localized_term_field(layout, "description", 1)

      _layout ->
        nil
    end
  end

  defp localized_term_field(entity, key, language_id) when is_map(entity) do
    entity
    |> Map.get("localizedTerms", [])
    |> Enum.find_value(fn
      %{"languageId" => ^language_id} = term -> string_field(term, key)
      _term -> nil
    end)
  end

  defp localized_term_field(_entity, _key, _language_id), do: nil

  defp seinet_document_url(nil), do: nil
  defp seinet_document_url(document_id), do: @seinet_document_base_url <> URI.encode(document_id)

  defp seinet_document_datetime(record) do
    ["publishedDate", "requestPublishDate"]
    |> Enum.find_value(fn key ->
      record
      |> string_field(key)
      |> then(&(parse_iso8601_datetime(&1) || parse_naive_iso8601_datetime(&1)))
    end)
    |> case do
      nil -> DateTime.utc_now()
      datetime -> datetime
    end
  end

  defp seinet_excerpt(nil), do: nil

  defp seinet_excerpt(value) do
    value
    |> String.slice(0, 320)
    |> String.trim()
    |> case do
      "" -> nil
      excerpt -> excerpt
    end
  end

  defp seinet_clean_content(nil), do: nil
  defp seinet_clean_content(value), do: value |> clean_html() |> seinet_excerpt()

  defp parse_mnse_corporate_news(raw_payload) do
    items =
      Regex.scan(
        ~r/<td class="td_color1_01 novosti"[^>]*>\s*<span class="novostiDate">\s*(.*?)\s*<\/span>\s*<br\s*\/?>\s*<a href="([^"]+)"[^>]*>\s*(.*?)\s*<\/a>/is,
        raw_payload
      )
      |> Enum.map(&parse_mnse_corporate_news_row/1)
      |> Enum.filter(&(&1.url && &1.title && &1.published_at))

    {:ok, items}
  end

  defp parse_mnse_corporate_news_row([_row, date_issuer_html, href, title_html]) do
    date_issuer = clean_html(date_issuer_html)
    {date_text, issuer} = mnse_date_issuer_parts(date_issuer)
    title = clean_html(title_html)
    url = mnse_url(href)

    %{
      external_id: mnse_external_id(url),
      title: title,
      url: url,
      summary:
        join_non_empty(
          [
            "Montenegro Stock Exchange corporate issuer announcement",
            prefixed("Issuer", issuer),
            prefixed("Published", date_text)
          ],
          " | "
        ),
      published_at: parse_mnse_datetime(date_text),
      category: "corporate_news"
    }
  end

  defp parse_mnse_corporate_news_row(_row) do
    %{
      external_id: nil,
      title: nil,
      url: nil,
      summary: nil,
      published_at: nil,
      category: nil
    }
  end

  defp mnse_date_issuer_parts(nil), do: {nil, nil}

  defp mnse_date_issuer_parts(value) do
    case String.split(value, "|", parts: 2) do
      [date_text, issuer] -> {String.trim(date_text), blank_to_nil(issuer)}
      [date_text] -> {String.trim(date_text), nil}
      _parts -> {nil, nil}
    end
  end

  defp mnse_url(nil), do: nil

  defp mnse_url(raw_url) do
    url = decode_html_entities(raw_url)

    cond do
      String.starts_with?(url, "http") -> url
      String.starts_with?(url, "/") -> @mnse_base_url <> url
      true -> @mnse_base_url <> "/" <> url
    end
  end

  defp mnse_external_id(nil), do: nil

  defp mnse_external_id(url) do
    url
    |> URI.parse()
    |> case do
      %URI{path: path, query: query} when is_binary(path) ->
        join_non_empty([path |> String.split("/", trim: true) |> Enum.join("-"), query], "?")

      _uri ->
        url
    end
  end

  defp parse_mnse_datetime(nil), do: DateTime.utc_now()

  defp parse_mnse_datetime(value) do
    with [_, day_text, month_text, year_text, hour_text, minute_text] <-
           Regex.run(~r/(\d{2})\/(\d{2})\/(\d{2})\s+(\d{2}):(\d{2})/, value),
         {day, ""} <- Integer.parse(day_text),
         {month, ""} <- Integer.parse(month_text),
         {year, ""} <- Integer.parse("20" <> year_text),
         {hour, ""} <- Integer.parse(hour_text),
         {minute, ""} <- Integer.parse(minute_text),
         {:ok, datetime} <- build_utc_datetime(year, month, day, hour, minute, 0),
         true <-
           DateTime.compare(datetime, DateTime.add(DateTime.utc_now(), 86_400, :second)) != :gt do
      datetime
    else
      _ -> DateTime.utc_now()
    end
  end

  defp parse_md_msi_regulated_information(raw_payload) do
    rows =
      Regex.scan(
        ~r/<tr>\s*<td>(.*?)<\/td>\s*<td>(.*?)<\/td>\s*<td>(.*?)<\/td>\s*<td>\s*<a[^>]+href="([^"]+)"[^>]*>/is,
        raw_payload
      )

    items =
      rows
      |> Enum.map(&parse_md_msi_regulated_information_row/1)
      |> Enum.filter(&(&1.url && &1.title && &1.published_at))

    {:ok, items}
  end

  defp parse_md_msi_regulated_information_row([
         _row,
         company_html,
         document_type_html,
         date_html,
         href
       ]) do
    company = clean_html(company_html)
    document_type = clean_html(document_type_html)
    date_text = clean_html(date_html)
    url = md_msi_url(href)

    %{
      external_id: md_msi_external_id(url),
      title: join_non_empty([company, document_type], " - "),
      url: url,
      summary:
        join_non_empty(
          [
            "Moldova MSI regulated issuer information",
            prefixed("Issuer", company),
            prefixed("Document type", document_type),
            prefixed("Published", date_text)
          ],
          " | "
        ),
      published_at: parse_md_msi_date(date_text),
      category: document_type
    }
  end

  defp parse_md_msi_regulated_information_row(_row) do
    %{
      external_id: nil,
      title: nil,
      url: nil,
      summary: nil,
      published_at: nil,
      category: nil
    }
  end

  defp md_msi_url(nil), do: nil

  defp md_msi_url(raw_url) do
    url = decode_html_entities(raw_url)

    cond do
      String.starts_with?(url, "http") -> url
      String.starts_with?(url, "/") -> @md_msi_base_url <> url
      true -> @md_msi_base_url <> "/" <> url
    end
  end

  defp md_msi_external_id(nil), do: nil

  defp md_msi_external_id(url) do
    url
    |> URI.parse()
    |> case do
      %URI{path: path} when is_binary(path) ->
        path |> String.split("/", trim: true) |> Enum.join("-")

      _uri ->
        url
    end
  end

  defp parse_md_msi_date(nil), do: DateTime.utc_now()

  defp parse_md_msi_date(value) do
    with [_, day_text, month_text, year_text] <- Regex.run(~r/(\d{2})\/(\d{2})\/(\d{4})/, value),
         {day, ""} <- Integer.parse(day_text),
         {month, ""} <- Integer.parse(month_text),
         {year, ""} <- Integer.parse(year_text),
         {:ok, datetime} <- build_utc_datetime(year, month, day, 0, 0, 0),
         true <-
           DateTime.compare(datetime, DateTime.add(DateTime.utc_now(), 86_400, :second)) != :gt do
      datetime
    else
      _ -> DateTime.utc_now()
    end
  end

  defp parse_dfsa_oam_company_announcements(raw_payload) do
    with {:ok, decoded} <- Jason.decode(raw_payload),
         %{"data" => %{"rows" => rows}} when is_list(rows) <- decoded do
      items =
        rows
        |> Enum.map(&parse_dfsa_oam_company_announcement_row/1)
        |> Enum.filter(&(&1.url && &1.title && &1.published_at))

      {:ok, items}
    else
      {:error, reason} -> {:error, {:invalid_dfsa_oam_company_announcements_json, reason}}
      _shape -> {:error, :unexpected_dfsa_oam_company_announcements_shape}
    end
  end

  defp parse_dfsa_oam_company_announcement_row(%{} = row) do
    id = string_field(row, "id")
    title = string_field(row, "HeadlineColumn")
    issuer = string_field(row, "IssuerColumn")
    category = string_field(row, "CategoryColumn")
    published_text = string_field(row, "PublicationDateColumn")

    %{
      external_id: "dfsa-oam-#{id}",
      title: title,
      url: dfsa_oam_details_url(id),
      summary:
        join_non_empty(
          [
            "Danish FSA OAM company announcement",
            prefixed("Issuer", issuer),
            prefixed("Type", category),
            prefixed("Published", published_text)
          ],
          " | "
        ),
      published_at: parse_dfsa_oam_datetime(published_text),
      category: category
    }
  end

  defp parse_dfsa_oam_company_announcement_row(_row) do
    %{
      external_id: nil,
      title: nil,
      url: nil,
      summary: nil,
      published_at: nil,
      category: nil
    }
  end

  defp dfsa_oam_details_url(""), do: nil
  defp dfsa_oam_details_url(nil), do: nil
  defp dfsa_oam_details_url(id), do: @dfsa_oam_details_base_url <> id

  defp parse_dfsa_oam_datetime(nil), do: DateTime.utc_now()

  defp parse_dfsa_oam_datetime(value) do
    with [_, day_text, month_text, year_text, hour_text, minute_text, second_text] <-
           Regex.run(~r/(\d{2})-(\d{2})-(\d{4})\s+(\d{2}):(\d{2}):(\d{2})/, value),
         {day, ""} <- Integer.parse(day_text),
         {month, ""} <- Integer.parse(month_text),
         {year, ""} <- Integer.parse(year_text),
         {hour, ""} <- Integer.parse(hour_text),
         {minute, ""} <- Integer.parse(minute_text),
         {second, ""} <- Integer.parse(second_text),
         {:ok, datetime} <- build_utc_datetime(year, month, day, hour, minute, second),
         true <-
           DateTime.compare(datetime, DateTime.add(DateTime.utc_now(), 86_400, :second)) != :gt do
      datetime
    else
      _ -> DateTime.utc_now()
    end
  end

  defp parse_set_thailand_company_news(raw_payload) do
    with {:ok, decoded} <- Jason.decode(raw_payload),
         groups when is_list(groups) <- Map.get(decoded, "newsGroups") do
      items =
        groups
        |> Enum.flat_map(&set_thailand_company_news_group_records/1)
        |> Enum.map(&parse_set_thailand_company_news_record/1)
        |> Enum.filter(&(&1.url && &1.title && &1.published_at))

      {:ok, items}
    else
      {:error, reason} -> {:error, {:invalid_set_thailand_company_news_json, reason}}
      _shape -> {:error, :unexpected_set_thailand_company_news_shape}
    end
  end

  defp set_thailand_company_news_group_records(%{"newsInfoList" => records} = group)
       when is_list(records) do
    group_name = string_field(group, "group")

    records
    |> Enum.filter(&is_map/1)
    |> Enum.map(&Map.put(&1, "_group", group_name))
  end

  defp set_thailand_company_news_group_records(_group), do: []

  defp parse_set_thailand_company_news_record(%{} = record) do
    id = string_field(record, "id")
    symbol = string_field(record, "symbol")
    source = string_field(record, "source")
    headline = string_field(record, "headline")
    group = string_field(record, "_group")
    tag = string_field(record, "tag")
    product = string_field(record, "product")
    published_text = string_field(record, "datetime")

    %{
      external_id: set_thailand_company_news_external_id(id),
      title: join_non_empty([symbol, headline], " - "),
      url: set_thailand_company_news_url(record),
      summary:
        join_non_empty(
          [
            "SET Thailand company news",
            prefixed("Symbol", symbol),
            prefixed("Source", source),
            prefixed("Group", group),
            prefixed("Tag", tag),
            prefixed("Product", product),
            prefixed("Published", published_text)
          ],
          " | "
        ),
      published_at: parse_set_thailand_company_news_datetime(published_text),
      category: group || tag || "company_news"
    }
  end

  defp parse_set_thailand_company_news_record(_record) do
    %{
      external_id: nil,
      title: nil,
      url: nil,
      summary: nil,
      published_at: nil,
      category: nil
    }
  end

  defp set_thailand_company_news_external_id(nil), do: nil
  defp set_thailand_company_news_external_id(id), do: "set-thailand:" <> id

  defp set_thailand_company_news_url(record) do
    record
    |> string_field("url")
    |> case do
      @set_thailand_base_url <> "/" <> _path = url -> url
      _url -> nil
    end
  end

  defp parse_set_thailand_company_news_datetime(nil), do: DateTime.utc_now()

  defp parse_set_thailand_company_news_datetime(value) do
    parse_iso8601_datetime(value) || DateTime.utc_now()
  end

  defp parse_tw_mops_daily_material_info(raw_payload) do
    with {:ok, decoded} <- raw_payload |> trim_utf8_bom() |> Jason.decode(),
         %{"result" => %{"data" => rows}} <- decoded,
         true <- is_list(rows) do
      items =
        rows
        |> Enum.map(&parse_tw_mops_daily_material_info_row/1)
        |> Enum.filter(&(&1.url && &1.title && &1.published_at))

      {:ok, items}
    else
      {:error, reason} -> {:error, {:invalid_tw_mops_daily_material_info_json, reason}}
      _shape -> {:error, :unexpected_tw_mops_daily_material_info_shape}
    end
  end

  defp parse_tw_mops_daily_material_info_row([
         date_text,
         time_text,
         company_id,
         company_name,
         headline | rest
       ]) do
    detail = Enum.at(rest, 0)
    detail_params = tw_mops_detail_params(detail)
    enter_date = string_field(detail_params, "enterDate")
    serial_number = string_field(detail_params, "serialNumber")
    company_id = to_clean_string(company_id)
    company_name = to_clean_string(company_name)
    headline = clean_html(to_clean_string(headline))

    %{
      external_id:
        join_non_empty(
          [
            "tw-mops",
            company_id,
            enter_date || tw_mops_compact_roc_date(date_text),
            serial_number
          ],
          ":"
        ),
      title: join_non_empty([company_id, company_name, headline], " - "),
      url: tw_mops_material_info_url(date_text),
      summary:
        join_non_empty(
          [
            "Taiwan MOPS daily material information",
            prefixed("Company", join_non_empty([company_id, company_name], " ")),
            prefixed("Published", join_non_empty([date_text, time_text], " ")),
            prefixed("Market", string_field(detail_params, "marketKind"))
          ],
          " | "
        ),
      published_at: parse_tw_mops_datetime(date_text, time_text),
      category: "material_information"
    }
  end

  defp parse_tw_mops_daily_material_info_row(_row) do
    %{
      external_id: nil,
      title: nil,
      url: nil,
      summary: nil,
      published_at: nil,
      category: nil
    }
  end

  defp tw_mops_detail_params(%{"parameters" => params}) when is_map(params), do: params
  defp tw_mops_detail_params(_detail), do: %{}

  defp tw_mops_material_info_url(date_text) do
    case parse_tw_mops_roc_date_parts(date_text) do
      {year, month, day} ->
        @tw_mops_material_info_base_url <>
          "/#/web/t05st02?year=#{year}&month=#{month}&day=#{pad2(day)}"

      nil ->
        @tw_mops_material_info_base_url <> "/#/web/t05st02"
    end
  end

  defp tw_mops_compact_roc_date(date_text) do
    case parse_tw_mops_roc_date_parts(date_text) do
      {year, month, day} -> "#{year}#{pad2(month)}#{pad2(day)}"
      nil -> nil
    end
  end

  defp parse_tw_mops_datetime(date_text, time_text) do
    with {roc_year, month, day} <- parse_tw_mops_roc_date_parts(date_text),
         {hour, minute, second} <- parse_hms(time_text),
         {:ok, date} <- Date.new(roc_year + 1911, month, day),
         {:ok, time} <- Time.new(hour, minute, second),
         {:ok, naive} <- NaiveDateTime.new(date, time) do
      naive
      |> DateTime.from_naive!("Etc/UTC")
      |> DateTime.add(-8 * 60 * 60, :second)
    else
      _ -> DateTime.utc_now()
    end
  end

  defp parse_tw_mops_roc_date_parts(value) do
    value = to_clean_string(value)

    with [_, year_text, month_text, day_text] <-
           Regex.run(~r/^(\d{2,3})\/(\d{1,2})\/(\d{1,2})$/, value),
         {year, ""} <- Integer.parse(year_text),
         {month, ""} <- Integer.parse(month_text),
         {day, ""} <- Integer.parse(day_text) do
      {year, month, day}
    else
      _ -> nil
    end
  end

  defp parse_hms(value) do
    value = to_clean_string(value)

    with [_, hour_text, minute_text, second_text] <-
           Regex.run(~r/^(\d{1,2}):(\d{2}):(\d{2})$/, value),
         {hour, ""} <- Integer.parse(hour_text),
         {minute, ""} <- Integer.parse(minute_text),
         {second, ""} <- Integer.parse(second_text) do
      {hour, minute, second}
    else
      _ -> nil
    end
  end

  defp parse_belex_issuer_news(raw_payload) do
    table_html = regex_capture_raw(raw_payload, ~r/<table\s+id=["']t5["'][^>]*>(.*?)<\/table>/is)

    items =
      (table_html || raw_payload)
      |> then(
        &Regex.scan(
          ~r/<tr[^>]*>\s*<td\s+class=["']date["'][^>]*>\s*(.*?)\s*<\/td>\s*<td\s+class=["']vest["'][^>]*>\s*<a\s+href=["']([^"']+)["'][^>]*>\s*(.*?)\s*<\/a>/is,
          &1
        )
      )
      |> Enum.map(&parse_belex_issuer_news_row/1)
      |> Enum.filter(&(&1.url && &1.title && &1.published_at))

    {:ok, items}
  end

  defp parse_belex_issuer_news_row([_row, date_html, href, title_html]) do
    date_text = clean_html(date_html)
    raw_title = clean_html(title_html)
    {symbol, title} = belex_title_parts(raw_title)
    url = belex_url(href)

    %{
      external_id: belex_external_id(symbol, date_text, title),
      title: title,
      url: url,
      summary:
        join_non_empty(
          [
            "Belgrade Stock Exchange issuer news",
            prefixed("Symbol", symbol),
            prefixed("Published", date_text)
          ],
          " | "
        ),
      published_at: parse_belex_date(date_text),
      category: "issuer_news"
    }
  end

  defp parse_belex_issuer_news_row(_row) do
    %{
      external_id: nil,
      title: nil,
      url: nil,
      summary: nil,
      published_at: nil,
      category: nil
    }
  end

  defp belex_title_parts(nil), do: {nil, nil}

  defp belex_title_parts(value) do
    case Regex.run(~r/^([A-Z0-9]+)\s+-\s+(.+)$/u, value) do
      [_match, symbol, title] -> {symbol, String.trim(title)}
      _ -> {nil, value}
    end
  end

  defp belex_url(nil), do: nil

  defp belex_url(raw_url) do
    url = decode_html_entities(raw_url)

    cond do
      String.starts_with?(url, "http") -> url
      String.starts_with?(url, "/") -> @belex_base_url <> url
      true -> @belex_base_url <> "/" <> url
    end
  end

  defp belex_external_id(symbol, date_text, title) do
    [symbol, date_text, title]
    |> Enum.reject(&is_nil/1)
    |> Enum.map(&belex_external_id_part/1)
    |> Enum.reject(&(&1 == ""))
    |> Enum.join(":")
    |> case do
      "" -> nil
      value -> "belex:" <> value
    end
  end

  defp belex_external_id_part(value) do
    value
    |> to_string()
    |> String.downcase()
    |> String.replace(~r/[^a-z0-9]+/u, "-")
    |> String.trim("-")
  end

  defp parse_belex_date(nil), do: DateTime.utc_now()

  defp parse_belex_date(value) do
    with [_, day_text, month_text, year_text] <-
           Regex.run(~r/^(\d{2})\.(\d{2})\.(\d{4})\./, value),
         {day, ""} <- Integer.parse(day_text),
         {month, ""} <- Integer.parse(month_text),
         {year, ""} <- Integer.parse(year_text),
         {:ok, datetime} <- build_utc_datetime(year, month, day, 0, 0, 0),
         true <-
           DateTime.compare(datetime, DateTime.add(DateTime.utc_now(), 86_400, :second)) != :gt do
      datetime
    else
      _ -> DateTime.utc_now()
    end
  end

  defp parse_sase_multi_issuer_announcements(raw_payload) do
    with {:ok, decoded} <- Jason.decode(raw_payload),
         true <- Map.get(decoded, "strategy") == @sase_strategy,
         responses when is_list(responses) <- Map.get(decoded, "responses") do
      items =
        responses
        |> Enum.flat_map(&parse_sase_issuer_announcement_response/1)
        |> Enum.filter(&(&1.url && &1.title && &1.published_at))

      {:ok, items}
    else
      {:error, error} -> {:error, {:invalid_json, error}}
      false -> {:error, {:invalid_json_shape, "sase_multi_issuer_announcements_xml_v1"}}
      _ -> {:error, {:invalid_json_shape, "sase_multi_issuer_announcements_xml_v1"}}
    end
  end

  defp parse_sase_issuer_announcement_response(%{
         "issuer_code" => issuer_code,
         "issuer" => issuer,
         "data" => data
       })
       when is_binary(data) do
    data
    |> then(&Regex.scan(~r/<ANNOUNCEMENT>(.*?)<\/ANNOUNCEMENT>/s, &1))
    |> Enum.map(&parse_sase_issuer_announcement(&1, issuer_code, issuer))
  end

  defp parse_sase_issuer_announcement_response(_response), do: []

  defp parse_sase_issuer_announcement([_row, row], issuer_code, issuer) do
    id = sase_xml_tag(row, "Id")
    company_id = sase_xml_tag(row, "CompanyId") || issuer_code
    subject = sase_xml_tag(row, "Subject")
    document_link = sase_xml_tag(row, "Link")
    announcement_type = sase_xml_tag(row, "AnnouncementTypeId")
    event_date = sase_xml_tag(row, "DateOfEvent")

    %{
      external_id: join_non_empty(["sase", company_id, id], ":"),
      title: subject,
      url: sase_issuer_profile_url(company_id),
      summary:
        join_non_empty(
          [
            "Sarajevo Stock Exchange issuer announcement",
            prefixed("Issuer", issuer),
            prefixed("CompanyId", company_id),
            prefixed("Document", sase_clean_document_link(document_link)),
            prefixed("Event date", event_date)
          ],
          " | "
        ),
      published_at: parse_sase_datetime(sase_xml_tag(row, "AnnouncementDate")),
      category: announcement_type
    }
  end

  defp parse_sase_issuer_announcement(_row, _issuer_code, _issuer) do
    %{
      external_id: nil,
      title: nil,
      url: nil,
      summary: nil,
      published_at: nil,
      category: nil
    }
  end

  defp sase_xml_tag(row, tag) do
    case Regex.run(~r/<#{tag}>(.*?)<\/#{tag}>/s, row, capture: :all_but_first) do
      [value] ->
        value
        |> decode_html_entities()
        |> String.trim()
        |> case do
          "" -> nil
          trimmed -> trimmed
        end

      _ ->
        nil
    end
  end

  defp sase_issuer_profile_url(nil), do: @sase_profile_base_url

  defp sase_issuer_profile_url(company_id) do
    @sase_profile_base_url <> URI.encode_www_form(company_id)
  end

  defp sase_clean_document_link(nil), do: nil

  defp sase_clean_document_link(value) do
    value
    |> String.replace(";", "")
    |> String.trim()
    |> case do
      "" -> nil
      cleaned -> cleaned
    end
  end

  defp parse_sase_datetime(nil), do: DateTime.utc_now()

  defp parse_sase_datetime(value) do
    parse_iso8601_datetime(value) || parse_naive_iso8601_datetime(value) || DateTime.utc_now()
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

  defp to_clean_string(value) when is_binary(value) do
    value
    |> String.replace(~r/\s+/u, " ")
    |> String.trim()
    |> case do
      "" -> nil
      cleaned -> cleaned
    end
  end

  defp to_clean_string(value) when is_integer(value) or is_float(value), do: to_string(value)
  defp to_clean_string(_value), do: nil

  defp trim_utf8_bom(<<0xEF, 0xBB, 0xBF, rest::binary>>), do: rest
  defp trim_utf8_bom(value), do: value

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

  defp clean_html(nil), do: nil

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

  defp pad2(value) when is_integer(value) and value < 10, do: "0#{value}"
  defp pad2(value), do: to_string(value)

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
    title = xpath_string_any(item, [~c"string(title)", ~c"string(Title)"])
    summary = xpath_string_any(item, [~c"string(description)", ~c"string(Description)"])

    %{
      external_id: xpath_string_any(item, [~c"string(guid)", ~c"string(Guid)"]) || link,
      title: clean_html(title),
      url: link,
      summary: clean_html(summary),
      published_at:
        xpath_pub_date_any(item, [
          ~c"string(pubDate)",
          ~c"string(PubDate)",
          ~c"string(a10:updated)",
          ~c"string(a10:published)",
          ~c"string(updated)",
          ~c"string(Updated)",
          ~c"string(published)",
          ~c"string(Published)",
          ~c"string(*[local-name()='updated'])",
          ~c"string(*[local-name()='published'])"
        ]),
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
  @pse_default_issuer_universe_urls [
    "https://www.pse.cz/en/market-data/shares/prime-market",
    "https://www.pse.cz/en/market-data/shares/standard-market",
    "https://www.pse.cz/en/market-data/shares/start-market",
    "https://www.pse.cz/en/market-data/shares/free-market"
  ]
  @pse_news_url_template "https://www.pse.cz/api/news?lang=en&type=pse&page=1&homepage=0&searchKey=&dateFrom=&dateTo=&isin={isin}"
  @pse_calendar_url_template "https://www.pse.cz/api/corporation-calendar?isin={isin}&order=date-DESC&lang=en"
  @de_company_register_support_url "https://www.unternehmensregister.de/en/search/capital-market-info"
  @de_company_register_token_url "https://www.unternehmensregister.de/api/search-token"
  @de_company_register_search_url_template "https://www.unternehmensregister.de/en/search?formType=CAPITAL_MARKET&searchToken={token}&sourceDateFrom={source_date_from}&sourceDateTo={source_date_to}&from={from}"
  @de_company_register_strategy "germany_company_register_token_preflight_v1"
  @blse_strategy "blse_multi_issuer_news_rss_v1"
  @sase_strategy "sase_multi_issuer_announcements_xml_v1"
  @tw_mops_material_info_strategy "tw_mops_daily_material_info_json_v1"
  @blse_ticker_url "https://services.blberza.com/blse/ticker.ashx?LangId=3&TickerTypeId=1&filter=all&ct=xml"
  @blse_issuer_news_url_template "https://www.blberza.com/pages/IssuerNewsRss.aspx?Code={code}&LangId=3"

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

      {:error, reason} when prefer_live_fetch ->
        if disable_live_fixture_fallback?(source) do
          {:error, reason}
        else
          load_fixture_payload(source)
        end

      :skip ->
        load_fixture_payload(source)
    end
  end

  defp maybe_load_live_payload(
         %SourceRegistry{parser_key: "germany_company_register_capital_market_flight_v1"} =
           source,
         true
       ) do
    with {:ok, support_response, support_cookie} <-
           fetch_de_company_register_support_page(source),
         {:ok, token, token_response, token_cookie} <-
           fetch_de_company_register_search_token(source, support_cookie),
         cookie <- merge_cookie_headers(support_cookie, token_cookie),
         {:ok, page_responses} <- fetch_de_company_register_search_pages(source, token, cookie) do
      raw_payload =
        Jason.encode!(%{
          "strategy" => @de_company_register_strategy,
          "source_date_from" => de_company_register_source_date_from(source),
          "source_date_to" => de_company_register_source_date_to(source),
          "page_size" => de_company_register_page_size(source),
          "max_pages_per_poll" => de_company_register_max_pages_per_poll(source),
          "pages_fetched" => length(page_responses),
          "total_pages" => de_company_register_first_meta(page_responses, "total_pages"),
          "total_results" => de_company_register_first_meta(page_responses, "total_results"),
          "over_page_cap" =>
            de_company_register_over_page_cap?(
              page_responses,
              de_company_register_max_pages_per_poll(source)
            ),
          "responses" => page_responses
        })

      {:ok,
       %{
         raw_payload: raw_payload,
         http_status: 200,
         fetch_info: %{
           "mode" => "live",
           "loaded" => true,
           "strategy" => @de_company_register_strategy,
           "url" => source.base_url,
           "support_status_code" => support_response.status_code,
           "token_status_code" => token_response.status_code,
           "search_status_code" => de_company_register_first_meta(page_responses, "status_code"),
           "status_code" => 200,
           "bytes" => byte_size(raw_payload),
           "source_date_from" => de_company_register_source_date_from(source),
           "source_date_to" => de_company_register_source_date_to(source),
           "page_size" => de_company_register_page_size(source),
           "max_pages_per_poll" => de_company_register_max_pages_per_poll(source),
           "pages_fetched" => length(page_responses),
           "total_pages" => de_company_register_first_meta(page_responses, "total_pages"),
           "total_results" => de_company_register_first_meta(page_responses, "total_results"),
           "records_seen" => de_company_register_records_seen(page_responses),
           "records_kept" =>
             min(
               de_company_register_records_seen(page_responses),
               source_config_positive_integer(
                 source,
                 "max_items_per_poll",
                 :max_items_per_poll,
                 25
               )
             ),
           "over_page_cap" =>
             de_company_register_over_page_cap?(
               page_responses,
               de_company_register_max_pages_per_poll(source)
             ),
           "fixture_fallback" => false
         }
       }}
    end
  end

  defp maybe_load_live_payload(
         %SourceRegistry{parser_key: "blse_multi_issuer_news_rss_v1"} = source,
         true
       ) do
    with {:ok, ticker_response, universe} <- fetch_blse_issuer_universe(source),
         issuer_window <- blse_issuer_window(source, universe),
         selected_universe <- issuer_window.selected_universe,
         {:ok, responses} <- fetch_blse_issuer_news_responses(source, selected_universe) do
      raw_payload =
        Jason.encode!(%{
          "strategy" => @blse_strategy,
          "universe" => universe,
          "issuer_window" => blse_issuer_window_payload(issuer_window),
          "selected_codes" => Enum.map(selected_universe, & &1["code"]),
          "responses" => responses
        })

      {:ok,
       %{
         raw_payload: raw_payload,
         http_status: 200,
         fetch_info: %{
           "mode" => "live",
           "loaded" => true,
           "strategy" => @blse_strategy,
           "url" => source.base_url,
           "ticker_status_code" => ticker_response.status_code,
           "status_code" => 200,
           "bytes" => byte_size(raw_payload),
           "universe_count" => length(universe),
           "selected_issuer_count" => length(selected_universe),
           "selected_issuer_window_strategy" => issuer_window.strategy,
           "selected_issuer_window_offset" => issuer_window.offset,
           "selected_issuer_window_size" => issuer_window.size,
           "selected_issuer_window_universe_count" => issuer_window.universe_count,
           "issuer_request_count" => length(responses),
           "records_seen" => blse_response_records_seen(responses),
           "fixture_fallback" => false
         }
       }}
    end
  end

  defp maybe_load_live_payload(
         %SourceRegistry{parser_key: "sase_multi_issuer_announcements_xml_v1"} = source,
         true
       ) do
    selected_codes = sase_selected_issuer_codes(source)

    with {:ok, responses} <- fetch_sase_issuer_announcement_responses(source, selected_codes) do
      raw_payload =
        Jason.encode!(%{
          "strategy" => @sase_strategy,
          "selected_codes" => selected_codes,
          "responses" => responses
        })

      {:ok,
       %{
         raw_payload: raw_payload,
         http_status: 200,
         fetch_info: %{
           "mode" => "live",
           "loaded" => true,
           "strategy" => @sase_strategy,
           "url" => source.base_url,
           "status_code" => 200,
           "bytes" => byte_size(raw_payload),
           "selected_issuer_count" => length(selected_codes),
           "issuer_request_count" => length(responses),
           "records_seen" => sase_response_records_seen(responses),
           "fixture_fallback" => false
         }
       }}
    end
  end

  defp maybe_load_live_payload(
         %SourceRegistry{parser_key: "pse_multi_isin_issuer_news_json_v1"} = source,
         true
       ) do
    with {:ok, universe_pages} <- fetch_pse_issuer_universe_pages(source),
         {:ok, universe} <- pse_issuer_universe(universe_pages),
         issuer_window <- pse_issuer_window(source, universe),
         selected_universe <- issuer_window.selected_universe,
         {:ok, responses} <- fetch_pse_issuer_news_responses(source, selected_universe) do
      raw_payload =
        Jason.encode!(%{
          "strategy" => "pse_multi_isin_news_v1",
          "universe" => universe,
          "issuer_window" => pse_issuer_window_payload(issuer_window),
          "selected_isins" => Enum.map(selected_universe, & &1["isin"]),
          "responses" => responses
        })

      {:ok,
       %{
         raw_payload: raw_payload,
         http_status: 200,
         fetch_info: %{
           "mode" => "live",
           "loaded" => true,
           "strategy" => "pse_multi_isin_news_v1",
           "url" => source.base_url,
           "status_code" => 200,
           "bytes" => byte_size(raw_payload),
           "universe_count" => length(universe),
           "selected_issuer_count" => length(selected_universe),
           "selected_issuer_window_strategy" => issuer_window.strategy,
           "selected_issuer_window_offset" => issuer_window.offset,
           "selected_issuer_window_size" => issuer_window.size,
           "selected_issuer_window_universe_count" => issuer_window.universe_count,
           "issuer_request_count" => length(responses)
         }
       }}
    end
  end

  defp maybe_load_live_payload(
         %SourceRegistry{parser_key: "pse_multi_isin_issuer_report_calendar_json_v1"} = source,
         true
       ) do
    with {:ok, universe_pages} <- fetch_pse_issuer_universe_pages(source),
         {:ok, universe} <- pse_issuer_universe(universe_pages),
         issuer_window <- pse_issuer_window(source, universe),
         selected_universe <- issuer_window.selected_universe,
         {:ok, responses} <- fetch_pse_issuer_calendar_responses(source, selected_universe) do
      raw_payload =
        Jason.encode!(%{
          "strategy" => "pse_multi_isin_report_calendar_v1",
          "universe" => universe,
          "issuer_window" => pse_issuer_window_payload(issuer_window),
          "selected_isins" => Enum.map(selected_universe, & &1["isin"]),
          "responses" => responses
        })

      {:ok,
       %{
         raw_payload: raw_payload,
         http_status: 200,
         fetch_info: %{
           "mode" => "live",
           "loaded" => true,
           "strategy" => "pse_multi_isin_report_calendar_v1",
           "url" => source.base_url,
           "status_code" => 200,
           "bytes" => byte_size(raw_payload),
           "universe_count" => length(universe),
           "selected_issuer_count" => length(selected_universe),
           "selected_issuer_window_strategy" => issuer_window.strategy,
           "selected_issuer_window_offset" => issuer_window.offset,
           "selected_issuer_window_size" => issuer_window.size,
           "selected_issuer_window_universe_count" => issuer_window.universe_count,
           "calendar_request_count" => length(responses)
         }
       }}
    end
  end

  defp maybe_load_live_payload(
         %SourceRegistry{parser_key: "tw_mops_daily_material_info_json_v1"} = source,
         true
       ) do
    query_date = tw_mops_query_date(source)
    request_body = tw_mops_daily_material_info_request_body(query_date)

    with {:ok, response} <-
           Http.fetch(source.base_url,
             timeout: source_live_timeout(source),
             headers: source_live_headers(source),
             method: :post,
             body: Jason.encode!(request_body),
             content_type: "application/json"
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
           "strategy" => @tw_mops_material_info_strategy,
           "url" => source.base_url,
           "status_code" => response.status_code,
           "bytes" => response.bytes,
           "query_date" => Date.to_iso8601(query_date),
           "roc_year" => Map.fetch!(request_body, "year"),
           "month" => Map.fetch!(request_body, "month"),
           "day" => Map.fetch!(request_body, "day"),
           "records_seen" => tw_mops_daily_material_info_records_seen(response.body),
           "fixture_fallback" => false
         }
       }}
    else
      false -> {:error, :unexpected_status}
      {:error, _reason} = error -> error
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

  defp fetch_de_company_register_support_page(source) do
    url =
      source_config_value(
        source,
        "support_url",
        :support_url,
        @de_company_register_support_url
      )

    case Http.fetch(url,
           timeout: source_live_timeout(source),
           headers: source_live_headers(source)
         ) do
      {:ok, %{status_code: status_code} = response} when status_code in 200..299 ->
        cond do
          not html_content_type?(response.headers) ->
            {:error,
             {:de_company_register_support_unsupported_content_type,
              content_type(response.headers)}}

          not de_company_register_support_page?(response.body) ->
            {:error, :de_company_register_unexpected_support_page}

          true ->
            {:ok, response, response_cookie_header(response.headers)}
        end

      {:ok, response} ->
        {:error, {:de_company_register_support_unexpected_status, response.status_code}}

      {:error, reason} ->
        {:error, {:de_company_register_support_fetch_failed, reason}}
    end
  end

  defp fetch_de_company_register_search_token(source, cookie) do
    url =
      source_config_value(
        source,
        "token_url",
        :token_url,
        @de_company_register_token_url
      )

    case Http.fetch(url,
           timeout: source_live_timeout(source),
           headers: source_live_headers(source) |> add_cookie_header(cookie)
         ) do
      {:ok, %{status_code: status_code} = response} when status_code in 200..299 ->
        with {:ok, decoded} <- Jason.decode(response.body),
             token when is_binary(token) <- Map.get(decoded, "token"),
             200 <- Map.get(decoded, "status") do
          {:ok, token, response, response_cookie_header(response.headers)}
        else
          {:error, reason} -> {:error, {:de_company_register_token_invalid_json, reason}}
          _ -> {:error, :de_company_register_token_unexpected_shape}
        end

      {:ok, response} ->
        {:error, {:de_company_register_token_unexpected_status, response.status_code}}

      {:error, reason} ->
        {:error, {:de_company_register_token_fetch_failed, reason}}
    end
  end

  defp fetch_de_company_register_search_pages(source, token, cookie) do
    max_pages = de_company_register_max_pages_per_poll(source)
    page_size = de_company_register_page_size(source)

    1..max_pages
    |> Enum.reduce_while({:ok, []}, fn page_number, {:ok, pages} ->
      from = (page_number - 1) * page_size
      url = de_company_register_search_url(source, token, from)

      case fetch_de_company_register_search_page(source, url, cookie) do
        {:ok, page} ->
          page =
            page
            |> Map.put("from", from)
            |> Map.put("url", redact_de_company_register_token(url))

          pages = pages ++ [page]
          total_pages = de_company_register_total_pages(page, page_number)

          if page_number >= total_pages or Map.get(page, "records_seen", 0) == 0 do
            {:halt, {:ok, pages}}
          else
            {:cont, {:ok, pages}}
          end

        {:error, reason} ->
          {:halt, {:error, reason}}
      end
    end)
  end

  defp fetch_de_company_register_search_page(source, url, cookie) do
    case Http.fetch(url,
           timeout: source_live_timeout(source),
           headers: source_live_headers(source) |> add_cookie_header(cookie)
         ) do
      {:ok, %{status_code: status_code} = response} when status_code in 200..299 ->
        cond do
          not html_content_type?(response.headers) ->
            {:error,
             {:de_company_register_search_unsupported_content_type,
              content_type(response.headers)}}

          true ->
            with {:ok, payload} <- de_company_register_extract_search_payload(response.body) do
              rows = Map.get(payload, "rows", [])

              {:ok,
               %{
                 "status_code" => response.status_code,
                 "bytes" => response.bytes,
                 "records_seen" => length(rows),
                 "current_page" => Map.get(payload, "current_page"),
                 "total_pages" => Map.get(payload, "total_pages"),
                 "total_results" => Map.get(payload, "total_results"),
                 "has_reached_results_limit" => Map.get(payload, "has_reached_results_limit"),
                 "is_restricted_search" => Map.get(payload, "is_restricted_search"),
                 "data" => rows
               }}
            end
        end

      {:ok, response} ->
        {:error, {:de_company_register_search_unexpected_status, response.status_code}}

      {:error, reason} ->
        {:error, {:de_company_register_search_fetch_failed, reason}}
    end
  end

  defp de_company_register_extract_search_payload(html) when is_binary(html) do
    with {:ok, escaped_payload} <- de_company_register_escaped_search_results(html),
         {:ok, json_text} <- Jason.decode("\"" <> escaped_payload <> "\""),
         {:ok, decoded} <- Jason.decode(json_text),
         %{"searchResults" => search_results} when is_map(search_results) <- decoded,
         entries when is_list(entries) <- Map.get(search_results, "elasticSearchDtos") do
      rows =
        entries
        |> Enum.map(&Map.get(&1, "publicationDto"))
        |> Enum.reject(&is_nil/1)

      {:ok,
       %{
         "rows" => rows,
         "current_page" => Map.get(search_results, "currentPage"),
         "total_pages" => Map.get(search_results, "totalPages"),
         "total_results" => get_in(search_results, ["drilldown", "totalResults"]),
         "has_reached_results_limit" => Map.get(search_results, "hasReachedResultsLimit"),
         "is_restricted_search" => Map.get(search_results, "isRestrictedSearch")
       }}
    else
      {:error, reason} -> {:error, {:de_company_register_search_invalid_payload, reason}}
      _ -> {:error, :de_company_register_search_unexpected_payload}
    end
  end

  defp de_company_register_escaped_search_results(html) do
    marker = "\\\"searchResults\\\":"
    suffix = ",\\\"formType\\\":\\\"CAPITAL_MARKET\\\"}"

    with {start, _length} <- :binary.match(html, marker),
         rest <- binary_part(html, start, byte_size(html) - start),
         {end_offset, suffix_length} <- :binary.match(rest, suffix) do
      {:ok, "{" <> binary_part(rest, 0, end_offset + suffix_length)}
    else
      :nomatch -> {:error, :missing_search_results_marker}
    end
  end

  defp de_company_register_support_page?(body) when is_binary(body) do
    body =~ "Company Register" and
      (body =~ "capital-market" or body =~ "CAPITAL_MARKET" or body =~ "issuer")
  end

  defp de_company_register_support_page?(_body), do: false

  defp de_company_register_search_url(source, token, from) do
    source
    |> source_config_value(
      "search_url_template",
      :search_url_template,
      @de_company_register_search_url_template
    )
    |> to_string()
    |> String.replace("{token}", URI.encode_www_form(token))
    |> String.replace("{searchToken}", URI.encode_www_form(token))
    |> String.replace("{source_date_from}", de_company_register_source_date_from(source))
    |> String.replace("{source_date_to}", de_company_register_source_date_to(source))
    |> String.replace("{from}", to_string(from))
  end

  defp de_company_register_source_date_from(source) do
    source_config_value(
      source,
      "source_date_from",
      :source_date_from,
      Date.utc_today() |> Date.add(-1) |> Date.to_iso8601()
    )
    |> to_string()
  end

  defp de_company_register_source_date_to(source) do
    source_config_value(
      source,
      "source_date_to",
      :source_date_to,
      Date.utc_today() |> Date.to_iso8601()
    )
    |> to_string()
  end

  defp de_company_register_page_size(source) do
    source_config_positive_integer(source, "page_size", :page_size, 30)
  end

  defp de_company_register_max_pages_per_poll(source) do
    source_config_positive_integer(source, "max_pages_per_poll", :max_pages_per_poll, 1)
  end

  defp de_company_register_first_meta([page | _pages], key), do: Map.get(page, key)
  defp de_company_register_first_meta(_pages, _key), do: nil

  defp de_company_register_total_pages(page, default) do
    case Map.get(page, "total_pages") do
      value when is_integer(value) and value > 0 -> value
      _ -> default
    end
  end

  defp de_company_register_records_seen(pages) do
    Enum.reduce(pages, 0, fn page, count -> count + (Map.get(page, "records_seen") || 0) end)
  end

  defp de_company_register_over_page_cap?(pages, max_pages) do
    case de_company_register_first_meta(pages, "total_pages") do
      total_pages when is_integer(total_pages) -> total_pages > max_pages
      _ -> false
    end
  end

  defp redact_de_company_register_token(url) do
    String.replace(url, ~r/searchToken=[^&]+/, "searchToken=<redacted>")
  end

  defp response_cookie_header(headers) do
    headers
    |> Enum.filter(fn {key, _value} -> String.downcase(to_string(key)) == "set-cookie" end)
    |> Enum.map(fn {_key, value} ->
      value
      |> to_string()
      |> String.split(";", parts: 2)
      |> List.first()
      |> String.trim()
    end)
    |> Enum.reject(&(&1 == ""))
    |> case do
      [] -> nil
      cookies -> Enum.join(cookies, "; ")
    end
  end

  defp merge_cookie_headers(nil, nil), do: nil
  defp merge_cookie_headers(cookie, nil), do: cookie
  defp merge_cookie_headers(nil, cookie), do: cookie

  defp merge_cookie_headers(first_cookie, second_cookie) do
    [first_cookie, second_cookie]
    |> Enum.join("; ")
    |> String.split("; ")
    |> Enum.uniq()
    |> Enum.join("; ")
  end

  defp add_cookie_header(headers, nil), do: headers

  defp add_cookie_header(headers, cookie) do
    headers
    |> Enum.reject(fn {key, _value} -> String.downcase(to_string(key)) == "cookie" end)
    |> Kernel.++([{~c"cookie", String.to_charlist(cookie)}])
  end

  defp fetch_blse_issuer_universe(source) do
    url =
      source
      |> source_config_value("blse_ticker_url", :blse_ticker_url, @blse_ticker_url)
      |> to_string()

    case Http.fetch(url,
           timeout: source_live_timeout(source),
           headers: source_live_headers(source)
         ) do
      {:ok, %{status_code: status_code} = response} when status_code in 200..299 ->
        cond do
          not xml_content_type?(response.headers) ->
            {:error, {:blse_ticker_unsupported_content_type, content_type(response.headers)}}

          true ->
            case blse_issuer_universe(response.body) do
              [] -> {:error, :blse_empty_issuer_universe}
              universe -> {:ok, response, universe}
            end
        end

      {:ok, response} ->
        {:error, {:blse_ticker_unexpected_status, response.status_code}}

      {:error, reason} ->
        {:error, {:blse_ticker_fetch_failed, reason}}
    end
  end

  defp blse_issuer_universe(body) when is_binary(body) do
    ~r/<TickerItem>(.*?)<\/TickerItem>/s
    |> Regex.scan(body, capture: :all_but_first)
    |> Enum.map(fn [row] ->
      code = blse_xml_tag(row, "Code")
      issuer = blse_xml_tag(row, "Issuer")
      url = blse_xml_tag(row, "Url")

      %{
        "code" => blse_security_code(code, url),
        "issuer" => issuer,
        "ticker_url" => url
      }
    end)
    |> Enum.filter(&blse_listed_equity_universe_entry?/1)
    |> Enum.uniq_by(& &1["code"])
  end

  defp blse_issuer_universe(_body), do: []

  defp blse_xml_tag(row, tag) do
    case Regex.run(~r/<#{tag}>(.*?)<\/#{tag}>/s, row, capture: :all_but_first) do
      [value] ->
        value
        |> String.replace("&amp;", "&")
        |> String.trim()

      _ ->
        nil
    end
  end

  defp blse_security_code(code, url) do
    cond do
      is_binary(url) ->
        case Regex.run(~r/[?&]code=([^&]+)/i, url, capture: :all_but_first) do
          [url_code] -> URI.decode_www_form(url_code)
          _ -> code
        end

      true ->
        code
    end
  end

  defp blse_listed_equity_universe_entry?(%{"code" => code, "issuer" => issuer})
       when is_binary(code) and is_binary(issuer) do
    String.ends_with?(code, "-R-A")
  end

  defp blse_listed_equity_universe_entry?(_entry), do: false

  defp blse_issuer_window(source, universe) do
    universe_count = length(universe)
    window_size = min(blse_max_issuers_per_poll(source), universe_count)
    offset = blse_issuer_window_offset(source, universe_count)

    %{
      strategy: blse_issuer_window_strategy(source),
      offset: offset,
      size: window_size,
      universe_count: universe_count,
      selected_universe: blse_take_issuer_window(universe, offset, window_size)
    }
  end

  defp blse_issuer_window_payload(issuer_window) do
    %{
      "strategy" => issuer_window.strategy,
      "offset" => issuer_window.offset,
      "size" => issuer_window.size,
      "universe_count" => issuer_window.universe_count
    }
  end

  defp blse_issuer_window_strategy(source) do
    source_config_value(
      source,
      "blse_issuer_window_strategy",
      :blse_issuer_window_strategy,
      "static_offset"
    )
  end

  defp blse_issuer_window_offset(_source, 0), do: 0

  defp blse_issuer_window_offset(source, universe_count) do
    source
    |> source_config_non_negative_integer(
      "blse_issuer_window_offset",
      :blse_issuer_window_offset,
      0
    )
    |> rem(universe_count)
  end

  defp blse_take_issuer_window(_universe, _offset, 0), do: []

  defp blse_take_issuer_window(universe, offset, window_size) do
    universe
    |> Enum.drop(offset)
    |> Kernel.++(Enum.take(universe, offset))
    |> Enum.take(window_size)
  end

  defp blse_max_issuers_per_poll(source) do
    source_config_positive_integer(source, "max_issuers_per_poll", :max_issuers_per_poll, 5)
  end

  defp fetch_blse_issuer_news_responses(source, selected_universe) do
    selected_universe
    |> Enum.reduce_while({:ok, []}, fn %{"code" => code} = universe_entry, {:ok, responses} ->
      url = blse_issuer_news_url(source, code)

      case Http.fetch(url,
             timeout: source_live_timeout(source),
             headers: source_live_headers(source)
           ) do
        {:ok, %{status_code: status_code} = response}
        when status_code in 200..299 ->
          cond do
            not xml_content_type?(response.headers) ->
              {:halt,
               {:error,
                {:blse_issuer_news_unsupported_content_type, code, content_type(response.headers)}}}

            not blse_issuer_news_payload?(response.body) ->
              {:halt, {:error, {:blse_issuer_news_unexpected_payload, code}}}

            true ->
              records_seen = blse_rss_item_count(response.body)

              {:cont,
               {:ok,
                responses ++
                  [
                    %{
                      "code" => code,
                      "issuer" => Map.get(universe_entry, "issuer"),
                      "url" => url,
                      "status_code" => status_code,
                      "bytes" => response.bytes,
                      "records_seen" => records_seen,
                      "records_kept" => min(records_seen, blse_max_news_items_per_issuer(source)),
                      "data" => response.body
                    }
                  ]}}
          end

        {:ok, response} ->
          {:halt, {:error, {:blse_issuer_news_unexpected_status, code, response.status_code}}}

        {:error, reason} ->
          {:halt, {:error, {:blse_issuer_news_fetch_failed, code, reason}}}
      end
    end)
  end

  defp blse_issuer_news_url(source, code) do
    source
    |> source_config_value(
      "blse_issuer_news_url_template",
      :blse_issuer_news_url_template,
      @blse_issuer_news_url_template
    )
    |> to_string()
    |> String.replace("{code}", URI.encode_www_form(code))
    |> String.replace("<CODE>", URI.encode_www_form(code))
  end

  defp blse_max_news_items_per_issuer(source) do
    source_config_positive_integer(
      source,
      "max_news_items_per_issuer",
      :max_news_items_per_issuer,
      5
    )
  end

  defp blse_response_records_seen(responses) do
    Enum.reduce(responses, 0, fn response, count ->
      count + (Map.get(response, "records_seen") || 0)
    end)
  end

  defp blse_rss_item_count(body) when is_binary(body) do
    Regex.scan(~r/<item>/i, body) |> length()
  end

  defp blse_rss_item_count(_body), do: 0

  defp tw_mops_daily_material_info_records_seen(body) when is_binary(body) do
    with {:ok, decoded} <- body |> trim_utf8_bom() |> Jason.decode(),
         %{"result" => %{"data" => rows}} <- decoded,
         true <- is_list(rows) do
      length(rows)
    else
      _ -> 0
    end
  end

  defp tw_mops_daily_material_info_records_seen(_body), do: 0

  defp tw_mops_query_date(source) do
    case source_config_value(source, "live_query_date", :live_query_date, nil) do
      value when is_binary(value) ->
        case Date.from_iso8601(value) do
          {:ok, date} -> date
          _ -> taiwan_today()
        end

      _value ->
        taiwan_today()
    end
  end

  defp taiwan_today do
    DateTime.utc_now()
    |> DateTime.add(8 * 60 * 60, :second)
    |> DateTime.to_date()
  end

  defp tw_mops_daily_material_info_request_body(%Date{} = date) do
    %{
      "year" => to_string(date.year - 1911),
      "month" => to_string(date.month),
      "day" => to_string(date.day)
    }
  end

  defp blse_issuer_news_payload?(body) when is_binary(body) do
    body =~ "<rss" and body =~ "<channel>"
  end

  defp blse_issuer_news_payload?(_body), do: false

  defp sase_selected_issuer_codes(source) do
    source
    |> source_config_string_list(
      "sase_issuer_codes",
      :sase_issuer_codes,
      ["BHTS", "JPES", "BSNL", "ASA", "ALUM"]
    )
    |> Enum.take(sase_max_issuers_per_poll(source))
  end

  defp sase_max_issuers_per_poll(source) do
    source_config_positive_integer(source, "max_issuers_per_poll", :max_issuers_per_poll, 5)
  end

  defp fetch_sase_issuer_announcement_responses(source, selected_codes) do
    selected_codes
    |> Enum.reduce_while({:ok, []}, fn issuer_code, {:ok, responses} ->
      body = sase_issuer_announcement_body(source, issuer_code)

      case Http.fetch(source.base_url,
             timeout: source_live_timeout(source),
             headers: source_live_headers(source),
             method: :post,
             body: body,
             content_type: "application/x-www-form-urlencoded; charset=UTF-8"
           ) do
        {:ok, %{status_code: status_code} = response}
        when status_code in 200..299 ->
          if sase_issuer_announcements_payload?(response.body) do
            records_seen = sase_announcement_count(response.body)

            {:cont,
             {:ok,
              responses ++
                [
                  %{
                    "issuer_code" => issuer_code,
                    "issuer" => sase_known_issuer_name(source, issuer_code),
                    "url" => source.base_url,
                    "status_code" => status_code,
                    "bytes" => response.bytes,
                    "records_seen" => records_seen,
                    "records_kept" => min(records_seen, sase_max_items_per_issuer(source)),
                    "data" => response.body
                  }
                ]}}
          else
            {:halt, {:error, {:sase_issuer_announcements_unexpected_payload, issuer_code}}}
          end

        {:ok, response} ->
          {:halt,
           {:error,
            {:sase_issuer_announcements_unexpected_status, issuer_code, response.status_code}}}

        {:error, reason} ->
          {:halt, {:error, {:sase_issuer_announcements_fetch_failed, issuer_code, reason}}}
      end
    end)
  end

  defp sase_issuer_announcement_body(source, issuer_code) do
    URI.encode_query(%{
      "id" => "0",
      "type" => "24",
      "dateFrom" => "",
      "dateTo" => "",
      "cssClass" => "",
      "symbol" => issuer_code,
      "Months" => "0",
      "lng" => sase_language_id(source),
      "start" => "0",
      "end" => Integer.to_string(sase_max_items_per_issuer(source))
    })
  end

  defp sase_language_id(source),
    do: source_config_value(source, "sase_language_id", :sase_language_id, "1")

  defp sase_max_items_per_issuer(source) do
    source_config_positive_integer(source, "max_items_per_issuer", :max_items_per_issuer, 5)
  end

  defp sase_known_issuer_name(source, issuer_code) do
    known_issuers =
      source
      |> source_config_value("sase_known_issuers", :sase_known_issuers, %{})
      |> case do
        value when is_map(value) -> value
        _ -> %{}
      end

    Map.get(known_issuers, issuer_code)
  end

  defp sase_response_records_seen(responses) do
    Enum.reduce(responses, 0, fn response, count ->
      count + (Map.get(response, "records_seen") || 0)
    end)
  end

  defp sase_announcement_count(body) when is_binary(body) do
    Regex.scan(~r/<ANNOUNCEMENT>/i, body) |> length()
  end

  defp sase_announcement_count(_body), do: 0

  defp sase_issuer_announcements_payload?(body) when is_binary(body) do
    body =~ "<ANNOUNCEMENTS" and (body =~ "<ANNOUNCEMENT>" or body =~ "<ANNOUNCEMENTS />")
  end

  defp sase_issuer_announcements_payload?(_body), do: false

  defp fetch_pse_issuer_universe_pages(source) do
    source
    |> source_config_string_list(
      "pse_issuer_universe_urls",
      :pse_issuer_universe_urls,
      @pse_default_issuer_universe_urls
    )
    |> Enum.reduce_while({:ok, []}, fn url, {:ok, pages} ->
      case Http.fetch(url,
             timeout: source_live_timeout(source),
             headers: source_live_headers(source)
           ) do
        {:ok, %{status_code: status_code} = response}
        when status_code in 200..299 ->
          if html_content_type?(response.headers) do
            {:cont,
             {:ok,
              pages ++
                [
                  %{
                    url: url,
                    market: pse_market_from_url(url),
                    body: response.body,
                    bytes: response.bytes
                  }
                ]}}
          else
            {:halt,
             {:error,
              {:pse_universe_unsupported_content_type, url, content_type(response.headers)}}}
          end

        {:ok, response} ->
          {:halt, {:error, {:pse_universe_unexpected_status, url, response.status_code}}}

        {:error, reason} ->
          {:halt, {:error, {:pse_universe_fetch_failed, url, reason}}}
      end
    end)
  end

  defp pse_issuer_universe(pages) when is_list(pages) do
    universe =
      pages
      |> Enum.flat_map(&pse_issuer_universe_entries/1)
      |> Enum.uniq_by(& &1["isin"])

    case universe do
      [] -> {:error, :pse_empty_issuer_universe}
      entries -> {:ok, entries}
    end
  end

  defp pse_issuer_universe_entries(%{url: url, market: market, body: body}) do
    ~r/\/en\/detail\/([A-Z0-9]{12})/
    |> Regex.scan(body, capture: :all_but_first)
    |> Enum.map(fn [isin] ->
      %{
        "market" => market,
        "isin" => isin,
        "detail_url" => "https://www.pse.cz/en/detail/" <> isin,
        "source_url" => url
      }
    end)
  end

  defp pse_market_from_url(url) do
    url
    |> URI.parse()
    |> Map.get(:path, "")
    |> String.split("/", trim: true)
    |> List.last()
    |> case do
      nil -> "unknown"
      "" -> "unknown"
      market -> market
    end
  end

  defp fetch_pse_issuer_news_responses(source, selected_universe) do
    selected_universe
    |> Enum.reduce_while({:ok, []}, fn %{"isin" => isin} = universe_entry, {:ok, responses} ->
      url = pse_issuer_news_url(source, isin)

      case Http.fetch(url,
             timeout: source_live_timeout(source),
             headers: source_live_headers(source)
           ) do
        {:ok, %{status_code: status_code} = response}
        when status_code in 200..299 ->
          with true <- json_content_type?(response.headers),
               {:ok, decoded} <- Jason.decode(response.body),
               data when is_list(data) <- Map.get(decoded, "data") do
            limited_data = Enum.take(data, pse_max_news_items_per_issuer(source))

            {:cont,
             {:ok,
              responses ++
                [
                  %{
                    "isin" => isin,
                    "market" => Map.get(universe_entry, "market"),
                    "url" => url,
                    "status_code" => status_code,
                    "bytes" => response.bytes,
                    "records_seen" => length(data),
                    "records_kept" => length(limited_data),
                    "data" => limited_data
                  }
                ]}}
          else
            false ->
              {:halt,
               {:error,
                {:pse_news_unsupported_content_type, isin, content_type(response.headers)}}}

            {:error, reason} ->
              {:halt, {:error, {:pse_news_invalid_json, isin, reason}}}

            _shape ->
              {:halt, {:error, {:pse_news_unexpected_json_shape, isin}}}
          end

        {:ok, response} ->
          {:halt, {:error, {:pse_news_unexpected_status, isin, response.status_code}}}

        {:error, reason} ->
          {:halt, {:error, {:pse_news_fetch_failed, isin, reason}}}
      end
    end)
  end

  defp fetch_pse_issuer_calendar_responses(source, selected_universe) do
    selected_universe
    |> Enum.reduce_while({:ok, []}, fn %{"isin" => isin} = universe_entry, {:ok, responses} ->
      url = pse_issuer_calendar_url(source, isin)

      case Http.fetch(url,
             timeout: source_live_timeout(source),
             headers: source_live_headers(source)
           ) do
        {:ok, %{status_code: status_code} = response}
        when status_code in 200..299 ->
          with true <- json_content_type?(response.headers),
               {:ok, decoded} <- Jason.decode(response.body),
               %{"data" => data} when is_list(data) <- Map.get(decoded, "result") do
            limited_data = Enum.take(data, pse_max_calendar_items_per_issuer(source))

            {:cont,
             {:ok,
              responses ++
                [
                  %{
                    "isin" => isin,
                    "market" => Map.get(universe_entry, "market"),
                    "url" => url,
                    "status_code" => status_code,
                    "bytes" => response.bytes,
                    "records_seen" => length(data),
                    "records_kept" => length(limited_data),
                    "data" => limited_data
                  }
                ]}}
          else
            false ->
              {:halt,
               {:error,
                {:pse_calendar_unsupported_content_type, isin, content_type(response.headers)}}}

            {:error, reason} ->
              {:halt, {:error, {:pse_calendar_invalid_json, isin, reason}}}

            _shape ->
              {:halt, {:error, {:pse_calendar_unexpected_json_shape, isin}}}
          end

        {:ok, response} ->
          {:halt, {:error, {:pse_calendar_unexpected_status, isin, response.status_code}}}

        {:error, reason} ->
          {:halt, {:error, {:pse_calendar_fetch_failed, isin, reason}}}
      end
    end)
  end

  defp pse_issuer_news_url(source, isin) do
    source
    |> source_config_value(
      "pse_news_url_template",
      :pse_news_url_template,
      @pse_news_url_template
    )
    |> to_string()
    |> String.replace("{isin}", URI.encode(isin))
    |> String.replace("<ISIN>", URI.encode(isin))
  end

  defp pse_issuer_calendar_url(source, isin) do
    source
    |> source_config_value(
      "pse_calendar_url_template",
      :pse_calendar_url_template,
      @pse_calendar_url_template
    )
    |> to_string()
    |> String.replace("{isin}", URI.encode(isin))
    |> String.replace("<ISIN>", URI.encode(isin))
  end

  defp pse_max_issuers_per_poll(source) do
    source_config_positive_integer(source, "max_issuers_per_poll", :max_issuers_per_poll, 10)
  end

  defp pse_issuer_window(source, universe) do
    universe_count = length(universe)
    window_size = min(pse_max_issuers_per_poll(source), universe_count)
    offset = pse_issuer_window_offset(source, universe_count)

    %{
      strategy: pse_issuer_window_strategy(source),
      offset: offset,
      size: window_size,
      universe_count: universe_count,
      selected_universe: pse_take_issuer_window(universe, offset, window_size)
    }
  end

  defp pse_issuer_window_payload(issuer_window) do
    %{
      "strategy" => issuer_window.strategy,
      "offset" => issuer_window.offset,
      "size" => issuer_window.size,
      "universe_count" => issuer_window.universe_count
    }
  end

  defp pse_issuer_window_strategy(source) do
    source_config_value(
      source,
      "pse_issuer_window_strategy",
      :pse_issuer_window_strategy,
      "static_offset"
    )
  end

  defp pse_issuer_window_offset(_source, 0), do: 0

  defp pse_issuer_window_offset(source, universe_count) do
    source
    |> source_config_non_negative_integer(
      "pse_issuer_window_offset",
      :pse_issuer_window_offset,
      0
    )
    |> rem(universe_count)
  end

  defp pse_take_issuer_window(_universe, _offset, 0), do: []

  defp pse_take_issuer_window(universe, offset, window_size) do
    universe
    |> Enum.drop(offset)
    |> Kernel.++(Enum.take(universe, offset))
    |> Enum.take(window_size)
  end

  defp pse_max_news_items_per_issuer(source) do
    source_config_positive_integer(
      source,
      "max_news_items_per_issuer",
      :max_news_items_per_issuer,
      5
    )
  end

  defp pse_max_calendar_items_per_issuer(source) do
    source_config_positive_integer(
      source,
      "max_calendar_items_per_issuer",
      :max_calendar_items_per_issuer,
      8
    )
  end

  defp disable_live_fixture_fallback?(source) do
    source_config_boolean(
      source,
      "disable_live_fixture_fallback",
      :disable_live_fixture_fallback,
      false
    )
  end

  defp source_config_value(%SourceRegistry{config: config}, string_key, atom_key, default)
       when is_map(config) do
    Map.get(config, string_key) || Map.get(config, atom_key) || default
  end

  defp source_config_value(_source, _string_key, _atom_key, default), do: default

  defp source_config_string_list(source, string_key, atom_key, default) do
    case source_config_value(source, string_key, atom_key, default) do
      values when is_list(values) ->
        values
        |> Enum.filter(&is_binary/1)
        |> case do
          [] -> default
          filtered -> filtered
        end

      value when is_binary(value) ->
        [value]

      _value ->
        default
    end
  end

  defp source_config_positive_integer(source, string_key, atom_key, default) do
    source
    |> source_config_value(string_key, atom_key, default)
    |> case do
      value when is_integer(value) and value > 0 -> value
      value when is_binary(value) -> parse_positive_integer(value, default)
      _value -> default
    end
  end

  defp source_config_non_negative_integer(source, string_key, atom_key, default) do
    source
    |> source_config_value(string_key, atom_key, default)
    |> case do
      value when is_integer(value) and value >= 0 -> value
      value when is_binary(value) -> parse_non_negative_integer(value, default)
      _value -> default
    end
  end

  defp parse_positive_integer(value, default) do
    case Integer.parse(value) do
      {parsed, ""} when parsed > 0 -> parsed
      _ -> default
    end
  end

  defp parse_non_negative_integer(value, default) do
    case Integer.parse(value) do
      {parsed, ""} when parsed >= 0 -> parsed
      _ -> default
    end
  end

  defp source_config_boolean(source, string_key, atom_key, default) do
    case source_config_value(source, string_key, atom_key, default) do
      value when is_boolean(value) -> value
      value when is_binary(value) -> String.downcase(value) == "true"
      _value -> default
    end
  end

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

  defp validate_live_payload(
         %SourceRegistry{parser_key: "cmvm_portal_info_privi_json_v1"},
         response
       ) do
    cond do
      html_content_type?(response.headers) ->
        {:error,
         {:unsupported_live_content_type, "cmvm_portal_info_privi_json_v1",
          content_type(response.headers)}}

      html_payload?(response.body) ->
        {:error, {:unsupported_live_payload, "cmvm_portal_info_privi_json_v1", :html}}

      not json_content_type?(response.headers) ->
        {:error,
         {:unsupported_live_content_type, "cmvm_portal_info_privi_json_v1",
          content_type(response.headers)}}

      not cmvm_portal_info_privi_payload?(response.body) ->
        {:error, {:unsupported_live_payload, "cmvm_portal_info_privi_json_v1", :unexpected_json}}

      true ->
        :ok
    end
  end

  defp validate_live_payload(
         %SourceRegistry{parser_key: "oekb_oam_issuer_info_json_v1"},
         response
       ) do
    cond do
      html_content_type?(response.headers) ->
        {:error,
         {:unsupported_live_content_type, "oekb_oam_issuer_info_json_v1",
          content_type(response.headers)}}

      html_payload?(response.body) ->
        {:error, {:unsupported_live_payload, "oekb_oam_issuer_info_json_v1", :html}}

      not json_content_type?(response.headers) ->
        {:error,
         {:unsupported_live_content_type, "oekb_oam_issuer_info_json_v1",
          content_type(response.headers)}}

      not oekb_oam_issuer_info_payload?(response.body) ->
        {:error, {:unsupported_live_payload, "oekb_oam_issuer_info_json_v1", :unexpected_json}}

      true ->
        :ok
    end
  end

  defp validate_live_payload(
         %SourceRegistry{parser_key: "cse_oam_listing_versions_json_v1"},
         response
       ) do
    cond do
      html_content_type?(response.headers) ->
        {:error,
         {:unsupported_live_content_type, "cse_oam_listing_versions_json_v1",
          content_type(response.headers)}}

      html_payload?(response.body) ->
        {:error, {:unsupported_live_payload, "cse_oam_listing_versions_json_v1", :html}}

      not json_content_type?(response.headers) ->
        {:error,
         {:unsupported_live_content_type, "cse_oam_listing_versions_json_v1",
          content_type(response.headers)}}

      not cse_oam_listing_versions_payload?(response.body) ->
        {:error,
         {:unsupported_live_payload, "cse_oam_listing_versions_json_v1", :unexpected_json}}

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
         %SourceRegistry{parser_key: "lt_oam_regulated_information_html_v1"},
         response
       ) do
    cond do
      not html_content_type?(response.headers) ->
        {:error,
         {:unsupported_live_content_type, "lt_oam_regulated_information_html_v1",
          content_type(response.headers)}}

      not lt_oam_regulated_information_payload?(response.body) ->
        {:error,
         {:unsupported_live_payload, "lt_oam_regulated_information_html_v1", :unexpected_html}}

      true ->
        :ok
    end
  end

  defp validate_live_payload(
         %SourceRegistry{parser_key: "lv_csri_regulated_information_html_v1"},
         response
       ) do
    cond do
      not html_content_type?(response.headers) ->
        {:error,
         {:unsupported_live_content_type, "lv_csri_regulated_information_html_v1",
          content_type(response.headers)}}

      not lv_csri_regulated_information_payload?(response.body) ->
        {:error,
         {:unsupported_live_payload, "lv_csri_regulated_information_html_v1", :unexpected_html}}

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

  defp validate_live_payload(
         %SourceRegistry{parser_key: "malta_mse_announcements_html_v1"},
         response
       ) do
    cond do
      not html_content_type?(response.headers) ->
        {:error,
         {:unsupported_live_content_type, "malta_mse_announcements_html_v1",
          content_type(response.headers)}}

      not malta_mse_announcements_payload?(response.body) ->
        {:error, {:unsupported_live_payload, "malta_mse_announcements_html_v1", :unexpected_html}}

      true ->
        :ok
    end
  end

  defp validate_live_payload(
         %SourceRegistry{parser_key: "bg_x3news_issuer_disclosures_html_v1"},
         response
       ) do
    cond do
      not html_content_type?(response.headers) ->
        {:error,
         {:unsupported_live_content_type, "bg_x3news_issuer_disclosures_html_v1",
          content_type(response.headers)}}

      not x3news_issuer_disclosures_payload?(response.body) ->
        {:error,
         {:unsupported_live_payload, "bg_x3news_issuer_disclosures_html_v1", :unexpected_html}}

      true ->
        :ok
    end
  end

  defp validate_live_payload(
         %SourceRegistry{parser_key: "kap_company_notifications_html_v1"},
         response
       ) do
    cond do
      not html_content_type?(response.headers) ->
        {:error,
         {:unsupported_live_content_type, "kap_company_notifications_html_v1",
          content_type(response.headers)}}

      not kap_company_notifications_payload?(response.body) ->
        {:error,
         {:unsupported_live_payload, "kap_company_notifications_html_v1", :unexpected_html}}

      true ->
        :ok
    end
  end

  defp validate_live_payload(
         %SourceRegistry{parser_key: "mse_free_market_announcements_html_v1"},
         response
       ) do
    cond do
      not html_content_type?(response.headers) ->
        {:error,
         {:unsupported_live_content_type, "mse_free_market_announcements_html_v1",
          content_type(response.headers)}}

      not mse_free_market_announcements_payload?(response.body) ->
        {:error,
         {:unsupported_live_payload, "mse_free_market_announcements_html_v1", :unexpected_html}}

      true ->
        :ok
    end
  end

  defp validate_live_payload(
         %SourceRegistry{parser_key: "seinet_public_documents_json_v1"},
         response
       ) do
    cond do
      not json_content_type?(response.headers) ->
        {:error,
         {:unsupported_live_content_type, "seinet_public_documents_json_v1",
          content_type(response.headers)}}

      not seinet_public_documents_payload?(response.body) ->
        {:error, {:unsupported_live_payload, "seinet_public_documents_json_v1", :unexpected_json}}

      true ->
        :ok
    end
  end

  defp validate_live_payload(
         %SourceRegistry{parser_key: "mnse_corporate_news_html_v1"},
         response
       ) do
    cond do
      not html_content_type?(response.headers) ->
        {:error,
         {:unsupported_live_content_type, "mnse_corporate_news_html_v1",
          content_type(response.headers)}}

      not mnse_corporate_news_payload?(response.body) ->
        {:error, {:unsupported_live_payload, "mnse_corporate_news_html_v1", :unexpected_html}}

      true ->
        :ok
    end
  end

  defp validate_live_payload(
         %SourceRegistry{parser_key: "md_msi_regulated_information_html_v1"},
         response
       ) do
    cond do
      not html_content_type?(response.headers) ->
        {:error,
         {:unsupported_live_content_type, "md_msi_regulated_information_html_v1",
          content_type(response.headers)}}

      not md_msi_regulated_information_payload?(response.body) ->
        {:error,
         {:unsupported_live_payload, "md_msi_regulated_information_html_v1", :unexpected_html}}

      true ->
        :ok
    end
  end

  defp validate_live_payload(
         %SourceRegistry{parser_key: "dfsa_oam_company_announcements_json_v1"},
         response
       ) do
    cond do
      not json_content_type?(response.headers) ->
        {:error,
         {:unsupported_live_content_type, "dfsa_oam_company_announcements_json_v1",
          content_type(response.headers)}}

      not dfsa_oam_company_announcements_payload?(response.body) ->
        {:error,
         {:unsupported_live_payload, "dfsa_oam_company_announcements_json_v1", :unexpected_json}}

      true ->
        :ok
    end
  end

  defp validate_live_payload(
         %SourceRegistry{parser_key: "set_thailand_company_news_json_v1"},
         response
       ) do
    cond do
      not json_content_type?(response.headers) ->
        {:error,
         {:unsupported_live_content_type, "set_thailand_company_news_json_v1",
          content_type(response.headers)}}

      not set_thailand_company_news_payload?(response.body) ->
        {:error,
         {:unsupported_live_payload, "set_thailand_company_news_json_v1", :unexpected_json}}

      true ->
        :ok
    end
  end

  defp validate_live_payload(
         %SourceRegistry{parser_key: "tw_mops_daily_material_info_json_v1"},
         response
       ) do
    cond do
      not json_content_type?(response.headers) ->
        {:error,
         {:unsupported_live_content_type, "tw_mops_daily_material_info_json_v1",
          content_type(response.headers)}}

      not tw_mops_daily_material_info_payload?(response.body) ->
        {:error,
         {:unsupported_live_payload, "tw_mops_daily_material_info_json_v1", :unexpected_json}}

      true ->
        :ok
    end
  end

  defp validate_live_payload(%SourceRegistry{parser_key: "belex_issuer_news_html_v1"}, response) do
    cond do
      not html_content_type?(response.headers) ->
        {:error,
         {:unsupported_live_content_type, "belex_issuer_news_html_v1",
          content_type(response.headers)}}

      not belex_issuer_news_payload?(response.body) ->
        {:error, {:unsupported_live_payload, "belex_issuer_news_html_v1", :unexpected_html}}

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

  defp xml_content_type?(headers) do
    headers
    |> content_type()
    |> String.downcase()
    |> String.contains?("xml")
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

  defp cmvm_portal_info_privi_payload?(body) when is_binary(body) do
    body =~ "\"InfoPrivi\"" and body =~ "\"List\"" and body =~ "\"Desc\"" and body =~ "\"Tipo\""
  end

  defp cmvm_portal_info_privi_payload?(_body), do: false

  defp oekb_oam_issuer_info_payload?(body) when is_binary(body) do
    body =~ "\"anzahlTreffer\"" and body =~ "\"dokumente\"" and
      body =~ "\"uploadzeitpunkt\"" and body =~ "\"emittent\""
  end

  defp oekb_oam_issuer_info_payload?(_body), do: false

  defp cse_oam_listing_versions_payload?(body) when is_binary(body) do
    body =~ "\"content\"" and body =~ "\"listedCompanyEnglish\"" and
      body =~ "\"publicationTimestamp\"" and body =~ "\"infoCategoriesNameEnglish\""
  end

  defp cse_oam_listing_versions_payload?(_body), do: false

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

  defp lt_oam_regulated_information_payload?(body) when is_binary(body) do
    body =~ "OAM, Officially Appointed Mechanism" and
      body =~ "Nasdaq Vilnius listed issuers" and
      body =~ "<nef-table-row class=\"message-row\"" and
      body =~ "/view/"
  end

  defp lt_oam_regulated_information_payload?(_body), do: false

  defp lv_csri_regulated_information_payload?(body) when is_binary(body) do
    body =~ "LATEST DOCUMENTS" and
      body =~ "csridocumentsdetails" and
      body =~ "Date Time" and
      body =~ "Issuer"
  end

  defp lv_csri_regulated_information_payload?(_body), do: false

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

  defp malta_mse_announcements_payload?(body) when is_binary(body) do
    body =~ "Announcements - Malta Stock Exchange" and
      body =~ "box event-box" and
      body =~ "cdn.borzamalta.com.mt/download/announcements/"
  end

  defp malta_mse_announcements_payload?(_body), do: false

  defp x3news_issuer_disclosures_payload?(body) when is_binary(body) do
    body =~ "x3news_logo" and
      body =~ "class=\"news-row\"" and
      body =~ "newsHeaderLink show-date-on-right" and
      body =~ "javascript:showNews"
  end

  defp x3news_issuer_disclosures_payload?(_body), do: false

  defp kap_company_notifications_payload?(body) when is_binary(body) do
    body =~ "kap.org.tr" and
      body =~ ~s(\\"data\\":[) and
      body =~ ~s(\\"disclosureBasic\\") and
      body =~ ~s(\\"SERVER_BASE_URL\\":\\"https://kapsitebackend.mkk.com.tr\\")
  end

  defp kap_company_notifications_payload?(_body), do: false

  defp mse_free_market_announcements_payload?(body) when is_binary(body) do
    body =~ "Macedonian Stock Exchange" and
      body =~ "Announcements from companies on the Free Market" and
      body =~ "container-announcement166b"
  end

  defp mse_free_market_announcements_payload?(_body), do: false

  defp seinet_public_documents_payload?(body) when is_binary(body) do
    body =~ "\"isSuccess\":true" and
      body =~ "\"data\":[" and
      body =~ "\"documentId\"" and
      body =~ "\"publishedDate\"" and
      body =~ "\"issuer\""
  end

  defp seinet_public_documents_payload?(_body), do: false

  defp mnse_corporate_news_payload?(body) when is_binary(body) do
    body =~ "Korporativne novosti" and
      body =~ "novostiDate" and
      body =~ "/upload/documents/issuer/"
  end

  defp mnse_corporate_news_payload?(_body), do: false

  defp md_msi_regulated_information_payload?(body) when is_binary(body) do
    body =~ "Company name" and body =~ "Document type" and body =~ "displayfile"
  end

  defp md_msi_regulated_information_payload?(_body), do: false

  defp dfsa_oam_company_announcements_payload?(body) when is_binary(body) do
    with {:ok, %{"data" => %{"rows" => rows}}} <- Jason.decode(body) do
      Enum.any?(rows, fn
        %{
          "id" => _id,
          "HeadlineColumn" => _headline,
          "IssuerColumn" => _issuer,
          "PublicationDateColumn" => _published_at
        } ->
          true

        _row ->
          false
      end)
    else
      _ -> false
    end
  end

  defp dfsa_oam_company_announcements_payload?(_body), do: false

  defp set_thailand_company_news_payload?(body) when is_binary(body) do
    with {:ok, %{"newsGroups" => groups}} when is_list(groups) <- Jason.decode(body) do
      Enum.any?(groups, fn
        %{"newsInfoList" => records} when is_list(records) ->
          Enum.any?(records, fn
            %{
              "id" => _id,
              "datetime" => _datetime,
              "symbol" => _symbol,
              "headline" => _headline,
              "url" => _url
            } ->
              true

            _record ->
              false
          end)

        _group ->
          false
      end)
    else
      _ -> false
    end
  end

  defp set_thailand_company_news_payload?(_body), do: false

  defp tw_mops_daily_material_info_payload?(body) when is_binary(body) do
    with {:ok, %{"code" => 200, "result" => %{"data" => rows}}} <-
           body |> trim_utf8_bom() |> Jason.decode() do
      is_list(rows)
    else
      _ -> false
    end
  end

  defp tw_mops_daily_material_info_payload?(_body), do: false

  defp trim_utf8_bom(<<0xEF, 0xBB, 0xBF, rest::binary>>), do: rest
  defp trim_utf8_bom(value), do: value

  defp belex_issuer_news_payload?(body) when is_binary(body) do
    body =~ "News from Issuers" and
      body =~ ~s(id="t5") and
      body =~ ~s(class="vest") and
      body =~ "/eng/trgovanje/vesti/hartija/"
  end

  defp belex_issuer_news_payload?(_body), do: false

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
