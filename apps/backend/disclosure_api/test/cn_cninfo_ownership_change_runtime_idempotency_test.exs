defmodule DisclosureAutomation.CNCNInfoOwnershipChangeRuntimeIdempotencyTest do
  use DisclosureAutomationWeb.ConnCase, async: false

  import Ecto.Query

  alias DisclosureAutomation.Bootstrap
  alias DisclosureAutomation.Digest
  alias DisclosureAutomation.Feed
  alias DisclosureAutomation.Ingestion
  alias DisclosureAutomation.Ops.CNCNInfoOwnershipChangeSource
  alias DisclosureAutomation.Repo
  alias DisclosureAutomation.Schema.CanonicalFeedItem
  alias DisclosureAutomation.Schema.CanonicalItemSource
  alias DisclosureAutomation.Schema.RawDocument
  alias DisclosureAutomation.Schema.RawEvent
  alias DisclosureAutomation.Schema.SourceRegistry
  alias DisclosureAutomation.Sources

  @event_id "cn.cninfo.000404.20260330.major_shareholding_or_insider_trade.ownership_change_update.1225049497"
  @stable_external_id "CNINFO:1225049497"
  @cursor_value "2026-03-30|1225049497"

  setup do
    :ok = Bootstrap.bootstrap()
    {:ok, _source} = Sources.upsert_source(CNCNInfoOwnershipChangeSource.attrs())
    :ok
  end

  test "CNInfo ownership-change fixture path closes end-to-end and stays idempotent on repeated poll" do
    assert {:ok, first} =
             Ingestion.poll_source("cn_cninfo_ownership_change",
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
    assert item1["event_family"] == "ownership_change_update"
    assert item1["canonical_event_type"] == "major_shareholding_or_insider_trade"
    assert item1["published_at_local"] == "2026-03-30T00:00:00+08:00"
    assert String.starts_with?(item1["published_at_utc"], "2026-03-29T16:00:00")
    assert item1["filing_date_local"] == "2026-03-30"
    assert item1["region_code"] == "cn"
    assert item1["home_market_region_code"] == "cn"
    assert get_in(item1, ["source_meta", "stable_external_id"]) == @stable_external_id
    assert get_in(item1, ["source_meta", "cursor_value"]) == @cursor_value
    assert get_in(item1, ["source_meta", "announcement_id"]) == "1225049497"
    assert get_in(item1, ["source_meta", "sec_code"]) == "000404"
    assert get_in(item1, ["source_meta", "sec_name"]) == "长虹华意"
    assert get_in(item1, ["source_meta", "date_only_cursor"]) == true

    assert {:ok, event_payload} = Feed.get_event(item1["event_id"])
    assert event_payload["event_id"] == item1["event_id"]
    assert event_payload["event_family"] == "ownership_change_update"
    assert event_payload["canonical_event_type"] == "major_shareholding_or_insider_trade"

    assert {:ok, hero_payload} = Feed.get_hero()
    assert hero_payload["slot_id"] == "hero.global_priority"
    assert Enum.any?(hero_payload["items"], &(&1["event_id"] == item1["event_id"]))

    assert {:ok, region_payload} = Feed.get_region("cn")
    assert region_payload["slot_id"] == "lane.cn"
    assert Enum.any?(region_payload["items"], &(&1["event_id"] == item1["event_id"]))

    assert {:ok, second} =
             Ingestion.poll_source("cn_cninfo_ownership_change",
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

    source = Repo.get_by!(SourceRegistry, source_key: "cn_cninfo_ownership_change")
    canonical_item = Repo.get_by!(CanonicalFeedItem, event_id: item1["event_id"])

    assert Repo.aggregate(
             from(d in RawDocument,
               where:
                 d.source_registry_id == ^source.id and
                   d.external_id == ^"#{@stable_external_id}:discovery-row"
             ),
             :count
           ) == 1

    assert Repo.aggregate(
             from(d in RawDocument,
               where:
                 d.source_registry_id == ^source.id and
                   d.external_id == ^"#{@stable_external_id}:pdf:1225049497"
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

    assert {:ok, %{data: source_health, cursors: cursors}} = Sources.get_source_health("cn_cninfo_ownership_change")

    assert source_health.health_status == "healthy"
    assert Enum.any?(cursors, &(&1.cursor_key == "latest_announcement_date_and_announcement_id_seen"))
    assert Enum.any?(cursors, &(&1.cursor_value == @cursor_value))
  end
end
