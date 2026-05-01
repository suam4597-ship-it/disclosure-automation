defmodule DisclosureAutomation.Stage5NewsOverlayRawStagingRuntimeIdempotencyTest do
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
  @raw_document_external_id "NEWS-FIXTURE:jp:jp_tdnet_timely_disclosure:140120260430515474:reuters-jp-article-001:article-metadata"
  @raw_event_external_id "news_overlay:jp.tdnet.4527.20260430.material_information_update.material_information_update.140120260430515474:ba9e08fb9a92ac57:overlay-candidate"
  @cursor_key "latest_article_published_at_and_article_external_id_seen"
  @cursor_value "2026-04-30T10:30:00Z|NEWS-FIXTURE:jp:jp_tdnet_timely_disclosure:140120260430515474:reuters-jp-article-001"

  setup do
    :ok = Bootstrap.bootstrap()
    {:ok, _source} = Sources.upsert_source(JPTDnetTimelyDisclosureSource.attrs())
    {:ok, _source} = Sources.upsert_source(Stage5NewsOverlayFixtureSource.attrs())
    :ok
  end

  test "Reuters overlay fixture stages as raw document/raw event and does not mutate TDnet canonical item" do
    assert {:ok, official_poll} = poll_tdnet_once()
    assert official_poll.records_seen == 1
    assert canonical_count(@official_event_id) == 1

    official_before = canonical_contract(@official_event_id)
    assert official_before["event_id"] == @official_event_id
    assert get_in(official_before, ["source_meta", "stable_external_id"]) == @official_stable_external_id
    assert official_before["published_at_local"] == "2026-04-30T19:00:00+09:00"
    assert String.starts_with?(official_before["published_at_utc"], "2026-04-30T10:00:00")
    assert official_before["canonical_event_type"] == "material_information_update"

    assert {:ok, first} = Stage5NewsOverlayRawStaging.stage_once()
    assert first.records_seen == 1
    assert first.mode == "raw_staging"
    assert first.canonical_feed_mutation == false
    assert first.article_external_id == @article_external_id
    assert first.overlay_id == @overlay_id
    assert first.raw_document_external_id == @raw_document_external_id
    assert first.raw_event_external_id == @raw_event_external_id
    assert first.cursor_key == @cursor_key
    assert first.cursor_value == @cursor_value

    assert {:ok, second} = Stage5NewsOverlayRawStaging.stage_once()
    assert second.records_seen == 1
    assert second.overlay_id == first.overlay_id
    assert second.raw_document_external_id == first.raw_document_external_id
    assert second.raw_event_external_id == first.raw_event_external_id

    {:ok, overlay_source} = Sources.get_source_by_key("stage5_news_overlay_fixture")
    assert raw_document_count(overlay_source.id, @raw_document_external_id) == 1
    assert raw_event_count(overlay_source.id, @raw_event_external_id) == 1

    payload = raw_event_payload(overlay_source.id, @raw_event_external_id)
    assert payload["overlay_id"] == @overlay_id
    assert payload["article_external_id"] == @article_external_id
    assert payload["canonical_event_id"] == @official_event_id
    assert payload["canonical_feed_mutation"] == false
    assert payload["news_only_event_creation"] == false
    assert payload["source_tier"] == "reputable_news_source"
    assert payload["document_role"] == "news_article"
    assert payload["conflict_flags"] == []

    assert Enum.all?(payload["overlay_claims"], &(&1["canonicalFactOverride"] == false))

    citation_tiers = Enum.map(payload["citations"], & &1["sourceTier"])
    assert "official_exchange_storage" in citation_tiers
    assert "reputable_news_source" in citation_tiers

    assert get_in(payload, ["match_evidence", "matchDecisionSource"]) == "manual_fixture_author"
    assert get_in(payload, ["official_facts_preserved", "eventIdUnchanged"]) == true
    assert get_in(payload, ["official_facts_preserved", "stableExternalIdUnchanged"]) == true

    assert canonical_count(@overlay_id) == 0
    assert canonical_count(@official_event_id) == 1

    official_after = canonical_contract(@official_event_id)
    assert official_after["event_id"] == official_before["event_id"]
    assert get_in(official_after, ["source_meta", "stable_external_id"]) == get_in(official_before, ["source_meta", "stable_external_id"])
    assert official_after["published_at_local"] == official_before["published_at_local"]
    assert official_after["published_at_utc"] == official_before["published_at_utc"]
    assert official_after["canonical_event_type"] == official_before["canonical_event_type"]

    assert {:ok, %{data: source_health, cursors: cursors}} = Sources.get_source_health("stage5_news_overlay_fixture")
    assert source_health.health_status == "healthy"
    assert Enum.any?(cursors, &(&1.cursor_key == @cursor_key))
    assert Enum.any?(cursors, &(&1.cursor_value == @cursor_value))
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

  defp raw_document_count(source_registry_id, external_id) do
    %{rows: [[count]]} =
      Repo.query!(
        "select count(*) from raw_documents where source_registry_id = $1 and external_id = $2",
        [source_registry_id, external_id]
      )

    count
  end

  defp raw_event_count(source_registry_id, external_event_key) do
    %{rows: [[count]]} =
      Repo.query!(
        "select count(*) from raw_events where source_registry_id = $1 and external_event_key = $2",
        [source_registry_id, external_event_key]
      )

    count
  end

  defp raw_event_payload(source_registry_id, external_event_key) do
    %{rows: [[payload]]} =
      Repo.query!(
        "select payload from raw_events where source_registry_id = $1 and external_event_key = $2",
        [source_registry_id, external_event_key]
      )

    payload
  end
end
