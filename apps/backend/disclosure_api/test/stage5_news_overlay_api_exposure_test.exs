defmodule DisclosureAutomationWeb.Stage5NewsOverlayApiExposureTest do
  use DisclosureAutomationWeb.ConnCase, async: false

  alias DisclosureAutomation.Bootstrap
  alias DisclosureAutomation.Ingestion
  alias DisclosureAutomation.Ops.JPTDnetTimelyDisclosureSource
  alias DisclosureAutomation.Ops.Stage5NewsOverlayFixtureSource
  alias DisclosureAutomation.Repo
  alias DisclosureAutomation.Runtime.Stage5NewsOverlayRawStaging
  alias DisclosureAutomation.Sources

  @official_event_id "jp.tdnet.4527.20260430.material_information_update.material_information_update.140120260430515474"
  @overlay_id "news_overlay:jp.tdnet.4527.20260430.material_information_update.material_information_update.140120260430515474:ba9e08fb9a92ac57"
  @article_external_id "NEWS-FIXTURE:jp:jp_tdnet_timely_disclosure:140120260430515474:reuters-jp-article-001"

  setup do
    :ok = Bootstrap.bootstrap()
    {:ok, _source} = Sources.upsert_source(JPTDnetTimelyDisclosureSource.attrs())
    {:ok, _source} = Sources.upsert_source(Stage5NewsOverlayFixtureSource.attrs())
    :ok
  end

  test "news overlay endpoint returns official TDnet item with empty overlays before Reuters staging", %{conn: conn} do
    assert {:ok, official_poll} = poll_tdnet_once()
    assert official_poll.records_seen == 1

    response =
      conn
      |> get("/api/events/#{@official_event_id}/news-overlay")
      |> json_response(200)

    item = response["item"]

    assert is_binary(item["id"])
    assert String.match?(item["id"], ~r/^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/)
    assert item["eventId"] == @official_event_id
    assert item["sourceKey"] == "jp_tdnet_timely_disclosure"
    assert item["sourceTier"] == "official_exchange_storage"
    assert item["documentRole"] == "official_exchange_disclosure"
    assert item["securityCode"] == "4527"
    assert item["title"] == "株主提案に関する書面受領のお知らせ"
    assert item["publishedAt"] == "2026-04-30T10:00:00.000000Z"
    assert item["overlays"] == []
  end

  test "news overlay endpoint returns Reuters overlay under item.overlays after raw staging", %{conn: conn} do
    assert {:ok, official_poll} = poll_tdnet_once()
    assert official_poll.records_seen == 1

    official_before = canonical_contract(@official_event_id)

    assert {:ok, staged} = Stage5NewsOverlayRawStaging.stage_once()
    assert staged.overlay_id == @overlay_id

    response =
      conn
      |> get("/api/events/#{@official_event_id}/news-overlay")
      |> json_response(200)

    item = response["item"]

    assert is_binary(item["id"])
    assert String.match?(item["id"], ~r/^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/)
    assert item["eventId"] == @official_event_id
    assert item["sourceKey"] == "jp_tdnet_timely_disclosure"
    assert item["title"] == official_before["headline_local"]
    assert item["publishedAt"] == official_before["published_at_utc"]
    assert item["canonicalUrl"] == official_before["official_source_url"]
    assert item["canonicalEventType"] == official_before["canonical_event_type"]

    assert [overlay] = item["overlays"]
    assert overlay["overlayId"] == @overlay_id
    assert overlay["overlayMode"] == "attach_only"
    assert overlay["displayState"] == "visible"
    assert overlay["sourceKey"] == "stage5_news_overlay_fixture"
    assert overlay["provider"] == "Reuters"
    assert overlay["sourceTier"] == "reputable_news_source"
    assert overlay["documentRole"] == "news_article"
    assert overlay["articleExternalId"] == @article_external_id
    assert overlay["canonicalFactOverride"] == false
    assert overlay["url"] == "https://jp.reuters.com/markets/global-markets/JKGTTV5MI5PFRGFVTC37DW73GE-2026-04-30/"
    assert "provider_url_not_official_url" in overlay["conflictFlags"]

    assert Enum.all?(overlay["overlayClaims"], &(&1["canonicalFactOverride"] == false))
    assert Enum.all?(overlay["overlayClaims"], &(&1["sourceKey"] == "stage5_news_overlay_fixture"))

    assert [official_citation | _] = item["citations"]
    assert official_citation["isCanonicalSource"] == true

    assert [reuters_citation] = overlay["citations"]
    assert reuters_citation["sourceKey"] == "stage5_news_overlay_fixture"
    assert reuters_citation["isCanonicalSource"] == false

    existing_event =
      conn
      |> recycle()
      |> get("/api/events/#{@official_event_id}")
      |> json_response(200)

    assert get_in(existing_event, ["data", "event_id"]) == @official_event_id
    assert get_in(existing_event, ["data", "canonical_event_type"]) == "material_information_update"

    assert canonical_count(@overlay_id) == 0
    assert canonical_count(@official_event_id) == 1

    official_after = canonical_contract(@official_event_id)
    assert official_after["headline_local"] == official_before["headline_local"]
    assert official_after["published_at_utc"] == official_before["published_at_utc"]
    assert official_after["official_source_url"] == official_before["official_source_url"]
  end

  test "news overlay endpoint returns 404 for missing official event", %{conn: conn} do
    response =
      conn
      |> get("/api/events/missing.official.event/news-overlay")
      |> json_response(404)

    assert get_in(response, ["error", "code"]) == "official_event_not_found"
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
