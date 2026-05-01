defmodule DisclosureAutomation.Stage52NewsOverlayAttachmentReadPathTest do
  use DisclosureAutomationWeb.ConnCase, async: false

  alias DisclosureAutomation.Bootstrap
  alias DisclosureAutomation.Ingestion
  alias DisclosureAutomation.Ops.JPTDnetTimelyDisclosureSource
  alias DisclosureAutomation.Ops.Stage5NewsOverlayFixtureSource
  alias DisclosureAutomation.Repo
  alias DisclosureAutomation.Runtime.Stage52NewsOverlayAttachmentMaterializer
  alias DisclosureAutomation.Runtime.Stage5NewsOverlayRawStaging
  alias DisclosureAutomation.Runtime.Stage5NewsOverlayReadModel
  alias DisclosureAutomation.Schema.NewsOverlayAttachment
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

  test "read model prefers materialized attachments while preserving API and feed response shape", %{conn: conn} do
    assert {:ok, official_poll} = poll_tdnet_once()
    assert official_poll.records_seen == 1

    assert {:ok, staged} = Stage5NewsOverlayRawStaging.stage_once()
    assert staged.overlay_id == @overlay_id

    assert {:ok, raw_response} = Stage5NewsOverlayReadModel.get_by_event_id(@official_event_id)
    assert [raw_overlay] = raw_response.item.overlays
    assert raw_overlay.overlayId == @overlay_id
    assert raw_overlay.articleExternalId == @article_external_id

    assert {:ok, materialized} = Stage52NewsOverlayAttachmentMaterializer.materialize_once(@official_event_id)
    assert materialized.attachments_seen == 1
    assert materialized.attachments_upserted == 1
    assert Repo.aggregate(NewsOverlayAttachment, :count) == 1

    assert {:ok, attached_response} = Stage5NewsOverlayReadModel.get_by_event_id(@official_event_id)
    assert [attached_overlay] = attached_response.item.overlays

    assert attached_overlay.overlayId == raw_overlay.overlayId
    assert attached_overlay.overlayMode == raw_overlay.overlayMode
    assert attached_overlay.displayState == raw_overlay.displayState
    assert attached_overlay.sourceKey == raw_overlay.sourceKey
    assert attached_overlay.provider == raw_overlay.provider
    assert attached_overlay.sourceTier == raw_overlay.sourceTier
    assert attached_overlay.documentRole == raw_overlay.documentRole
    assert attached_overlay.articleExternalId == raw_overlay.articleExternalId
    assert attached_overlay.title == raw_overlay.title
    assert attached_overlay.publishedAt == raw_overlay.publishedAt
    assert attached_overlay.url == raw_overlay.url
    assert attached_overlay.canonicalFactOverride == false
    assert attached_overlay.conflictFlags == raw_overlay.conflictFlags

    assert [attached_citation] = attached_overlay.citations
    assert attached_citation.sourceKey == "stage5_news_overlay_fixture"
    assert attached_citation.isCanonicalSource == false

    assert Stage5NewsOverlayReadModel.flattened_citations(attached_response) |> List.first() |> Map.fetch!(:isCanonicalSource)

    event_overlay =
      conn
      |> get("/api/events/#{@official_event_id}/news-overlay")
      |> json_response(200)

    assert get_in(event_overlay, ["item", "eventId"]) == @official_event_id
    assert [api_overlay] = get_in(event_overlay, ["item", "overlays"])
    assert api_overlay["overlayId"] == @overlay_id
    assert api_overlay["articleExternalId"] == @article_external_id
    assert api_overlay["canonicalFactOverride"] == false

    feed_digest =
      conn
      |> recycle()
      |> get("/api/feed/digest/latest?edition=breaking")
      |> json_response(200)

    assert feed_digest["item_count"] == 1
    assert [feed_item] = feed_digest["items"]
    assert feed_item["event_id"] == @official_event_id
    assert [feed_overlay] = feed_item["news_overlays"]
    assert feed_overlay["overlay_id"] == @overlay_id
    assert feed_overlay["article_external_id"] == @article_external_id
    assert feed_overlay["canonical_fact_override"] == false

    assert canonical_count(@overlay_id) == 0
    assert canonical_count(@official_event_id) == 1
  end

  test "read model falls back to Stage 5.1 raw projection when no attachment rows exist" do
    assert {:ok, official_poll} = poll_tdnet_once()
    assert official_poll.records_seen == 1

    assert {:ok, staged} = Stage5NewsOverlayRawStaging.stage_once()
    assert staged.overlay_id == @overlay_id
    assert Repo.aggregate(NewsOverlayAttachment, :count) == 0

    assert {:ok, response} = Stage5NewsOverlayReadModel.get_by_event_id(@official_event_id)
    assert [overlay] = response.item.overlays
    assert overlay.overlayId == @overlay_id
    assert overlay.articleExternalId == @article_external_id
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
end
