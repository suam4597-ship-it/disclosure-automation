defmodule DisclosureAutomation.TWMOPSMaterialInformationRuntimeIdempotencyTest do
  use DisclosureAutomationWeb.ConnCase, async: false

  import Ecto.Query

  alias DisclosureAutomation.Bootstrap
  alias DisclosureAutomation.Digest
  alias DisclosureAutomation.Feed
  alias DisclosureAutomation.Ingestion
  alias DisclosureAutomation.Ops.TWMOPSMaterialInformationSource
  alias DisclosureAutomation.Repo
  alias DisclosureAutomation.Schema.CanonicalFeedItem
  alias DisclosureAutomation.Schema.CanonicalItemSource
  alias DisclosureAutomation.Schema.RawDocument
  alias DisclosureAutomation.Schema.RawEvent
  alias DisclosureAutomation.Schema.SourceRegistry
  alias DisclosureAutomation.Sources

  @event_id "tw.mops.2330.20260430.major_investment_or_asset_sale.material_information_update.1"
  @stable_external_id "MOPS:2330:20260430:162938:1"
  @cursor_value "20260430|162938|2330|1"

  setup do
    :ok = Bootstrap.bootstrap()
    {:ok, _source} = Sources.upsert_source(TWMOPSMaterialInformationSource.attrs())
    :ok
  end

  test "TW MOPS material information fixture path closes end-to-end and stays idempotent on repeated poll" do
    assert {:ok, first} =
             Ingestion.poll_source("tw_mops_material_information",
               trigger_kind: "manual",
               edition: "breaking",
               use_live_fetch: false,
               inline_feed: true
             )

    assert first.records_seen == 1
    assert get_in(first, [:feed, :mode]) == "inline"

    assert {:ok, digest1} = Digest.get_latest_digest("breaking")
    assert digest1["item_count"] == 1

    [item1] = digest1["items"]

    assert item1["event_id"] == @event_id
    assert item1["event_family"] == "material_information_update"
    assert item1["canonical_event_type"] == "major_investment_or_asset_sale"
    assert item1["published_at_local"] == "2026-04-30T16:29:38+08:00"
    assert String.starts_with?(item1["published_at_utc"], "2026-04-30T08:29:38")
    assert item1["filing_date_local"] == "2026-04-30"
    assert item1["region_code"] == "tw"
    assert item1["home_market_region_code"] == "tw"
    assert get_in(item1, ["source_meta", "stable_external_id"]) == @stable_external_id
    assert get_in(item1, ["source_meta", "cursor_value"]) == @cursor_value
    assert get_in(item1, ["source_meta", "skey"]) == "2330202604301"
    assert get_in(item1, ["source_meta", "roc_date"]) == "115/04/30"
    assert get_in(item1, ["source_meta", "clause"]) == "符合條款 第 20 款"

    assert {:ok, event_payload} = Feed.get_event(item1["event_id"])
    assert event_payload["event_id"] == item1["event_id"]
    assert event_payload["event_family"] == "material_information_update"
    assert event_payload["canonical_event_type"] == "major_investment_or_asset_sale"

    assert {:ok, hero_payload} = Feed.get_hero()
    assert hero_payload["slot_id"] == "hero.global_priority"
    assert Enum.any?(hero_payload["items"], &(&1["event_id"] == item1["event_id"]))

    assert {:ok, region_payload} = Feed.get_region("tw")
    assert region_payload["slot_id"] == "lane.tw"
    assert Enum.any?(region_payload["items"], &(&1["event_id"] == item1["event_id"]))

    assert {:ok, second} =
             Ingestion.poll_source("tw_mops_material_information",
               trigger_kind: "manual",
               edition: "breaking",
               use_live_fetch: false,
               inline_feed: true
             )

    assert second.records_seen == 1
    assert get_in(second, [:feed, :mode]) == "inline"

    assert {:ok, digest2} = Digest.get_latest_digest("breaking")
    assert digest2["item_count"] == 1

    [item2] = digest2["items"]
    assert item2["event_id"] == item1["event_id"]
    assert item2["event_family"] == item1["event_family"]
    assert item2["canonical_event_type"] == item1["canonical_event_type"]

    source = Repo.get_by!(SourceRegistry, source_key: "tw_mops_material_information")
    canonical_item = Repo.get_by!(CanonicalFeedItem, event_id: item1["event_id"])

    assert Repo.aggregate(
             from(d in RawDocument,
               where:
                 d.source_registry_id == ^source.id and
                   d.external_id == ^"#{@stable_external_id}:detail-page"
             ),
             :count
           ) == 1

    assert Repo.aggregate(
             from(d in RawDocument,
               where:
                 d.source_registry_id == ^source.id and
                   d.external_id == ^"#{@stable_external_id}:discovery-row"
             ),
             :count
           ) == 1

    assert Repo.aggregate(
             from(e in RawEvent, where: e.source_registry_id == ^source.id),
             :count
           ) == 1

    assert Repo.aggregate(
             from(i in CanonicalFeedItem, where: i.event_id == ^item1["event_id"]),
             :count
           ) == 1

    assert Repo.aggregate(
             from(s in CanonicalItemSource,
               where: s.canonical_feed_item_id == ^canonical_item.id
             ),
             :count
           ) == 2

    assert Repo.aggregate(
             from(s in CanonicalItemSource,
               where:
                 s.canonical_feed_item_id == ^canonical_item.id and
                   s.is_representative == true
             ),
             :count
           ) == 1

    assert {:ok, %{data: source_health, cursors: cursors}} = Sources.get_source_health("tw_mops_material_information")

    assert source_health.health_status == "healthy"
    assert Enum.any?(cursors, &(&1.cursor_key == "latest_spoke_date_time_and_sequence_seen"))
    assert Enum.any?(cursors, &(&1.cursor_value == @cursor_value))
  end
end
