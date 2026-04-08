defmodule DisclosureAutomation.Runtime.SECAdapter do
  @moduledoc false

  @behaviour DisclosureAutomation.Runtime.Adapter

  alias DisclosureAutomation.Fixtures
  alias DisclosureAutomation.Http
  alias DisclosureAutomation.Schema.SourceRegistry

  @cursor_key "latest_accession_seen"

  @impl true
  def discover(%SourceRegistry{} = source, opts \\ []) do
    use_live_fetch = Keyword.get(opts, :use_live_fetch, true)
    form_types = supported_forms(source)

    with {:ok, payload} <- load_discovery_payload(source, use_live_fetch) do
      payload
      |> parse_atom_feed(form_types)
      |> then(&{:ok, &1})
    end
  end

  @impl true
  def hydrate(%SourceRegistry{} = source, discovery_item, opts \\ []) do
    use_live_fetch = Keyword.get(opts, :use_live_fetch, true)
    fixtures = source.config["fixtures"] || %{}

    with {:ok, detail_payload} <-
           load_document(
             discovery_item.detail_url,
             get_in(fixtures, ["detail_pages", discovery_item.accession_no]),
             use_live_fetch
           ),
         {:ok, submission_payload} <-
           load_document(
             discovery_item.submission_text_url,
             get_in(fixtures, ["submission_texts", discovery_item.accession_no_nodash]),
             use_live_fetch
           ) do
      {:ok,
       %{
         discovery_item: discovery_item,
         detail_document: %{
           external_id: "#{discovery_item.accession_no}:detail-index",
           document_identity: "#{discovery_item.accession_no}:detail-index",
           document_type: "detail_index",
           document_role: "discovery_detail",
           mime_type: "text/html",
           url: discovery_item.detail_url,
           body_text: detail_payload.raw,
           published_at: discovery_item.accepted_at,
           metadata: %{"mode" => detail_payload.mode, "fixture" => detail_payload.fixture_path}
         },
         submission_document: %{
           external_id: "#{discovery_item.accession_no}:submission-text",
           document_identity: "#{discovery_item.accession_no}:submission-text",
           document_type: "submission_text",
           document_role: "primary_filing_text",
           mime_type: "text/plain",
           url: discovery_item.submission_text_url,
           body_text: submission_payload.raw,
           published_at: discovery_item.accepted_at,
           metadata: %{
             "mode" => submission_payload.mode,
             "fixture" => submission_payload.fixture_path
           }
         },
         accepted_at_local: discovery_item.accepted_at_local,
         accepted_at_utc: discovery_item.accepted_at,
         accepted_time_fallback: discovery_item.accepted_time_fallback
       }}
    end
  end

  @impl true
  def parse(%SourceRegistry{} = source, hydrated_item, _opts \\ []) do
    discovery_item = hydrated_item.discovery_item
    form_type = discovery_item.form_type

    if form_type not in supported_forms(source) do
      {:ok, []}
    else
      submission_text = hydrated_item.submission_document.body_text

      accepted_at =
        hydrated_item.accepted_at_utc || parse_submission_datetime(submission_text) ||
          discovery_item.accepted_at

      company_name = parse_header_field(submission_text, ~r/<COMPANY CONFORMED NAME>\s*(.+)/)
      cik = parse_header_field(submission_text, ~r/<CENTRAL INDEX KEY>\s*(\d+)/)
      filing_date = parse_header_field(submission_text, ~r/<FILING DATE>\s*(\d{8})/)
      excerpt = extract_excerpt(submission_text)

      {:ok,
       [
         %{
           event_key: source_event_key(form_type, discovery_item.accession_no),
           external_event_key: discovery_item.accession_no,
           parser_key: "sec_submission_text_v1",
           event_family: infer_event_family(form_type, submission_text),
           occurred_at: accepted_at,
           status: "parsed",
           payload: %{
             "accession_no" => discovery_item.accession_no,
             "accession_no_nodash" => discovery_item.accession_no_nodash,
             "form_type" => form_type,
             "company_name" => company_name || discovery_item.company_name,
             "cik" => cik || discovery_item.cik,
             "filing_date" => filing_date,
             "headline_local" => discovery_item.headline,
             "detail_url" => discovery_item.detail_url,
             "submission_text_url" => discovery_item.submission_text_url,
             "accepted_at" => iso8601(accepted_at),
             "accepted_at_local" => hydrated_item.accepted_at_local,
             "accepted_time_fallback" => hydrated_item.accepted_time_fallback,
             "atom_updated_at" => iso8601(discovery_item.atom_updated_at || discovery_item.accepted_at),
             "fact_summary_ko" => summarize_ko(form_type, excerpt),
             "why_important_ko" => why_important_ko(form_type),
             "raw_excerpt" => excerpt,
             "issuer_jurisdiction_raw" =>
               parse_header_field(
                 submission_text,
                 ~r/<(?:STATE OF INCORPORATION|JURISDICTION OF INCORPORATION)>\s*(.+)/
               ),
             "home_market_region_code" => nil
           },
           metadata: %{
             "supported_forms_now" => supported_forms(source),
             "planned_forms_next" => planned_forms(source)
           }
         }
       ]}
    end
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
    form_type = payload["form_type"] || "6-K"
    cik = payload["cik"] || "unknown"

    filing_date =
      payload["filing_date"] ||
        filing_date_from_local(payload["accepted_at_local"], published_at, digest_date)

    canonical_event_type = infer_canonical_event_type(form_type, payload["raw_excerpt"] || "")
    event_family = raw_event.event_family || infer_event_family(form_type, payload["raw_excerpt"] || "")

    event_id =
      build_temporary_deterministic_canonical_event_id(
        cik,
        filing_date,
        canonical_event_type,
        event_family,
        payload["accession_no"]
      )

    region_code = source.region_code || "us"

    home_market_region_code =
      payload["home_market_region_code"] || source.default_home_market_region_code

    contract_v1 = %{
      "event_id" => event_id,
      "dedupe_key" =>
        "sec|#{cik}|#{filing_date}|#{String.downcase(form_type)}|#{slug(event_family)}",
      "issuer_entity_key" => "cik:#{cik}",
      "issuer_ids" => %{"cik" => cik},
      "issuer_name_local" => payload["company_name"],
      "issuer_name_en" => payload["company_name"],
      "headline_local" => payload["headline_local"],
      "headline_ko" => headline_ko(form_type),
      "fact_summary_ko" => payload["fact_summary_ko"],
      "why_important_ko" => payload["why_important_ko"],
      "canonical_event_type" => canonical_event_type,
      "event_family" => event_family,
      "official_storage_name" => "SEC EDGAR",
      "official_source_name" => "SEC EDGAR Filing Detail Index",
      "official_source_url" => payload["detail_url"],
      "discovery_source_name" => "SEC current filings atom",
      "discovery_source_url" => source.base_url,
      "raw_source_type" => form_type,
      "source_tier" => "official_regulatory_storage",
      "country" => nil,
      "region_code" => region_code,
      "home_market_region_code" => home_market_region_code,
      "published_at_utc" => iso8601(published_at),
      "published_at_local" => payload["accepted_at_local"],
      "filing_date_local" => filing_date_local_from(payload["accepted_at_local"], published_at),
      "importance_band" => infer_importance_band(form_type),
      "source_meta" => %{
        "atom_updated_at" => payload["atom_updated_at"],
        "accepted_time_fallback" => payload["accepted_time_fallback"],
        "issuer_jurisdiction_raw" => payload["issuer_jurisdiction_raw"]
      },
      "risk_flags" =>
        (if payload["accepted_time_fallback"], do: ["accepted_time_parse_fallback"], else: []) ++
          ["home_market_overlap_review_pending"],
      "portable_citations" => [
        %{
          "source_name" => "SEC EDGAR Filing Detail Index",
          "claim_supported" => "accession, filing form, accepted time, and detail index anchor",
          "note" => payload["detail_url"]
        },
        %{
          "source_name" => "SEC EDGAR Complete Submission Text File",
          "claim_supported" => "submission text used for runtime normalization",
          "note" => payload["submission_text_url"]
        }
      ]
    }

    {:ok,
     %{
       contract_v1: contract_v1,
       digest_date: digest_date,
       edition: edition,
       story_key: event_id,
       headline: payload["headline_local"] || headline_ko(form_type),
       summary: payload["fact_summary_ko"],
       canonical_url: payload["detail_url"],
       published_at: published_at,
       tickers: [],
       regions: [region_code],
       sectors: ["regulatory"],
       sentiment_label: "neutral",
       relevance_score: Decimal.new("0.900"),
       priority_rank: nil,
       duplicate_group_key: payload["accession_no"],
       status: "ready"
     }}
  end

  def cursor_key, do: @cursor_key

  defp supported_forms(source) do
    source.config["supported_forms_now"] || ["6-K"]
  end

  defp planned_forms(source) do
    source.config["planned_forms_next"] || ["8-K", "SC TO-T", "SC 14D-9", "SC 13D/A"]
  end

  defp load_discovery_payload(source, true) do
    with {:ok, response} <- Http.fetch(source.base_url, timeout: 8_000),
         true <- response.status_code in 200..299 do
      {:ok, response.body}
    else
      _ -> load_fixture(source, get_in(source.config, ["fixtures", "discovery_feed"]))
    end
  end

  defp load_discovery_payload(source, false),
    do: load_fixture(source, get_in(source.config, ["fixtures", "discovery_feed"]))

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

  defp load_fixture(_source, fixture_path) do
    with {:ok, payload} <- Fixtures.load_source_payload(fixture_path) do
      {:ok, payload.raw}
    end
  end

  defp parse_atom_feed(raw, supported_forms) do
    with {:ok, document} <- parse_xml(raw) do
      :xmerl_xpath.string(~c"/*[local-name()='feed']/*[local-name()='entry']", document)
      |> Enum.map(&parse_atom_entry/1)
      |> Enum.filter(&(&1.form_type in supported_forms))
      |> Enum.sort_by(&sort_key/1, {:desc, DateTime})
    else
      _ -> []
    end
  end

  defp parse_atom_entry(entry) do
    href =
      entry
      |> :xmerl_xpath.string(~c"string(*[local-name()='link']/@href)")
      |> to_string()
      |> String.trim()

    accession_no =
      href
      |> String.split("/")
      |> List.last()
      |> String.replace("-index.html", "")

    accession_no_nodash = String.replace(accession_no, "-", "")
    updated = xpath_string(entry, ~c"string(*[local-name()='updated'])")
    headline = xpath_string(entry, ~c"string(*[local-name()='title'])") || "SEC filing"

    accepted_chronology = accepted_times_or_fallback_from_detail(href, parse_iso8601(updated))

    %{
      accession_no: accession_no,
      accession_no_nodash: accession_no_nodash,
      atom_updated_at: parse_iso8601(updated),
      accepted_at: accepted_chronology.accepted_at_utc,
      accepted_at_local: accepted_chronology.accepted_at_local,
      accepted_time_fallback: accepted_chronology.accepted_time_fallback,
      detail_url: href,
      submission_text_url:
        "https://www.sec.gov/Archives/edgar/data/#{normalize_cik(path_cik_from_url(href))}/#{accession_no_nodash}/#{accession_no_nodash}.txt",
      company_name: headline |> String.split(" - ") |> List.first(),
      cik: normalize_cik(path_cik_from_url(href)),
      form_type: headline |> form_type_from_title(),
      headline: headline
    }
  end

  defp form_type_from_title(title) do
    cond do
      String.contains?(title, "6-K") -> "6-K"
      String.contains?(title, "8-K") -> "8-K"
      String.contains?(title, "SC TO-T") -> "SC TO-T"
      String.contains?(title, "SC 14D-9") -> "SC 14D-9"
      String.contains?(title, "13D/A") -> "SC 13D/A"
      true -> "UNKNOWN"
    end
  end

  defp path_cik_from_url(url) do
    case Regex.run(~r|/data/(\d+)/|, url) do
      [_, cik] -> cik
      _ -> ""
    end
  end

  defp normalize_cik(""), do: nil
  defp normalize_cik(cik), do: String.pad_leading(cik, 10, "0")

  defp parse_xml(raw_payload) do
    try do
      {document, _rest} = :xmerl_scan.string(String.to_charlist(raw_payload), quiet: true)
      {:ok, document}
    rescue
      _ -> {:error, :invalid_xml}
    catch
      _, _ -> {:error, :invalid_xml}
    end
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

  defp parse_submission_datetime(nil), do: nil

  defp parse_submission_datetime(text) do
    case Regex.run(~r/<ACCEPTANCE-DATETIME>\s*(\d{14})/, text) do
      [_, value] ->
        with {:ok, naive} <-
               NaiveDateTime.new(
                 String.slice(value, 0, 4) |> String.to_integer(),
                 String.slice(value, 4, 2) |> String.to_integer(),
                 String.slice(value, 6, 2) |> String.to_integer(),
                 String.slice(value, 8, 2) |> String.to_integer(),
                 String.slice(value, 10, 2) |> String.to_integer(),
                 String.slice(value, 12, 2) |> String.to_integer(),
                 {0, 6}
               ),
             {:ok, dt} <- DateTime.from_naive(naive, "Etc/UTC") do
          dt
        else
          _ -> nil
        end

      _ ->
        nil
    end
  end

  defp parse_header_field(text, regex) when is_binary(text) do
    case Regex.run(regex, text) do
      [_, value] -> String.trim(value)
      _ -> nil
    end
  end

  defp extract_excerpt(text) when is_binary(text) do
    text
    |> String.split("<TEXT>")
    |> List.last()
    |> String.replace(~r/\s+/, " ")
    |> String.slice(0, 480)
  end

  defp infer_event_family("6-K", text) do
    if String.contains?(String.downcase(text), "recapitalization") do
      "foreign_issuer_recapitalization"
    else
      "foreign_issuer_material_update"
    end
  end

  defp infer_event_family("8-K", _text), do: "current_report"
  defp infer_event_family("SC TO-T", _text), do: "cash_tender_offer"
  defp infer_event_family("SC 14D-9", _text), do: "target_response_statement"
  defp infer_event_family("SC 13D/A", _text), do: "control_change_watch"
  defp infer_event_family(_form, _text), do: "sec_material_event"

  defp infer_canonical_event_type("SC TO-T", _), do: "tender_offer_or_go_private"
  defp infer_canonical_event_type("SC 14D-9", _), do: "tender_offer_or_go_private"
  defp infer_canonical_event_type("SC 13D/A", _), do: "major_shareholding_or_insider_trade"

  defp infer_canonical_event_type("6-K", excerpt) do
    if String.contains?(String.downcase(excerpt), "recapitalization") do
      "bankruptcy_or_restructuring"
    else
      "major_investment_or_asset_sale"
    end
  end

  defp infer_canonical_event_type("8-K", _), do: "major_investment_or_asset_sale"
  defp infer_canonical_event_type(_, _), do: "major_investment_or_asset_sale"

  defp summarize_ko("6-K", excerpt),
    do:
      "외국발행인 보고서 6-K가 수집됐고, submission text를 기준으로 요약한 본문 일부는 다음과 같다: #{excerpt}"

  defp summarize_ko(form_type, excerpt),
    do: "#{form_type} filing이 수집됐고 submission text 기준 요약 일부는 다음과 같다: #{excerpt}"

  defp why_important_ko("6-K"), do: "외국발행인 중요 업데이트다."
  defp why_important_ko("8-K"), do: "미국 현재보고서 업데이트다."
  defp why_important_ko("SC TO-T"), do: "공개매수 개시 문서다."
  defp why_important_ko("SC 14D-9"), do: "대상회사 의견서다."
  defp why_important_ko("SC 13D/A"), do: "대량보유·지배구조 변화 감시 문서다."
  defp why_important_ko(_), do: "중요 SEC 문서다."

  defp headline_ko("6-K"), do: "외국발행인 보고서(Form 6-K)"
  defp headline_ko("8-K"), do: "현재보고서(Form 8-K)"
  defp headline_ko("SC TO-T"), do: "제3자 공개매수 신고서(SC TO-T)"
  defp headline_ko("SC 14D-9"), do: "대상회사 의견서(SC 14D-9)"
  defp headline_ko("SC 13D/A"), do: "대량보유 변경보고서(13D/A)"
  defp headline_ko(_), do: "SEC filing"

  defp infer_importance_band("6-K"), do: "P1"
  defp infer_importance_band("SC TO-T"), do: "P1"
  defp infer_importance_band("8-K"), do: "P1"
  defp infer_importance_band(_), do: "P2"

  defp source_event_key(form_type, accession_no) do
    "sec:#{String.downcase(String.replace(form_type, " ", "-"))}:#{accession_no}"
  end

  defp build_temporary_deterministic_canonical_event_id(
         cik,
         filing_date,
         canonical_event_type,
         event_family,
         accession_no
       ) do
    short =
      accession_no
      |> to_string()
      |> String.replace("-", "")
      |> String.slice(-6, 6)

    family_token = normalize_id_token_preserve_underscore(event_family)
    "us.sec.#{cik}.#{filing_date}.#{canonical_event_type}.#{family_token}.#{short}"
  end

  defp normalize_id_token_preserve_underscore(value) do
    value
    |> to_string()
    |> String.downcase()
    |> String.replace(~r/[^a-z0-9_]+/u, "-")
    |> String.trim("-")
  end

  defp slug(value) do
    value
    |> to_string()
    |> String.downcase()
    |> String.replace(~r/[^a-z0-9]+/u, "-")
    |> String.trim("-")
  end

  defp accepted_times_or_fallback_from_detail(detail_url, atom_updated_at) do
    case fixture_detail_path_from_url(detail_url) do
      nil ->
        fallback_times_from_atom_updated(atom_updated_at)

      path ->
        case File.read(Path.expand(path, Application.fetch_env!(:disclosure_automation, :fixtures_root))) do
          {:ok, html} ->
            case extract_accepted_times(html) do
              {:ok, accepted} ->
                %{
                  accepted_at_utc: accepted.accepted_at_utc,
                  accepted_at_local: accepted.accepted_at_local,
                  accepted_time_fallback: false
                }

              {:error, _} ->
                fallback_times_from_atom_updated(atom_updated_at)
            end

          _ ->
            fallback_times_from_atom_updated(atom_updated_at)
        end
    end
  end

  defp fixture_detail_path_from_url(url) do
    acc =
      url
      |> String.split("/")
      |> List.last()
      |> String.replace("-index.htm", "")
      |> String.replace("-index.html", "")

    "source_payloads/sec_#{acc}_index.html"
  end

  defp extract_accepted_times(detail_index_html) do
    case Regex.run(
           ~r/Accepted\s+([0-9]{4}-[0-9]{2}-[0-9]{2})\s+([0-9]{2}:[0-9]{2}:[0-9]{2})/i,
           detail_index_html,
           capture: :all_but_first
         ) do
      [date, time] ->
        with {:ok, naive} <- NaiveDateTime.from_iso8601("#{date} #{time}"),
             {offset_seconds, offset_string} <- sec_eastern_offset_for(naive),
             accepted_utc <- NaiveDateTime.add(naive, offset_seconds, :second),
             {:ok, accepted_at_utc} <- DateTime.from_naive(accepted_utc, "Etc/UTC") do
          {:ok,
           %{accepted_at_local: "#{date}T#{time}#{offset_string}", accepted_at_utc: accepted_at_utc}}
        else
          _ -> {:error, :invalid_accepted_time}
        end

      _ ->
        {:error, :accepted_time_not_found}
    end
  end

  defp fallback_times_from_atom_updated(%DateTime{} = atom_updated_at) do
    {offset_seconds, offset_string} = sec_eastern_offset_for_utc(atom_updated_at)

    accepted_local_naive =
      atom_updated_at |> DateTime.add(offset_seconds, :second) |> DateTime.to_naive()

    %{
      accepted_at_local: "#{NaiveDateTime.to_iso8601(accepted_local_naive)}#{offset_string}",
      accepted_at_utc: atom_updated_at,
      accepted_time_fallback: true
    }
  end

  defp fallback_times_from_atom_updated(_),
    do: %{accepted_at_local: nil, accepted_at_utc: nil, accepted_time_fallback: true}

  defp sec_eastern_offset_for(%NaiveDateTime{} = naive) do
    year = naive.year
    dst_start_day = nth_weekday_of_month(year, 3, 7, 2)
    dst_end_day = nth_weekday_of_month(year, 11, 7, 1)

    cond do
      {naive.month, naive.day} > {3, dst_start_day} and
          {naive.month, naive.day} < {11, dst_end_day} ->
        {4 * 3600, "-04:00"}

      naive.month == 3 and naive.day == dst_start_day and naive.hour >= 2 ->
        {4 * 3600, "-04:00"}

      naive.month == 11 and naive.day == dst_end_day and naive.hour < 2 ->
        {4 * 3600, "-04:00"}

      true ->
        {5 * 3600, "-05:00"}
    end
  end

  defp sec_eastern_offset_for_utc(%DateTime{} = utc_dt) do
    year = utc_dt.year
    dst_start_day = nth_weekday_of_month(year, 3, 7, 2)
    dst_end_day = nth_weekday_of_month(year, 11, 7, 1)
    {:ok, dst_start_naive} = NaiveDateTime.new(year, 3, dst_start_day, 7, 0, 0)
    {:ok, dst_end_naive} = NaiveDateTime.new(year, 11, dst_end_day, 6, 0, 0)
    {:ok, dst_start_utc} = DateTime.from_naive(dst_start_naive, "Etc/UTC")
    {:ok, dst_end_utc} = DateTime.from_naive(dst_end_naive, "Etc/UTC")

    if DateTime.compare(utc_dt, dst_start_utc) in [:eq, :gt] and
         DateTime.compare(utc_dt, dst_end_utc) == :lt do
      {-4 * 3600, "-04:00"}
    else
      {-5 * 3600, "-05:00"}
    end
  end

  defp nth_weekday_of_month(year, month, weekday_target, nth) do
    1..31
    |> Enum.filter(fn day ->
      case Date.new(year, month, day) do
        {:ok, date} -> Date.day_of_week(date) == weekday_target
        _ -> false
      end
    end)
    |> Enum.at(nth - 1)
  end

  defp filing_date_from_local(filing_date, _published_at, _digest_date) when is_binary(filing_date),
    do: filing_date

  defp filing_date_from_local(_filing_date, %DateTime{} = published_at, _digest_date),
    do: published_at |> DateTime.to_date() |> Date.to_iso8601() |> String.replace("-", "")

  defp filing_date_from_local(_filing_date, _published_at, digest_date),
    do: Date.to_iso8601(digest_date) |> String.replace("-", "")

  defp filing_date_local_from(accepted_at_local, _published_at) when is_binary(accepted_at_local) do
    case String.split(accepted_at_local, "T", parts: 2) do
      [date_part, _] -> date_part
      _ -> nil
    end
  end

  defp filing_date_local_from(_accepted_at_local, %DateTime{} = published_at),
    do: published_at |> DateTime.to_date() |> Date.to_iso8601()

  defp filing_date_local_from(_, _), do: nil

  defp sort_key(%{accepted_at: %DateTime{} = dt}), do: dt
  defp sort_key(_), do: ~U[1970-01-01 00:00:00Z]
  defp parse_iso8601(nil), do: nil

  defp parse_iso8601(value) do
    case DateTime.from_iso8601(value) do
      {:ok, dt, _} -> dt
      _ -> nil
    end
  end

  defp iso8601(nil), do: nil
  defp iso8601(%DateTime{} = value), do: DateTime.to_iso8601(value)
end
