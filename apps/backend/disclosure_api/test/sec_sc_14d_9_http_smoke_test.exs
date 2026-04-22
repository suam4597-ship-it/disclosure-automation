defmodule DisclosureAutomationWeb.SECSC14D9HttpSmokeTest do
  use DisclosureAutomationWeb.ConnCase, async: false

  alias DisclosureAutomation.Bootstrap
  alias DisclosureAutomation.Ops.SECSC14D9Source
  alias DisclosureAutomation.Sources

  setup do
    :ok = Bootstrap.bootstrap()
    {:ok, _source} = Sources.upsert_source(SECSC14D9Source.attrs())
    :ok
  end

  test "health, poll, hero, region, digest, event, and source health close for SC 14D-9 fixture", %{conn: conn} do
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

    assert is_binary(event_id) and event_id != ""
    assert item["published_at_local"] == "2026-03-03T10:15:45-05:00"
    assert String.starts_with?(item["published_at_utc"], "2026-03-03T15:15:45")
    assert item["filing_date_local"] == "2026-03-03"
    assert get_in(item, ["source_meta", "accepted_time_fallback"]) == false
    assert is_binary(item["event_family"]) and item["event_family"] != ""
    assert is_binary(item["canonical_event_type"]) and item["canonical_event_type"] != ""

    event = get(build_conn(), "/api/events/#{event_id}") |> json_response(200)
    assert get_in(event, ["data", "event_id"]) == event_id
    assert is_binary(get_in(event, ["data", "event_family"])) and get_in(event, ["data", "event_family"]) != ""
    assert is_binary(get_in(event, ["data", "canonical_event_type"])) and get_in(event, ["data", "canonical_event_type"]) != ""

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
