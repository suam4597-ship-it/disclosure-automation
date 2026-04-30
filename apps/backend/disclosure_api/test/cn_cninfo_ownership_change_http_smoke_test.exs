defmodule DisclosureAutomationWeb.CNCNInfoOwnershipChangeHttpSmokeTest do
  use DisclosureAutomationWeb.ConnCase, async: false

  alias DisclosureAutomation.Bootstrap
  alias DisclosureAutomation.Ops.CNCNInfoOwnershipChangeSource
  alias DisclosureAutomation.Sources

  @event_id "cn.cninfo.000404.20260330.major_shareholding_or_insider_trade.ownership_change_update.1225049497"

  setup do
    :ok = Bootstrap.bootstrap()
    {:ok, _source} = Sources.upsert_source(CNCNInfoOwnershipChangeSource.attrs())
    :ok
  end

  test "health, poll, hero, region, digest, event, and source health close for CNInfo ownership-change fixture", %{conn: conn} do
    conn = get(conn, "/api/health")
    assert json_response(conn, 200)["status"] == "ok"

    conn =
      post(
        build_conn(),
        "/api/admin/sources/cn_cninfo_ownership_change/poll?edition=breaking&use_live_fetch=false&inline_feed=true"
      )

    poll_payload = json_response(conn, 202)
    assert poll_payload["records_seen"] == 1
    assert get_in(poll_payload, ["feed", "mode"]) == "inline"

    hero = get(build_conn(), "/api/feed/hero") |> json_response(200)
    assert hero["slot_id"] == "hero.global_priority"

    region = get(build_conn(), "/api/feed/region/cn") |> json_response(200)
    assert region["slot_id"] == "lane.cn"

    digest = get(build_conn(), "/api/feed/digest/latest?edition=breaking") |> json_response(200)
    assert digest["item_count"] == 1

    [item] = digest["items"]
    assert item["event_id"] == @event_id
    assert item["event_family"] == "ownership_change_update"
    assert item["canonical_event_type"] == "major_shareholding_or_insider_trade"
    assert item["published_at_local"] == "2026-03-30T00:00:00+08:00"
    assert String.starts_with?(item["published_at_utc"], "2026-03-29T16:00:00")
    assert item["filing_date_local"] == "2026-03-30"
    assert item["region_code"] == "cn"
    assert item["home_market_region_code"] == "cn"
    assert get_in(item, ["source_meta", "stable_external_id"]) == "CNINFO:1225049497"
    assert get_in(item, ["source_meta", "cursor_value"]) == "2026-03-30|1225049497"
    assert get_in(item, ["source_meta", "sec_code"]) == "000404"

    event = get(build_conn(), "/api/events/#{@event_id}") |> json_response(200)
    assert get_in(event, ["data", "event_id"]) == @event_id
    assert get_in(event, ["data", "event_family"]) == "ownership_change_update"
    assert get_in(event, ["data", "canonical_event_type"]) == "major_shareholding_or_insider_trade"

    source_health = get(build_conn(), "/api/admin/source-health/cn_cninfo_ownership_change") |> json_response(200)
    assert get_in(source_health, ["data", "health_status"]) == "healthy"

    conn =
      post(
        build_conn(),
        "/api/admin/sources/cn_cninfo_ownership_change/poll?edition=breaking&use_live_fetch=false&inline_feed=true"
      )

    second_poll_payload = json_response(conn, 202)
    assert second_poll_payload["records_seen"] == 1

    digest2 = get(build_conn(), "/api/feed/digest/latest?edition=breaking") |> json_response(200)
    assert digest2["item_count"] == 1
    assert hd(digest2["items"])["event_id"] == @event_id
    assert hd(digest2["items"])["event_family"] == item["event_family"]
    assert hd(digest2["items"])["canonical_event_type"] == item["canonical_event_type"]
  end
end
