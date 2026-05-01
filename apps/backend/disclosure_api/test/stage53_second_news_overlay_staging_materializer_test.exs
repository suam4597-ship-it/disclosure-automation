defmodule DisclosureAutomation.Stage53SecondNewsOverlayStagingMaterializerTest do
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
  alias DisclosureAutomation.Schema.NewsOverlayAttachment
  alias DisclosureAutomation.Sources

  @official_event_id "jp.tdnet.4527.20260430.material_information_update.material_information_update.140120260430515474"
  @reuters_overlay_id "news_overlay:jp.tdnet.4527.20260430.material_information_update.material_information_update.140120260430515474:ba9e08fb9a92ac57"
  @bloomberg_overlay_id "news_overlay:jp.tdnet.4527.20260430.material_information_update.material_information_update.140120260430515474:bloomberg-jp-article-001"

  setup do
    :ok = Bootstrap.bootstrap()
    {:ok, _source} = Sources.upsert_source(JPTDnetTimelyDisclosureSource.attrs())
    {:ok, _source} = Sources.upsert_source(Stage5NewsOverlayFixtureSource.attrs())
    {:ok, _source} = Sources.upsert_source(Stage53SecondNewsOverlayFixtureSource.attrs())
    :ok
  end

  test "stages second provider overlay and materializes two attachments idempotently", %{conn: conn} do
    assert {:ok, official_poll} = poll_tdnet_once()
    assert official_poll.records_seen == 1

    official_before = canonical_contract(@official_event_id)

    assert {:ok, reuters_stage} = Stage5NewsOverlayRawStaging.stage_once()
    assert reuters_stage.overlay_id == @reuters_overlay_id
    assert reuters_stage.canonical_feed_mutation == false

    assert {:ok, bloomberg_stage} = Stage53SecondNewsOverlayRawStaging.stage_once()
    assert bloomberg_stage.overlay_id == @bloomberg_overlay_id
    assert bloomberg_stage.canonical_feed_mutation == false

    assert {:ok, first_result} = Stage52NewsOverlayAttachmentMaterializer.materialize_once(@official_event_id)
    assert first_result.attachments_seen == 2
    assert first_result.attachments_upserted == 2
    assert first_result.canonical_feed_mutation == false
    assert first_result.news_only_event_creation == false
    assert attachment_count() == 2

    providers = Repo.all(NewsOverlayAttachment) |> Enum.sort_by(& &1.published_at) |> Enum.map(& &1.overlay_provider)
    assert providers == ["Reuters", "Bloomberg"]

    assert {:ok, second_result} = Stage52NewsOverlayAttachmentMaterializer.materialize_once(@official_event_id)
    assert second_result.attachments_seen == 2
    assert second_result.attachments_upserted == 2
    assert attachment_count() == 2

    event_overlay =
      conn
      |> get("/api/events/#{@official_event_id}/news-overlay")
      |> json_response(200)

    overlays = get_in(event_overlay, ["item", "overlays"])
    assert Enum.map(overlays, & &1["overlayId"]) == [@reuters_overlay_id, @bloomberg_overlay_id]
    assert Enum.all?(overlays, &(&1["canonicalFactOverride"] == false))

    feed_digest =
      conn
      |> recycle()
      |> get("/api/feed/digest/latest?edition=breaking")
      |> json_response(200)

    assert feed_digest["item_count"] == 1
    assert [feed_item] = feed_digest["items"]
    assert Enum.map(feed_item["news_overlays"], & &1["overlay_id"]) == [@reuters_overlay_id, @bloomberg_overlay_id]

    assert canonical_count(@official_event_id) == 1
    assert canonical_count(@reuters_overlay_id) == 0
    assert canonical_count(@bloomberg_overlay_id) == 0

    official_after = canonical_contract(@official_event_id)
    assert official_after["headline_local"] == official_before["headline_local"]
    assert official_after["published_at_utc"] == official_before["published_at_utc"]
    assert official_after["official_source_url"] == official_before["official_source_url"]
  end

  defp poll_tdnet_once do
    Ingestion.poll_source("jp_tdnet_timely_disclosure",
      trigger_kind: "manual",
      edition: "breaking",
      use_live_fetch: false,
      inline_feed: true
    )
  end

  defp attachment_count, do: Repo.aggregate(NewsOverlayAttachment, :count)

  defp canonical_count(event_id) do
    %{rows: [[count]]} = Repo.query!("select count(*) from canonical_feed_items where event_id = $1", [event_id])
    count
  end

  defp canonical_contract(event_id) do
    %{rows: [[contract]]} = Repo.query!("select contract_v1 from canonical_feed_items where event_id = $1", [event_id])
    contract
  end
end
