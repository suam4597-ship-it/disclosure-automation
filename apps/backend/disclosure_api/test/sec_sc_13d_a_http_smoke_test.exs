defmodule DisclosureAutomationWeb.SECSC13DAHttpSmokeTest do
  use DisclosureAutomationWeb.ConnCase, async: false

  alias DisclosureAutomation.Bootstrap
  alias DisclosureAutomation.Ops.SECSC13DASource
  alias DisclosureAutomation.Sources

  setup do
    :ok = Bootstrap.bootstrap()
    {:ok, _source} = Sources.upsert_source(SECSC13DASource.attrs())
    :ok
  end

  test "health, poll, hero, region, digest, event, and source health close for SC 13D amended fixture", %{conn: conn} do
    conn = get(conn, "/api/health")
    assert json_response(conn, 200)["status"] == "ok"

    conn =
      post(
        build_conn(),
        "/api/admin/sources/sec_current_forms/poll?edition=breaking&use_live_fetch=false&inline_feed=true"
      )

    poll_payload = json_response(conn, 202)
    assert poll_payload["records_seen"] == 1
    assert get_in(poll_payload, ["feed", "mode"]) == "inline"

    hero = get(build_conn(), "/api/feed/hero") |> json_response(200)
    assert hero["slot_id"] == "hero.global_priority"

    region = get(build_conn(), "/api/feed/region/us") |> json_response(200)
    assert region["slot_id"] == "lane.us"

    digest = get(build_conn(), "/api/feed/digest/latest?edition=breaking") |> json_response(200)
    assert digest["item_count"] == 1

    [item] = digest["items"]
    event_id = item["event_id"]

    assert event_id == "us.sec.1512345.20260310.major_shareholding_or_insider_trade.control_change_watch.000789"
    assert item["published_at_local"] == "2026-03-10T09:42:18-04:00"
    assert String.starts_with?(item["published_at_utc"], "2026-03-10T13:42:18")
    assert item["filing_date_local"] == "2026-03-10"
    assert get_in(item, ["source_meta", "accepted_time_fallback"]) == false
    assert item["event_family"] == "control_change_watch"
    assert item["canonical_event_type"] == "major_shareholding_or_insider_trade"

    event = get(build_conn(), "/api/events/#{event_id}") |> json_response(200)
    assert get_in(event, ["data", "event_id"]) == event_id
    assert get_in(event, ["data", "event_family"]) == "control_change_watch"
    assert get_in(event, ["data", "canonical_event_type"]) == "major_shareholding_or_insider_trade"

    source_health = get(build_conn(), "/api/admin/source-health/sec_current_forms") |> json_response(200)
    assert get_in(source_health, ["data", "health_status"]) == "healthy"

    conn =
      post(
        build_conn(),
        "/api/admin/sources/sec_current_forms/poll?edition=breaking&use_live_fetch=false&inline_feed=true"
      )

    _second_poll_payload = json_response(conn, 202)

    digest2 = get(build_conn(), "/api/feed/digest/latest?edition=breaking") |> json_response(200)
    assert digest2["item_count"] == 1
    assert hd(digest2["items"])["event_id"] == event_id
    assert hd(digest2["items"])["event_family"] == item["event_family"]
    assert hd(digest2["items"])["canonical_event_type"] == item["canonical_event_type"]
  end
end
