defmodule DisclosureAutomation.Stage52NewsOverlayAttachmentMaterializerTest do
  use DisclosureAutomationWeb.ConnCase, async: false

  alias DisclosureAutomation.Bootstrap
  alias DisclosureAutomation.Ingestion
  alias DisclosureAutomation.Ops.JPTDnetTimelyDisclosureSource
  alias DisclosureAutomation.Ops.Stage5NewsOverlayFixtureSource
  alias DisclosureAutomation.Repo
  alias DisclosureAutomation.Runtime.Stage52NewsOverlayAttachmentMaterializer
  alias DisclosureAutomation.Runtime.Stage5NewsOverlayRawStaging
  alias DisclosureAutomation.Schema.NewsOverlayAttachment
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

  test "materializes one visible Reuters attachment from locked Stage 5.1 raw staging and is idempotent", %{conn: conn} do
    assert {:ok, official_poll} = poll_tdnet_once()
    assert official_poll.records_seen == 1

    official_before = canonical_contract(@official_event_id)

    assert {:ok, empty_result} = Stage52NewsOverlayAttachmentMaterializer.materialize_once(@official_event_id)
    assert empty_result.attachments_seen == 0
    assert empty_result.attachments_upserted == 0
    assert attachment_count() == 0

    assert {:ok, staged} = Stage5NewsOverlayRawStaging.stage_once()
    assert staged.overlay_id == @overlay_id

    assert {:ok, first_result} = Stage52NewsOverlayAttachmentMaterializer.materialize_once(@official_event_id)
    assert first_result.mode == "materialized_attachment"
    assert first_result.attachments_seen == 1
    assert first_result.attachments_upserted == 1
    assert first_result.canonical_feed_mutation == false
    assert first_result.news_only_event_creation == false
    assert attachment_count() == 1

    attachment = Repo.one!(NewsOverlayAttachment)
    assert attachment.official_event_id == @official_event_id
    assert attachment.official_stable_external_id == @official_stable_external_id
    assert attachment.overlay_source_key == "stage5_news_overlay_fixture"
    assert attachment.overlay_provider == "Reuters"
    assert attachment.overlay_external_id == @article_external_id
    assert attachment.overlay_id == @overlay_id
    assert attachment.overlay_mode == "attach_only"
    assert attachment.display_state == "visible"
    assert attachment.canonical_fact_override == false
    assert attachment.source_tier == "reputable_news_source"
    assert attachment.document_role == "news_article"
    assert attachment.title == "英ファンドＡＶＩ、ロートの会長解任議案を提出　企業統治改善求める"
    assert attachment.url == "https://jp.reuters.com/markets/global-markets/JKGTTV5MI5PFRGFVTC37DW73GE-2026-04-30/"
    assert attachment.overlay_payload["canonical_fact_override"] == false
    assert attachment.conflict_flags["items"] == ["provider_url_not_official_url"]
    assert [%{"source_key" => "stage5_news_overlay_fixture", "is_canonical_source" => false}] = attachment.citations["items"]

    assert {:ok, second_result} = Stage52NewsOverlayAttachmentMaterializer.materialize_once(@official_event_id)
    assert second_result.attachments_seen == 1
    assert second_result.attachments_upserted == 1
    assert attachment_count() == 1

    event_overlay =
      conn
      |> get("/api/events/#{@official_event_id}/news-overlay")
      |> json_response(200)

    assert get_in(event_overlay, ["item", "eventId"]) == @official_event_id
    assert [overlay] = get_in(event_overlay, ["item", "overlays"])
    assert overlay["overlayId"] == @overlay_id

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

    assert canonical_count(@overlay_id) == 0
    assert canonical_count(@official_event_id) == 1

    official_after = canonical_contract(@official_event_id)
    assert official_after["headline_local"] == official_before["headline_local"]
    assert official_after["published_at_utc"] == official_before["published_at_utc"]
    assert official_after["official_source_url"] == official_before["official_source_url"]
    assert get_in(official_after, ["source_meta", "stable_external_id"]) == get_in(official_before, ["source_meta", "stable_external_id"])
  end

  defp poll_tdnet_once do
    Ingestion.poll_source("jp_tdnet_timely_disclosure",
      trigger_kind: "manual",
      edition: "breaking",
      use_live_fetch: false,
      inline_feed: true
    )
  end

  defp attachment_count do
    Repo.aggregate(NewsOverlayAttachment, :count)
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
