defmodule DisclosureAutomation.AFMSubstantialHoldingsRuntimeIdempotencyTest do
  use DisclosureAutomationWeb.ConnCase, async: false

  import Ecto.Query

  alias DisclosureAutomation.Bootstrap
  alias DisclosureAutomation.Digest
  alias DisclosureAutomation.Feed
  alias DisclosureAutomation.Ingestion
  alias DisclosureAutomation.Ops.AFMSubstantialHoldingsSource
  alias DisclosureAutomation.Repo
  alias DisclosureAutomation.Schema.CanonicalFeedItem
  alias DisclosureAutomation.Schema.CanonicalItemSource
  alias DisclosureAutomation.Schema.RawDocument
  alias DisclosureAutomation.Schema.RawEvent
  alias DisclosureAutomation.Schema.SourceRegistry
  alias DisclosureAutomation.Sources

  setup do
    :ok = Bootstrap.bootstrap()
    {:ok, _source} = Sources.upsert_source(AFMSubstantialHoldingsSource.attrs())
    :ok
  end

  test "AFM substantial holdings fixture path closes end-to-end and stays idempotent on repeated poll" do
    assert {:ok, first} =
             Ingestion.poll_source("afm_substantial_holdings",
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

    assert item1["event_id"] ==
             "nl.afm.example_dutch_holdings_n_v.20260312.major_shareholding_or_insider_trade.shareholding_threshold_crossing.0001"

    assert item1["published_at_local"] == "2026-03-12T17:45:00+01:00"
    assert String.starts_with?(item1["published_at_utc"], "2026-03-12T16:45:00")
    assert item1["filing_date_local"] == "2026-03-12"
    assert item1["event_family"] == "shareholding_threshold_crossing"
    assert item1["canonical_event_type"] == "major_shareholding_or_insider_trade"
    assert item1["region_code"] == "nl"
    assert item1["home_market_region_code"] == "nl"
    assert get_in(item1, ["source_meta", "notification_id"]) == "afm-sh-20260312-0001"
    assert get_in(item1, ["source_meta", "threshold"]) == "5%"

    assert {:ok, event_payload} = Feed.get_event(item1["event_id"])
    assert event_payload["event_id"] == item1["event_id"]
    assert event_payload["event_family"] == "shareholding_threshold_crossing"
    assert event_payload["canonical_event_type"] == "major_shareholding_or_insider_trade"

    assert {:ok, hero_payload} = Feed.get_hero()
    assert hero_payload["slot_id"] == "hero.global_priority"
    assert Enum.any?(hero_payload["items"], &(&1["event_id"] == item1["event_id"]))

    assert {:ok, region_payload} = Feed.get_region("nl")
    assert region_payload["slot_id"] == "lane.nl"
    assert Enum.any?(region_payload["items"], &(&1["event_id"] == item1["event_id"]))

    assert {:ok, second} =
             Ingestion.poll_source("afm_substantial_holdings",
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

    source = Repo.get_by!(SourceRegistry, source_key: "afm_substantial_holdings")
    canonical_item = Repo.get_by!(CanonicalFeedItem, event_id: item1["event_id"])

    assert Repo.aggregate(
             from(d in RawDocument,
               where:
                 d.source_registry_id == ^source.id and
                   d.external_id == ^"afm-sh-20260312-0001:register-export"
             ),
             :count
           ) == 1

    assert Repo.aggregate(
             from(d in RawDocument,
               where:
                 d.source_registry_id == ^source.id and
                   d.external_id == ^"afm-sh-20260312-0001:detail-page"
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

    assert {:ok, %{data: source_health, cursors: cursors}} =
             Sources.get_source_health("afm_substantial_holdings")

    assert source_health.health_status == "healthy"
    assert Enum.any?(cursors, &(&1.cursor_key == "latest_notification_seen"))
    assert Enum.any?(cursors, &(&1.cursor_value == "afm-sh-20260312-0001"))
  end
end
