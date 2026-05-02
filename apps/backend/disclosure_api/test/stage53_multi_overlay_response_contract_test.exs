defmodule DisclosureAutomation.Stage53MultiOverlayResponseContractTest do
  use DisclosureAutomationWeb.ConnCase, async: false

  alias DisclosureAutomation.Bootstrap
  alias DisclosureAutomation.Ingestion
  alias DisclosureAutomation.Ops.JPTDnetTimelyDisclosureSource
  alias DisclosureAutomation.Ops.Stage53SecondNewsOverlayFixtureSource
  alias DisclosureAutomation.Ops.Stage5NewsOverlayFixtureSource
  alias DisclosureAutomation.Repo
  alias DisclosureAutomation.Runtime.Stage52NewsOverlayAttachmentMaterializer
  alias DisclosureAutomation.Runtime.Stage53SecondNewsOverlayRawStaging
  alias DisclosureAutomation.Runtime.Stage5NewsOverlayRawStaging
  alias DisclosureAutomation.Runtime.Stage5NewsOverlayReadModel
  alias DisclosureAutomation.Sources

  @official_event_id "jp.tdnet.4527.20260430.material_information_update.material_information_update.140120260430515474"
  @reuters_overlay_id "news_overlay:jp.tdnet.4527.20260430.material_information_update.material_information_update.140120260430515474:ba9e08fb9a92ac57"
  @bloomberg_overlay_id "news_overlay:jp.tdnet.4527.20260430.material_information_update.material_information_update.140120260430515474:bloomberg-jp-article-001"

  setup do
    :ok = Bootstrap.bootstrap()
    {:ok, _source} = Sources.upsert_source(JPTDnetTimelyDisclosureSource.attrs())
    {:ok, _source} = Sources.upsert_source(Stage5NewsOverlayFixtureSource.attrs())
    {:ok, _source} = Sources.upsert_source(Stage53SecondNewsOverlayFixtureSource.attrs())

    assert {:ok, official_poll} = poll_tdnet_once()
    assert official_poll.records_seen == 1
    assert {:ok, _reuters} = Stage5NewsOverlayRawStaging.stage_once()
    assert {:ok, _bloomberg} = Stage53SecondNewsOverlayRawStaging.stage_once()
    assert {:ok, materialized} = Stage52NewsOverlayAttachmentMaterializer.materialize_once(@official_event_id)
    assert materialized.attachments_seen == 2

    :ok
  end

  test "read model returns two materialized overlays in deterministic order with separated citations" do
    assert {:ok, response} = Stage5NewsOverlayReadModel.get_by_event_id(@official_event_id)
    assert response.item.eventId == @official_event_id

    assert [reuters, bloomberg] = response.item.overlays
    assert reuters.overlayId == @reuters_overlay_id
    assert bloomberg.overlayId == @bloomberg_overlay_id
    assert reuters.provider == "Reuters"
    assert bloomberg.provider == "Bloomberg"
    assert reuters.publishedAt == "2026-04-30T10:30:00Z"
    assert bloomberg.publishedAt == "2026-04-30T10:45:00Z"
    assert reuters.canonicalFactOverride == false
    assert bloomberg.canonicalFactOverride == false

    flattened_citations = Stage5NewsOverlayReadModel.flattened_citations(response)
    official_citations = Enum.filter(flattened_citations, & &1.isCanonicalSource)
    overlay_citations = Enum.reject(flattened_citations, & &1.isCanonicalSource)

    assert official_citations != []
    assert Enum.all?(official_citations, &(&1.sourceKey == "jp_tdnet_timely_disclosure"))

    assert Enum.map(flattened_citations, & &1.sourceKey) ==
             Enum.map(official_citations, & &1.sourceKey) ++
               ["stage5_news_overlay_fixture", "stage53_news_overlay_fixture"]

    assert Enum.map(overlay_citations, & &1.sourceKey) == ["stage5_news_overlay_fixture", "stage53_news_overlay_fixture"]
    assert Enum.all?(overlay_citations, &(&1.isCanonicalSource == false))
  end

  test "event overlay API preserves item.overlays list shape and citation separation", %{conn: conn} do
    response =
      conn
      |> get("/api/events/#{@official_event_id}/news-overlay")
      |> json_response(200)

    item = response["item"]
    assert item["eventId"] == @official_event_id
    assert item["sourceKey"] == "jp_tdnet_timely_disclosure"

    assert [reuters, bloomberg] = item["overlays"]
    assert reuters["overlayId"] == @reuters_overlay_id
    assert bloomberg["overlayId"] == @bloomberg_overlay_id
    assert reuters["provider"] == "Reuters"
    assert bloomberg["provider"] == "Bloomberg"
    assert reuters["canonicalFactOverride"] == false
    assert bloomberg["canonicalFactOverride"] == false

    assert [official_citation | _] = item["citations"]
    assert official_citation["isCanonicalSource"] == true
    assert official_citation["sourceKey"] == "jp_tdnet_timely_disclosure"

    assert [reuters_citation] = reuters["citations"]
    assert [bloomberg_citation] = bloomberg["citations"]
    assert reuters_citation["sourceKey"] == "stage5_news_overlay_fixture"
    assert bloomberg_citation["sourceKey"] == "stage53_news_overlay_fixture"
    assert reuters_citation["isCanonicalSource"] == false
    assert bloomberg_citation["isCanonicalSource"] == false
  end

  test "feed digest preserves item count and renders two news_overlays without mutating official fields", %{conn: conn} do
    response =
      conn
      |> get("/api/feed/digest/latest?edition=breaking")
      |> json_response(200)

    assert response["item_count"] == 1
    assert [item] = response["items"]
    assert item["event_id"] == @official_event_id
    assert item["headline_local"] == "株主提案に関する書面受領のお知らせ"
    assert item["published_at_utc"] == "2026-04-30T10:00:00.000000Z"

    assert [reuters, bloomberg] = item["news_overlays"]
    assert reuters["overlay_id"] == @reuters_overlay_id
    assert bloomberg["overlay_id"] == @bloomberg_overlay_id
    assert reuters["provider"] == "Reuters"
    assert bloomberg["provider"] == "Bloomberg"
    assert reuters["canonical_fact_override"] == false
    assert bloomberg["canonical_fact_override"] == false
    assert reuters["url"] != item["official_source_url"]
    assert bloomberg["url"] != item["official_source_url"]
  end

  test "canonical feed item counts remain official-only" do
    assert canonical_count(@official_event_id) == 1
    assert canonical_count(@reuters_overlay_id) == 0
    assert canonical_count(@bloomberg_overlay_id) == 0
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
