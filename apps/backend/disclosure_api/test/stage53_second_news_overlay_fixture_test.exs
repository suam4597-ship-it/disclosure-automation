defmodule DisclosureAutomation.Stage53SecondNewsOverlayFixtureTest do
  use DisclosureAutomationWeb.ConnCase, async: true

  alias DisclosureAutomation.Ops.Stage53SecondNewsOverlayFixtureSource

  @fixture_path "../priv/fixtures/source_payloads/stage53_news_overlay_fixture_jp_tdnet_140120260430515474_bloomberg_jp_article_001.json"
  @official_event_id "jp.tdnet.4527.20260430.material_information_update.material_information_update.140120260430515474"
  @official_stable_external_id "TDNET:4527:20260430:1900:140120260430515474"
  @reuters_overlay_id "news_overlay:jp.tdnet.4527.20260430.material_information_update.material_information_update.140120260430515474:ba9e08fb9a92ac57"
  @reuters_article_external_id "NEWS-FIXTURE:jp:jp_tdnet_timely_disclosure:140120260430515474:reuters-jp-article-001"
  @bloomberg_overlay_id "news_overlay:jp.tdnet.4527.20260430.material_information_update.material_information_update.140120260430515474:bloomberg-jp-article-001"
  @bloomberg_article_external_id "NEWS-FIXTURE:jp:jp_tdnet_timely_disclosure:140120260430515474:bloomberg-jp-article-001"

  @prohibited_keys [
    "articleBody",
    "fullText",
    "rawHtml",
    "providerResponseBody",
    "scrapedText",
    "paywalledArticleText",
    "requestHeaders",
    "responseHeaders",
    "credentials",
    "apiKey",
    "authorization",
    "Authorization",
    "cookie",
    "Cookie",
    "subscriptionKey",
    "Subscription-Key"
  ]

  test "source attrs load Stage 5.3 second overlay fixture policy" do
    attrs = Stage53SecondNewsOverlayFixtureSource.attrs()

    assert attrs["source_key"] == "stage53_news_overlay_fixture"
    assert attrs["adapter_key"] == "stage53_news_overlay_fixture_v1"
    assert attrs["default_source_tier"] == "reputable_news_source"
    assert attrs["discovery_mode"] == "fixture"
    assert attrs["hydrate_mode"] == "local_fixture"
    assert attrs["config"]["overlay_mode"] == "attach_only"
    assert attrs["config"]["storage_mode"] == "raw_staging"
    assert attrs["config"]["canonical_feed_mutation"] == false
    assert attrs["config"]["news_only_event_creation"] == false
    assert attrs["config"]["fixtures"]["overlay_result"] ==
             "source_payloads/stage53_news_overlay_fixture_jp_tdnet_140120260430515474_bloomberg_jp_article_001.json"
    assert "bloomberg" in attrs["coverage_tags"]
    assert "multi_overlay" in attrs["coverage_tags"]
  end

  test "Bloomberg fixture has exactly one safe attach-only overlay" do
    payload = fixture_payload()

    assert payload["fixtureVersion"] == "stage53_second_news_overlay_fixture_v1"
    assert payload["sourceKey"] == "stage53_news_overlay_fixture"
    assert payload["adapterKey"] == "stage53_news_overlay_fixture_v1"
    assert payload["sourceTier"] == "reputable_news_source"
    assert payload["documentRole"] == "news_article"
    assert payload["networkAccess"] == "forbidden"
    assert payload["overlayMode"] == "attach_only"
    assert payload["newsOnlyEventCreation"] == false
    assert payload["canonicalFactOverride"] == false

    assert [overlay] = payload["overlays"]
    assert overlay["overlayId"] == @bloomberg_overlay_id
    assert overlay["articleExternalId"] == @bloomberg_article_external_id
    assert overlay["overlayId"] != @reuters_overlay_id
    assert overlay["articleExternalId"] != @reuters_article_external_id
    assert overlay["canonicalEventId"] == @official_event_id
    assert overlay["sourceKey"] == "stage53_news_overlay_fixture"
    assert overlay["sourceTier"] == "reputable_news_source"
    assert overlay["documentRole"] == "news_article"
    assert overlay["sourceName"] == "Bloomberg related news article fixture"
    assert overlay["articlePublishedAt"] == "2026-04-30T10:45:00Z"
    assert overlay["articleLanguage"] == "en"
  end

  test "Bloomberg fixture carries direct official match evidence and preserves official facts" do
    [overlay] = fixture_payload()["overlays"]

    assert get_in(overlay, ["officialAnchor", "eventId"]) == @official_event_id
    assert get_in(overlay, ["officialAnchor", "stableExternalId"]) == @official_stable_external_id
    assert get_in(overlay, ["officialAnchor", "officialSourceKey"]) == "jp_tdnet_timely_disclosure"
    assert get_in(overlay, ["matchEvidence", "matchedCanonicalEventId"]) == @official_event_id
    assert get_in(overlay, ["matchEvidence", "matchedOfficialStableExternalId"]) == @official_stable_external_id
    assert get_in(overlay, ["officialFactsPreserved", "eventIdUnchanged"]) == true
    assert get_in(overlay, ["officialFactsPreserved", "stableExternalIdUnchanged"]) == true
    assert get_in(overlay, ["officialFactsPreserved", "officialTimestampUnchanged"]) == true
    assert get_in(overlay, ["officialFactsPreserved", "officialSourceUrlUnchanged"]) == true
    assert get_in(overlay, ["officialFactsPreserved", "canonicalFactOverride"]) == false
  end

  test "Bloomberg fixture claims and citations stay overlay-scoped" do
    [overlay] = fixture_payload()["overlays"]

    assert Enum.all?(overlay["overlayClaims"], &(&1["canonicalFactOverride"] == false))
    assert Enum.all?(overlay["overlayClaims"], &is_binary(&1["sourceCitationRef"]))

    citations = overlay["citations"]
    assert Enum.any?(citations, &(&1["sourceKey"] == "jp_tdnet_timely_disclosure"))
    assert Enum.any?(citations, &(&1["sourceKey"] == "stage53_news_overlay_fixture"))
    assert Enum.all?(citations, &(&1["documentRole"] in ["official_exchange_disclosure", "news_article"]))
  end

  test "Bloomberg fixture does not include prohibited full text, headers, or secrets" do
    payload = fixture_payload()
    flattened = flatten_json(payload)

    Enum.each(@prohibited_keys, fn key ->
      refute Enum.any?(flattened, fn {path, _value} -> String.ends_with?(path, ".#{key}") or path == key end),
             "unexpected prohibited key #{key} in fixture"
    end)

    rendered = Jason.encode!(payload)
    refute String.contains?(rendered, "Subscription-Key")
    refute String.contains?(rendered, "Authorization:")
    refute String.contains?(rendered, "Cookie:")
    refute String.contains?(rendered, "BEGIN PRIVATE KEY")
  end

  defp fixture_payload do
    @fixture_path
    |> Path.expand(__DIR__)
    |> File.read!()
    |> Jason.decode!()
  end

  defp flatten_json(value, prefix \\ "")

  defp flatten_json(%{} = map, prefix) do
    Enum.flat_map(map, fn {key, value} ->
      path = if prefix == "", do: key, else: "#{prefix}.#{key}"
      [{path, value} | flatten_json(value, path)]
    end)
  end

  defp flatten_json(values, prefix) when is_list(values) do
    values
    |> Enum.with_index()
    |> Enum.flat_map(fn {value, index} -> flatten_json(value, "#{prefix}[#{index}]") end)
  end

  defp flatten_json(_value, _prefix), do: []
end
