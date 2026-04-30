defmodule DisclosureAutomation.JPTDnetTimelyDisclosureRuntimeIdempotencyTest do
  use DisclosureAutomationWeb.ConnCase, async: false

  import Ecto.Query

  alias DisclosureAutomation.Bootstrap
  alias DisclosureAutomation.Digest
  alias DisclosureAutomation.Feed
  alias DisclosureAutomation.Ingestion
  alias DisclosureAutomation.Ops.JPTDnetTimelyDisclosureSource
  alias DisclosureAutomation.Repo
  alias DisclosureAutomation.Schema.CanonicalFeedItem
  alias DisclosureAutomation.Schema.CanonicalItemSource
  alias DisclosureAutomation.Schema.RawDocument
  alias DisclosureAutomation.Schema.RawEvent
  alias DisclosureAutomation.Schema.SourceRegistry
  alias DisclosureAutomation.Sources

  @event_id "jp.tdnet.4527.20260430.material_information_update.material_information_update.140120260430515474"
  @stable_external_id "TDNET:4527:20260430:1900:140120260430515474"
  @cursor_key "latest_disclosure_datetime_security_code_and_pdf_token_seen"
  @cursor_value "2026-04-30T19:00:00+09:00|4527|140120260430515474"

  setup do
    :ok = Bootstrap.bootstrap()
    {:ok, _source} = Sources.upsert_source(JPTDnetTimelyDisclosureSource.attrs())
    :ok
  end

  test "TDnet fixture path closes end-to-end and stays idempotent" do
    assert {:ok, first} = poll_once()
    assert first.records_seen == 1
    assert get_in(first, [:feed, :mode]) == "inline"

    assert {:ok, digest1} = Digest.get_latest_digest("breaking")
    assert digest1["item_count"] == 1

    [item1] = digest1["items"]
    assert_frozen_item(item1)

    assert {:ok, event_payload} = Feed.get_event(item1["event_id"])
    assert event_payload["event_id"] == item1["event_id"]
    assert event_payload["event_family"] == "material_information_update"
    assert event_payload["canonical_event_type"] == "material_information_update"

    assert {:ok, hero_payload} = Feed.get_hero()
    assert hero_payload["slot_id"] == "hero.global_priority"
    assert Enum.any?(hero_payload["items"], &(&1["event_id"] == item1["event_id"]))

    assert {:ok, region_payload} = Feed.get_region("jp")
    assert region_payload["slot_id"] == "lane.jp"
    assert Enum.any?(region_payload["items"], &(&1["event_id"] == item1["event_id"]))

    assert {:ok, second} = poll_once()
    assert second.records_seen == 1
    assert get_in(second, [:feed, :mode]) == "inline"

    assert {:ok, digest2} = Digest.get_latest_digest("breaking")
    assert digest2["item_count"] == 1

    [item2] = digest2["items"]
    assert item2["event_id"] == item1["event_id"]
    assert item2["event_family"] == item1["event_family"]
    assert item2["canonical_event_type"] == item1["canonical_event_type"]

    assert_storage_idempotency(item1["event_id"])

    assert {:ok, %{data: source_health, cursors: cursors}} = Sources.get_source_health("jp_tdnet_timely_disclosure")
    assert source_health.health_status == "healthy"
    assert Enum.any?(cursors, &(&1.cursor_key == @cursor_key))
    assert Enum.any?(cursors, &(&1.cursor_value == @cursor_value))
  end

  defp poll_once do
    Ingestion.poll_source("jp_tdnet_timely_disclosure",
      trigger_kind: "manual",
      edition: "breaking",
      use_live_fetch: false,
      inline_feed: true
    )
  end

  defp assert_frozen_item(item) do
    assert item["event_id"] == @event_id
    assert item["event_family"] == "material_information_update"
    assert item["canonical_event_type"] == "material_information_update"
    assert item["published_at_local"] == "2026-04-30T19:00:00+09:00"
    assert String.starts_with?(item["published_at_utc"], "2026-04-30T10:00:00")
    assert item["filing_date_local"] == "2026-04-30"
    assert item["region_code"] == "jp"
    assert item["home_market_region_code"] == "jp"
    assert get_in(item, ["source_meta", "stable_external_id"]) == @stable_external_id
    assert get_in(item, ["source_meta", "cursor_key"]) == @cursor_key
    assert get_in(item, ["source_meta", "cursor_value"]) == @cursor_value
    assert get_in(item, ["source_meta", "tdnet_raw_row_code"]) == "45270"
    assert get_in(item, ["source_meta", "normalized_security_code"]) == "4527"
    assert get_in(item, ["source_meta", "pdf_document_token"]) == "140120260430515474"
    assert get_in(item, ["source_meta", "source_category"]) == nil
    assert get_in(item, ["source_meta", "material_category"]) == "unknown"
    assert get_in(item, ["source_meta", "source_category_inferred"]) == false
  end

  defp assert_storage_idempotency(event_id) do
    source = Repo.get_by!(SourceRegistry, source_key: "jp_tdnet_timely_disclosure")
    canonical_item = Repo.get_by!(CanonicalFeedItem, event_id: event_id)

    assert Repo.aggregate(from(d in RawDocument, where: d.source_registry_id == ^source.id and d.external_id == ^"#{@stable_external_id}:discovery-row"), :count) == 1
    assert Repo.aggregate(from(d in RawDocument, where: d.source_registry_id == ^source.id and d.external_id == ^"#{@stable_external_id}:pdf:140120260430515474"), :count) == 1
    assert Repo.aggregate(from(e in RawEvent, where: e.source_registry_id == ^source.id), :count) == 1
    assert Repo.aggregate(from(i in CanonicalFeedItem, where: i.event_id == ^event_id), :count) == 1
    assert Repo.aggregate(from(s in CanonicalItemSource, where: s.canonical_feed_item_id == ^canonical_item.id), :count) == 2
    assert Repo.aggregate(from(s in CanonicalItemSource, where: s.canonical_feed_item_id == ^canonical_item.id and s.is_representative == true), :count) == 1
  end
end
