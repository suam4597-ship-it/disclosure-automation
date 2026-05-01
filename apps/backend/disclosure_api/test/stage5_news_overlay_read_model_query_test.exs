defmodule DisclosureAutomation.Stage5NewsOverlayReadModelQueryTest do
  use DisclosureAutomationWeb.ConnCase, async: false

  alias DisclosureAutomation.Bootstrap
  alias DisclosureAutomation.Ingestion
  alias DisclosureAutomation.Ops.JPTDnetTimelyDisclosureSource
  alias DisclosureAutomation.Ops.Stage5NewsOverlayFixtureSource
  alias DisclosureAutomation.Repo
  alias DisclosureAutomation.Runtime.Stage5NewsOverlayRawStaging
  alias DisclosureAutomation.Runtime.Stage5NewsOverlayReadModel
  alias DisclosureAutomation.Sources

  @official_event_id "jp.tdnet.4527.20260430.material_information_update.material_information_update.140120260430515474"
  @official_stable_external_id "TDNET:4527:20260430:1900:140120260430515474"
  @official_published_at_utc "2026-04-30T10:00:00.000000Z"
  @overlay_id "news_overlay:jp.tdnet.4527.20260430.material_information_update.material_information_update.140120260430515474:ba9e08fb9a92ac57"
  @article_external_id "NEWS-FIXTURE:jp:jp_tdnet_timely_disclosure:140120260430515474:reuters-jp-article-001"
  @raw_event_external_id "news_overlay:jp.tdnet.4527.20260430.material_information_update.material_information_update.140120260430515474:ba9e08fb9a92ac57:overlay-candidate"

  setup do
    :ok = Bootstrap.bootstrap()
    {:ok, _source} = Sources.upsert_source(JPTDnetTimelyDisclosureSource.attrs())
    {:ok, _source} = Sources.upsert_source(Stage5NewsOverlayFixtureSource.attrs())
    :ok
  end

  test "returns official TDnet item with empty overlays when no Reuters raw overlay is staged" do
    assert {:ok, official_poll} = poll_tdnet_once()
    assert official_poll.records_seen == 1

    assert {:ok, response} = Stage5NewsOverlayReadModel.get_by_event_id(@official_event_id)

    assert response.item.eventId == @official_event_id
    assert response.item.stableExternalId == @official_stable_external_id
    assert response.item.sourceKey == "jp_tdnet_timely_disclosure"
    assert response.item.sourceTier == "official_exchange_storage"
    assert response.item.documentRole == "official_exchange_disclosure"
    assert response.item.securityCode == "4527"
    assert response.item.title == "株主提案に関する書面受領のお知らせ"
    assert response.item.publishedAt == @official_published_at_utc
    assert response.item.overlays == []
  end

  test "returns Reuters overlay under overlays without mutating official TDnet fields" do
    assert {:ok, official_poll} = poll_tdnet_once()
    assert official_poll.records_seen == 1

    official_before = canonical_contract(@official_event_id)

    assert {:ok, staged} = Stage5NewsOverlayRawStaging.stage_once()
    assert staged.overlay_id == @overlay_id
    assert canonical_count(@overlay_id) == 0

    assert {:ok, response} = Stage5NewsOverlayReadModel.get_by_event_id(@official_event_id)
    item = response.item

    assert item.eventId == @official_event_id
    assert item.stableExternalId == @official_stable_external_id
    assert item.sourceKey == "jp_tdnet_timely_disclosure"
    assert item.sourceTier == "official_exchange_storage"
    assert item.documentRole == "official_exchange_disclosure"
    assert item.securityCode == "4527"
    assert item.title == official_before["headline_local"]
    assert item.publishedAt == official_before["published_at_utc"]
    assert item.canonicalUrl == official_before["official_source_url"]
    assert item.canonicalEventType == official_before["canonical_event_type"]

    assert [overlay] = item.overlays
    assert overlay.overlayId == @overlay_id
    assert overlay.overlayType == "news_article_context"
    assert overlay.overlayMode == "attach_only"
    assert overlay.displayState == "visible"
    assert overlay.sourceKey == "stage5_news_overlay_fixture"
    assert overlay.provider == "Reuters"
    assert overlay.sourceTier == "reputable_news_source"
    assert overlay.documentRole == "news_article"
    assert overlay.articleExternalId == @article_external_id
    assert overlay.rawEventExternalId == @raw_event_external_id
    assert overlay.title == "英ファンドＡＶＩ、ロートの会長解任議案を提出　企業統治改善求める"
    assert overlay.publishedAt == "2026-04-30T10:30:00Z"
    assert overlay.url == "https://jp.reuters.com/markets/global-markets/JKGTTV5MI5PFRGFVTC37DW73GE-2026-04-30/"
    assert overlay.jurisdiction == "JP"
    assert overlay.canonicalFactOverride == false
    assert "provider_url_not_official_url" in overlay.conflictFlags

    assert Enum.all?(overlay.overlayClaims, &(&1.canonicalFactOverride == false))
    assert Enum.all?(overlay.overlayClaims, &(&1.sourceKey == "stage5_news_overlay_fixture"))
    assert Enum.all?(overlay.overlayClaims, &(&1.sourceTier == "reputable_news_source"))
    assert Enum.all?(overlay.overlayClaims, &(&1.documentRole == "news_article"))

    assert [reuters_citation] = overlay.citations
    assert reuters_citation.sourceKey == "stage5_news_overlay_fixture"
    assert reuters_citation.sourceTier == "reputable_news_source"
    assert reuters_citation.documentRole == "news_article"
    assert reuters_citation.provider == "Reuters"
    assert reuters_citation.isCanonicalSource == false

    flattened = Stage5NewsOverlayReadModel.flattened_citations(response)
    assert List.first(flattened).isCanonicalSource == true
    assert List.last(flattened).sourceKey == "stage5_news_overlay_fixture"
    assert List.last(flattened).isCanonicalSource == false

    assert canonical_count(@overlay_id) == 0
    assert canonical_count(@official_event_id) == 1

    official_after = canonical_contract(@official_event_id)
    assert official_after["event_id"] == official_before["event_id"]
    assert official_after["headline_local"] == official_before["headline_local"]
    assert official_after["published_at_utc"] == official_before["published_at_utc"]
    assert official_after["official_source_url"] == official_before["official_source_url"]
    assert official_after["canonical_event_type"] == official_before["canonical_event_type"]
    assert get_in(official_after, ["source_meta", "stable_external_id"]) == get_in(official_before, ["source_meta", "stable_external_id"])
  end

  test "can resolve the official TDnet item by stable external id" do
    assert {:ok, official_poll} = poll_tdnet_once()
    assert official_poll.records_seen == 1

    assert {:ok, staged} = Stage5NewsOverlayRawStaging.stage_once()
    assert staged.overlay_id == @overlay_id

    assert {:ok, response} = Stage5NewsOverlayReadModel.get_by_stable_external_id(@official_stable_external_id)

    assert response.item.eventId == @official_event_id
    assert response.item.stableExternalId == @official_stable_external_id
    assert [overlay] = response.item.overlays
    assert overlay.overlayId == @overlay_id
    assert overlay.displayState == "visible"
  end

  defp poll_tdnet_once do
    Ingestion.poll_source("jp_tdnet_timely_disclosure",
      trigger_kind: "manual",
      edition: "breaking",
      use_live_fetch: false,
      inline_feed: true
    )
  end

  defp canonical_count(event_id) do
    %{rows: [[count]]} = Repo.query!("select count(*) from canonical_feed_items where event_id = $1", [event_id])
    count
  end

  defp canonical_contract(event_id) do
    %{rows: [[contract]]} = Repo.query!("select contract_v1 from canonical_feed_items where event_id = $1", [event_id])
    contract
  end
end
