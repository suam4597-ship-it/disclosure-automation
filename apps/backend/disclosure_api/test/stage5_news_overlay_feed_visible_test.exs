defmodule DisclosureAutomationWeb.Stage5NewsOverlayFeedVisibleTest do
  use DisclosureAutomationWeb.ConnCase, async: false

  alias DisclosureAutomation.Bootstrap
  alias DisclosureAutomation.Ingestion
  alias DisclosureAutomation.Ops.JPTDnetTimelyDisclosureSource
  alias DisclosureAutomation.Ops.Stage5NewsOverlayFixtureSource
  alias DisclosureAutomation.Repo
  alias DisclosureAutomation.Runtime.Stage5NewsOverlayRawStaging
  alias DisclosureAutomation.Sources

  @official_event_id "jp.tdnet.4527.20260430.material_information_update.material_information_update.140120260430515474"
  @official_stable_external_id "TDNET:4527:20260430:1900:140120260430515474"
  @overlay_id "news_overlay:jp.tdnet.4527.20260430.material_information_update.material_information_update.140120260430515474:ba9e08fb9a92ac57"
  @article_external_id "NEWS-FIXTURE:jp:jp_tdnet_timely_disclosure:140120260430515474:reuters-jp-article-001"

  setup do
    :ok = Bootstrap.bootstrap()
    {:ok, _source} = Sources.upsert_source(JPTDnetTimelyDisclosureSource.attrs())
    {:ok, _source} = Sources.upsert_source(Stage5NewsOverlayFixtureSource.attrs())
    :ok
  end

  test "digest feed item exposes news_overlays additively without changing official item fields", %{conn: conn} do
    assert {:ok, official_poll} = poll_tdnet_once()
    assert official_poll.records_seen == 1

    before_response =
      conn
      |> get("/api/feed/digest/latest?edition=breaking")
      |> json_response(200)

    assert before_response["item_count"] == 1
    assert [before_item] = before_response["items"]
    assert before_item["event_id"] == @official_event_id
    assert before_item["headline_local"] == "株主提案に関する書面受領のお知らせ"
    assert before_item["published_at_utc"] == "2026-04-30T10:00:00.000000Z"
    assert before_item["canonical_event_type"] == "material_information_update"
    assert get_in(before_item, ["source_meta", "stable_external_id"]) == @official_stable_external_id
    assert before_item["news_overlays"] == []

    assert {:ok, staged} = Stage5NewsOverlayRawStaging.stage_once()
    assert staged.overlay_id == @overlay_id

    after_response =
      conn
      |> recycle()
      |> get("/api/feed/digest/latest?edition=breaking")
      |> json_response(200)

    assert after_response["item_count"] == before_response["item_count"]
    assert after_response["item_event_ids"] == before_response["item_event_ids"]
    assert [after_item] = after_response["items"]

    assert after_item["event_id"] == before_item["event_id"]
    assert after_item["headline_local"] == before_item["headline_local"]
    assert after_item["published_at_utc"] == before_item["published_at_utc"]
    assert after_item["canonical_event_type"] == before_item["canonical_event_type"]
    assert after_item["official_source_url"] == before_item["official_source_url"]
    assert get_in(after_item, ["source_meta", "stable_external_id"]) == get_in(before_item, ["source_meta", "stable_external_id"])

    assert [overlay] = after_item["news_overlays"]
    assert overlay["overlay_id"] == @overlay_id
    assert overlay["overlay_mode"] == "attach_only"
    assert overlay["display_state"] == "visible"
    assert overlay["source_key"] == "stage5_news_overlay_fixture"
    assert overlay["provider"] == "Reuters"
    assert overlay["source_tier"] == "reputable_news_source"
    assert overlay["document_role"] == "news_article"
    assert overlay["article_external_id"] == @article_external_id
    assert overlay["canonical_fact_override"] == false
    assert overlay["published_at"] == "2026-04-30T10:30:00Z"
    assert overlay["url"] == "https://jp.reuters.com/markets/global-markets/JKGTTV5MI5PFRGFVTC37DW73GE-2026-04-30/"
    assert overlay["url"] != after_item["official_source_url"]
    assert "provider_url_not_official_url" in overlay["conflict_flags"]

    assert Enum.all?(overlay["overlay_claims"], &(&1["canonical_fact_override"] == false))
    assert Enum.all?(overlay["overlay_claims"], &(&1["source_key"] == "stage5_news_overlay_fixture"))

    assert [reuters_citation] = overlay["citations"]
    assert reuters_citation["source_key"] == "stage5_news_overlay_fixture"
    assert reuters_citation["is_canonical_source"] == false

    event_overlay =
      conn
      |> recycle()
      |> get("/api/events/#{@official_event_id}/news-overlay")
      |> json_response(200)

    assert get_in(event_overlay, ["item", "eventId"]) == @official_event_id
    assert [event_overlay_item] = get_in(event_overlay, ["item", "overlays"])
    assert event_overlay_item["overlayId"] == @overlay_id

    existing_event =
      conn
      |> recycle()
      |> get("/api/events/#{@official_event_id}")
      |> json_response(200)

    assert get_in(existing_event, ["data", "event_id"]) == @official_event_id
    assert get_in(existing_event, ["data", "canonical_event_type"]) == "material_information_update"

    assert canonical_count(@overlay_id) == 0
    assert canonical_count(@official_event_id) == 1
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
end
