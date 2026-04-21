defmodule DisclosureAutomation.SECSCToTRuntimeIdempotencyTest do
  use DisclosureAutomationWeb.ConnCase, async: false

  import Ecto.Query

  alias DisclosureAutomation.Bootstrap
  alias DisclosureAutomation.Digest
  alias DisclosureAutomation.Feed
  alias DisclosureAutomation.Ingestion
  alias DisclosureAutomation.Ops.SECSCToTSource
  alias DisclosureAutomation.Repo
  alias DisclosureAutomation.Schema.CanonicalFeedItem
  alias DisclosureAutomation.Schema.CanonicalItemSource
  alias DisclosureAutomation.Schema.RawDocument
  alias DisclosureAutomation.Schema.RawEvent
  alias DisclosureAutomation.Schema.SourceRegistry
  alias DisclosureAutomation.Sources

  setup do
    :ok = Bootstrap.bootstrap()
    {:ok, _source} = Sources.upsert_source(SECSCToTSource.attrs())
    :ok
  end

  test "SC TO-T fixture path closes end-to-end and stays idempotent on repeated poll" do
    assert {:ok, first} =
             Ingestion.poll_source("sec_current_forms",
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
    assert item1["published_at_local"] == "2026-02-26T11:11:11-05:00"
    assert String.starts_with?(item1["published_at_utc"], "2026-02-26T16:11:11")
    assert item1["filing_date_local"] == "2026-02-26"
    assert get_in(item1, ["source_meta", "accepted_time_fallback"]) == false
    assert item1["event_family"] == "cash_tender_offer"
    refute String.contains?(item1["fact_summary_ko"], "</TEXT>")
    refute String.contains?(item1["fact_summary_ko"], "</SEC-DOCUMENT>")

    assert {:ok, event_payload} = Feed.get_event(item1["event_id"])
    assert event_payload["event_id"] == item1["event_id"]

    assert {:ok, hero_payload} = Feed.get_hero()
    assert hero_payload["slot_id"] == "hero.global_priority"
    assert Enum.any?(hero_payload["items"], &(&1["event_id"] == item1["event_id"]))

    assert {:ok, region_payload} = Feed.get_region("us")
    assert region_payload["slot_id"] == "lane.us"
    assert Enum.any?(region_payload["items"], &(&1["event_id"] == item1["event_id"]))

    assert {:ok, second} =
             Ingestion.poll_source("sec_current_forms",
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

    source = Repo.get_by!(SourceRegistry, source_key: "sec_current_forms")
    canonical_item = Repo.get_by!(CanonicalFeedItem, event_id: item1["event_id"])

    assert Repo.aggregate(
             from(d in RawDocument,
               where:
                 d.source_registry_id == ^source.id and
                   d.external_id == ^"0000950123-26-001234:submission-text"
             ),
             :count
           ) == 1

    assert Repo.aggregate(
             from(d in RawDocument,
               where:
                 d.source_registry_id == ^source.id and
                   d.external_id == ^"0000950123-26-001234:detail-index"
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
             Sources.get_source_health("sec_current_forms")

    assert source_health.health_status == "healthy"
    assert Enum.any?(cursors, &(&1.cursor_key == "latest_accession_seen"))
    assert Enum.any?(cursors, &(&1.cursor_value == "0000950123-26-001234"))
  end
end
