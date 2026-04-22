defmodule DisclosureAutomationWeb.SEC8KHttpSmokeTest do
  use DisclosureAutomationWeb.ConnCase, async: false

  alias DisclosureAutomation.Bootstrap
  alias DisclosureAutomation.Ops.SEC8KSource
  alias DisclosureAutomation.Sources

  setup do
    :ok = Bootstrap.bootstrap()
    {:ok, _source} = Sources.upsert_source(SEC8KSource.attrs())
    :ok
  end

  test "health, poll, hero, region, digest, event, and source health close for 8-K fixture", %{conn: conn} do
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

    assert item["published_at_local"] == "2026-02-25T15:20:28-05:00"
    assert String.starts_with?(item["published_at_utc"], "2026-02-25T20:20:28")
    assert item["filing_date_local"] == "2026-02-25"
    assert get_in(item, ["source_meta", "accepted_time_fallback"]) == false

    event = get(build_conn(), "/api/events/#{event_id}") |> json_response(200)
    assert get_in(event, ["data", "event_id"]) == event_id

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
  end
end
