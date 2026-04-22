defmodule DisclosureAutomationWeb.AFMSubstantialHoldingsHttpSmokeTest do
  use DisclosureAutomationWeb.ConnCase, async: false

  alias DisclosureAutomation.Bootstrap
  alias DisclosureAutomation.Ops.AFMSubstantialHoldingsSource
  alias DisclosureAutomation.Sources

  setup do
    :ok = Bootstrap.bootstrap()
    {:ok, _source} = Sources.upsert_source(AFMSubstantialHoldingsSource.attrs())
    :ok
  end

  test "health, poll, hero, region, digest, event, and source health close for AFM substantial holdings fixture", %{conn: conn} do
    conn = get(conn, "/api/health")
    assert json_response(conn, 200)["status"] == "ok"

    conn =
      post(
        build_conn(),
        "/api/admin/sources/afm_substantial_holdings/poll?edition=breaking&use_live_fetch=false&inline_feed=true"
      )

    poll_payload = json_response(conn, 202)
    assert poll_payload["records_seen"] == 1
    assert get_in(poll_payload, ["feed", "mode"]) == "inline"

    hero = get(build_conn(), "/api/feed/hero") |> json_response(200)
    assert hero["slot_id"] == "hero.global_priority"

    region = get(build_conn(), "/api/feed/region/nl") |> json_response(200)
    assert region["slot_id"] == "lane.nl"

    digest = get(build_conn(), "/api/feed/digest/latest?edition=breaking") |> json_response(200)
    assert digest["item_count"] == 1

    [item] = digest["items"]
    event_id = item["event_id"]

    assert event_id ==
             "nl.afm.example_dutch_holdings_n_v.20260312.major_shareholding_or_insider_trade.shareholding_threshold_crossing.0001"

    assert item["published_at_local"] == "2026-03-12T17:45:00+01:00"
    assert String.starts_with?(item["published_at_utc"], "2026-03-12T16:45:00")
    assert item["filing_date_local"] == "2026-03-12"
    assert item["event_family"] == "shareholding_threshold_crossing"
    assert item["canonical_event_type"] == "major_shareholding_or_insider_trade"
    assert item["region_code"] == "nl"
    assert item["home_market_region_code"] == "nl"
    assert get_in(item, ["source_meta", "notification_id"]) == "afm-sh-20260312-0001"

    event = get(build_conn(), "/api/events/#{event_id}") |> json_response(200)
    assert get_in(event, ["data", "event_id"]) == event_id
    assert get_in(event, ["data", "event_family"]) == "shareholding_threshold_crossing"
    assert get_in(event, ["data", "canonical_event_type"]) == "major_shareholding_or_insider_trade"

    source_health = get(build_conn(), "/api/admin/source-health/afm_substantial_holdings") |> json_response(200)
    assert get_in(source_health, ["data", "health_status"]) == "healthy"

    conn =
      post(
        build_conn(),
        "/api/admin/sources/afm_substantial_holdings/poll?edition=breaking&use_live_fetch=false&inline_feed=true"
      )

    _second_poll_payload = json_response(conn, 202)

    digest2 = get(build_conn(), "/api/feed/digest/latest?edition=breaking") |> json_response(200)
    assert digest2["item_count"] == 1
    assert hd(digest2["items"])["event_id"] == event_id
    assert hd(digest2["items"])["event_family"] == item["event_family"]
    assert hd(digest2["items"])["canonical_event_type"] == item["canonical_event_type"]
  end
end
