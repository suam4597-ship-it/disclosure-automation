defmodule DisclosureAutomation.CNCNInfoBroadAnnouncementFeedRuntimeIdempotencyTest do
  use DisclosureAutomationWeb.ConnCase, async: false

  import Ecto.Query

  alias DisclosureAutomation.Bootstrap
  alias DisclosureAutomation.Digest
  alias DisclosureAutomation.Ingestion
  alias DisclosureAutomation.Ops.CNCNInfoBroadAnnouncementFeedSource
  alias DisclosureAutomation.Repo
  alias DisclosureAutomation.Schema.CanonicalFeedItem
  alias DisclosureAutomation.Schema.RawDocument
  alias DisclosureAutomation.Schema.RawEvent
  alias DisclosureAutomation.Schema.SourceRegistry
  alias DisclosureAutomation.Sources

  @event_ids [
    "cn.cninfo.603660.20260501.major_shareholding_or_insider_trade.ownership_change_update.1225274841",
    "cn.cninfo.603350.20260501.shareholder_meeting.shareholder_meeting_update.1225274838",
    "cn.cninfo.300376.20260501.board_or_management_change.board_change_update.1225274454"
  ]

  @stable_ids [
    "CNINFO:603660:20260501:1225274841",
    "CNINFO:603350:20260501:1225274838",
    "CNINFO:300376:20260501:1225274454"
  ]

  setup do
    :ok = Bootstrap.bootstrap()
    {:ok, _source} = Sources.upsert_source(CNCNInfoBroadAnnouncementFeedSource.attrs())
    :ok
  end

  test "CNInfo broad fixture path closes end-to-end and stays idempotent" do
    assert {:ok, first} = poll_once()
    assert first.records_seen == 3

    assert {:ok, digest1} = Digest.get_latest_digest("breaking")
    assert digest1["item_count"] == 3
    event_ids = Enum.map(digest1["items"], & &1["event_id"])
    assert Enum.sort(event_ids) == Enum.sort(@event_ids)

    for item <- digest1["items"] do
      assert item["region_code"] == "cn"
      assert item["home_market_region_code"] == "cn"
      assert get_in(item, ["source_meta", "date_only_cursor"]) == true
      assert get_in(item, ["source_meta", "announcement_id"]) in ["1225274841", "1225274838", "1225274454"]
      assert get_in(item, ["source_meta", "sec_code"]) in ["603660", "603350", "300376"]
    end

    assert {:ok, second} = poll_once()
    assert second.records_seen == 3

    assert {:ok, digest2} = Digest.get_latest_digest("breaking")
    assert digest2["item_count"] == 3
    assert Enum.sort(Enum.map(digest2["items"], & &1["event_id"])) == Enum.sort(@event_ids)

    source = Repo.get_by!(SourceRegistry, source_key: "cn_cninfo_broad_announcement_feed")
    assert Repo.aggregate(from(e in RawEvent, where: e.source_registry_id == ^source.id), :count) == 3
    assert Repo.aggregate(from(i in CanonicalFeedItem, where: i.event_id in ^@event_ids), :count) == 3

    for stable_id <- @stable_ids do
      assert Repo.aggregate(from(d in RawDocument, where: d.source_registry_id == ^source.id and d.external_id == ^"#{stable_id}:discovery-row"), :count) == 1
    end

    assert {:ok, %{data: source_health, cursors: cursors}} = Sources.get_source_health("cn_cninfo_broad_announcement_feed")
    assert source_health.health_status == "healthy"
    assert Enum.any?(cursors, &(&1.cursor_key == "latest_announcement_date_and_announcement_id_seen"))
  end

  defp poll_once do
    Ingestion.poll_source("cn_cninfo_broad_announcement_feed",
      trigger_kind: "manual",
      edition: "breaking",
      use_live_fetch: false,
      inline_feed: true
    )
  end
end
