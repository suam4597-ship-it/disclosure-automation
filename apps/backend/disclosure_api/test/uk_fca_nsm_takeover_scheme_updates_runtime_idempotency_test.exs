defmodule DisclosureAutomation.UKFCANSMTakeoverSchemeUpdatesRuntimeIdempotencyTest do
  use DisclosureAutomationWeb.ConnCase, async: false

  import Ecto.Query

  alias DisclosureAutomation.Bootstrap
  alias DisclosureAutomation.Digest
  alias DisclosureAutomation.Feed
  alias DisclosureAutomation.Ingestion
  alias DisclosureAutomation.Ops.UKFCANSMTakeoverSchemeUpdatesSource
  alias DisclosureAutomation.Repo
  alias DisclosureAutomation.Schema.CanonicalFeedItem
  alias DisclosureAutomation.Schema.CanonicalItemSource
  alias DisclosureAutomation.Schema.RawDocument
  alias DisclosureAutomation.Schema.RawEvent
  alias DisclosureAutomation.Schema.SourceRegistry
  alias DisclosureAutomation.Sources

  @event_id "uk.fca_nsm.british_land_company_public_limited_company_the.20260420.tender_offer_or_go_private.takeover_or_scheme_update.5c9e4a51_b4c6_4977_86d3_ac8567261289"
  @stable_external_id "NSM:RNS:5c9e4a51-b4c6-4977-86d3-ac8567261289"
  @cursor_value "2026-04-20T06:13:00|RNS|5c9e4a51-b4c6-4977-86d3-ac8567261289"

  setup do
    :ok = Bootstrap.bootstrap()
    {:ok, _source} = Sources.upsert_source(UKFCANSMTakeoverSchemeUpdatesSource.attrs())
    :ok
  end

  test "UK FCA NSM takeover/scheme fixture path closes end-to-end and stays idempotent on repeated poll" do
    assert {:ok, first} =
             Ingestion.poll_source("uk_fca_nsm_takeover_scheme_updates",
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
    assert item1["event_family"] == "takeover_or_scheme_update"
    assert item1["canonical_event_type"] == "tender_offer_or_go_private"
    assert item1["published_at_local"] == "2026-04-20T06:00:00+01:00"
    assert String.starts_with?(item1["published_at_utc"], "2026-04-20T05:00:00")
    assert item1["filing_date_local"] == "2026-04-20"
    assert item1["region_code"] == "uk"
    assert item1["home_market_region_code"] == "uk"
    assert get_in(item1, ["source_meta", "stable_external_id"]) == @stable_external_id
    assert get_in(item1, ["source_meta", "artefact_token"]) == "5c9e4a51-b4c6-4977-86d3-ac8567261289"
    assert get_in(item1, ["source_meta", "cursor_value"]) == @cursor_value
    assert get_in(item1, ["source_meta", "category"]) == "Scheme of Arrangement"

    assert {:ok, event_payload} = Feed.get_event(item1["event_id"])
    assert event_payload["event_id"] == item1["event_id"]
    assert event_payload["event_family"] == "takeover_or_scheme_update"
    assert event_payload["canonical_event_type"] == "tender_offer_or_go_private"

    assert {:ok, hero_payload} = Feed.get_hero()
    assert hero_payload["slot_id"] == "hero.global_priority"
    assert Enum.any?(hero_payload["items"], &(&1["event_id"] == item1["event_id"]))

    assert {:ok, region_payload} = Feed.get_region("uk")
    assert region_payload["slot_id"] == "lane.uk"
    assert Enum.any?(region_payload["items"], &(&1["event_id"] == item1["event_id"]))

    assert {:ok, second} =
             Ingestion.poll_source("uk_fca_nsm_takeover_scheme_updates",
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

    source = Repo.get_by!(SourceRegistry, source_key: "uk_fca_nsm_takeover_scheme_updates")
    canonical_item = Repo.get_by!(CanonicalFeedItem, event_id: item1["event_id"])

    assert Repo.aggregate(
             from(d in RawDocument,
               where:
                 d.source_registry_id == ^source.id and
                   d.external_id == ^"#{@stable_external_id}:artefact-html"
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

    assert {:ok, %{data: source_health, cursors: cursors}} =
             Sources.get_source_health("uk_fca_nsm_takeover_scheme_updates")

    assert source_health.health_status == "healthy"
    assert Enum.any?(cursors, &(&1.cursor_key == "latest_filing_at_and_artefact_id_seen"))
    assert Enum.any?(cursors, &(&1.cursor_value == @cursor_value))
  end
end
