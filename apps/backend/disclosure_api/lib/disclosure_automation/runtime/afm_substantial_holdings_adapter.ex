defmodule DisclosureAutomation.Runtime.AFMSubstantialHoldingsAdapter do
  @moduledoc false

  @behaviour DisclosureAutomation.Runtime.Adapter

  alias DisclosureAutomation.Fixtures
  alias DisclosureAutomation.Http
  alias DisclosureAutomation.Schema.SourceRegistry

  @cursor_key "latest_notification_seen"
  @default_register_kind "substantial_holdings"

  @impl true
  def discover(%SourceRegistry{} = source, opts \\ []) do
    use_live_fetch = Keyword.get(opts, :use_live_fetch, true)

    with {:ok, payload} <- load_register_payload(source, use_live_fetch) do
      {:ok, parse_register_export(payload, register_kind(source))}
    end
  end

  @impl true
  def hydrate(%SourceRegistry{} = source, discovery_item, _opts \\ []) do
    register_url = source.base_url || discovery_item.detail_url

    {:ok,
     %{
       discovery_item: discovery_item,
       detail_document: %{
         external_id: "#{discovery_item.notification_id}:detail-page",
         document_identity: "#{discovery_item.notification_id}:detail-page",
         document_type: "register_detail",
         document_role: "discovery_detail",
         mime_type: "text/html",
         url: discovery_item.detail_url,
         body_text: render_detail_body(discovery_item),
         published_at: discovery_item.published_at_utc,
         metadata: %{
           "mode" => "fixture",
           "notification_id" => discovery_item.notification_id
         }
       },
       submission_document: %{
         external_id: "#{discovery_item.notification_id}:register-export",
         document_identity: "#{discovery_item.notification_id}:register-export",
         document_type: "register_export",
         document_role: "primary_register_row",
         mime_type: "application/xml",
         url: register_url,
         body_text: discovery_item.raw_xml,
         published_at: discovery_item.published_at_utc,
         metadata: %{
           "mode" => "fixture",
           "notification_id" => discovery_item.notification_id
         }
       },
       published_at_local: discovery_item.published_at_local,
       published_at_utc: discovery_item.published_at_utc
     }}
  end

  @impl true
  def parse(%SourceRegistry{} = source, hydrated_item, _opts \\ []) do
    item = hydrated_item.discovery_item

    {:ok,
     [
       %{
         event_key: "afm:substantial-holdings:#{item.notification_id}",
         external_event_key: item.notification_id,
         parser_key: source.parser_key || "afm_substantial_holdings_xml_v1",
         event_family: "shareholding_threshold_crossing",
         occurred_at: item.published_at_utc,
         status: "parsed",
         payload: %{
           "notification_id" => item.notification_id,
           "transaction_date" => item.transaction_date,
           "published_at_local" => item.published_at_local,
           "issuing_institution" => item.issuing_institution,
           "person_obliged_to_notify" => item.person_obliged_to_notify,
           "threshold" => item.threshold,
           "capital_interest" => item.capital_interest,
           "voting_rights" => item.voting_rights,
           "detail_url" => item.detail_url,
           "position_kind" => item.position_kind,
           "register_kind" => item.register_kind
         },
         metadata: %{
           "register_kind" => item.register_kind
         }
       }
     ]}
  end

  @impl true
  def normalize(%SourceRegistry{} = source, raw_event, opts \\ []) do
    payload = raw_event.payload || %{}
    published_at = raw_event.occurred_at
    transaction_date = payload["transaction_date"] || published_date_local(published_at)
    canonical_event_type = "major_shareholding_or_insider_trade"
    event_family = raw_event.event_family || "shareholding_threshold_crossing"
    issuer_slug = normalize_id_token_preserve_underscore(payload["issuing_institution"] || "issuer")
    notification_short = notification_short_id(payload["notification_id"])

    event_id =
      "nl.afm.#{issuer_slug}.#{String.replace(transaction_date, "-", "")}.#{canonical_event_type}.#{event_family}.#{notification_short}"

    digest_date =
      Keyword.get(
        opts,
        :digest_date,
        if(published_at, do: DateTime.to_date(published_at), else: Date.utc_today())
      )

    edition = Keyword.get(opts, :edition, "breaking")
    region_code = source.region_code || "nl"
    home_market_region_code = source.default_home_market_region_code || region_code

    contract_v1 = %{
      "event_id" => event_id,
      "dedupe_key" => "afm|#{issuer_slug}|#{transaction_date}|#{event_family}",
      "issuer_entity_key" => "afm:issuer:#{issuer_slug}",
      "issuer_name_local" => payload["issuing_institution"],
      "issuer_name_en" => payload["issuing_institution"],
      "headline_local" => "Substantial holding notification: #{payload["issuing_institution"]}",
      "headline_ko" => "AFM substantial holding notification",
      "fact_summary_ko" =>
        "#{payload["person_obliged_to_notify"]} reported a #{payload["threshold"]} threshold position in #{payload["issuing_institution"]}. Capital interest #{payload["capital_interest"]}, voting rights #{payload["voting_rights"]}.",
      "why_important_ko" => "Major shareholding threshold disclosure in the AFM public register.",
      "canonical_event_type" => canonical_event_type,
      "event_family" => event_family,
      "official_storage_name" => "AFM",
      "official_source_name" => "AFM Register substantial holdings and gross short positions",
      "official_source_url" => payload["detail_url"],
      "discovery_source_name" => "AFM register export",
      "discovery_source_url" => source.base_url,
      "raw_source_type" => "substantial_holdings_register",
      "source_tier" => "official_regulatory_storage",
      "country" => "NL",
      "region_code" => region_code,
      "home_market_region_code" => home_market_region_code,
      "published_at_utc" => iso8601(published_at),
      "published_at_local" => payload["published_at_local"],
      "filing_date_local" => transaction_date,
      "importance_band" => "P2",
      "source_meta" => %{
        "notification_id" => payload["notification_id"],
        "threshold" => payload["threshold"],
        "capital_interest" => payload["capital_interest"],
        "voting_rights" => payload["voting_rights"],
        "person_obliged_to_notify" => payload["person_obliged_to_notify"],
        "position_kind" => payload["position_kind"],
        "register_kind" => payload["register_kind"]
      },
      "risk_flags" => [],
      "portable_citations" => [
        %{
          "source_name" => "AFM register export",
          "claim_supported" => "transaction date, issuer, notifying party, and threshold",
          "note" => source.base_url
        },
        %{
          "source_name" => "AFM notification detail page",
          "claim_supported" => "official notification detail anchor",
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
       headline: contract_v1["headline_local"],
       summary: contract_v1["fact_summary_ko"],
       canonical_url: payload["detail_url"],
       published_at: published_at,
       tickers: [],
       regions: [region_code],
       sectors: ["regulatory"],
       sentiment_label: "neutral",
       relevance_score: Decimal.new("0.900"),
       priority_rank: nil,
       duplicate_group_key: payload["notification_id"],
       status: "ready"
     }}
  end

  def cursor_key, do: @cursor_key

  defp register_kind(source) do
    source.config["register_kind"] || source.config[:register_kind] || @default_register_kind
  end

  defp load_register_payload(source, true) do
    fixture_path =
      get_in(source.config, ["fixtures", "register_export"]) ||
        get_in(source.config, [:fixtures, :register_export])

    with {:ok, response} <- Http.fetch(source.base_url, timeout: 8_000),
         true <- response.status_code in 200..299 do
      {:ok, response.body}
    else
      _ -> load_fixture(fixture_path)
    end
  end

  defp load_register_payload(source, false) do
    fixture_path =
      get_in(source.config, ["fixtures", "register_export"]) ||
        get_in(source.config, [:fixtures, :register_export])

    load_fixture(fixture_path)
  end

  defp load_fixture(fixture_path) do
    with {:ok, payload} <- Fixtures.load_source_payload(fixture_path) do
      {:ok, payload.raw}
    end
  end

  defp parse_register_export(raw_payload, register_kind) do
    with {:ok, document} <- parse_xml(raw_payload) do
      :xmerl_xpath.string(~c"/register/notification", document)
      |> Enum.map(&parse_notification(&1, register_kind))
      |> Enum.sort_by(&sort_key/1, {:desc, DateTime})
    else
      _ -> []
    end
  end

  defp parse_notification(notification, register_kind) do
    published_at_local = xpath_string(notification, ~c"string(published_at_local)")

    published_at_utc =
      xpath_string(notification, ~c"string(published_at_utc)")
      |> parse_iso8601()
      |> case do
        nil -> parse_iso8601(published_at_local)
        value -> value
      end

    issuing_institution = xpath_string(notification, ~c"string(issuing_institution)")

    %{
      notification_id: xpath_string(notification, ~c"string(notification_id)"),
      transaction_date: xpath_string(notification, ~c"string(transaction_date)"),
      published_at_local: published_at_local,
      published_at_utc: published_at_utc,
      issuing_institution: issuing_institution,
      person_obliged_to_notify: xpath_string(notification, ~c"string(person_obliged_to_notify)"),
      threshold: xpath_string(notification, ~c"string(threshold)"),
      capital_interest: xpath_string(notification, ~c"string(capital_interest)"),
      voting_rights: xpath_string(notification, ~c"string(voting_rights)"),
      detail_url: xpath_string(notification, ~c"string(detail_url)"),
      position_kind: xpath_string(notification, ~c"string(position_kind)") || "substantial_holding",
      register_kind: xpath_string(notification, ~c"string(register_kind)") || register_kind,
      raw_xml: render_notification_xml(notification),
      headline: "Substantial holding notification: #{issuing_institution}"
    }
  end

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

  defp render_notification_xml(notification) do
    fields = [
      {"notification_id", xpath_string(notification, ~c"string(notification_id)")},
      {"transaction_date", xpath_string(notification, ~c"string(transaction_date)")},
      {"published_at_local", xpath_string(notification, ~c"string(published_at_local)")},
      {"published_at_utc", xpath_string(notification, ~c"string(published_at_utc)")},
      {"issuing_institution", xpath_string(notification, ~c"string(issuing_institution)")},
      {"person_obliged_to_notify", xpath_string(notification, ~c"string(person_obliged_to_notify)")},
      {"threshold", xpath_string(notification, ~c"string(threshold)")},
      {"capital_interest", xpath_string(notification, ~c"string(capital_interest)")},
      {"voting_rights", xpath_string(notification, ~c"string(voting_rights)")},
      {"detail_url", xpath_string(notification, ~c"string(detail_url)")},
      {"position_kind", xpath_string(notification, ~c"string(position_kind)")}
    ]

    inner =
      Enum.map_join(fields, "", fn {tag, value} ->
        "  <#{tag}>#{xml_escape(value)}</#{tag}>\n"
      end)

    "<notification>\n" <> inner <> "</notification>\n"
  end

  defp render_detail_body(item) do
    [
      "AFM substantial holdings notification",
      "notification_id=#{item.notification_id}",
      "transaction_date=#{item.transaction_date}",
      "issuing_institution=#{item.issuing_institution}",
      "person_obliged_to_notify=#{item.person_obliged_to_notify}",
      "threshold=#{item.threshold}",
      "capital_interest=#{item.capital_interest}",
      "voting_rights=#{item.voting_rights}",
      "detail_url=#{item.detail_url}"
    ]
    |> Enum.join("\n")
  end

  defp xml_escape(nil), do: ""

  defp xml_escape(value) do
    value
    |> to_string()
    |> String.replace("&", "&amp;")
    |> String.replace("<", "&lt;")
    |> String.replace(">", "&gt;")
  end

  defp xpath_string(node, query) do
    query
    |> :xmerl_xpath.string(node)
    |> xpath_value_to_string()
    |> String.trim()
    |> case do
      "" -> nil
      value -> value
    end
  end

  defp xpath_value_to_string(node) when is_list(node) do
    cond do
      node == [] -> ""
      Enum.all?(node, &is_integer/1) -> List.to_string(node)
      match?([{:xmlObj, :string, _}], node) -> node |> List.flatten() |> xpath_value_to_string()
      true -> node |> Enum.map(&xpath_value_to_string/1) |> Enum.join("")
    end
  end

  defp xpath_value_to_string({:xmlObj, :string, chars}), do: List.to_string(chars)
  defp xpath_value_to_string(binary) when is_binary(binary), do: binary
  defp xpath_value_to_string(other), do: to_string(other)

  defp notification_short_id(nil), do: "item"

  defp notification_short_id(notification_id) do
    case Regex.run(~r/(\d+)$/, notification_id) do
      [_, digits] -> digits
      _ -> notification_id |> normalize_id_token_preserve_underscore() |> String.slice(-6, 6)
    end
  end

  defp normalize_id_token_preserve_underscore(value) do
    value
    |> to_string()
    |> String.downcase()
    |> String.replace(~r/[^a-z0-9_]+/u, "_")
    |> String.trim("_")
    |> case do
      "" -> "item"
      token -> token
    end
  end

  defp published_date_local(%DateTime{} = published_at), do: published_at |> DateTime.to_date() |> Date.to_iso8601()
  defp published_date_local(_), do: Date.utc_today() |> Date.to_iso8601()

  defp sort_key(%{published_at_utc: %DateTime{} = dt}), do: dt
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
