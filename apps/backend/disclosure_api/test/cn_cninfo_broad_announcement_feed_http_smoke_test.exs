defmodule DisclosureAutomationWeb.CNCNInfoBroadAnnouncementFeedHttpSmokeTest do
  use DisclosureAutomationWeb.ConnCase, async: false

  alias DisclosureAutomation.Bootstrap
  alias DisclosureAutomation.Ops.CNCNInfoBroadAnnouncementFeedSource
  alias DisclosureAutomation.Sources

  @event_ids [
    "cn.cninfo.603660.20260501.major_shareholding_or_insider_trade.ownership_change_update.1225274841",
    "cn.cninfo.603350.20260501.shareholder_meeting.shareholder_meeting_update.1225274838",
    "cn.cninfo.300376.20260501.board_or_management_change.board_change_update.1225274454"
  ]

  setup do
    :ok = Bootstrap.bootstrap()
    {:ok, _source} = Sources.upsert_source(CNCNInfoBroadAnnouncementFeedSource.attrs())
    :ok
  end

  test "health, poll, region, digest, event, and source health close for CNInfo broad fixture", %{conn: conn} do
    conn = get(conn, "/api/health")
    assert json_response(conn, 200)["status"] == "ok"

    conn =
      post(
        build_conn(),
        "/api/admin/sources/cn_cninfo_broad_announcement_feed/poll?edition=breaking&use_live_fetch=false&inline_feed=true"
      )

    poll_payload = json_response(conn, 202)
    assert poll_payload["records_seen"] == 3
    assert get_in(poll_payload, ["feed", "mode"]) == "inline"

    region = get(build_conn(), "/api/feed/region/cn") |> json_response(200)
    assert region["slot_id"] == "lane.cn"

    digest = get(build_conn(), "/api/feed/digest/latest?edition=breaking") |> json_response(200)
    assert digest["item_count"] == 3

    items = digest["items"]
    assert Enum.sort(Enum.map(items, & &1["event_id"])) == Enum.sort(@event_ids)

    for item <- items do
      assert item["region_code"] == "cn"
      assert item["home_market_region_code"] == "cn"
      assert get_in(item, ["source_meta", "date_only_cursor"]) == true
      assert get_in(item, ["source_meta", "announcement_id"]) in ["1225274841", "1225274838", "1225274454"]
      assert get_in(item, ["source_meta", "sec_code"]) in ["603660", "603350", "300376"]
    end

    event = get(build_conn(), "/api/events/#{hd(@event_ids)}") |> json_response(200)
    assert get_in(event, ["data", "event_id"]) == hd(@event_ids)

    source_health = get(build_conn(), "/api/admin/source-health/cn_cninfo_broad_announcement_feed") |> json_response(200)
    assert get_in(source_health, ["data", "health_status"]) == "healthy"

    conn =
      post(
        build_conn(),
        "/api/admin/sources/cn_cninfo_broad_announcement_feed/poll?edition=breaking&use_live_fetch=false&inline_feed=true"
      )

    second_poll_payload = json_response(conn, 202)
    assert second_poll_payload["records_seen"] == 3

    digest2 = get(build_conn(), "/api/feed/digest/latest?edition=breaking") |> json_response(200)
    assert digest2["item_count"] == 3
    assert Enum.sort(Enum.map(digest2["items"], & &1["event_id"])) == Enum.sort(@event_ids)
  end
end
